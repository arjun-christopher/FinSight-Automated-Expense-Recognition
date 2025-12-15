# Export Module - Quick Start Guide

Get started with the Export Module in 5 minutes!

## 🚀 What You'll Learn

- Generate PDF reports in 30 seconds
- Export CSV files
- Share exports with other apps
- Manage export history

---

## 📋 Prerequisites

Already done! The Export Module is fully integrated. Just need to:

```bash
flutter pub get
```

---

## ⚡ Quick Start (30 Seconds)

### 1. Basic PDF Export

```dart
import 'package:finsight/services/export_service.dart';

// Create service
final exportService = ExportService();

// Get your expenses (from your existing code)
final expenses = await expenseRepository.getAllExpenses();

// Export to PDF
final pdfFile = await exportService.generatePDFReport(
  expenses: expenses,
  title: 'My Expense Report',
);

print('PDF created: ${pdfFile.path}');
```

**That's it!** You now have a professional PDF report.

---

## 📤 Share the Export (30 Seconds)

```dart
import 'package:finsight/services/share_helper.dart';

// After creating the PDF...
await ShareHelper.shareFile(
  file: pdfFile,
  subject: 'Expense Report',
  text: 'Here is my expense report',
);
```

This opens the native share dialog on iOS/Android!

---

## 💾 CSV Export (30 Seconds)

```dart
// Export to CSV instead
final csvFile = await exportService.generateCSV(
  expenses: expenses,
);

// CSV is ready to open in Excel, Google Sheets, etc.
```

---

## 🎮 Using the UI (1 Minute)

### Navigate to Export Page

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ExportPage(),
  ),
);
```

### The UI provides:

1. **Format Selection** - Choose PDF or CSV, standard or detailed
2. **Date Range** - Filter expenses by date
3. **Export Button** - One-click export
4. **Share Button** - Share immediately after export
5. **History** - View all past exports

---

## 🔄 Using Riverpod (2 Minutes)

More control with the ExportController:

```dart
// In your ConsumerWidget
class MyExportWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportStateProvider);
    final controller = ref.read(exportStateProvider.notifier);
    
    return ElevatedButton(
      onPressed: () async {
        // Export
        final file = await controller.exportToPDF(
          expenses: myExpenses,
          title: 'Monthly Report',
        );
        
        // Share
        if (file != null) {
          await controller.shareLastExport();
        }
      },
      child: Text(
        exportState.isExporting ? 'Exporting...' : 'Export',
      ),
    );
  }
}
```

---

## 📊 Export Formats

### 4 Format Options:

| Format | Best For | Features |
|--------|----------|----------|
| **PDF Report** | Quick overview | Summary + expense list |
| **Detailed PDF** | Full analysis | Budgets + category analysis |
| **CSV File** | Spreadsheet import | Basic columns |
| **Detailed CSV** | Data backup | All fields + metadata |

---

## 🎯 Common Use Cases

### 1. Monthly Report

```dart
final now = DateTime.now();
final startOfMonth = DateTime(now.year, now.month, 1);

final file = await exportService.generatePDFReport(
  expenses: expenses,
  title: 'Monthly Expense Report',
  startDate: startOfMonth,
  endDate: now,
);
```

### 2. Budget Review

```dart
final file = await exportService.generateDetailedPDFReport(
  expenses: expenses,
  budgets: myBudgets,  // Include budget comparison
  title: 'Budget Review',
);
```

### 3. Tax Documentation

```dart
// Full year CSV for tax records
final taxFile = await exportService.generateDetailedCSV(
  expenses: yearExpenses,
  fileName: 'tax_records_2024.csv',
);
```

### 4. Share with Accountant

```dart
// Generate both formats and share
final pdf = await exportService.generateDetailedPDFReport(...);
final csv = await exportService.generateDetailedCSV(...);

await ShareHelper.shareFiles(
  files: [pdf, csv],
  subject: 'Expense Records - Q4 2024',
  text: 'Attached are my expense records in PDF and CSV format.',
);
```

---

## 🗂️ Managing Exports

### View Export History

```dart
// Navigate to history
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ExportHistoryPage(),
  ),
);
```

### Get All Exports

```dart
final files = await exportService.getExportedFiles();
print('You have ${files.length} exported files');
```

### Clean Up Old Exports

```dart
// Delete specific file
await exportService.deleteExportedFile(oldFile);

// Or clear all
await exportService.clearAllExports();
```

---

## 🎨 Customization

### Custom Report Title

```dart
await exportService.generatePDFReport(
  expenses: expenses,
  title: '🎉 Year-End Summary 2024',
);
```

### Custom File Name

```dart
await exportService.generateCSV(
  expenses: expenses,
  fileName: 'my_custom_name.csv',
);
```

### Date Range Filter

```dart
final lastWeek = DateTime.now().subtract(Duration(days: 7));

await exportService.generatePDFReport(
  expenses: expenses,
  startDate: lastWeek,
  endDate: DateTime.now(),
);
```

---

## 📱 Platform Notes

### iOS
- Share dialog includes: Messages, Mail, Files, etc.
- PDFs can be saved to Files app
- No additional setup required

### Android
- Share dialog includes: Gmail, Drive, WhatsApp, etc.
- Files saved to app storage
- No permissions needed

---

## 🔧 Troubleshooting

### "No expenses to export"
```dart
// Check if list is empty
if (expenses.isEmpty) {
  print('Add some expenses first!');
}
```

### "File not found"
```dart
// Files are in app documents directory
final dir = await getApplicationDocumentsDirectory();
print('Exports location: ${dir.path}/exports');
```

### "Share not working"
```dart
// Make sure file was created successfully
if (file != null && await file.exists()) {
  await ShareHelper.shareFile(file: file);
}
```

---

## 🎓 Next Steps

1. ✅ **Done:** Basic export working
2. 📚 **Learn More:** Check [EXPORT_MODULE.md](./EXPORT_MODULE.md) for full API
3. 💡 **Examples:** See [export_examples.dart](./lib/examples/export_examples.dart)
4. 🔗 **Integrate:** Add export button to your dashboard
5. 🎨 **Customize:** Adjust report formatting to your needs

---

## 📚 More Resources

- **Full Documentation:** [EXPORT_MODULE.md](./EXPORT_MODULE.md)
- **10 Examples:** [export_examples.dart](./lib/examples/export_examples.dart)
- **Implementation Details:** [TASK_13_SUMMARY.md](./TASK_13_SUMMARY.md)

---

## 💡 Pro Tips

1. **Use CSV for large datasets** - Faster and smaller file size
2. **Set up monthly auto-export** - Schedule with notification system
3. **Keep last 10 exports** - Clean up old files regularly
4. **Share both PDF + CSV** - Give recipients options
5. **Add date ranges** - Keep reports focused

---

## ✅ Checklist

- [ ] Run `flutter pub get`
- [ ] Test basic PDF export
- [ ] Test sharing functionality
- [ ] Try different export formats
- [ ] Check export history page
- [ ] Integrate into your app
- [ ] Customize report titles
- [ ] Set up automated exports (optional)

---

**Ready to Export!** 🚀

Your Export Module is fully configured and ready to use. Start with the basic examples above, then explore the full documentation for advanced features.

**Questions?** Check [EXPORT_MODULE.md](./EXPORT_MODULE.md) or [export_examples.dart](./lib/examples/export_examples.dart)
