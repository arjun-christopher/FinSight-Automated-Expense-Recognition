import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/receipt_list_provider.dart';
import '../../../../core/models/receipt_image.dart';

class ReceiptListPage extends ConsumerStatefulWidget {
  const ReceiptListPage({super.key});

  @override
  ConsumerState<ReceiptListPage> createState() => _ReceiptListPageState();
}

class _ReceiptListPageState extends ConsumerState<ReceiptListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load receipts when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receiptListProvider.notifier).loadReceipts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receiptListProvider);
    final notifier = ref.read(receiptListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Gallery'),
        actions: [
          // View mode toggle
          IconButton(
            icon: Icon(
              state.viewMode == ReceiptViewMode.grid
                  ? Icons.view_list
                  : Icons.grid_view,
            ),
            onPressed: () {
              notifier.setViewMode(
                state.viewMode == ReceiptViewMode.grid
                    ? ReceiptViewMode.list
                    : ReceiptViewMode.grid,
              );
            },
          ),
          // More options
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'cleanup') {
                _showCleanupDialog(context, notifier);
              } else if (value == 'storage') {
                _showStorageInfo(context, notifier);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'storage',
                child: Row(
                  children: [
                    Icon(Icons.storage),
                    SizedBox(width: 8),
                    Text('Storage Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cleanup',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services),
                    SizedBox(width: 8),
                    Text('Cleanup'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search receipts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                notifier.setSearchQuery(value);
              },
            ),
          ),

          // Filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(
                  context,
                  'All',
                  ReceiptFilterType.all,
                  state.filterType,
                  notifier,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'Processed',
                  ReceiptFilterType.processed,
                  state.filterType,
                  notifier,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'Unprocessed',
                  ReceiptFilterType.unprocessed,
                  state.filterType,
                  notifier,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Receipt count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${state.filteredReceipts.length} receipts',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                if (state.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Receipt list/grid
          Expanded(
            child: _buildReceiptList(context, state, notifier),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/receipt/capture');
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    ReceiptFilterType filterType,
    ReceiptFilterType currentFilter,
    ReceiptListNotifier notifier,
  ) {
    final isSelected = currentFilter == filterType;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        notifier.setFilterType(filterType);
      },
    );
  }

  Widget _buildReceiptList(
    BuildContext context,
    ReceiptListState state,
    ReceiptListNotifier notifier,
  ) {
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.loadReceipts(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredReceipts.isEmpty && !state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No receipts found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to capture a receipt',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.refreshReceipts(),
      child: state.viewMode == ReceiptViewMode.grid
          ? _buildGridView(state.filteredReceipts)
          : _buildListView(state.filteredReceipts),
    );
  }

  Widget _buildGridView(List<ReceiptImage> receipts) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        return _buildGridItem(context, receipts[index]);
      },
    );
  }

  Widget _buildListView(List<ReceiptImage> receipts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        return _buildListItem(context, receipts[index]);
      },
    );
  }

  Widget _buildGridItem(BuildContext context, ReceiptImage receipt) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.push('/receipt/detail/${receipt.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildReceiptImage(receipt.filePath),
                  // Status badge
                  if (receipt.isProcessed)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Processed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Receipt info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (receipt.extractedMerchant != null)
                    Text(
                      receipt.extractedMerchant!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (receipt.extractedAmount != null)
                    Text(
                      '\$${receipt.extractedAmount!.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (receipt.extractedDate != null)
                    Text(
                      DateFormat('MMM dd, yyyy').format(receipt.extractedDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, ReceiptImage receipt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/receipt/detail/${receipt.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: _buildReceiptImage(receipt.filePath),
                ),
              ),
              const SizedBox(width: 12),
              // Receipt info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (receipt.extractedMerchant != null)
                      Text(
                        receipt.extractedMerchant!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (receipt.extractedAmount != null)
                      Text(
                        '\$${receipt.extractedAmount!.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    if (receipt.extractedDate != null)
                      Text(
                        DateFormat('MMM dd, yyyy').format(receipt.extractedDate!),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    Row(
                      children: [
                        Icon(
                          receipt.isProcessed ? Icons.check_circle : Icons.pending,
                          size: 16,
                          color: receipt.isProcessed ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          receipt.isProcessed ? 'Processed' : 'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: receipt.isProcessed ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                onPressed: () {
                  _showDeleteDialog(context, receipt);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptImage(String filePath) {
    final file = File(filePath);
    
    if (!file.existsSync()) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, ReceiptImage receipt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receipt'),
        content: const Text('Are you sure you want to delete this receipt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await ref
                  .read(receiptListProvider.notifier)
                  .deleteReceipt(receipt.id!, receipt.filePath);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Receipt deleted successfully'
                          : 'Failed to delete receipt',
                    ),
                  ),
                );
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

  void _showStorageInfo(BuildContext context, ReceiptListNotifier notifier) async {
    final storageUsed = await notifier.getTotalStorageUsed();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Storage Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total storage used: $storageUsed'),
              const SizedBox(height: 8),
              Text('Total receipts: ${ref.read(receiptListProvider).receipts.length}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showCleanupDialog(BuildContext context, ReceiptListNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cleanup Orphaned Files'),
        content: const Text(
          'This will remove receipt image files that are no longer in the database. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final deletedCount = await notifier.cleanupOrphanedFiles();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cleaned up $deletedCount orphaned files'),
                  ),
                );
              }
            },
            child: const Text('Cleanup'),
          ),
        ],
      ),
    );
  }
}
