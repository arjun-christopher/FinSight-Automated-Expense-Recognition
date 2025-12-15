# Receipt Storage + Viewer Module

## Overview
The Receipt Storage + Viewer module provides comprehensive functionality for storing, managing, and viewing receipt images within the FinSight application. This module enables users to maintain a digital gallery of their receipts with powerful search, filter, and viewing capabilities.

## Features

### 1. Receipt Storage Service
**Location:** `lib/services/receipt_storage_service.dart`

Manages all file operations for receipt images stored in the local file system.

#### Key Capabilities:
- **Save Images**: Save receipt images from files or bytes to local storage
- **Delete Images**: Remove individual or all receipt images
- **File Management**: Check existence, get file size, and retrieve file objects
- **Storage Analytics**: Calculate total storage used by receipts
- **Cleanup**: Remove orphaned files that are no longer in the database
- **Unique Naming**: Generate unique file names for new receipts

#### Storage Location:
- Receipt images are stored in: `{ApplicationDocumentsDirectory}/receipts/`
- Files are automatically organized and managed by the service

### 2. Receipt List Provider
**Location:** `lib/features/receipt/providers/receipt_list_provider.dart`

Manages state and business logic for receipt listing and operations using Riverpod.

#### State Management:
```dart
class ReceiptListState {
  final List<ReceiptImage> receipts;
  final bool isLoading;
  final String? error;
  final ReceiptFilterType filterType;
  final String searchQuery;
  final ReceiptViewMode viewMode;
}
```

#### Key Features:
- **Load & Refresh**: Fetch all receipts from the database
- **Delete**: Remove receipts from both database and file system
- **Filter**: Filter by all/processed/unprocessed receipts
- **Search**: Search by merchant name, amount, or date
- **View Modes**: Toggle between grid and list view
- **Storage Info**: Get total storage usage statistics
- **Cleanup**: Remove orphaned files

### 3. Receipt List Page
**Location:** `lib/features/receipt/presentation/pages/receipt_list_page.dart`

A comprehensive UI for viewing and managing all receipts.

#### UI Components:
- **Search Bar**: Real-time search across merchant, amount, and date
- **Filter Chips**: Quick filters for All, Processed, and Unprocessed receipts
- **View Mode Toggle**: Switch between grid and list views
- **Receipt Counter**: Display number of filtered receipts
- **Pull-to-Refresh**: Refresh receipt list with pull gesture
- **Empty State**: Friendly message when no receipts exist

#### Grid View:
- 2-column grid layout
- Receipt image thumbnail
- Status badge (Processed/Unprocessed)
- Merchant name (if available)
- Amount and date
- Tap to view details

#### List View:
- Full-width list items
- Larger thumbnails (80x80)
- More detailed information
- Quick delete button
- Better for scanning through receipts

#### Actions:
- **Add Receipt**: FAB button to capture new receipt
- **Storage Info**: View total storage usage and receipt count
- **Cleanup**: Remove orphaned files
- **Delete**: Remove individual receipts with confirmation

### 4. Receipt Detail Page
**Location:** `lib/features/receipt/presentation/pages/receipt_detail_page.dart`

Detailed view of a single receipt with advanced viewing capabilities.

#### Image Viewing:
- **Zoomable Image**: Pan and zoom with InteractiveViewer
- **Double-Tap Zoom**: Quick zoom in/out with double-tap gesture
- **Full-Screen Mode**: View image in dedicated full-screen viewer
- **Zoom Range**: 0.5x to 5.0x magnification
- **Image Controls**: Reset zoom, pan around image

#### Information Display:
- **Status Badge**: Visual indicator of processing status
- **Merchant Name**: Extracted merchant information
- **Amount**: Formatted dollar amount in prominent display
- **Date**: Full date formatting (e.g., "December 15, 2025")
- **Confidence Score**: OCR confidence percentage
- **Capture Date**: When the receipt was captured

#### Extracted Text:
- **Full Text Display**: View complete extracted text in formatted box
- **Copy Function**: Copy text to clipboard
- **Scrollable**: Long text is fully scrollable

#### Actions:
- **Process Receipt**: Trigger OCR processing (if unprocessed)
- **Create Expense**: Navigate to expense entry with pre-filled data
- **View Full Screen**: Open dedicated full-screen image viewer
- **Share**: Share receipt (functionality placeholder)
- **Delete**: Remove receipt with confirmation dialog

### 5. Navigation Integration
**Updated Files:**
- `lib/core/router/app_router.dart`: Added routes for receipt list and detail
- `lib/core/widgets/main_navigation.dart`: Added receipts tab to bottom navigation

#### Routes:
```dart
/receipts                    // Receipt list page (with nav bar)
/receipt/capture            // Receipt capture page (full screen)
/receipt/detail/:id         // Receipt detail page (full screen)
```

#### Navigation Bar:
- **Dashboard**: Main overview
- **Add Expense**: Manual expense entry
- **Receipts**: 📄 Receipt gallery (NEW)
- **Scan**: Camera capture
- **Settings**: App settings

## Usage Examples

### Saving a Receipt Image
```dart
final storageService = ReceiptStorageService();

// Save from file
final savedPath = await storageService.saveReceiptImage(
  imageFile,
  customFileName: 'receipt_walmart_2025',
);

// Save from bytes
final savedPath = await storageService.saveReceiptImageFromBytes(
  imageBytes,
  'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
);
```

### Loading Receipts
```dart
// In a ConsumerWidget
@override
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(receiptListProvider);
  
  // Access filtered receipts
  final receipts = state.filteredReceipts;
  
  // Load receipts
  ref.read(receiptListProvider.notifier).loadReceipts();
}
```

### Filtering Receipts
```dart
final notifier = ref.read(receiptListProvider.notifier);

// Filter by type
notifier.setFilterType(ReceiptFilterType.processed);

// Search
notifier.setSearchQuery('walmart');

// Change view mode
notifier.setViewMode(ReceiptViewMode.list);
```

### Deleting a Receipt
```dart
final success = await ref
    .read(receiptListProvider.notifier)
    .deleteReceipt(receiptId, filePath);

if (success) {
  // Receipt deleted from both database and file system
}
```

### Viewing Receipt Details
```dart
// Navigate to detail page
context.push('/receipt/detail/${receiptId}');

// Or programmatically get receipt
final receipt = await ref
    .read(receiptListProvider.notifier)
    .getReceiptById(receiptId);
```

## Storage Management

### Storage Location Structure
```
{ApplicationDocumentsDirectory}/
  └── receipts/
      ├── receipt_1234567890.jpg
      ├── receipt_1234567891.jpg
      └── receipt_walmart_2025.jpg
```

### Cleanup Orphaned Files
Removes files that exist in storage but not in the database:
```dart
final deletedCount = await ref
    .read(receiptListProvider.notifier)
    .cleanupOrphanedFiles();
```

### Storage Analytics
```dart
// Get total storage used
final storageUsed = await notifier.getTotalStorageUsed();
// Returns formatted string: "2.4 MB"

// Get receipt count
final state = ref.watch(receiptListProvider);
final count = state.receipts.length;
```

## UI/UX Features

### Responsive Design
- Grid view automatically adjusts for different screen sizes
- Image thumbnails are optimized for performance
- Smooth transitions between views

### User Feedback
- Loading indicators during operations
- Error messages with retry options
- Success/failure snackbars
- Confirmation dialogs for destructive actions

### Performance Optimizations
- Images loaded on-demand
- Efficient filtering and searching
- Pull-to-refresh for manual updates
- Lazy loading in list/grid views

### Accessibility
- Clear labels and icons
- Status indicators with both color and text
- Tap targets sized appropriately
- Screen reader friendly

## Error Handling

All operations include comprehensive error handling:
- **File Not Found**: Displays broken image placeholder
- **Database Errors**: Shows error message with retry option
- **Storage Full**: Handled at system level
- **Invalid Image**: Graceful fallback to error state

## Integration Points

### With OCR Module
- Receipts can be processed using OCR workflow
- Extracted data is stored in receipt model
- Processing status tracked and displayed

### With Expense Module
- Create expense from receipt with pre-filled data
- Link expense to receipt via `receipt_image_id`
- Navigate seamlessly between modules

### With Database
- All receipts stored in SQLite database
- File paths stored as references
- Automatic cleanup on deletion

## Future Enhancements

Potential features for future development:
- [ ] Receipt image editing (crop, rotate)
- [ ] Multiple receipt images per expense
- [ ] Cloud backup and sync
- [ ] Receipt sharing via multiple channels
- [ ] Batch operations (delete multiple)
- [ ] Advanced search filters (date range, amount range)
- [ ] Receipt categories/tags
- [ ] Export receipts as PDF
- [ ] Receipt templates/presets

## Testing

### Manual Testing Checklist
- [ ] Capture and save receipt image
- [ ] View receipt in list (grid and list modes)
- [ ] Search for receipts
- [ ] Filter receipts by status
- [ ] View receipt details
- [ ] Zoom in/out on receipt image
- [ ] Delete receipt
- [ ] Check storage info
- [ ] Cleanup orphaned files
- [ ] Navigate between screens
- [ ] Handle missing images gracefully

### Edge Cases
- Empty receipt list
- Missing image files
- Very large images
- Long merchant names
- Many receipts (100+)
- Network interruption (N/A for local storage)

## Dependencies

Required packages:
- `flutter_riverpod`: State management
- `go_router`: Navigation
- `path_provider`: Local storage paths
- `sqflite`: Database operations
- `intl`: Date formatting

## Performance Considerations

- Images are not loaded into memory until needed
- Thumbnails are created on-demand by Flutter's Image widget
- Database queries are optimized with indexes
- File operations are asynchronous
- Pull-to-refresh prevents excessive database hits

## Conclusion

The Receipt Storage + Viewer module provides a complete solution for managing receipt images in the FinSight application. With its intuitive UI, powerful search and filter capabilities, and robust file management, users can easily maintain and access their receipt history.
