import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/receipt_list_provider.dart';
import '../../../../core/models/receipt_image.dart';

class ReceiptDetailPage extends ConsumerStatefulWidget {
  final int receiptId;

  const ReceiptDetailPage({
    super.key,
    required this.receiptId,
  });

  @override
  ConsumerState<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends ConsumerState<ReceiptDetailPage> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      // Reset zoom
      _transformationController.value = Matrix4.identity();
    } else {
      // Zoom in
      final position = _doubleTapDetails!.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx * 2, -position.dy * 2)
        ..scale(3.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptAsync = ref.watch(receiptDetailProvider(widget.receiptId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReceipt(context),
          ),
        ],
      ),
      body: receiptAsync.when(
        data: (receipt) {
          if (receipt == null) {
            return const Center(
              child: Text('Receipt not found'),
            );
          }
          return _buildReceiptContent(context, receipt);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptContent(BuildContext context, ReceiptImage receipt) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Receipt Image with zoom capability
          _buildZoomableImage(receipt.filePath),

          const Divider(height: 1),

          // Receipt Information
          _buildReceiptInfo(context, receipt),

          const SizedBox(height: 16),

          // Extracted Data Section
          if (receipt.extractedText != null) _buildExtractedDataSection(receipt),

          const SizedBox(height: 16),

          // Action Buttons
          _buildActionButtons(context, receipt),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildZoomableImage(String filePath) {
    final file = File(filePath);

    if (!file.existsSync()) {
      return Container(
        height: 400,
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 64, color: Colors.grey),
              SizedBox(height: 8),
              Text('Image not found'),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 400,
      color: Colors.black,
      child: GestureDetector(
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptInfo(BuildContext context, ReceiptImage receipt) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status
          Row(
            children: [
              Icon(
                receipt.isProcessed ? Icons.check_circle : Icons.pending,
                color: receipt.isProcessed ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                receipt.isProcessed ? 'Processed' : 'Pending Processing',
                style: TextStyle(
                  color: receipt.isProcessed ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Merchant
          if (receipt.extractedMerchant != null) ...[
            _buildInfoRow(
              'Merchant',
              receipt.extractedMerchant!,
              Icons.store,
            ),
            const SizedBox(height: 12),
          ],

          // Amount
          if (receipt.extractedAmount != null) ...[
            _buildInfoRow(
              'Amount',
              '\$${receipt.extractedAmount!.toStringAsFixed(2)}',
              Icons.attach_money,
              valueColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 12),
          ],

          // Date
          if (receipt.extractedDate != null) ...[
            _buildInfoRow(
              'Date',
              DateFormat('MMMM dd, yyyy').format(receipt.extractedDate!),
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),
          ],

          // Confidence
          if (receipt.confidence != null) ...[
            _buildInfoRow(
              'Confidence',
              '${(receipt.confidence! * 100).toStringAsFixed(1)}%',
              Icons.verified,
            ),
            const SizedBox(height: 12),
          ],

          // Created date
          _buildInfoRow(
            'Captured',
            DateFormat('MMM dd, yyyy - hh:mm a').format(receipt.createdAt),
            Icons.camera_alt,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExtractedDataSection(ReceiptImage receipt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Extracted Text',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () => _copyExtractedText(receipt.extractedText!),
                tooltip: 'Copy text',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              receipt.extractedText!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ReceiptImage receipt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!receipt.isProcessed)
            ElevatedButton.icon(
              onPressed: () => _processReceipt(receipt),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Process Receipt'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _createExpenseFromReceipt(context, receipt),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Create Expense Entry'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _viewFullImage(context, receipt),
            icon: const Icon(Icons.fullscreen),
            label: const Text('View Full Screen'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _copyExtractedText(String text) {
    // TODO: Implement copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  void _processReceipt(ReceiptImage receipt) {
    // TODO: Implement receipt processing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing receipt...')),
    );
  }

  void _createExpenseFromReceipt(BuildContext context, ReceiptImage receipt) {
    // Navigate to expense entry with pre-filled data
    context.push('/expenses/add', extra: {
      'amount': receipt.extractedAmount,
      'date': receipt.extractedDate,
      'merchant': receipt.extractedMerchant,
      'receiptId': receipt.id,
    });
  }

  void _viewFullImage(BuildContext context, ReceiptImage receipt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          imagePath: receipt.filePath,
        ),
      ),
    );
  }

  void _shareReceipt(BuildContext context) {
    // TODO: Implement receipt sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing not yet implemented')),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receipt'),
        content: const Text(
          'Are you sure you want to delete this receipt? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              
              final receipt = await ref
                  .read(receiptDetailProvider(widget.receiptId).future);
              
              if (receipt != null) {
                final success = await ref
                    .read(receiptListProvider.notifier)
                    .deleteReceipt(receipt.id!, receipt.filePath);

                if (mounted) {
                  if (success) {
                    context.pop(); // Go back to list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Receipt deleted successfully'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete receipt'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// Full screen image viewer
class _FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const _FullScreenImageViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
