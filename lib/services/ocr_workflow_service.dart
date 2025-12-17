import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/models/expense.dart';
import '../core/models/parsed_receipt.dart';
import '../core/models/classification_result.dart';
import '../core/models/ocr_result.dart';
import '../core/config/app_config.dart';
import 'base_ocr_service.dart';
import 'ocr_service.dart';
import 'ocr_service_cloud.dart';
import 'receipt_parser.dart';
import 'category_classifier.dart';

/// Complete OCR workflow: Camera → OCR → Parser → Classifier
class OcrWorkflowService {
  final BaseOcrService ocrService;
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
    debugPrint('\n\ud83d\udd04 WORKFLOW: Starting receipt processing');
    debugPrint('  Image: $imagePath');
    debugPrint('  Use classifier: $useClassifier');
    
    final stopwatch = Stopwatch()..start();
    
    try {
      // Step 1: OCR - Extract text from image
      debugPrint('\n👁️  WORKFLOW Step 1: OCR');
      onStepComplete?.call(WorkflowStep.ocr);
      final ocrResult = await ocrService.recognizeText(imagePath);
      
      // Check if OCR itself failed
      if (!ocrResult.success) {
        throw WorkflowException(
          ocrResult.errorMessage ?? 'OCR processing failed',
          step: WorkflowStep.ocr,
        );
      }
      
      final ocrText = ocrResult.rawText;
      debugPrint('  OCR result: ${ocrText.isEmpty ? "EMPTY" : "${ocrText.length} chars"}');
      
      if (ocrText.isEmpty) {
        throw WorkflowException(
          'No text found in image',
          step: WorkflowStep.ocr,
        );
      }

      // Step 2: Parse - Convert text to structured data
      debugPrint('\n\ud83d\udcca WORKFLOW Step 2: Parse');
      onStepComplete?.call(WorkflowStep.parse);
      
      ParsedReceipt parsedReceipt;
      try {
        parsedReceipt = await parser.parse(ocrText);
        debugPrint('  Merchant: ${parsedReceipt.merchantName ?? "N/A"}');
        debugPrint('  Amount: \$${parsedReceipt.totalAmount ?? "N/A"}');
      } catch (e) {
        debugPrint('  ⚠️ Parser error: $e');
        // Create minimal receipt if parsing fails
        parsedReceipt = ParsedReceipt.empty(
          rawText: ocrText,
          errorMessage: e.toString(),
        );
        // Override with minimal values
        parsedReceipt = ParsedReceipt(
          merchantName: 'Unknown Merchant',
          totalAmount: 0.0,
          date: DateTime.now(),
          items: [],
          confidence: 0.5,
          rawText: ocrText,
          metadata: parsedReceipt.metadata,
        );
      }
      
      // If no amount found, use 0.0 instead of failing
      if (parsedReceipt.totalAmount == null) {
        debugPrint('  ⚠️ No amount found, using 0.0');
        parsedReceipt = ParsedReceipt(
          merchantName: parsedReceipt.merchantName ?? 'Unknown',
          totalAmount: 0.0,
          date: parsedReceipt.date ?? DateTime.now(),
          items: parsedReceipt.items,
          currency: parsedReceipt.currency,
          paymentMethod: parsedReceipt.paymentMethod,
          confidence: parsedReceipt.confidence,
          rawText: parsedReceipt.rawText,
          metadata: parsedReceipt.metadata,
        );
      }

      // Step 3: Classify - Determine category (rule-based)
      debugPrint('\n🤖 WORKFLOW Step 3: Classify');
      onStepComplete?.call(WorkflowStep.classify);
      
      ClassificationResult classification;
      if (useClassifier && classifier != null) {
        try {
          final classifyStart = stopwatch.elapsedMilliseconds;
          classification = await classifier!.classify(
            merchantName: parsedReceipt.merchantName ?? 'Unknown',
            description: parsedReceipt.items.map((i) => i.name).join(', '),
            amount: parsedReceipt.totalAmount,
          ).timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('⏱️ Classification timeout, using default');
              return ClassificationResult.fromRule(
                category: 'Shopping',
                confidence: 0.3,
                candidateScores: {'Shopping': 0.3},
                processingTimeMs: 2000,
              );
            },
          );
          final classifyTime = stopwatch.elapsedMilliseconds - classifyStart;
          debugPrint('  Category: ${classification.category}');
          debugPrint('  Confidence: ${(classification.confidence * 100).toStringAsFixed(1)}%');
          debugPrint('  Time: ${classifyTime}ms');
        } catch (e) {
          debugPrint('  ⚠️ Classification error: $e');
          classification = ClassificationResult.fromRule(
            category: 'Shopping',
            confidence: 0.3,
            candidateScores: {'Shopping': 0.3},
            processingTimeMs: 0,
          );
        }
      } else {
        classification = ClassificationResult.fromRule(
          category: 'Shopping',
          confidence: 0.3,
          candidateScores: {'Shopping': 0.3},
          processingTimeMs: 0,
        );
      }

      onStepComplete?.call(WorkflowStep.complete);

      stopwatch.stop();
      
      debugPrint('\n\u2713 WORKFLOW: Completed successfully');
      debugPrint('  Total time: ${stopwatch.elapsedMilliseconds}ms');

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
      return ocrResult.rawText.length > 20; // Minimum text threshold
    } catch (e) {
      return false;
    }
  }

  /// Extract preview data without full processing (faster)
  Future<ReceiptPreview> getPreview(String imagePath) async {
    try {
      final ocrResult = await ocrService.recognizeText(imagePath);
      
      // Quick parse to get key fields
      final text = ocrResult.rawText;
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
      description: notesOverride ?? 
             parsedReceipt!.items?.map((i) => i.name).join(', ') ??
             parsedReceipt!.merchantName,
      paymentMethod: paymentMethodOverride ?? 
                    parsedReceipt!.paymentMethod,
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
  /// Create production workflow with CLOUD OCR
  /// 
  /// PRODUCTION APPROACH:
  /// - Cloud OCR API (OCR.space)
  /// - Rule-based classification
  /// - Lenient parsing (no failures on missing data)
  static OcrWorkflowService createProductionWorkflow() {
    debugPrint('\n🏭 Creating production workflow...');
    debugPrint('  ☁️ Using CLOUD OCR (OCR.space API)');
    debugPrint('  🎯 Rule-based classification');
    debugPrint('  🔧 Lenient parsing');
    
    return OcrWorkflowService(
      ocrService: OcrServiceCloud(),
      parser: ReceiptParser(),
      classifier: CategoryClassifier(),
    );
  }

  /// Create workflow without classifier (OCR + Parse only)
  static OcrWorkflowService createBasicWorkflow() {
    return OcrWorkflowService(
      ocrService: OcrService(),
      parser: ReceiptParser(),
    );
  }
}
