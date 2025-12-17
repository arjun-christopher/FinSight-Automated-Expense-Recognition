import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/export_providers.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/models/budget.dart';
import '../../../budget/providers/budget_providers.dart';

/// Export Page - Allows users to export expenses in various formats
/// 
/// Features:
/// - Multiple export formats (PDF, CSV, detailed versions)
/// - Date range selection
/// - Export preview and management
/// - Share exported files
class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  ExportFormat _selectedFormat = ExportFormat.pdf;

  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportStateProvider);
    final exportController = ref.read(exportStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showExportHistory(context),
            tooltip: 'Export History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Export Format Selection
            _buildFormatSelection(),
            const SizedBox(height: 24),

            // Date Range Selection
            _buildDateRangeSelection(),
            const SizedBox(height: 24),

            // Export Button
            _buildExportButton(exportState, exportController),
            const SizedBox(height: 16),

            // Progress/Status
            if (exportState.isExporting) _buildProgressIndicator(exportState),
            if (exportState.error != null) _buildErrorMessage(exportState, exportController),
            if (exportState.lastExportedFile != null && !exportState.isExporting)
              _buildSuccessCard(exportState, exportController),

            const SizedBox(height: 24),

            // Info Section
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Format',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...ExportFormat.values.map((format) {
              return RadioListTile<ExportFormat>(
                title: Text(format.displayName),
                subtitle: Text(format.description),
                value: format,
                groupValue: _selectedFormat,
                onChanged: (value) {
                  setState(() {
                    _selectedFormat = value!;
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Range (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectStartDate(context),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _startDate != null
                          ? _dateFormat.format(_startDate!)
                          : 'Start Date',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectEndDate(context),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _endDate != null
                          ? _dateFormat.format(_endDate!)
                          : 'End Date',
                    ),
                  ),
                ),
              ],
            ),
            if (_startDate != null || _endDate != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Date Range'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(ExportState state, ExportController controller) {
    return ElevatedButton.icon(
      onPressed: state.isExporting ? null : () => _handleExport(controller),
      icon: state.isExporting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.file_download),
      label: Text(state.isExporting ? 'Exporting...' : 'Export'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildProgressIndicator(ExportState state) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (state.progress?.percentage != null)
              LinearProgressIndicator(value: state.progress!.percentage),
            if (state.progress?.percentage == null)
              const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              state.progress?.message ?? 'Exporting...',
              style: TextStyle(color: Colors.blue.shade900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(ExportState state, ExportController controller) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade900),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.error!,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: controller.clearError,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard(ExportState state, ExportController controller) {
    final file = state.lastExportedFile!;
    final fileName = file.path.split('/').last;
    final fileSize = _getFileSize(file);

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Successful',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                      Text(
                        fileName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        fileSize,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => controller.shareLastExport(
                      subject: 'FinSight Export - ${_dateFormat.format(DateTime.now())}',
                      text: 'Here is your expense report from FinSight.',
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleExport(controller),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Export Again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Export Information',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              'PDF Reports',
              'Includes expense summary, category breakdown, and detailed lists. Detailed version includes budget analysis.',
            ),
            const Divider(),
            _buildInfoItem(
              'CSV Files',
              'Comma-separated values for easy import to spreadsheets. Detailed version includes additional columns.',
            ),
            const Divider(),
            _buildInfoItem(
              'Date Range',
              'If no date range is selected, all expenses will be exported.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
        if (_endDate != null && date.isAfter(_endDate!)) {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _handleExport(ExportController controller) async {
    // Refresh expenses data to get latest
    ref.invalidate(allExpensesProvider);
    final allExpensesAsync = ref.read(allExpensesProvider);
    
    allExpensesAsync.when(
      data: (expenses) async {
        var filteredExpenses = expenses;

        // Apply date filter if set
        if (_startDate != null || _endDate != null) {
          filteredExpenses = expenses.where((expense) {
            if (_startDate != null && expense.date.isBefore(_startDate!)) {
              return false;
            }
            if (_endDate != null && expense.date.isAfter(_endDate!)) {
              return false;
            }
            return true;
          }).toList();
        }

        if (filteredExpenses.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No expenses found for the selected date range'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Export based on selected format
        File? exportedFile;
        
        switch (_selectedFormat) {
          case ExportFormat.pdf:
            exportedFile = await controller.exportToPDF(
              expenses: filteredExpenses,
              title: 'Expense Report',
              startDate: _startDate,
              endDate: _endDate,
            );
            break;

          case ExportFormat.detailedPdf:
            final budgetsAsync = ref.read(allBudgetsProvider);
            final budgets = budgetsAsync.maybeWhen(
              data: (budgets) => budgets,
              orElse: () => <Budget>[],
            );
            
            exportedFile = await controller.exportToDetailedPDF(
              expenses: filteredExpenses,
              budgets: budgets.isNotEmpty ? budgets : null,
              title: 'Detailed Expense Report',
              startDate: _startDate,
              endDate: _endDate,
            );
            break;

          case ExportFormat.csv:
            exportedFile = await controller.exportToCSV(
              expenses: filteredExpenses,
            );
            break;

          case ExportFormat.detailedCsv:
            exportedFile = await controller.exportToDetailedCSV(
              expenses: filteredExpenses,
            );
            break;
        }

        if (exportedFile != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export successful: ${_selectedFormat.displayName}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),  // Auto-close after 3 seconds
              action: exportedFile != null ? SnackBarAction(
                label: 'Share',
                textColor: Colors.white,
                onPressed: () => controller.shareFile(exportedFile!),
              ) : SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading expenses...')),
        );
      },
      error: (error, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  void _showExportHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExportHistoryPage(),
      ),
    );
  }

  String _getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Export History Page - Shows all previously exported files
class ExportHistoryPage extends ConsumerWidget {
  const ExportHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportedFilesAsync = ref.watch(exportedFilesProvider);
    final exportController = ref.read(exportStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _confirmClearAll(context, exportController, ref),
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: exportedFilesAsync.when(
        data: (files) {
          if (files.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No exports yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return _buildFileItem(context, file, exportController, ref);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading files: $error'),
        ),
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    File file,
    ExportController controller,
    WidgetRef ref,
  ) {
    final fileName = file.path.split('/').last;
    final isPdf = fileName.endsWith('.pdf');
    final fileSize = _getFileSize(file);
    final lastModified = file.lastModifiedSync();
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isPdf ? Icons.picture_as_pdf : Icons.table_chart,
          color: isPdf ? Colors.red : Colors.green,
          size: 40,
        ),
        title: Text(fileName),
        subtitle: Text(
          '${dateFormat.format(lastModified)} • $fileSize',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'share') {
              controller.shareFile(file);
            } else if (value == 'delete') {
              _confirmDelete(context, file, controller, ref);
            }
          },
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    File file,
    ExportController controller,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Export'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await controller.deleteFile(file);
              ref.invalidate(exportedFilesProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(
    BuildContext context,
    ExportController controller,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Exports'),
        content: const Text('Are you sure you want to delete all exported files?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await controller.clearAllExports();
              ref.invalidate(exportedFilesProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All files deleted')),
                );
              }
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
