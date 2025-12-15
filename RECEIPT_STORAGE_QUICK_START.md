# Receipt Storage + Viewer - Quick Start Guide

## Table of Contents
1. [Overview](#overview)
2. [Quick Setup](#quick-setup)
3. [Basic Usage](#basic-usage)
4. [Common Tasks](#common-tasks)
5. [Code Examples](#code-examples)

## Overview

The Receipt Storage + Viewer module provides a complete solution for managing receipt images in your expense tracking app. Users can:
- View all receipts in a beautiful gallery
- Search and filter receipts
- Zoom in to view receipt details
- Delete unwanted receipts
- Track storage usage

## Quick Setup

### 1. Navigation
The module is already integrated into the app navigation. Access it via:
- **Bottom Navigation Bar**: Tap the "Receipts" tab (📄 icon)
- **Programmatically**: `context.push('/receipts')`

### 2. Dependencies
All required dependencies are already included in `pubspec.yaml`:
```yaml
dependencies:
  flutter_riverpod: ^2.4.9    # State management
  go_router: ^12.1.3          # Navigation
  path_provider: ^2.1.1       # Local storage
  sqflite: ^2.3.0             # Database
  intl: ^0.18.1               # Date formatting
```

### 3. File Structure
```
lib/
├── services/
│   └── receipt_storage_service.dart          # Storage operations
├── features/receipt/
│   ├── providers/
│   │   └── receipt_list_provider.dart        # State management
│   └── presentation/pages/
│       ├── receipt_list_page.dart            # Gallery view
│       └── receipt_detail_page.dart          # Detail view
└── core/
    └── router/app_router.dart                # Routes configured
```

## Basic Usage

### Viewing Receipts

1. **Open Receipt Gallery**
   - Tap "Receipts" in bottom navigation
   - View all saved receipts

2. **Switch View Modes**
   - Tap the view toggle icon (grid/list) in app bar
   - Grid view: 2-column thumbnail grid
   - List view: Detailed list with larger thumbnails

3. **Search Receipts**
   - Use search bar at top of screen
   - Search by merchant, amount, or date
   - Results filter in real-time

4. **Filter Receipts**
   - Tap filter chips below search bar
   - Options: All, Processed, Unprocessed

### Viewing Receipt Details

1. **Open Detail View**
   - Tap any receipt in the gallery
   - View full-size image and extracted data

2. **Zoom Image**
   - Pinch to zoom in/out
   - Double-tap to quick zoom (3x)
   - Pan around zoomed image

3. **Full Screen Mode**
   - Tap "View Full Screen" button
   - View image without UI elements
   - Zoom up to 5x magnification

## Common Tasks

### Task 1: Capture and View Receipt

```dart
// Navigate to capture screen
context.push('/receipt/capture');

// After capture, view in gallery
context.push('/receipts');
```

### Task 2: Search for Specific Receipt

```dart
// In a ConsumerWidget
final notifier = ref.read(receiptListProvider.notifier);

// Search by merchant
notifier.setSearchQuery('Walmart');

// Filter to processed only
notifier.setFilterType(ReceiptFilterType.processed);
```

### Task 3: Delete a Receipt

```dart
// From list page or detail page
final success = await ref
    .read(receiptListProvider.notifier)
    .deleteReceipt(receiptId, filePath);

if (success) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Receipt deleted')),
  );
}
```

### Task 4: Check Storage Usage

```dart
// In a ConsumerWidget
final notifier = ref.read(receiptListProvider.notifier);
final storageUsed = await notifier.getTotalStorageUsed();

// Display: "2.4 MB", "156 KB", etc.
```

### Task 5: Clean Up Orphaned Files

```dart
// Remove files not in database
final deletedCount = await ref
    .read(receiptListProvider.notifier)
    .cleanupOrphanedFiles();

print('Cleaned up $deletedCount orphaned files');
```

## Code Examples

### Example 1: Programmatically Save Receipt

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsight/services/receipt_storage_service.dart';
import 'package:finsight/data/repositories/receipt_image_repository.dart';
import 'package:finsight/core/models/receipt_image.dart';

Future<void> saveNewReceipt(
  WidgetRef ref,
  File imageFile,
  String merchant,
  double amount,
) async {
  // 1. Save image to storage
  final storageService = ref.read(receiptStorageServiceProvider);
  final savedPath = await storageService.saveReceiptImage(imageFile);

  // 2. Create receipt record
  final receipt = ReceiptImage(
    filePath: savedPath,
    extractedMerchant: merchant,
    extractedAmount: amount,
    isProcessed: true,
  );

  // 3. Save to database
  final repository = ref.read(receiptImageRepositoryProvider);
  final id = await repository.createReceiptImage(receipt);

  // 4. Refresh list
  await ref.read(receiptListProvider.notifier).loadReceipts();

  print('Receipt saved with ID: $id');
}
```

### Example 2: Create Custom Receipt Viewer

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsight/features/receipt/providers/receipt_list_provider.dart';

class CustomReceiptViewer extends ConsumerWidget {
  const CustomReceiptViewer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(receiptListProvider);

    return Scaffold(
      appBar: AppBar(title: Text('My Receipts')),
      body: ListView.builder(
        itemCount: state.filteredReceipts.length,
        itemBuilder: (context, index) {
          final receipt = state.filteredReceipts[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: FileImage(File(receipt.filePath)),
            ),
            title: Text(receipt.extractedMerchant ?? 'Unknown'),
            subtitle: Text('\$${receipt.extractedAmount?.toStringAsFixed(2) ?? '0.00'}'),
            trailing: Icon(
              receipt.isProcessed ? Icons.check : Icons.pending,
            ),
            onTap: () {
              // Navigate to detail page
              context.push('/receipt/detail/${receipt.id}');
            },
          );
        },
      ),
    );
  }
}
```

### Example 3: Receipt Statistics Widget

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsight/features/receipt/providers/receipt_list_provider.dart';

class ReceiptStatsWidget extends ConsumerWidget {
  const ReceiptStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(receiptListProvider);
    final notifier = ref.read(receiptListProvider.notifier);

    final totalReceipts = state.receipts.length;
    final processedReceipts = state.receipts.where((r) => r.isProcessed).length;
    final unprocessedReceipts = totalReceipts - processedReceipts;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _StatRow('Total Receipts', totalReceipts.toString()),
            _StatRow('Processed', processedReceipts.toString()),
            _StatRow('Pending', unprocessedReceipts.toString()),
            FutureBuilder<String>(
              future: notifier.getTotalStorageUsed(),
              builder: (context, snapshot) {
                return _StatRow('Storage Used', snapshot.data ?? 'Loading...');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
```

### Example 4: Batch Operations

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsight/features/receipt/providers/receipt_list_provider.dart';

class ReceiptBatchOperations {
  final WidgetRef ref;

  ReceiptBatchOperations(this.ref);

  /// Delete all unprocessed receipts
  Future<int> deleteUnprocessedReceipts() async {
    final state = ref.read(receiptListProvider);
    final unprocessed = state.receipts.where((r) => !r.isProcessed).toList();
    
    int deletedCount = 0;
    for (final receipt in unprocessed) {
      final success = await ref
          .read(receiptListProvider.notifier)
          .deleteReceipt(receipt.id!, receipt.filePath);
      if (success) deletedCount++;
    }
    
    return deletedCount;
  }

  /// Get receipts from date range
  Future<List<ReceiptImage>> getReceiptsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final repository = ref.read(receiptImageRepositoryProvider);
    return await repository.getReceiptsByDateRange(start, end);
  }

  /// Calculate total amount from all receipts
  double getTotalAmountFromReceipts() {
    final state = ref.read(receiptListProvider);
    return state.receipts
        .where((r) => r.extractedAmount != null)
        .fold(0.0, (sum, receipt) => sum + receipt.extractedAmount!);
  }
}
```

## Tips & Best Practices

### Performance
✅ **DO**: Use pull-to-refresh to manually refresh receipt list
✅ **DO**: Clean up orphaned files periodically
✅ **DO**: Use appropriate view mode for your use case (grid for browsing, list for details)

❌ **DON'T**: Load all receipts at once if you have thousands
❌ **DON'T**: Keep duplicate receipts without cleanup

### User Experience
✅ **DO**: Provide feedback for all operations (snackbars, loading indicators)
✅ **DO**: Confirm before deleting receipts
✅ **DO**: Show empty state when no receipts exist

❌ **DON'T**: Navigate away during file operations
❌ **DON'T**: Forget to handle error cases

### Storage Management
✅ **DO**: Monitor storage usage regularly
✅ **DO**: Clean up orphaned files when deleting receipts
✅ **DO**: Use meaningful file names when possible

❌ **DON'T**: Assume unlimited storage
❌ **DON'T**: Keep very large images without compression

## Troubleshooting

### Issue: Receipts not showing
**Solution**: 
```dart
// Manually refresh
await ref.read(receiptListProvider.notifier).loadReceipts();
```

### Issue: Image not loading
**Check**:
1. File exists: Use storage service to verify
2. File permissions are correct
3. File path is absolute and correct

### Issue: Search not working
**Verify**:
1. Search query is set: `notifier.setSearchQuery('query')`
2. Receipts have extracted data to search
3. No conflicting filters applied

### Issue: High storage usage
**Actions**:
1. Check storage info in menu
2. Run cleanup for orphaned files
3. Delete old/unnecessary receipts
4. Consider implementing image compression

## Next Steps

1. **Explore the Full Documentation**: Read [RECEIPT_STORAGE_VIEWER_MODULE.md](./RECEIPT_STORAGE_VIEWER_MODULE.md)
2. **Integrate with OCR**: Process receipts using the OCR workflow
3. **Link to Expenses**: Create expenses from receipt data
4. **Customize UI**: Modify pages to match your design system
5. **Add Features**: Implement additional functionality as needed

## Support

For issues or questions:
- Review the comprehensive module documentation
- Check code comments in implementation files
- Review existing examples in the `examples/` directory
- Test with the included manual testing checklist

---

**Module Version**: 1.0.0  
**Last Updated**: December 15, 2025  
**Status**: ✅ Production Ready
