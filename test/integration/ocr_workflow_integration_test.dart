import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ocr_workflow_service.dart';
import '../core/models/expense.dart';

/// Integration test for complete OCR workflow
void main() {
  group('OCR Workflow Integration Tests', () {
    late OcrWorkflowService workflow;

    setUp(() {
      workflow = OcrWorkflowFactory.createMockWorkflow();
    });

    test('Complete workflow processes receipt successfully', () async {
      // Arrange
      const imagePath = '/test/receipt.jpg';

      // Act
      final result = await workflow.processReceipt(
        imagePath: imagePath,
        useClassifier: true,
      );

      // Assert
      expect(result.success, isTrue);
      expect(result.parsedReceipt, isNotNull);
      expect(result.classification, isNotNull);
      expect(result.processingTimeMs, greaterThan(0));
    });

    test('Workflow extracts merchant name', () async {
      // Arrange
      const imagePath = '/test/starbucks_receipt.jpg';

      // Act
      final result = await workflow.processReceipt(imagePath: imagePath);

      // Assert
      expect(result.parsedReceipt?.merchantName, isNotNull);
    });

    test('Workflow extracts total amount', () async {
      // Arrange
      const imagePath = '/test/receipt.jpg';

      // Act
      final result = await workflow.processReceipt(imagePath: imagePath);

      // Assert
      expect(result.parsedReceipt?.totalAmount, isNotNull);
      expect(result.parsedReceipt!.totalAmount, greaterThan(0));
    });

    test('Workflow classifies category', () async {
      // Arrange
      const imagePath = '/test/receipt.jpg';

      // Act
      final result = await workflow.processReceipt(
        imagePath: imagePath,
        useClassifier: true,
      );

      // Assert
      expect(result.classification, isNotNull);
      expect(result.classification!.category, isNotEmpty);
      expect(result.classification!.confidence, inInclusiveRange(0.0, 1.0));
    });

    test('Workflow calculates overall confidence', () async {
      // Arrange
      const imagePath = '/test/receipt.jpg';

      // Act
      final result = await workflow.processReceipt(imagePath: imagePath);

      // Assert
      expect(result.overallConfidence, inInclusiveRange(0.0, 1.0));
    });

    test('Workflow determines if review needed', () async {
      // Arrange
      const imagePath = '/test/receipt.jpg';

      // Act
      final result = await workflow.processReceipt(imagePath: imagePath);

      // Assert
      expect(result.needsReview, isA<bool>());
      
      // High confidence should not need review
      if (result.overallConfidence > 0.7) {
        expect(result.needsReview, isFalse);
      }
    });

    test('Workflow converts to Expense model', () async {
      // Arrange
      const imagePath = '/test/receipt.jpg';

      // Act
      final result = await workflow.processReceipt(imagePath: imagePath);
      final expense = result.toExpense();

      // Assert
      expect(expense, isA<Expense>());
      expect(expense.amount, greaterThan(0));
      expect(expense.category, isNotEmpty);
      expect(expense.date, isNotNull);
    });

    test('Workflow provides step callbacks', () async {
      // Arrange
      const imagePath = '/test/receipt.jpg';
      final steps = <WorkflowStep>[];

      // Act
      await workflow.processReceipt(
        imagePath: imagePath,
        onStepComplete: (step) => steps.add(step),
      );

      // Assert
      expect(steps, contains(WorkflowStep.ocr));
      expect(steps, contains(WorkflowStep.parse));
      expect(steps, contains(WorkflowStep.complete));
    });

    test('Batch processing handles multiple receipts', () async {
      // Arrange
      final imagePaths = [
        '/test/receipt1.jpg',
        '/test/receipt2.jpg',
        '/test/receipt3.jpg',
      ];

      // Act
      final results = await workflow.processBatch(imagePaths: imagePaths);

      // Assert
      expect(results.length, equals(3));
      expect(results.every((r) => r.success), isTrue);
    });

    test('Workflow validates image before processing', () async {
      // Arrange
      const imagePath = '/test/receipt.jpg';

      // Act
      final isValid = await workflow.validateImage(imagePath);

      // Assert
      expect(isValid, isA<bool>());
    });

    test('Preview provides quick information', () async {
      // Arrange
      const imagePath = '/test/receipt.jpg';

      // Act
      final preview = await workflow.getPreview(imagePath);

      // Assert
      expect(preview, isA<ReceiptPreview>());
      expect(preview.hasReadableText, isA<bool>());
    });

    test('Workflow without classifier skips classification', () async {
      // Arrange
      const imagePath = '/test/receipt.jpg';

      // Act
      final result = await workflow.processReceipt(
        imagePath: imagePath,
        useClassifier: false,
      );

      // Assert
      expect(result.classification, isNull);
    });

    test('Workflow handles classification failure gracefully', () async {
      // Arrange
      final basicWorkflow = OcrWorkflowFactory.createBasicWorkflow();
      const imagePath = '/test/receipt.jpg';

      // Act
      final result = await basicWorkflow.processReceipt(imagePath: imagePath);

      // Assert - Should still succeed without classification
      expect(result.success, isTrue);
      expect(result.classification, isNull);
    });
  });

  group('WorkflowResult Tests', () {
    test('toExpense creates valid Expense', () {
      // Arrange
      final result = WorkflowResult(
        success: true,
        imagePath: '/test/receipt.jpg',
        parsedReceipt: ParsedReceipt(
          totalAmount: 25.50,
          merchantName: 'Test Store',
          date: DateTime(2024, 12, 15),
        ),
        classification: ClassificationResult(
          category: 'Shopping',
          confidence: 0.85,
          method: ClassificationMethod.hybrid,
          processingTimeMs: 100,
        ),
        processingTimeMs: 1500,
      );

      // Act
      final expense = result.toExpense();

      // Assert
      expect(expense.amount, equals(25.50));
      expect(expense.merchantName, equals('Test Store'));
      expect(expense.category, equals('Shopping'));
      expect(expense.date, equals(DateTime(2024, 12, 15)));
    });

    test('toExpense allows category override', () {
      // Arrange
      final result = WorkflowResult(
        success: true,
        imagePath: '/test/receipt.jpg',
        parsedReceipt: ParsedReceipt(totalAmount: 10.0),
        classification: ClassificationResult(
          category: 'Food & Dining',
          confidence: 0.6,
          method: ClassificationMethod.hybrid,
          processingTimeMs: 100,
        ),
        processingTimeMs: 1000,
      );

      // Act
      final expense = result.toExpense(categoryOverride: 'Groceries');

      // Assert
      expect(expense.category, equals('Groceries'));
    });

    test('summary provides formatted output', () {
      // Arrange
      final result = WorkflowResult(
        success: true,
        imagePath: '/test/receipt.jpg',
        parsedReceipt: ParsedReceipt(
          totalAmount: 50.0,
          merchantName: 'Target',
        ),
        classification: ClassificationResult(
          category: 'Shopping',
          confidence: 0.9,
          method: ClassificationMethod.hybrid,
          processingTimeMs: 100,
        ),
        processingTimeMs: 2000,
      );

      // Act
      final summary = result.summary;

      // Assert
      expect(summary, contains('Target'));
      expect(summary, contains('50.00'));
      expect(summary, contains('Shopping'));
      expect(summary, contains('2000ms'));
    });
  });

  group('Error Handling Tests', () {
    test('Failed result has error message', () {
      // Arrange
      final result = WorkflowResult(
        success: false,
        imagePath: '/test/bad_receipt.jpg',
        errorMessage: 'No text found',
        processingTimeMs: 500,
      );

      // Assert
      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, contains('No text found'));
    });

    test('Failed result throws on toExpense', () {
      // Arrange
      final result = WorkflowResult(
        success: false,
        imagePath: '/test/receipt.jpg',
        errorMessage: 'Processing failed',
        processingTimeMs: 100,
      );

      // Act & Assert
      expect(() => result.toExpense(), throwsStateError);
    });

    test('WorkflowException includes step information', () {
      // Arrange
      final exception = WorkflowException(
        'OCR failed',
        step: WorkflowStep.ocr,
      );

      // Assert
      expect(exception.message, equals('OCR failed'));
      expect(exception.step, equals(WorkflowStep.ocr));
      expect(exception.toString(), contains('ocr'));
    });
  });

  group('Performance Tests', () {
    test('Workflow completes within reasonable time', () async {
      // Arrange
      final workflow = OcrWorkflowFactory.createMockWorkflow();
      const imagePath = '/test/receipt.jpg';
      final stopwatch = Stopwatch()..start();

      // Act
      await workflow.processReceipt(imagePath: imagePath);
      stopwatch.stop();

      // Assert - Mock should be fast
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('Batch processing is efficient', () async {
      // Arrange
      final workflow = OcrWorkflowFactory.createMockWorkflow();
      final imagePaths = List.generate(10, (i) => '/test/receipt$i.jpg');
      final stopwatch = Stopwatch()..start();

      // Act
      await workflow.processBatch(imagePaths: imagePaths);
      stopwatch.stop();

      // Assert - Should process 10 receipts reasonably fast
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    });
  });
}

// Mock imports (would be actual imports in real project)
class ParsedReceipt {
  final double? totalAmount;
  final String? merchantName;
  final DateTime? date;
  final List<ReceiptItem>? items;
  final double? confidence;
  final String? paymentMethod;

  ParsedReceipt({
    this.totalAmount,
    this.merchantName,
    this.date,
    this.items,
    this.confidence,
    this.paymentMethod,
  });
}

class ReceiptItem {
  final String description;
  final double price;

  ReceiptItem(this.description, this.price);
}

class ClassificationResult {
  final String category;
  final double confidence;
  final ClassificationMethod method;
  final int processingTimeMs;

  ClassificationResult({
    required this.category,
    required this.confidence,
    required this.method,
    required this.processingTimeMs,
  });
}

enum ClassificationMethod { ruleBased, llm, hybrid }
