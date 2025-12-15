/// COMPLETE INTEGRATION EXAMPLE
/// Shows how OCR service integrates with Camera Capture and Expense Form

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ocr_service.dart';
import '../core/models/ocr_result.dart';
import '../features/receipt/providers/receipt_capture_provider.dart';

// ============================================================
// SCENARIO 1: Camera → OCR → Display Results
// ============================================================

class CaptureAndOcrPage extends ConsumerStatefulWidget {
  const CaptureAndOcrPage({super.key});

  @override
  ConsumerState<CaptureAndOcrPage> createState() => _CaptureAndOcrPageState();
}

class _CaptureAndOcrPageState extends ConsumerState<CaptureAndOcrPage> {
  final _ocrService = OcrService();
  OcrResult? _ocrResult;
  bool _isProcessing = false;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcess() async {
    // Step 1: Capture receipt image
    await ref.read(receiptCaptureProvider.notifier).captureFromCamera();

    final captureState = ref.read(receiptCaptureProvider);

    if (!captureState.hasImage) {
      _showMessage('No image captured');
      return;
    }

    // Step 2: Process with OCR
    setState(() => _isProcessing = true);

    final result = await _ocrService.recognizeText(captureState.imagePath!);

    setState(() {
      _ocrResult = result;
      _isProcessing = false;
    });

    if (result.success) {
      _showMessage('Text extracted successfully!');
    } else {
      _showMessage('OCR failed: ${result.errorMessage}');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(receiptCaptureProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Capture & OCR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Capture button
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _captureAndProcess,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture Receipt'),
            ),
            const SizedBox(height: 16),

            // Image preview
            if (captureState.hasImage) ...[
              const Text(
                'Captured Image:',
                style: TextStyle(fontWeight: FontWeight.bold),
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

            // Processing indicator
            if (_isProcessing) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text(
                'Processing OCR...',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            // OCR results
            if (_ocrResult != null && _ocrResult!.success) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'OCR Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('Text blocks: ${_ocrResult!.textBlockCount}'),
                      Text('Lines: ${_ocrResult!.lines.length}'),
                      if (_ocrResult!.confidence != null)
                        Text(
                          'Confidence: ${(_ocrResult!.confidence! * 100).toStringAsFixed(1)}%',
                        ),
                      const SizedBox(height: 16),
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
                          _ocrResult!.rawText,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SCENARIO 2: Camera → OCR → Pre-fill Expense Form
// ============================================================

class SmartExpenseEntryPage extends ConsumerStatefulWidget {
  const SmartExpenseEntryPage({super.key});

  @override
  ConsumerState<SmartExpenseEntryPage> createState() =>
      _SmartExpenseEntryPageState();
}

class _SmartExpenseEntryPageState
    extends ConsumerState<SmartExpenseEntryPage> {
  final _ocrService = OcrService();
  
  // Form data (would normally use ExpenseFormProvider)
  double? _amount;
  String? _merchant;
  DateTime? _date;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    // Capture image
    await ref.read(receiptCaptureProvider.notifier).captureFromCamera();

    final captureState = ref.read(receiptCaptureProvider);
    if (!captureState.hasImage) return;

    // Show processing dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Scanning receipt...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Process OCR
    final result = await _ocrService.recognizeText(captureState.imagePath!);

    // Close dialog
    if (!mounted) return;
    Navigator.pop(context);

    if (result.success) {
      // Parse text for expense data
      final parsedData = _parseReceiptData(result.rawText);

      setState(() {
        _amount = parsedData['amount'];
        _merchant = parsedData['merchant'];
        _date = parsedData['date'];
      });

      // TODO: Actually set values in ExpenseFormProvider
      // ref.read(expenseFormProvider.notifier).setAmount(_amount);
      // ref.read(expenseFormProvider.notifier).setMerchant(_merchant);
      // ref.read(expenseFormProvider.notifier).setDate(_date);

      _showMessage('Receipt scanned! Review the data below.');
    } else {
      _showMessage('Failed to scan receipt');
    }
  }

  // Simple parser (placeholder - would be more sophisticated in production)
  Map<String, dynamic> _parseReceiptData(String text) {
    // Find price patterns
    final pricePattern = RegExp(r'[\$£€]?\s*(\d+[.,]\d{2})');
    final priceMatches = pricePattern.allMatches(text);
    
    double? amount;
    if (priceMatches.isNotEmpty) {
      // Get the largest price (likely total)
      final prices = priceMatches
          .map((m) => double.tryParse(m.group(1)?.replaceAll(',', '.') ?? '0') ?? 0.0)
          .toList()
        ..sort();
      amount = prices.last;
    }

    // Find merchant (first line usually)
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final merchant = lines.isNotEmpty ? lines.first.trim() : null;

    // Find date
    final datePattern = RegExp(r'(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})');
    final dateMatch = datePattern.firstMatch(text);
    DateTime? date;
    if (dateMatch != null) {
      // Simple parsing - would need proper date parsing in production
      date = DateTime.now(); // Placeholder
    }

    return {
      'amount': amount,
      'merchant': merchant,
      'date': date,
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Expense Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scan button
            ElevatedButton.icon(
              onPressed: _scanReceipt,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Receipt'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Form fields
            if (_amount != null || _merchant != null || _date != null) ...[
              const Text(
                'Extracted Data:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
            ],

            if (_amount != null)
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Amount'),
                subtitle: Text('\$${_amount!.toStringAsFixed(2)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Edit amount
                  },
                ),
              ),

            if (_merchant != null)
              ListTile(
                leading: const Icon(Icons.store),
                title: const Text('Merchant'),
                subtitle: Text(_merchant!),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Edit merchant
                  },
                ),
              ),

            if (_date != null)
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(_date.toString().split(' ')[0]),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Edit date
                  },
                ),
              ),

            const Spacer(),

            if (_amount != null || _merchant != null || _date != null)
              ElevatedButton(
                onPressed: () {
                  // Save expense
                  _showMessage('Expense saved!');
                },
                child: const Text('Save Expense'),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SCENARIO 3: Batch Process Multiple Receipts
// ============================================================

class BatchOcrPage extends ConsumerStatefulWidget {
  const BatchOcrPage({super.key});

  @override
  ConsumerState<BatchOcrPage> createState() => _BatchOcrPageState();
}

class _BatchOcrPageState extends ConsumerState<BatchOcrPage> {
  final _ocrService = OcrService();
  final List<String> _capturedImages = [];
  final List<OcrResult> _ocrResults = [];
  bool _isProcessing = false;
  int _currentIndex = 0;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    await ref.read(receiptCaptureProvider.notifier).captureFromCamera();

    final captureState = ref.read(receiptCaptureProvider);
    if (captureState.hasImage) {
      setState(() {
        _capturedImages.add(captureState.imagePath!);
      });

      // Reset for next capture
      ref.read(receiptCaptureProvider.notifier).reset();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Captured ${_capturedImages.length} receipts'),
        ),
      );
    }
  }

  Future<void> _processAll() async {
    if (_capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images to process')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentIndex = 0;
      _ocrResults.clear();
    });

    for (var i = 0; i < _capturedImages.length; i++) {
      setState(() => _currentIndex = i);

      final result = await _ocrService.recognizeText(_capturedImages[i]);
      _ocrResults.add(result);

      // Small delay to avoid overwhelming the system
      await Future.delayed(const Duration(milliseconds: 100));
    }

    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processed ${_ocrResults.length} receipts'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batch OCR')),
      body: Column(
        children: [
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _captureImage,
                    icon: const Icon(Icons.add_a_photo),
                    label: Text('Add Receipt (${_capturedImages.length})'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _processAll,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Process'),
                ),
              ],
            ),
          ),

          // Processing indicator
          if (_isProcessing) ...[
            LinearProgressIndicator(
              value: _currentIndex / _capturedImages.length,
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Processing ${_currentIndex + 1}/${_capturedImages.length}',
              ),
            ),
          ],

          // Results list
          Expanded(
            child: ListView.builder(
              itemCount: _ocrResults.length,
              itemBuilder: (context, index) {
                final result = _ocrResults[index];
                final imagePath = _capturedImages[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ExpansionTile(
                    leading: result.success
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.error, color: Colors.red),
                    title: Text('Receipt ${index + 1}'),
                    subtitle: result.success
                        ? Text('${result.textBlockCount} blocks, confidence: ${(result.confidence ?? 0 * 100).toStringAsFixed(1)}%')
                        : Text(result.errorMessage ?? 'Failed'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.file(File(imagePath), height: 150),
                            const SizedBox(height: 8),
                            if (result.success) Text(result.rawText),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SCENARIO 4: Real-time OCR with Live Preview
// ============================================================

class LiveOcrPage extends ConsumerStatefulWidget {
  final String imagePath;

  const LiveOcrPage({super.key, required this.imagePath});

  @override
  ConsumerState<LiveOcrPage> createState() => _LiveOcrPageState();
}

class _LiveOcrPageState extends ConsumerState<LiveOcrPage> {
  final _ocrService = OcrService();
  OcrResult? _result;
  String _status = 'Ready';

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _processImage() async {
    _updateStatus('Validating image...');
    await Future.delayed(const Duration(milliseconds: 300));

    _updateStatus('Starting OCR...');
    await Future.delayed(const Duration(milliseconds: 300));

    final result = await _ocrService.recognizeText(widget.imagePath);

    setState(() => _result = result);

    if (result.success) {
      _updateStatus('Complete!');
    } else {
      _updateStatus('Failed');
    }
  }

  void _updateStatus(String status) {
    if (mounted) {
      setState(() => _status = status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live OCR')),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                if (_result == null)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(width: 8),
                Text(
                  _status,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _result == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(widget.imagePath),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats
                        if (_result!.success) ...[
                          _buildStat('Text Blocks', '${_result!.textBlockCount}'),
                          _buildStat('Lines', '${_result!.lines.length}'),
                          if (_result!.confidence != null)
                            _buildStat(
                              'Confidence',
                              '${(_result!.confidence! * 100).toStringAsFixed(1)}%',
                            ),
                          const Divider(),

                          // Text
                          const Text(
                            'Extracted Text:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_result!.rawText),
                          ),
                        ] else
                          Text('Error: ${_result!.errorMessage}'),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
