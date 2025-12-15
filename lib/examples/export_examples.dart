// EXPORT MODULE EXAMPLES
// 
// This file contains 10 comprehensive examples demonstrating
// how to use the Export Module in various scenarios.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/export_service.dart';
import '../services/share_helper.dart';
import '../features/export/providers/export_providers.dart';
import '../core/models/expense.dart';
import '../core/models/budget.dart';

// =============================================================================
// EXAMPLE 1: Basic PDF Export
// =============================================================================
// Generate a simple PDF report from expenses
class Example1_BasicPDFExport extends ConsumerWidget {
  const Example1_BasicPDFExport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // Create sample expenses
        final expenses = [
          Expense(
            id: 1,
            description: 'Grocery Shopping',
            amount: 85.50,
            category: 'Food',
            date: DateTime.now().subtract(const Duration(days: 2)),
            createdAt: DateTime.now(),
          ),
          Expense(
            id: 2,
            description: 'Gas Station',
            amount: 45.00,
            category: 'Transportation',
            date: DateTime.now().subtract(const Duration(days: 1)),
            createdAt: DateTime.now(),
          ),
          Expense(
            id: 3,
            description: 'Movie Tickets',
            amount: 30.00,
            category: 'Entertainment',
            date: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        ];

        // Export to PDF
        final exportService = ExportService();
        final pdfFile = await exportService.generatePDFReport(
          expenses: expenses,
          title: 'Weekly Expenses',
        );

        print('PDF generated: ${pdfFile.path}');
        print('File size: ${exportService.getFileSize(pdfFile)}');
      },
      child: const Text('Generate Basic PDF'),
    );
  }
}

// =============================================================================
// EXAMPLE 2: PDF Export with Date Range
// =============================================================================
// Export expenses for a specific date range
class Example2_PDFWithDateRange extends ConsumerWidget {
  const Example2_PDFWithDateRange({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final exportService = ExportService();
        
        // Define date range (last 30 days)
        final endDate = DateTime.now();
        final startDate = endDate.subtract(const Duration(days: 30));

        // Sample expenses
        final expenses = _generateSampleExpenses(20);

        // Export PDF with date range
        final pdfFile = await exportService.generatePDFReport(
          expenses: expenses,
          title: 'Monthly Expense Report',
          startDate: startDate,
          endDate: endDate,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF created: ${pdfFile.path}')),
        );
      },
      child: const Text('Export Last 30 Days'),
    );
  }

  List<Expense> _generateSampleExpenses(int count) {
    final categories = ['Food', 'Transportation', 'Entertainment', 'Shopping', 'Bills'];
    final expenses = <Expense>[];

    for (int i = 0; i < count; i++) {
      expenses.add(Expense(
        id: i + 1,
        description: 'Expense ${i + 1}',
        amount: 25.0 + (i * 10),
        category: categories[i % categories.length],
        date: DateTime.now().subtract(Duration(days: i)),
        createdAt: DateTime.now(),
      ));
    }

    return expenses;
  }
}

// =============================================================================
// EXAMPLE 3: Detailed PDF with Budget Analysis
// =============================================================================
// Generate comprehensive PDF with budget information
class Example3_DetailedPDFWithBudgets extends ConsumerWidget {
  const Example3_DetailedPDFWithBudgets({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final exportService = ExportService();

        // Sample expenses
        final expenses = [
          Expense(
            id: 1,
            description: 'Weekly Groceries',
            amount: 120.00,
            category: 'Food',
            date: DateTime.now(),
            createdAt: DateTime.now(),
          ),
          Expense(
            id: 2,
            description: 'Restaurant Dinner',
            amount: 65.00,
            category: 'Food',
            date: DateTime.now(),
            createdAt: DateTime.now(),
          ),
          Expense(
            id: 3,
            description: 'Uber Rides',
            amount: 45.00,
            category: 'Transportation',
            date: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        ];

        // Sample budgets
        final budgets = [
          Budget(
            id: 1,
            category: 'Food',
            amount: 500.00,
            period: BudgetPeriod.monthly,
            startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
          ),
          Budget(
            id: 2,
            category: 'Transportation',
            amount: 200.00,
            period: BudgetPeriod.monthly,
            startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
          ),
        ];

        // Generate detailed PDF
        final pdfFile = await exportService.generateDetailedPDFReport(
          expenses: expenses,
          budgets: budgets,
          title: 'Detailed Financial Report',
        );

        print('Detailed PDF: ${pdfFile.path}');
      },
      child: const Text('Generate Detailed PDF'),
    );
  }
}

// =============================================================================
// EXAMPLE 4: Basic CSV Export
// =============================================================================
// Export expenses as CSV file
class Example4_BasicCSVExport extends ConsumerWidget {
  const Example4_BasicCSVExport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final exportService = ExportService();

        // Sample expenses
        final expenses = [
          Expense(
            id: 1,
            description: 'Coffee Shop',
            amount: 5.50,
            category: 'Food',
            date: DateTime.now(),
            createdAt: DateTime.now(),
          ),
          Expense(
            id: 2,
            description: 'Parking Fee',
            amount: 12.00,
            category: 'Transportation',
            date: DateTime.now(),
            createdAt: DateTime.now(),
            notes: 'Downtown parking',
          ),
        ];

        // Export to CSV
        final csvFile = await exportService.generateCSV(
          expenses: expenses,
          fileName: 'my_expenses.csv',
        );

        print('CSV generated: ${csvFile.path}');

        // Read and display CSV content
        final content = await csvFile.readAsString();
        print('CSV Content:\n$content');
      },
      child: const Text('Generate CSV'),
    );
  }
}

// =============================================================================
// EXAMPLE 5: Detailed CSV with Extra Columns
// =============================================================================
// Export comprehensive CSV with additional data
class Example5_DetailedCSVExport extends ConsumerWidget {
  const Example5_DetailedCSVExport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final exportService = ExportService();

        final expenses = [
          Expense(
            id: 1,
            description: 'Online Shopping',
            amount: 89.99,
            category: 'Shopping',
            date: DateTime.now(),
            createdAt: DateTime.now(),
            paymentMethod: 'Credit Card',
            notes: 'Amazon purchase',
          ),
          Expense(
            id: 2,
            description: 'Gym Membership',
            amount: 45.00,
            category: 'Health',
            date: DateTime.now(),
            createdAt: DateTime.now(),
            paymentMethod: 'Debit Card',
          ),
        ];

        // Generate detailed CSV
        final csvFile = await exportService.generateDetailedCSV(
          expenses: expenses,
        );

        print('Detailed CSV: ${csvFile.path}');
        print('Content:\n${await csvFile.readAsString()}');
      },
      child: const Text('Generate Detailed CSV'),
    );
  }
}

// =============================================================================
// EXAMPLE 6: Budget CSV Export
// =============================================================================
// Export budget data with actual spending
class Example6_BudgetCSVExport extends ConsumerWidget {
  const Example6_BudgetCSVExport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final exportService = ExportService();

        final budgets = [
          Budget(
            id: 1,
            category: 'Food',
            amount: 600.00,
            period: BudgetPeriod.monthly,
            startDate: DateTime(2024, 1, 1),
          ),
          Budget(
            id: 2,
            category: 'Entertainment',
            amount: 200.00,
            period: BudgetPeriod.monthly,
            startDate: DateTime(2024, 1, 1),
          ),
        ];

        // Actual spending data
        final actualSpending = {
          'Food': 450.00,
          'Entertainment': 220.00, // Exceeded!
        };

        // Export budget CSV
        final csvFile = await exportService.generateBudgetCSV(
          budgets: budgets,
          actualSpending: actualSpending,
        );

        print('Budget CSV: ${csvFile.path}');
      },
      child: const Text('Export Budget CSV'),
    );
  }
}

// =============================================================================
// EXAMPLE 7: Share Exported File
// =============================================================================
// Export and immediately share the file
class Example7_ExportAndShare extends ConsumerWidget {
  const Example7_ExportAndShare({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final exportService = ExportService();

        // Generate PDF
        final expenses = _createSampleExpenses();
        final pdfFile = await exportService.generatePDFReport(
          expenses: expenses,
          title: 'Expense Report',
        );

        // Share the file
        await ShareHelper.shareFile(
          file: pdfFile,
          subject: 'My Expense Report',
          text: 'Please find attached my expense report.',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share dialog opened')),
        );
      },
      child: const Text('Export & Share'),
    );
  }

  List<Expense> _createSampleExpenses() {
    return [
      Expense(
        id: 1,
        description: 'Business Lunch',
        amount: 45.00,
        category: 'Food',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
      Expense(
        id: 2,
        description: 'Taxi to Airport',
        amount: 35.00,
        category: 'Transportation',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    ];
  }
}

// =============================================================================
// EXAMPLE 8: Using Riverpod Controller
// =============================================================================
// Export using the ExportController with Riverpod
class Example8_UseExportController extends ConsumerWidget {
  const Example8_UseExportController({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportStateProvider);
    final exportController = ref.read(exportStateProvider.notifier);

    return Column(
      children: [
        ElevatedButton(
          onPressed: exportState.isExporting
              ? null
              : () async {
                  final expenses = _getSampleExpenses();
                  
                  // Export using controller
                  final file = await exportController.exportToPDF(
                    expenses: expenses,
                    title: 'My Report',
                  );

                  if (file != null) {
                    // Share the exported file
                    await exportController.shareLastExport(
                      subject: 'FinSight Report',
                      text: 'Check out this report!',
                    );
                  }
                },
          child: exportState.isExporting
              ? const Text('Exporting...')
              : const Text('Export with Controller'),
        ),
        if (exportState.error != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              exportState.error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        if (exportState.lastExportedFile != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Last export: ${exportState.lastExportedFile!.path.split('/').last}',
              style: const TextStyle(color: Colors.green),
            ),
          ),
      ],
    );
  }

  List<Expense> _getSampleExpenses() {
    return [
      Expense(
        id: 1,
        description: 'Sample Expense',
        amount: 50.00,
        category: 'Other',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    ];
  }
}

// =============================================================================
// EXAMPLE 9: Managing Export History
// =============================================================================
// List, share, and delete exported files
class Example9_ManageExportHistory extends ConsumerWidget {
  const Example9_ManageExportHistory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportedFilesAsync = ref.watch(exportedFilesProvider);

    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            final exportService = ExportService();
            
            // Get all exported files
            final files = await exportService.getExportedFiles();
            
            print('Found ${files.length} exported files:');
            for (final file in files) {
              print('  - ${file.path.split('/').last}');
              print('    Size: ${exportService.getFileSize(file)}');
            }

            // Delete oldest file if more than 5 exist
            if (files.length > 5) {
              final oldestFile = files.first;
              await exportService.deleteExportedFile(oldestFile);
              print('Deleted: ${oldestFile.path.split('/').last}');
              
              // Refresh the provider
              ref.invalidate(exportedFilesProvider);
            }
          },
          child: const Text('Manage History'),
        ),
        const SizedBox(height: 16),
        exportedFilesAsync.when(
          data: (files) => Text('${files.length} files in history'),
          loading: () => const CircularProgressIndicator(),
          error: (e, s) => Text('Error: $e'),
        ),
      ],
    );
  }
}

// =============================================================================
// EXAMPLE 10: Complete Export Workflow
// =============================================================================
// Full workflow: Filter, Export, Share, Clean up
class Example10_CompleteWorkflow extends ConsumerStatefulWidget {
  const Example10_CompleteWorkflow({super.key});

  @override
  ConsumerState<Example10_CompleteWorkflow> createState() =>
      _Example10CompleteWorkflowState();
}

class _Example10CompleteWorkflowState
    extends ConsumerState<Example10_CompleteWorkflow> {
  bool _isProcessing = false;
  String _status = 'Ready';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isProcessing ? null : _runCompleteWorkflow,
              child: const Text('Run Complete Workflow'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runCompleteWorkflow() async {
    setState(() {
      _isProcessing = true;
      _status = 'Starting...';
    });

    try {
      final exportService = ExportService();
      final exportController = ref.read(exportStateProvider.notifier);

      // Step 1: Generate sample data
      setState(() => _status = 'Generating sample data...');
      final expenses = _generateExpenses(30);
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: Filter expenses (last 7 days)
      setState(() => _status = 'Filtering expenses...');
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentExpenses = expenses
          .where((e) => e.date.isAfter(sevenDaysAgo))
          .toList();
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 3: Export to PDF
      setState(() => _status = 'Generating PDF report...');
      final pdfFile = await exportController.exportToPDF(
        expenses: recentExpenses,
        title: 'Weekly Report',
        startDate: sevenDaysAgo,
        endDate: DateTime.now(),
      );
      await Future.delayed(const Duration(milliseconds: 500));

      if (pdfFile == null) {
        throw Exception('Failed to generate PDF');
      }

      // Step 4: Export to CSV
      setState(() => _status = 'Generating CSV file...');
      final csvFile = await exportController.exportToCSV(
        expenses: recentExpenses,
      );
      await Future.delayed(const Duration(milliseconds: 500));

      if (csvFile == null) {
        throw Exception('Failed to generate CSV');
      }

      // Step 5: Share both files
      setState(() => _status = 'Sharing files...');
      await ShareHelper.shareFiles(
        files: [pdfFile, csvFile],
        subject: 'Weekly Expense Report',
        text: 'Please find attached my weekly expense report in PDF and CSV format.',
      );
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 6: Clean up old exports (keep last 10)
      setState(() => _status = 'Cleaning up old exports...');
      final allFiles = await exportService.getExportedFiles();
      if (allFiles.length > 10) {
        final filesToDelete = allFiles.take(allFiles.length - 10);
        for (final file in filesToDelete) {
          await exportService.deleteExportedFile(file);
        }
      }

      setState(() => _status = 'Workflow completed successfully!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export workflow completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workflow failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  List<Expense> _generateExpenses(int count) {
    final categories = [
      'Food',
      'Transportation',
      'Entertainment',
      'Shopping',
      'Bills',
      'Health',
    ];
    
    return List.generate(count, (i) {
      return Expense(
        id: i + 1,
        description: 'Expense ${i + 1}',
        amount: 10.0 + (i * 5),
        category: categories[i % categories.length],
        date: DateTime.now().subtract(Duration(days: i)),
        createdAt: DateTime.now(),
        paymentMethod: i % 2 == 0 ? 'Credit Card' : 'Cash',
        notes: i % 3 == 0 ? 'Sample note' : null,
      );
    });
  }
}

// =============================================================================
// DEMO APP - Run all examples
// =============================================================================
class ExportExamplesDemo extends StatelessWidget {
  const ExportExamplesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Example 1: Basic PDF Export',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Example1_BasicPDFExport(),
          Divider(),
          Text('Example 2: PDF with Date Range',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Example2_PDFWithDateRange(),
          Divider(),
          Text('Example 3: Detailed PDF with Budgets',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Example3_DetailedPDFWithBudgets(),
          Divider(),
          Text('Example 4: Basic CSV Export',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Example4_BasicCSVExport(),
          Divider(),
          Text('Example 5: Detailed CSV Export',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Example5_DetailedCSVExport(),
          Divider(),
          Text('Example 6: Budget CSV Export',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Example6_BudgetCSVExport(),
          Divider(),
          Text('Example 7: Export and Share',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Example7_ExportAndShare(),
          Divider(),
          Text('Example 8: Use Export Controller',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Example8_UseExportController(),
          Divider(),
          Text('Example 9: Manage Export History',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Example9_ManageExportHistory(),
          Divider(),
          Text('Example 10: Complete Workflow',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Example10_CompleteWorkflow(),
        ],
      ),
    );
  }
}
