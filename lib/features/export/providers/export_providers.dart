import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/export_service.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/budget.dart';
import '../../../services/share_helper.dart';

// Export Service Provider
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

// Export State Provider
final exportStateProvider = StateNotifierProvider<ExportController, ExportState>((ref) {
  final exportService = ref.watch(exportServiceProvider);
  return ExportController(exportService);
});

// Export Format Provider
final exportFormatProvider = StateProvider<ExportFormat>((ref) {
  return ExportFormat.pdf;
});

// Date Range Provider for exports
final exportDateRangeProvider = StateProvider<DateRange?>((ref) {
  return null;
});

// Exported Files Provider
final exportedFilesProvider = FutureProvider<List<File>>((ref) async {
  final exportService = ref.watch(exportServiceProvider);
  return await exportService.getExportedFiles();
});

// Export State
class ExportState {
  final bool isExporting;
  final File? lastExportedFile;
  final String? error;
  final ExportProgress? progress;

  const ExportState({
    this.isExporting = false,
    this.lastExportedFile,
    this.error,
    this.progress,
  });

  ExportState copyWith({
    bool? isExporting,
    File? lastExportedFile,
    String? error,
    ExportProgress? progress,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      lastExportedFile: lastExportedFile ?? this.lastExportedFile,
      error: error,
      progress: progress,
    );
  }

  ExportState clearError() {
    return ExportState(
      isExporting: isExporting,
      lastExportedFile: lastExportedFile,
    );
  }
}

// Export Progress
class ExportProgress {
  final String message;
  final double? percentage;

  const ExportProgress(this.message, [this.percentage]);
}

// Export Format
enum ExportFormat {
  pdf,
  csv,
  detailedPdf,
  detailedCsv,
}

// Date Range
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  const DateRange(this.startDate, this.endDate);

  @override
  String toString() {
    return '${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}';
  }
}

// Export Controller
class ExportController extends StateNotifier<ExportState> {
  final ExportService _exportService;

  ExportController(this._exportService) : super(const ExportState());

  /// Export expenses to PDF
  Future<File?> exportToPDF({
    required List<Expense> expenses,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(
      isExporting: true,
      progress: const ExportProgress('Generating PDF...', 0.0),
    );

    try {
      final file = await _exportService.generatePDFReport(
        expenses: expenses,
        title: title,
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(
        isExporting: false,
        lastExportedFile: file,
        progress: const ExportProgress('PDF generated successfully', 1.0),
      );

      return file;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: 'Failed to generate PDF: $e',
      );
      return null;
    }
  }

  /// Export expenses to detailed PDF with budgets
  Future<File?> exportToDetailedPDF({
    required List<Expense> expenses,
    List<Budget>? budgets,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(
      isExporting: true,
      progress: const ExportProgress('Generating detailed PDF...', 0.0),
    );

    try {
      final file = await _exportService.generateDetailedPDFReport(
        expenses: expenses,
        budgets: budgets,
        title: title,
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(
        isExporting: false,
        lastExportedFile: file,
        progress: const ExportProgress('Detailed PDF generated successfully', 1.0),
      );

      return file;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: 'Failed to generate detailed PDF: $e',
      );
      return null;
    }
  }

  /// Export expenses to CSV
  Future<File?> exportToCSV({
    required List<Expense> expenses,
    String? fileName,
  }) async {
    state = state.copyWith(
      isExporting: true,
      progress: const ExportProgress('Generating CSV...', 0.0),
    );

    try {
      final file = await _exportService.generateCSV(
        expenses: expenses,
        fileName: fileName,
      );

      state = state.copyWith(
        isExporting: false,
        lastExportedFile: file,
        progress: const ExportProgress('CSV generated successfully', 1.0),
      );

      return file;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: 'Failed to generate CSV: $e',
      );
      return null;
    }
  }

  /// Export expenses to detailed CSV
  Future<File?> exportToDetailedCSV({
    required List<Expense> expenses,
    String? fileName,
  }) async {
    state = state.copyWith(
      isExporting: true,
      progress: const ExportProgress('Generating detailed CSV...', 0.0),
    );

    try {
      final file = await _exportService.generateDetailedCSV(
        expenses: expenses,
        fileName: fileName,
      );

      state = state.copyWith(
        isExporting: false,
        lastExportedFile: file,
        progress: const ExportProgress('Detailed CSV generated successfully', 1.0),
      );

      return file;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: 'Failed to generate detailed CSV: $e',
      );
      return null;
    }
  }

  /// Export budgets to CSV
  Future<File?> exportBudgetsToCSV({
    required List<Budget> budgets,
    Map<String, double>? actualSpending,
    String? fileName,
  }) async {
    state = state.copyWith(
      isExporting: true,
      progress: const ExportProgress('Generating budget CSV...', 0.0),
    );

    try {
      final file = await _exportService.generateBudgetCSV(
        budgets: budgets,
        actualSpending: actualSpending,
        fileName: fileName,
      );

      state = state.copyWith(
        isExporting: false,
        lastExportedFile: file,
        progress: const ExportProgress('Budget CSV generated successfully', 1.0),
      );

      return file;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: 'Failed to generate budget CSV: $e',
      );
      return null;
    }
  }

  /// Share the last exported file
  Future<bool> shareLastExport({
    String? subject,
    String? text,
  }) async {
    if (state.lastExportedFile == null) {
      state = state.copyWith(error: 'No file to share');
      return false;
    }

    try {
      await ShareHelper.shareFile(
        file: state.lastExportedFile!,
        subject: subject ?? 'FinSight Export',
        text: text ?? 'Here is your exported file from FinSight',
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to share file: $e');
      return false;
    }
  }

  /// Share a specific file
  Future<bool> shareFile(
    File file, {
    String? subject,
    String? text,
  }) async {
    try {
      await ShareHelper.shareFile(
        file: file,
        subject: subject ?? 'FinSight Export',
        text: text ?? 'Here is your exported file from FinSight',
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to share file: $e');
      return false;
    }
  }

  /// Delete exported file
  Future<void> deleteFile(File file) async {
    try {
      await _exportService.deleteExportedFile(file);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete file: $e');
    }
  }

  /// Clear all exported files
  Future<void> clearAllExports() async {
    try {
      await _exportService.clearAllExports();
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear exports: $e');
    }
  }

  /// Clear error state
  void clearError() {
    state = state.clearError();
  }
}

/// Extension methods for ExportFormat
extension ExportFormatExtension on ExportFormat {
  String get displayName {
    switch (this) {
      case ExportFormat.pdf:
        return 'PDF Report';
      case ExportFormat.csv:
        return 'CSV File';
      case ExportFormat.detailedPdf:
        return 'Detailed PDF Report';
      case ExportFormat.detailedCsv:
        return 'Detailed CSV File';
    }
  }

  String get description {
    switch (this) {
      case ExportFormat.pdf:
        return 'Standard PDF with expense summary and list';
      case ExportFormat.csv:
        return 'Simple CSV with basic expense data';
      case ExportFormat.detailedPdf:
        return 'Comprehensive PDF with budget analysis';
      case ExportFormat.detailedCsv:
        return 'Extended CSV with additional columns';
    }
  }

  String get fileExtension {
    switch (this) {
      case ExportFormat.pdf:
      case ExportFormat.detailedPdf:
        return '.pdf';
      case ExportFormat.csv:
      case ExportFormat.detailedCsv:
        return '.csv';
    }
  }
}
