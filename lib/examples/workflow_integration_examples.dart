import 'dart:io';
import 'package:flutter/material.dart';
import '../services/ocr_workflow_service.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';
import '../services/category_classifier.dart';

/// Comprehensive examples for OCR Workflow integration

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('='.padRight(80, '='));
  print('OCR WORKFLOW INTEGRATION EXAMPLES');
  print('='.padRight(80, '='));
  print('');

  // Example 1: Basic workflow with mock data
  await example1BasicWorkflow();

  // Example 2: Full workflow with classification
  await example2FullWorkflow();

  // Example 3: Batch processing
  await example3BatchProcessing();

  // Example 4: Error handling
  await example4ErrorHandling();

  // Example 5: Preview before processing
  await example5Preview();

  // Example 6: Step-by-step callback
  await example6StepByStep();

  // Example 7: Convert to expense
  await example7ConvertToExpense();

  // Example 8: Custom workflow configuration
  await example8CustomConfiguration();
}

/// Example 1: Basic workflow
Future<void> example1BasicWorkflow() async {
  print('Example 1: Basic Workflow (OCR + Parse)');
  print('-' * 40);

  // Create workflow without classifier
  final workflow = OcrWorkflowFactory.createBasicWorkflow();

  // Simulate processing (would use real image path)
  print('Processing receipt image...');
  print('Steps: Camera → OCR → Parse');
  print('');
  
  print('✓ OCR: Text extracted from image');
  print('✓ Parse: Structured data created');
  print('');
  
  print('Result:');
  print('  Merchant: Starbucks Coffee');
  print('  Amount: \$5.50');
  print('  Date: 2024-12-15');
  print('  Confidence: 92%');
  print('\n');
}

/// Example 2: Full workflow with classification
Future<void> example2FullWorkflow() async {
  print('Example 2: Full Workflow (OCR + Parse + Classify)');
  print('-' * 40);

  // Create workflow with mock classifier
  final workflow = OcrWorkflowFactory.createMockWorkflow();

  print('Processing receipt image...');
  print('Steps: Camera → OCR → Parse → Classify');
  print('');
  
  print('✓ OCR: Extracted 156 characters');
  print('✓ Parse: Found merchant, amount, date, 3 items');
  print('✓ Classify: Category determined with 95% confidence');
  print('');
  
  print('Result:');
  print('  Merchant: Walmart Supercenter');
  print('  Amount: \$67.40');
  print('  Date: 2024-12-15');
  print('  Category: Groceries (95% confidence)');
  print('  Method: Hybrid (rule + LLM)');
  print('  Items: Milk, Bread, Eggs');
  print('  Processing time: 1,250ms');
  print('\n');
}

/// Example 3: Batch processing multiple receipts
Future<void> example3BatchProcessing() async {
  print('Example 3: Batch Processing');
  print('-' * 40);

  final workflow = OcrWorkflowFactory.createMockWorkflow();

  final imagePaths = [
    '/path/to/receipt1.jpg',
    '/path/to/receipt2.jpg',
    '/path/to/receipt3.jpg',
  ];

  print('Processing ${imagePaths.length} receipts...\n');

  // Simulate batch processing
  for (int i = 0; i < imagePaths.length; i++) {
    print('Receipt ${i + 1}/${imagePaths.length}');
    print('  Status: Success');
    print('  Time: ${500 + (i * 100)}ms');
  }

  print('\nBatch complete!');
  print('Success: 3/3');
  print('Total time: 1,800ms');
  print('Average: 600ms per receipt');
  print('\n');
}

/// Example 4: Error handling
Future<void> example4ErrorHandling() async {
  print('Example 4: Error Handling');
  print('-' * 40);

  final workflow = OcrWorkflowFactory.createMockWorkflow();

  print('Scenario 1: No text detected');
  print('  Error: No text found in image');
  print('  Step: OCR');
  print('  Action: Ask user to retake photo');
  print('');

  print('Scenario 2: Amount not found');
  print('  Error: Could not extract total amount');
  print('  Step: Parse');
  print('  Action: Manual entry with OCR text hints');
  print('');

  print('Scenario 3: Classification failed');
  print('  Warning: Classification service unavailable');
  print('  Step: Classify');
  print('  Action: Continue with category selection');
  print('');

  print('Scenario 4: Invalid image');
  print('  Error: Unable to read image file');
  print('  Step: OCR');
  print('  Action: Show file error, request new image');
  print('\n');
}

/// Example 5: Preview before full processing
Future<void> example5Preview() async {
  print('Example 5: Quick Preview');
  print('-' * 40);

  final workflow = OcrWorkflowFactory.createMockWorkflow();

  print('Quick scan (fast preview)...');
  print('');
  
  print('Preview:');
  print('  Merchant: Starbucks');
  print('  Estimated Total: \$5.50');
  print('  Readable Text: Yes (156 characters)');
  print('  Processing time: 250ms');
  print('');
  
  print('User can now choose:');
  print('  1. Continue with full processing');
  print('  2. Retake photo');
  print('  3. Enter manually');
  print('\n');
}

/// Example 6: Step-by-step callback
Future<void> example6StepByStep() async {
  print('Example 6: Step-by-Step Progress');
  print('-' * 40);

  final workflow = OcrWorkflowFactory.createMockWorkflow();

  print('Processing with progress updates:');
  print('');
  
  final steps = [
    'OCR: Scanning receipt...',
    'Parse: Extracting information...',
    'Classify: Determining category...',
    'Complete: Ready for review!',
  ];

  for (int i = 0; i < steps.length; i++) {
    await Future.delayed(const Duration(milliseconds: 300));
    print('[$i/${steps.length - 1}] ${steps[i]}');
  }
  
  print('');
  print('Progress: 100%');
  print('Status: Success ✓');
  print('\n');
}

/// Example 7: Convert to expense model
Future<void> example7ConvertToExpense() async {
  print('Example 7: Convert to Expense Model');
  print('-' * 40);

  print('WorkflowResult:');
  print('  Merchant: Target');
  print('  Amount: \$85.30');
  print('  Category: Shopping (82% confidence)');
  print('  Date: 2024-12-15');
  print('  Items: Various items');
  print('');
  
  print('Converted to Expense:');
  print('  amount: 85.30');
  print('  category: "Shopping"');
  print('  date: 2024-12-15T10:30:00');
  print('  merchantName: "Target"');
  print('  notes: "Various items"');
  print('  receiptImagePath: "/path/to/image.jpg"');
  print('');
  
  print('Ready to save to database!');
  print('\n');
}

/// Example 8: Custom configuration
Future<void> example8CustomConfiguration() async {
  print('Example 8: Custom Configuration');
  print('-' * 40);

  print('Configuration Options:');
  print('');
  
  print('1. Mock Workflow (testing):');
  print('   - Mock LLM classifier');
  print('   - No API calls');
  print('   - Fast, deterministic');
  print('');
  
  print('2. Basic Workflow (OCR + Parse only):');
  print('   - No classification');
  print('   - Manual category selection');
  print('   - Fastest processing');
  print('');
  
  print('3. Full Workflow (production):');
  print('   - Real LLM API');
  print('   - Hybrid classification');
  print('   - Best accuracy');
  print('');
  
  print('4. Custom Service Injection:');
  print('   - Custom OCR service');
  print('   - Custom parser');
  print('   - Custom classifier');
  print('\n');
}

/// Integration example with UI
class WorkflowIntegrationExample extends StatefulWidget {
  const WorkflowIntegrationExample({super.key});

  @override
  State<WorkflowIntegrationExample> createState() =>
      _WorkflowIntegrationExampleState();
}

class _WorkflowIntegrationExampleState
    extends State<WorkflowIntegrationExample> {
  bool _isProcessing = false;
  WorkflowResult? _result;
  WorkflowStep? _currentStep;

  Future<void> _processReceipt(String imagePath) async {
    setState(() {
      _isProcessing = true;
      _currentStep = null;
    });

    try {
      final workflow = OcrWorkflowFactory.createMockWorkflow();

      final result = await workflow.processReceipt(
        imagePath: imagePath,
        useClassifier: true,
        onStepComplete: (step) {
          setState(() {
            _currentStep = step;
          });
        },
      );

      setState(() {
        _result = result;
        _isProcessing = false;
      });

      if (result.success) {
        // Navigate to confirmation
        _navigateToConfirmation(result);
      } else {
        // Show error
        _showError(result.errorMessage ?? 'Unknown error');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError(e.toString());
    }
  }

  void _navigateToConfirmation(WorkflowResult result) {
    // Navigator.push to confirmation screen
    print('Navigating to confirmation with result: ${result.summary}');
  }

  void _showError(String message) {
    // Show error dialog or snackbar
    print('Error: $message');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workflow Example')),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_getStepMessage(_currentStep)),
                ],
              )
            : _result != null
                ? _buildResultPreview(_result!)
                : ElevatedButton(
                    onPressed: () => _processReceipt('/path/to/receipt.jpg'),
                    child: const Text('Process Receipt'),
                  ),
      ),
    );
  }

  String _getStepMessage(WorkflowStep? step) {
    switch (step) {
      case WorkflowStep.ocr:
        return 'Scanning receipt...';
      case WorkflowStep.parse:
        return 'Extracting information...';
      case WorkflowStep.classify:
        return 'Classifying expense...';
      case WorkflowStep.complete:
        return 'Complete!';
      default:
        return 'Processing...';
    }
  }

  Widget _buildResultPreview(WorkflowResult result) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Result:', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(result.summary),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _navigateToConfirmation(result),
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );
  }
}

/// Error handling example
class ErrorHandlingExample {
  Future<void> processWithErrorHandling(String imagePath) async {
    final workflow = OcrWorkflowFactory.createMockWorkflow();

    try {
      // Validate image first
      final isValid = await workflow.validateImage(imagePath);
      if (!isValid) {
        throw WorkflowException(
          'Image does not contain readable text',
          step: WorkflowStep.ocr,
        );
      }

      // Process with timeout
      final result = await workflow
          .processReceipt(imagePath: imagePath)
          .timeout(const Duration(seconds: 30));

      if (!result.success) {
        // Handle processing failure
        _handleFailure(result);
        return;
      }

      if (result.needsReview) {
        // Low confidence - prompt user review
        _promptReview(result);
      } else {
        // High confidence - auto-save
        _autoSave(result);
      }
    } on WorkflowException catch (e) {
      // Handle workflow-specific errors
      print('Workflow error at ${e.step.name}: ${e.message}');
    } on TimeoutException {
      // Handle timeout
      print('Processing timed out');
    } catch (e) {
      // Handle other errors
      print('Unexpected error: $e');
    }
  }

  void _handleFailure(WorkflowResult result) {
    print('Processing failed: ${result.errorMessage}');
  }

  void _promptReview(WorkflowResult result) {
    print('Low confidence (${result.overallConfidence}), needs review');
  }

  void _autoSave(WorkflowResult result) {
    print('High confidence, auto-saving expense');
  }
}
