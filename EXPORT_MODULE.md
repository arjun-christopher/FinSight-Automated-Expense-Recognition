# Export Module Documentation

Complete documentation for the FinSight Export Module.

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Installation](#installation)
5. [Quick Start](#quick-start)
6. [API Reference](#api-reference)
7. [Usage Examples](#usage-examples)
8. [Integration Guide](#integration-guide)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

---

## Overview

The Export Module provides comprehensive data export functionality for FinSight, allowing users to generate professional reports and share expense data in multiple formats.

### Key Capabilities

- **PDF Generation**: Create formatted PDF reports with summaries, tables, and analysis
- **CSV Export**: Generate CSV files for spreadsheet import and data analysis
- **File Sharing**: Share exports via native platform sharing
- **Export Management**: Track, list, and manage exported files
- **Date Filtering**: Export data for specific time periods
- **Budget Integration**: Include budget analysis in detailed reports

---

## Features

### Export Formats

| Format | Description | Use Case |
|--------|-------------|----------|
| **PDF Report** | Standard PDF with expense summary and list | Quick overview, professional reports |
| **Detailed PDF** | Comprehensive PDF with budget analysis | Monthly reviews, detailed analysis |
| **CSV File** | Simple CSV with basic expense data | Spreadsheet import, basic analysis |
| **Detailed CSV** | Extended CSV with additional columns | Advanced analysis, data backup |
| **Budget CSV** | Budget data with actual vs planned | Budget tracking, financial planning |

### Core Features

✅ **Multiple Export Formats** - PDF and CSV in standard and detailed versions  
✅ **Date Range Filtering** - Export specific time periods  
✅ **Category Analysis** - Breakdown by expense categories  
✅ **Budget Comparison** - Actual vs budgeted spending  
✅ **File Sharing** - Native platform sharing via share_plus  
✅ **Export History** - Track and manage all exported files  
✅ **File Management** - Delete individual or all exports  
✅ **Progress Tracking** - Monitor export operations  
✅ **Error Handling** - Comprehensive error messages  

---

## Architecture

### Component Overview

```
Export Module
├── Services
│   ├── ExportService (export_service.dart)
│   └── ShareHelper (share_helper.dart)
├── Providers
│   └── export_providers.dart
│       ├── ExportController
│       ├── ExportState
│       └── Providers (8 total)
├── UI
│   └── pages
│       ├── ExportPage
│       └── ExportHistoryPage
└── Examples
    └── export_examples.dart (10 examples)
```

### Data Flow

```
User Action → ExportController → ExportService → File System
                    ↓                    ↓
              Update State         Generate File
                    ↓                    ↓
              UI Update ← ← ← ← Return File Path
                    ↓
            ShareHelper (optional)
                    ↓
          Platform Share Dialog
```

---

## Installation

### 1. Dependencies

The following packages are required (already in pubspec.yaml):

```yaml
dependencies:
  # File Operations
  pdf: ^3.10.7              # PDF generation
  csv: ^5.1.1               # CSV generation
  share_plus: ^7.2.1        # File sharing
  path_provider: ^2.1.1     # File storage
  
  # Utilities
  intl: ^0.18.1             # Formatting
  flutter_riverpod: ^2.4.9  # State management
```

### 2. Install Packages

```bash
flutter pub get
```

### 3. Platform Configuration

#### iOS (ios/Runner/Info.plist)

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Allow FinSight to save exports to your photo library</string>
```

#### Android (android/app/src/main/AndroidManifest.xml)

```xml
<!-- Already configured, no additional permissions needed -->
```

---

## Quick Start

### Basic PDF Export (30 seconds)

```dart
import 'package:finsight/services/export_service.dart';

// 1. Create export service
final exportService = ExportService();

// 2. Get your expenses
final expenses = await expenseRepository.getAllExpenses();

// 3. Generate PDF
final pdfFile = await exportService.generatePDFReport(
  expenses: expenses,
  title: 'My Expense Report',
);

print('PDF created: ${pdfFile.path}');
```

### Export and Share (1 minute)

```dart
import 'package:finsight/services/export_service.dart';
import 'package:finsight/services/share_helper.dart';

// Generate PDF
final exportService = ExportService();
final pdfFile = await exportService.generatePDFReport(
  expenses: expenses,
);

// Share it
await ShareHelper.shareFile(
  file: pdfFile,
  subject: 'Expense Report',
  text: 'Here is my expense report',
);
```

### Using Riverpod Controller (2 minutes)

```dart
// In your widget
final exportController = ref.read(exportStateProvider.notifier);

// Export
final file = await exportController.exportToPDF(
  expenses: expenses,
  title: 'Monthly Report',
);

// Share
if (file != null) {
  await exportController.shareLastExport();
}
```

---

## API Reference

### ExportService

Main service for generating exports.

#### Methods

##### `generatePDFReport()`

Generate a standard PDF report.

```dart
Future<File> generatePDFReport({
  required List<Expense> expenses,
  String? title,
  DateTime? startDate,
  DateTime? endDate,
})
```

**Parameters:**
- `expenses` - List of expenses to include
- `title` - Report title (optional)
- `startDate` - Start of date range (optional)
- `endDate` - End of date range (optional)

**Returns:** File object of generated PDF

**Example:**
```dart
final pdf = await exportService.generatePDFReport(
  expenses: myExpenses,
  title: 'Q1 Report',
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 3, 31),
);
```

---

##### `generateDetailedPDFReport()`

Generate a comprehensive PDF with budget analysis.

```dart
Future<File> generateDetailedPDFReport({
  required List<Expense> expenses,
  List<Budget>? budgets,
  String? title,
  DateTime? startDate,
  DateTime? endDate,
})
```

**Additional Parameters:**
- `budgets` - Budget data for comparison (optional)

**Includes:**
- Budget vs Actual comparison
- Category analysis with counts and averages
- Detailed expense list
- Statistical summary

---

##### `generateCSV()`

Generate a basic CSV file.

```dart
Future<File> generateCSV({
  required List<Expense> expenses,
  String? fileName,
})
```

**CSV Columns:**
- Date
- Description
- Category
- Amount
- Notes

---

##### `generateDetailedCSV()`

Generate CSV with additional columns.

```dart
Future<File> generateDetailedCSV({
  required List<Expense> expenses,
  String? fileName,
})
```

**Additional Columns:**
- Day of Week
- Payment Method
- Created At timestamp

---

##### `generateBudgetCSV()`

Export budget data with spending comparison.

```dart
Future<File> generateBudgetCSV({
  required List<Budget> budgets,
  Map<String, double>? actualSpending,
  String? fileName,
})
```

**CSV Columns:**
- Category
- Budget Amount
- Period
- Start/End Date
- Actual Spending
- Remaining
- Status

---

##### Utility Methods

```dart
// Get all exported files
Future<List<File>> getExportedFiles()

// Delete a file
Future<void> deleteExportedFile(File file)

// Clear all exports
Future<void> clearAllExports()

// Get human-readable file size
String getFileSize(File file)
```

---

### ShareHelper

Static helper class for sharing files.

#### Methods

##### `shareFile()`

Share a single file.

```dart
static Future<ShareResult> shareFile({
  required File file,
  String? subject,
  String? text,
})
```

**Example:**
```dart
await ShareHelper.shareFile(
  file: pdfFile,
  subject: 'My Report',
  text: 'Please review this expense report',
);
```

---

##### `shareFiles()`

Share multiple files.

```dart
static Future<ShareResult> shareFiles({
  required List<File> files,
  String? subject,
  String? text,
})
```

**Example:**
```dart
await ShareHelper.shareFiles(
  files: [pdfFile, csvFile],
  subject: 'Expense Reports',
  text: 'Attached are PDF and CSV versions',
);
```

---

### ExportController (Riverpod)

State management for export operations.

#### State

```dart
class ExportState {
  final bool isExporting;           // Export in progress
  final File? lastExportedFile;     // Most recent file
  final String? error;              // Error message
  final ExportProgress? progress;   // Progress info
}
```

#### Methods

```dart
// Export to PDF
Future<File?> exportToPDF({
  required List<Expense> expenses,
  String? title,
  DateTime? startDate,
  DateTime? endDate,
})

// Export to detailed PDF
Future<File?> exportToDetailedPDF({
  required List<Expense> expenses,
  List<Budget>? budgets,
  String? title,
  DateTime? startDate,
  DateTime? endDate,
})

// Export to CSV
Future<File?> exportToCSV({
  required List<Expense> expenses,
  String? fileName,
})

// Export to detailed CSV
Future<File?> exportToDetailedCSV({
  required List<Expense> expenses,
  String? fileName,
})

// Export budgets to CSV
Future<File?> exportBudgetsToCSV({
  required List<Budget> budgets,
  Map<String, double>? actualSpending,
  String? fileName,
})

// Share last export
Future<bool> shareLastExport({
  String? subject,
  String? text,
})

// Share specific file
Future<bool> shareFile(File file, {
  String? subject,
  String? text,
})

// Delete file
Future<void> deleteFile(File file)

// Clear all exports
Future<void> clearAllExports()

// Clear error
void clearError()
```

---

### Providers

#### exportServiceProvider

Provides ExportService instance.

```dart
final exportService = ref.watch(exportServiceProvider);
```

---

#### exportStateProvider

Provides ExportController and state.

```dart
final exportState = ref.watch(exportStateProvider);
final controller = ref.read(exportStateProvider.notifier);
```

---

#### exportFormatProvider

Currently selected export format.

```dart
final format = ref.watch(exportFormatProvider);
ref.read(exportFormatProvider.notifier).state = ExportFormat.pdf;
```

---

#### exportedFilesProvider

List of all exported files.

```dart
final filesAsync = ref.watch(exportedFilesProvider);
filesAsync.when(
  data: (files) => Text('${files.length} files'),
  loading: () => CircularProgressIndicator(),
  error: (e, s) => Text('Error: $e'),
);
```

---

## Usage Examples

See [`lib/examples/export_examples.dart`](../lib/examples/export_examples.dart) for 10 complete examples:

1. **Basic PDF Export** - Simple PDF generation
2. **PDF with Date Range** - Filter by dates
3. **Detailed PDF with Budgets** - Include budget analysis
4. **Basic CSV Export** - Generate CSV file
5. **Detailed CSV** - CSV with extra columns
6. **Budget CSV** - Export budget data
7. **Export and Share** - Generate and share
8. **Using Controller** - Riverpod integration
9. **Export History** - Manage files
10. **Complete Workflow** - End-to-end example

---

## Integration Guide

### Add Export to Your App

#### 1. Add Navigation

```dart
// In your navigation menu
ListTile(
  leading: Icon(Icons.file_download),
  title: Text('Export Data'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExportPage(),
      ),
    );
  },
)
```

#### 2. Add to Dashboard

```dart
// Quick export button on dashboard
ElevatedButton.icon(
  onPressed: () => _quickExport(),
  icon: Icon(Icons.download),
  label: Text('Export Report'),
)

Future<void> _quickExport() async {
  final controller = ref.read(exportStateProvider.notifier);
  final expenses = await getRecentExpenses();
  
  final file = await controller.exportToPDF(
    expenses: expenses,
    title: 'Quick Report',
  );
  
  if (file != null) {
    await controller.shareLastExport();
  }
}
```

#### 3. Automated Exports

```dart
// Schedule monthly export
void scheduleMonthlyExport() {
  // Use with notification_scheduler
  final now = DateTime.now();
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
  
  // Schedule for last day of month
  notificationService.scheduleNotification(
    title: 'Monthly Export Ready',
    body: 'Tap to export your monthly report',
    scheduledDate: lastDayOfMonth,
    payload: 'export_monthly',
  );
}
```

---

## Best Practices

### 1. Data Volume

```dart
// For large datasets, filter before export
final recentExpenses = expenses
    .where((e) => e.date.isAfter(cutoffDate))
    .toList();

await exportService.generatePDFReport(
  expenses: recentExpenses,
);
```

### 2. Error Handling

```dart
try {
  final file = await controller.exportToPDF(
    expenses: expenses,
  );
  
  if (file != null) {
    // Success
  }
} catch (e) {
  // Handle error
  showError('Export failed: $e');
}
```

### 3. User Feedback

```dart
// Show progress
if (exportState.isExporting) {
  return LinearProgressIndicator();
}

// Show success
if (exportState.lastExportedFile != null) {
  showSnackBar('Export successful!');
}

// Show error
if (exportState.error != null) {
  showError(exportState.error!);
}
```

### 4. File Management

```dart
// Clean up old exports periodically
Future<void> cleanupOldExports() async {
  final files = await exportService.getExportedFiles();
  
  // Keep only last 10 files
  if (files.length > 10) {
    final toDelete = files.take(files.length - 10);
    for (final file in toDelete) {
      await exportService.deleteExportedFile(file);
    }
  }
}
```

### 5. Naming Conventions

```dart
// Use descriptive file names
final fileName = 'expenses_${category}_${dateRange}.csv';

await exportService.generateCSV(
  expenses: expenses,
  fileName: fileName,
);
```

---

## Troubleshooting

### Common Issues

#### 1. File Not Found

**Problem:** Exported file cannot be found  
**Solution:** Files are stored in app documents directory

```dart
final exportDir = await getApplicationDocumentsDirectory();
print('Export location: ${exportDir.path}/exports');
```

#### 2. Share Dialog Not Opening

**Problem:** Share dialog doesn't appear  
**Solution:** Check platform permissions

```dart
// iOS: Add to Info.plist
<key>NSPhotoLibraryUsageDescription</key>
<string>To save exports</string>
```

#### 3. PDF Generation Fails

**Problem:** PDF generation throws error  
**Solution:** Check for empty expense list or invalid data

```dart
if (expenses.isEmpty) {
  throw Exception('No expenses to export');
}
```

#### 4. Large File Size

**Problem:** PDF files are too large  
**Solution:** Limit number of expenses or use CSV

```dart
// Limit to 100 expenses per PDF
final limitedExpenses = expenses.take(100).toList();
```

#### 5. Memory Issues

**Problem:** App crashes on large exports  
**Solution:** Use streaming or pagination

```dart
// Export in batches
for (var i = 0; i < expenses.length; i += 100) {
  final batch = expenses.skip(i).take(100).toList();
  await exportBatch(batch, i ~/ 100);
}
```

---

## Performance Considerations

### PDF Generation

- **Small (<50 expenses):** < 1 second
- **Medium (50-200 expenses):** 1-3 seconds
- **Large (200+ expenses):** 3-10 seconds

### CSV Generation

- **All sizes:** < 1 second (CSV is lightweight)

### Recommendations

1. Show progress indicator for exports > 50 items
2. Use CSV for large datasets
3. Implement pagination for very large reports
4. Clean up old exports regularly

---

## Security Considerations

### File Storage

- Files are stored in app-specific documents directory
- Automatically cleaned when app is uninstalled
- Not accessible to other apps

### Data Privacy

- No data is sent to external servers
- All processing happens locally
- User controls all file sharing

### Best Practices

```dart
// 1. Validate input
if (expenses.isEmpty) {
  return; // Don't export empty data
}

// 2. Sanitize file names
final safeName = fileName.replaceAll(RegExp(r'[^\w\s-]'), '');

// 3. Delete sensitive exports
await exportService.clearAllExports();
```

---

## Testing

### Unit Tests

```dart
test('Export service generates PDF', () async {
  final service = ExportService();
  final expenses = [createTestExpense()];
  
  final file = await service.generatePDFReport(
    expenses: expenses,
  );
  
  expect(await file.exists(), true);
});
```

### Widget Tests

```dart
testWidgets('Export page shows format options', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: ExportPage()),
    ),
  );
  
  expect(find.text('PDF Report'), findsOneWidget);
  expect(find.text('CSV File'), findsOneWidget);
});
```

---

## Changelog

### Version 1.0.0 (Task 13)

- ✅ Initial release
- ✅ PDF report generation (standard and detailed)
- ✅ CSV file generation (standard and detailed)
- ✅ File sharing via share_plus
- ✅ Export history management
- ✅ Riverpod state management
- ✅ Date range filtering
- ✅ Budget integration
- ✅ Complete UI (ExportPage + HistoryPage)
- ✅ 10 usage examples
- ✅ Comprehensive documentation

---

## Additional Resources

- [Export Examples](../lib/examples/export_examples.dart) - 10 complete examples
- [Quick Start Guide](./EXPORT_QUICK_START.md) - 5-minute setup
- [Task Summary](./TASK_13_SUMMARY.md) - Implementation details
- [pdf Package Docs](https://pub.dev/packages/pdf)
- [csv Package Docs](https://pub.dev/packages/csv)
- [share_plus Docs](https://pub.dev/packages/share_plus)

---

## Support

For issues or questions:

1. Check [Troubleshooting](#troubleshooting) section
2. Review [Examples](../lib/examples/export_examples.dart)
3. See [Integration Guide](#integration-guide)

---

**Module:** Export  
**Version:** 1.0.0  
**Status:** ✅ Production Ready  
**Last Updated:** January 2024
