import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/models/expense.dart';
import '../core/models/parsed_receipt.dart';
import '../core/models/classification_result.dart';
import '../core/models/ocr_result.dart';
import 'ocr_service.dart';
import 'receipt_parser.dart';
import 'category_classifier.dart';

/// Complete OCR workflow: Camera → OCR → Parser → Classifier
class OcrWorkflowService {
  final OcrService ocrService;
  final ReceiptParser parser;
  final CategoryClassifier? classifier;

  OcrWorkflowService({
    required this.ocrService,
    required this.parser,
    this.classifier,
  });

  /// Process receipt image through complete workflow
  /// 
  /// Returns [WorkflowResult] containing all processed data
  Future<WorkflowResult> processReceipt({
    required String imagePath,
    bool useClassifier = true,
    void Function(WorkflowStep)? onStepComplete,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Step 1: OCR - Extract text from image
      onStepComplete?.call(WorkflowStep.ocr);
      final ocrResult = await ocrService.recognizeText(imagePath);
      final ocrText = ocrResult.text;
      
      if (ocrText.isEmpty) {
        throw WorkflowException(
          'No text found in image',
          step: WorkflowStep.ocr,
        );
      }

      // Step 2: Parse - Convert text to structured data
      onStepComplete?.call(WorkflowStep.parse);
      final parsedReceipt = await parser.parse(ocrText);
      
      if (parsedReceipt.totalAmount == null) {
        throw WorkflowException(
          'Could not extract total amount from receipt',
          step: WorkflowStep.parse,
        );
      }

      // Step 3: Classify - Determine category
      ClassificationResult? classification;
      if (useClassifier && classifier != null) {
        onStepComplete?.call(WorkflowStep.classify);
        
        try {
          classification = await classifier!.classifyHybrid(
            merchantName: parsedReceipt.merchantName ?? 'Unknown',
            description: parsedReceipt.items?.map((i) => i.description).join(', '),
            amount: parsedReceipt.totalAmount,
          );
        } catch (e) {
          // Classification failure is not critical
          debugPrint('Classification failed: $e');
        }
      }

      onStepComplete?.call(WorkflowStep.complete);

      stopwatch.stop();

      return WorkflowResult(
        success: true,
        imagePath: imagePath,
        ocrResult: ocrResult,
        parsedReceipt: parsedReceipt,
        classification: classification,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      
      if (e is WorkflowException) {
        rethrow;
      }
      
      throw WorkflowException(
        'Workflow failed: $e',
        step: WorkflowStep.ocr,
      );
    }
  }

  /// Process multiple receipts in batch
  Future<List<WorkflowResult>> processBatch({
    required List<String> imagePaths,
    bool useClassifier = true,
    void Function(int current, int total)? onProgress,
  }) async {
    final results = <WorkflowResult>[];
    
    for (int i = 0; i < imagePaths.length; i++) {
      onProgress?.call(i + 1, imagePaths.length);
      
      try {
        final result = await processReceipt(
          imagePath: imagePaths[i],
          useClassifier: useClassifier,
        );
        results.add(result);
      } catch (e) {
        // Continue with other images even if one fails
        results.add(WorkflowResult(
          success: false,
          imagePath: imagePaths[i],
          errorMessage: e.toString(),
          processingTimeMs: 0,
        ));
      }
    }
    
    return results;
  }

  /// Quick validation - check if image contains readable text
  Future<bool> validateImage(String imagePath) async {
    try {
      final ocrResult = await ocrService.recognizeText(imagePath);
      return ocrResult.text.length > 20; // Minimum text threshold
    } catch (e) {
      return false;
    }
  }

  /// Extract preview data without full processing (faster)
  Future<ReceiptPreview> getPreview(String imagePath) async {
    try {
      final ocrResult = await ocrService.recognizeText(imagePath);
      
      // Quick parse to get key fields
      final text = ocrResult.text;
      final lines = text.split('\n');
      
      // Try to find merchant name (usually in first few lines)
      String? merchantName;
      for (final line in lines.take(5)) {
        if (line.trim().length > 3) {
          merchantName = line.trim();
          break;
        }
      }
      
      // Try to find total
      double? total;
      for (final line in lines.reversed) {
        final match = RegExp(r'[\$]?\s*(\d+\.\d{2})').firstMatch(line);
        if (match != null) {
          total = double.tryParse(match.group(1)!);
          if (total != null && total > 0) break;
        }
      }
      
      return ReceiptPreview(
        merchantName: merchantName,
        estimatedTotal: total,
        textLength: text.length,
        hasReadableText: text.length > 20,
      );
    } catch (e) {
      return ReceiptPreview(hasReadableText: false);
    }
  }
}

/// Result of complete workflow processing
class WorkflowResult {
  final bool success;
  final String imagePath;
  final OcrResult? ocrResult;
  final ParsedReceipt? parsedReceipt;
  final ClassificationResult? classification;
  final String? errorMessage;
  final int processingTimeMs;

  WorkflowResult({
    required this.success,
    required this.imagePath,
    this.ocrResult,
    this.parsedReceipt,
    this.classification,
    this.errorMessage,
    required this.processingTimeMs,
  });

  /// Convert to Expense model for database save
  Expense toExpense({
    String? categoryOverride,
    String? notesOverride,
    String? paymentMethodOverride,
  }) {
    if (!success || parsedReceipt == null) {
      throw StateError('Cannot convert failed result to expense');
    }

    return Expense(
      amount: parsedReceipt!.totalAmount ?? 0.0,
      category: categoryOverride ?? 
               classification?.category ?? 
               'Other',
      date: parsedReceipt!.date ?? DateTime.now(),
      merchantName: parsedReceipt!.merchantName,
      notes: notesOverride ?? 
             parsedReceipt!.items?.map((i) => i.description).join(', '),
      paymentMethod: paymentMethodOverride ?? 
                    parsedReceipt!.paymentMethod,
      receiptImagePath: imagePath,
    );
  }

  /// Get confidence level of the result
  double get overallConfidence {
    if (!success) return 0.0;
    
    double confidence = 0.0;
    int count = 0;
    
    if (parsedReceipt?.confidence != null) {
      confidence += parsedReceipt!.confidence!;
      count++;
    }
    
    if (classification?.confidence != null) {
      confidence += classification!.confidence;
      count++;
    }
    
    return count > 0 ? confidence / count : 0.0;
  }

  /// Check if result needs manual review
  bool get needsReview {
    if (!success) return true;
    return overallConfidence < 0.7;
  }

  /// Get summary for display
  String get summary {
    if (!success) {
      return 'Processing failed: ${errorMessage ?? "Unknown error"}';
    }

    final buffer = StringBuffer();
    buffer.writeln('Merchant: ${parsedReceipt?.merchantName ?? "Unknown"}');
    buffer.writeln('Amount: \$${parsedReceipt?.totalAmount?.toStringAsFixed(2) ?? "0.00"}');
    buffer.writeln('Category: ${classification?.category ?? "Unclassified"}');
    buffer.writeln('Confidence: ${(overallConfidence * 100).toStringAsFixed(1)}%');
    buffer.writeln('Processing time: ${processingTimeMs}ms');
    
    return buffer.toString();
  }
}

/// Preview of receipt before full processing
class ReceiptPreview {
  final String? merchantName;
  final double? estimatedTotal;
  final int textLength;
  final bool hasReadableText;

  ReceiptPreview({
    this.merchantName,
    this.estimatedTotal,
    this.textLength = 0,
    required this.hasReadableText,
  });

  String get summary {
    if (!hasReadableText) {
      return 'No readable text detected';
    }
    
    final buffer = StringBuffer();
    if (merchantName != null) {
      buffer.write('Merchant: $merchantName');
    }
    if (estimatedTotal != null) {
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write('Estimated total: \$${estimatedTotal!.toStringAsFixed(2)}');
    }
    if (buffer.isEmpty) {
      buffer.write('Text detected ($textLength characters)');
    }
    
    return buffer.toString();
  }
}

/// Workflow processing steps
enum WorkflowStep {
  ocr,
  parse,
  classify,
  complete,
}

/// Exception during workflow processing
class WorkflowException implements Exception {
  final String message;
  final WorkflowStep step;

  WorkflowException(this.message, {required this.step});

  @override
  String toString() => 'WorkflowException at ${step.name}: $message';
}

/// Factory for creating workflow service with different configurations
class OcrWorkflowFactory {
  /// Create workflow with mock classifier (for testing)
  static OcrWorkflowService createMockWorkflow() {
    return OcrWorkflowService(
      ocrService: OcrService(),
      parser: ReceiptParser(),
      classifier: ClassifierFactory.createMockHybridClassifier(),
    );
  }

  /// Create workflow without classifier (OCR + Parse only)
  static OcrWorkflowService createBasicWorkflow() {
    return OcrWorkflowService(
      ocrService: OcrService(),
      parser: ReceiptParser(),
    );
  }

  /// Create full workflow with real classifier
  static OcrWorkflowService createFullWorkflow({
    required String apiKey,
    String? baseUrl,
    String? model,
  }) {
    return OcrWorkflowService(
      ocrService: OcrService(),
      parser: ReceiptParser(),
      classifier: ClassifierFactory.createHybridClassifier(
        apiKey: apiKey,
        baseUrl: baseUrl,
        model: model,
      ),
    );
  }
}
