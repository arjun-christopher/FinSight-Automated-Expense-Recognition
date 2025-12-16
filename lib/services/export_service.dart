import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../core/models/expense.dart';
import '../core/models/budget.dart';
import '../services/currency_service.dart';

/// Export Service for FinSight
/// 
/// Handles all export operations including:
/// - PDF report generation
/// - CSV file generation
/// - File sharing
/// - Export formatting
/// 
/// Usage:
/// ```dart
/// final exportService = ExportService();
/// final pdfFile = await exportService.generatePDFReport(expenses, displayCurrency: 'USD');
/// await exportService.shareFile(pdfFile);
/// ```
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final _dateFormat = DateFormat('dd/MM/yyyy');
  
  /// Get currency formatter for a specific currency
  NumberFormat _getCurrencyFormat(String currency) {
    final symbol = CurrencyService.getSymbol(currency);
    return NumberFormat.currency(symbol: symbol);
  }

  /// Generate PDF report from expenses
  /// 
  /// Creates a comprehensive PDF report with:
  /// - Summary statistics
  /// - Expense list table
  /// - Category breakdown
  /// - Date range information
  Future<File> generatePDFReport({
    required List<Expense> expenses,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String displayCurrency = 'USD',
    CurrencyService? currencyService,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = _getCurrencyFormat(displayCurrency);
    
    // Calculate summary statistics (note: amounts shown in original currency)
    final totalExpenses = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final averageExpense = expenses.isEmpty ? 0.0 : totalExpenses / expenses.length;
    
    // Group by category
    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    
    // Group by date
    final dailyTotals = <String, double>{};
    for (final expense in expenses) {
      final dateKey = _dateFormat.format(expense.date);
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + expense.amount;
    }

    // Add page with content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildPDFHeader(title ?? 'Expense Report', startDate, endDate),
          pw.SizedBox(height: 20),
          
          // Summary Section
          _buildPDFSummary(expenses.length, totalExpenses, averageExpense, currencyFormat),
          pw.SizedBox(height: 20),
          
          // Category Breakdown
          if (categoryTotals.isNotEmpty) ...[
            _buildPDFSectionTitle('Category Breakdown'),
            pw.SizedBox(height: 10),
            _buildPDFCategoryTable(categoryTotals, totalExpenses, currencyFormat),
            pw.SizedBox(height: 20),
          ],
          
          // Expense List
          if (expenses.isNotEmpty) ...[
            _buildPDFSectionTitle('Expense Details'),
            pw.SizedBox(height: 10),
            _buildPDFExpenseTable(expenses, currencyFormat),
          ],
          
          // Footer
          pw.Spacer(),
          _buildPDFFooter(),
        ],
      ),
    );

    // Save to file
    final output = await _getExportDirectory();
    final fileName = 'expense_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  /// Generate detailed PDF report with budget information
  Future<File> generateDetailedPDFReport({
    required List<Expense> expenses,
    List<Budget>? budgets,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String displayCurrency = 'USD',
    CurrencyService? currencyService,
  }) async {
    final service = currencyService ?? CurrencyService();
    final currencyFormat = _getCurrencyFormat(displayCurrency);
    final pdf = pw.Document();
    
    // Calculate statistics
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final averageExpense = expenses.isEmpty ? 0.0 : totalExpenses / expenses.length;
    
    final categoryTotals = <String, double>{};
    final categoryCount = <String, int>{};
    for (final expense in expenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0) + expense.amount;
      categoryCount[expense.category] = 
          (categoryCount[expense.category] ?? 0) + 1;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildPDFHeader(title ?? 'Detailed Expense Report', startDate, endDate),
          pw.SizedBox(height: 20),
          
          _buildPDFSummary(expenses.length, totalExpenses, averageExpense, currencyFormat),
          pw.SizedBox(height: 20),
          
          // Budget vs Actual (if budgets provided)
          if (budgets != null && budgets.isNotEmpty) ...[
            _buildPDFSectionTitle('Budget Status'),
            pw.SizedBox(height: 10),
            _buildPDFBudgetTable(budgets, categoryTotals, currencyFormat),
            pw.SizedBox(height: 20),
          ],
          
          // Category Analysis
          _buildPDFSectionTitle('Category Analysis'),
          pw.SizedBox(height: 10),
          _buildPDFCategoryAnalysis(categoryTotals, categoryCount, totalExpenses, currencyFormat),
          pw.SizedBox(height: 20),
          
          // Expense List
          _buildPDFSectionTitle('All Expenses'),
          pw.SizedBox(height: 10),
          _buildPDFExpenseTable(expenses, currencyFormat),
          
          pw.Spacer(),
          _buildPDFFooter(),
        ],
      ),
    );

    final output = await _getExportDirectory();
    final fileName = 'detailed_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  /// Generate CSV file from expenses
  /// 
  /// Creates a CSV with columns:
  /// - Date
  /// - Description
  /// - Category
  /// - Amount (converted to displayCurrency)
  Future<File> generateCSV({
    required List<Expense> expenses,
    String? fileName,
    String displayCurrency = 'USD',
    CurrencyService? currencyService,
  }) async {
    final service = currencyService ?? CurrencyService();
    final rows = <List<String>>[
      // Header row
      ['Date', 'Description', 'Category', 'Amount', 'Notes'],
      
      // Data rows
      ...expenses.map((expense) => [
        _dateFormat.format(expense.date),
        expense.description ?? '',
        expense.category,
        expense.amount.toStringAsFixed(2),
        expense.description ?? '',
      ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    
    final output = await _getExportDirectory();
    final name = fileName ?? 'expenses_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${output.path}/$name');
    await file.writeAsString(csv);
    
    return file;
  }

  /// Generate detailed CSV with additional columns
  Future<File> generateDetailedCSV({
    required List<Expense> expenses,
    String? fileName,
    String displayCurrency = 'USD',
    CurrencyService? currencyService,
  }) async {
    final service = currencyService ?? CurrencyService();
    final rows = <List<String>>[
      // Header row with more details
      [
        'Date',
        'Day of Week',
        'Description',
        'Category',
        'Amount',
        'Payment Method',
        'Notes',
        'Created At',
      ],
      
      // Data rows
      ...expenses.map((expense) {
        final dayOfWeek = DateFormat('EEEE').format(expense.date);
        final createdAt = _dateFormat.format(expense.createdAt);
        
        return [
          _dateFormat.format(expense.date),
          dayOfWeek,
          expense.description ?? '',
          expense.category,
          expense.amount.toStringAsFixed(2),
          expense.paymentMethod ?? 'N/A',
          expense.description ?? '',
          createdAt,
        ];
      }),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    
    final output = await _getExportDirectory();
    final name = fileName ?? 'expenses_detailed_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${output.path}/$name');
    await file.writeAsString(csv);
    
    return file;
  }

  /// Generate budget CSV
  Future<File> generateBudgetCSV({
    required List<Budget> budgets,
    Map<String, double>? actualSpending,
    String? fileName,
  }) async {
    final rows = <List<String>>[
      // Header row
      [
        'Category',
        'Budget Amount',
        'Period',
        'Start Date',
        'End Date',
        'Actual Spending',
        'Remaining',
        'Status',
      ],
      
      // Data rows
      ...budgets.map((budget) {
        final spent = actualSpending?[budget.category] ?? 0.0;
        final remaining = budget.amount - spent;
        final percentage = (spent / budget.amount * 100).toStringAsFixed(1);
        final status = spent >= budget.amount
            ? 'Exceeded'
            : spent >= budget.amount * 0.8
                ? 'Warning'
                : 'On Track';
        
        return [
          budget.category,
          budget.amount.toStringAsFixed(2),
          budget.period.name,
          _dateFormat.format(budget.startDate),
          budget.endDate != null ? _dateFormat.format(budget.endDate!) : 'N/A',
          spent.toStringAsFixed(2),
          remaining.toStringAsFixed(2),
          '$status ($percentage%)',
        ];
      }),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    
    final output = await _getExportDirectory();
    final name = fileName ?? 'budgets_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${output.path}/$name');
    await file.writeAsString(csv);
    
    return file;
  }

  // PDF Building Helper Methods

  pw.Widget _buildPDFHeader(String title, DateTime? startDate, DateTime? endDate) {
    String dateRange = '';
    if (startDate != null && endDate != null) {
      dateRange = '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}';
    } else if (startDate != null) {
      dateRange = 'From ${_dateFormat.format(startDate)}';
    } else if (endDate != null) {
      dateRange = 'Until ${_dateFormat.format(endDate)}';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        if (dateRange.isNotEmpty)
          pw.Text(
            dateRange,
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        pw.Text(
          'Generated on ${_dateFormat.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  pw.Widget _buildPDFSummary(int count, double total, double average, NumberFormat currencyFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildPDFSummaryStat('Total Expenses', count.toString()),
          _buildPDFSummaryStat('Total Amount', currencyFormat.format(total)),
          _buildPDFSummaryStat('Average', currencyFormat.format(average)),
        ],
      ),
    );
  }

  pw.Widget _buildPDFSummaryStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildPDFSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
    );
  }

  pw.Widget _buildPDFCategoryTable(
    Map<String, double> categoryTotals,
    double totalExpenses,
    NumberFormat currencyFormat,
  ) {
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildPDFTableCell('Category', isHeader: true),
            _buildPDFTableCell('Amount', isHeader: true),
            _buildPDFTableCell('Percentage', isHeader: true),
          ],
        ),
        // Data rows
        ...sortedCategories.map((entry) {
          final percentage = (entry.value / totalExpenses * 100).toStringAsFixed(1);
          return pw.TableRow(
            children: [
              _buildPDFTableCell(entry.key),
              _buildPDFTableCell(currencyFormat.format(entry.value)),
              _buildPDFTableCell('$percentage%'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildPDFExpenseTable(List<Expense> expenses, NumberFormat currencyFormat) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildPDFTableCell('Date', isHeader: true),
            _buildPDFTableCell('Description', isHeader: true),
            _buildPDFTableCell('Category', isHeader: true),
            _buildPDFTableCell('Amount', isHeader: true),
          ],
        ),
        // Data rows (limit to prevent overflow)
        ...expenses.take(50).map((expense) => pw.TableRow(
          children: [
            _buildPDFTableCell(_dateFormat.format(expense.date)),
            _buildPDFTableCell(expense.description ?? 'No description'),
            _buildPDFTableCell(expense.category),
            _buildPDFTableCell(currencyFormat.format(expense.amount)),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildPDFBudgetTable(
    List<Budget> budgets,
    Map<String, double> actualSpending,
    NumberFormat currencyFormat,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildPDFTableCell('Category', isHeader: true),
            _buildPDFTableCell('Budget', isHeader: true),
            _buildPDFTableCell('Actual', isHeader: true),
            _buildPDFTableCell('Remaining', isHeader: true),
            _buildPDFTableCell('Status', isHeader: true),
          ],
        ),
        ...budgets.map((budget) {
          final spent = actualSpending[budget.category] ?? 0.0;
          final remaining = budget.amount - spent;
          final percentage = (spent / budget.amount * 100).toStringAsFixed(0);
          final status = spent >= budget.amount ? 'Over' : 'OK';
          
          return pw.TableRow(
            children: [
              _buildPDFTableCell(budget.category),
              _buildPDFTableCell(currencyFormat.format(budget.amount)),
              _buildPDFTableCell(currencyFormat.format(spent)),
              _buildPDFTableCell(currencyFormat.format(remaining)),
              _buildPDFTableCell('$status ($percentage%)'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildPDFCategoryAnalysis(
    Map<String, double> categoryTotals,
    Map<String, int> categoryCount,
    double totalExpenses,
    NumberFormat currencyFormat,
  ) {
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildPDFTableCell('Category', isHeader: true),
            _buildPDFTableCell('Count', isHeader: true),
            _buildPDFTableCell('Total', isHeader: true),
            _buildPDFTableCell('Average', isHeader: true),
            _buildPDFTableCell('%', isHeader: true),
          ],
        ),
        ...sortedCategories.map((entry) {
          final count = categoryCount[entry.key] ?? 0;
          final average = count > 0 ? entry.value / count : 0;
          final percentage = (entry.value / totalExpenses * 100).toStringAsFixed(1);
          
          return pw.TableRow(
            children: [
              _buildPDFTableCell(entry.key),
              _buildPDFTableCell(count.toString()),
              _buildPDFTableCell(currencyFormat.format(entry.value)),
              _buildPDFTableCell(currencyFormat.format(average)),
              _buildPDFTableCell('$percentage%'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildPDFTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildPDFFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by FinSight',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // Helper Methods

  Future<Directory> _getExportDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');
    
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    
    return exportDir;
  }

  /// Get list of all exported files
  Future<List<File>> getExportedFiles() async {
    final directory = await _getExportDirectory();
    final files = await directory.list().toList();
    
    return files
        .whereType<File>()
        .where((file) => file.path.endsWith('.pdf') || file.path.endsWith('.csv'))
        .toList();
  }

  /// Delete an exported file
  Future<void> deleteExportedFile(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Clear all exported files
  Future<void> clearAllExports() async {
    final files = await getExportedFiles();
    for (final file in files) {
      await file.delete();
    }
  }

  /// Get file size in human-readable format
  String getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
