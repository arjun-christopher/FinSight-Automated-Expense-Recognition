/// COMPLETE WORKFLOW: From Camera Capture to OCR
/// This demonstrates the end-to-end flow of Tasks 4 & 5

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Task 4 imports - Camera Capture
import '../features/receipt/providers/receipt_capture_provider.dart';

// Task 5 imports - OCR
import '../services/ocr_service.dart';
import '../core/models/ocr_result.dart';

// ============================================================
// COMPLETE WORKFLOW EXAMPLE
// ============================================================

class CompleteReceiptWorkflow extends ConsumerStatefulWidget {
  const CompleteReceiptWorkflow({super.key});

  @override
  ConsumerState<CompleteReceiptWorkflow> createState() =>
      _CompleteReceiptWorkflowState();
}

class _CompleteReceiptWorkflowState
    extends ConsumerState<CompleteReceiptWorkflow> {
  final _ocrService = OcrService();
  
  // Workflow state
  WorkflowStep _currentStep = WorkflowStep.initial;
  OcrResult? _ocrResult;
  String? _errorMessage;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  /// Complete workflow: Capture → OCR → Display
  Future<void> _runCompleteWorkflow() async {
    try {
      // STEP 1: Capture receipt image (Task 4)
      await _captureReceipt();
      
      // STEP 2: Process with OCR (Task 5)
      await _processOcr();
      
      // STEP 3: Display results
      _showResults();
      
    } catch (e) {
      setState(() {
        _currentStep = WorkflowStep.error;
        _errorMessage = e.toString();
      });
    }
  }

  /// Step 1: Capture receipt using camera
  Future<void> _captureReceipt() async {
    setState(() => _currentStep = WorkflowStep.capturing);

    await ref.read(receiptCaptureProvider.notifier).captureFromCamera();

    final captureState = ref.read(receiptCaptureProvider);

    if (!captureState.hasImage) {
      throw Exception('Image capture cancelled or failed');
    }

    setState(() => _currentStep = WorkflowStep.captured);
  }

  /// Step 2: Process captured image with OCR
  Future<void> _processOcr() async {
    setState(() => _currentStep = WorkflowStep.processing);

    final captureState = ref.read(receiptCaptureProvider);
    
    if (captureState.imagePath == null) {
      throw Exception('No image path available');
    }

    final result = await _ocrService.recognizeText(captureState.imagePath!);

    if (!result.success) {
      throw Exception(result.errorMessage ?? 'OCR processing failed');
    }

    setState(() {
      _ocrResult = result;
      _currentStep = WorkflowStep.completed;
    });
  }

  /// Step 3: Show results
  void _showResults() {
    if (_ocrResult != null && _ocrResult!.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Success! Extracted ${_ocrResult!.textBlockCount} text blocks',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(receiptCaptureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Workflow'),
        actions: [
          if (_currentStep != WorkflowStep.initial)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _currentStep = WorkflowStep.initial;
                  _ocrResult = null;
                  _errorMessage = null;
                });
                ref.read(receiptCaptureProvider.notifier).reset();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Workflow progress indicator
            _buildWorkflowProgress(),
            const SizedBox(height: 24),

            // Main action button
            if (_currentStep == WorkflowStep.initial)
              _buildStartButton()
            else if (_currentStep == WorkflowStep.capturing ||
                _currentStep == WorkflowStep.processing)
              _buildLoadingIndicator()
            else if (_currentStep == WorkflowStep.error)
              _buildErrorView()
            else
              _buildResultsView(captureState),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowProgress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workflow Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildProgressStep(
              1,
              'Capture Receipt',
              _currentStep.index >= WorkflowStep.captured.index,
              _currentStep == WorkflowStep.capturing,
            ),
            _buildProgressStep(
              2,
              'Process OCR',
              _currentStep.index >= WorkflowStep.completed.index,
              _currentStep == WorkflowStep.processing,
            ),
            _buildProgressStep(
              3,
              'Extract Data',
              _currentStep == WorkflowStep.completed,
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(
    int number,
    String label,
    bool completed,
    bool active,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed
                  ? Colors.green
                  : active
                      ? Colors.blue
                      : Colors.grey[300],
            ),
            child: Center(
              child: active
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : completed
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '$number',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: completed || active ? FontWeight.w600 : FontWeight.normal,
              color: completed || active ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton.icon(
      onPressed: _runCompleteWorkflow,
      icon: const Icon(Icons.play_arrow, size: 32),
      label: const Text(
        'Start Workflow',
        style: TextStyle(fontSize: 18),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(20),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _currentStep == WorkflowStep.capturing
                ? 'Waiting for image capture...'
                : 'Processing OCR...',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Workflow Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep = WorkflowStep.initial;
                  _errorMessage = null;
                });
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView(ReceiptCaptureState captureState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success message
        Card(
          color: Colors.green[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workflow Complete!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Receipt captured and processed successfully'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Captured image
        if (captureState.hasImage) ...[
          const Text(
            'Captured Image:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(captureState.imagePath!),
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // OCR results
        if (_ocrResult != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OCR Analysis:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildOcrStat(
                    'Text Blocks',
                    '${_ocrResult!.textBlockCount}',
                    Icons.view_module,
                  ),
                  _buildOcrStat(
                    'Lines',
                    '${_ocrResult!.lines.length}',
                    Icons.format_list_numbered,
                  ),
                  if (_ocrResult!.confidence != null)
                    _buildOcrStat(
                      'Confidence',
                      '${(_ocrResult!.confidence! * 100).toStringAsFixed(1)}%',
                      Icons.stars,
                    ),
                  _buildOcrStat(
                    'Characters',
                    '${_ocrResult!.rawText.length}',
                    Icons.text_fields,
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Extracted Text:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _ocrResult!.rawText.isNotEmpty
                          ? _ocrResult!.rawText
                          : 'No text detected',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Next steps
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Next Steps',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. Parse text to extract amount, merchant, date\n'
                    '2. Pre-fill expense form with extracted data\n'
                    '3. Allow user to review and edit\n'
                    '4. Save to database',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to expense form with pre-filled data
                      _showMessage('Feature coming soon!');
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Create Expense'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOcrStat(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// ============================================================
// WORKFLOW STATE ENUM
// ============================================================

enum WorkflowStep {
  initial,      // Ready to start
  capturing,    // Camera is open
  captured,     // Image captured successfully
  processing,   // Running OCR
  completed,    // Workflow complete
  error,        // Error occurred
}

// ============================================================
// STANDALONE FUNCTION - Complete Workflow
// ============================================================

/// Run the complete workflow programmatically
Future<Map<String, dynamic>> runReceiptWorkflow(WidgetRef ref) async {
  final ocrService = OcrService();
  
  try {
    // Step 1: Capture receipt
    await ref.read(receiptCaptureProvider.notifier).captureFromCamera();
    
    final captureState = ref.read(receiptCaptureProvider);
    
    if (!captureState.hasImage) {
      return {
        'success': false,
        'error': 'Image capture failed',
      };
    }
    
    // Step 2: Process with OCR
    final result = await ocrService.recognizeText(captureState.imagePath!);
    
    if (!result.success) {
      return {
        'success': false,
        'error': result.errorMessage,
      };
    }
    
    // Step 3: Return results
    return {
      'success': true,
      'imagePath': captureState.imagePath,
      'rawText': result.rawText,
      'textBlocks': result.textBlocks.length,
      'confidence': result.confidence,
      'lines': result.lines,
    };
    
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
    };
  } finally {
    await ocrService.dispose();
  }
}

// ============================================================
// USAGE EXAMPLE
// ============================================================

/*
// In your widget:
final result = await runReceiptWorkflow(ref);

if (result['success']) {
  print('Text: ${result['rawText']}');
  print('Confidence: ${result['confidence']}');
  
  // TODO: Parse text and extract expense data
  // final parsedData = parseReceiptText(result['rawText']);
  
  // TODO: Pre-fill expense form
  // ref.read(expenseFormProvider.notifier).setAmount(parsedData.amount);
  
} else {
  print('Error: ${result['error']}');
}
*/
