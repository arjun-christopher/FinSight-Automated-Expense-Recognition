import 'dart:io';
import 'package:share_plus/share_plus.dart';

/// Helper class for sharing files
/// 
/// Provides methods to share files with other apps using the
/// platform's native sharing functionality.
/// 
/// Usage:
/// ```dart
/// await ShareHelper.shareFile(
///   file: pdfFile,
///   subject: 'Expense Report',
///   text: 'Here is your expense report for January',
/// );
/// ```
class ShareHelper {
  /// Share a single file
  /// 
  /// [file] - The file to share
  /// [subject] - Optional subject for the share (used in email, etc.)
  /// [text] - Optional message to accompany the file
  static Future<ShareResult> shareFile({
    required File file,
    String? subject,
    String? text,
  }) async {
    final xFile = XFile(file.path);
    
    final result = await Share.shareXFiles(
      [xFile],
      subject: subject,
      text: text,
    );
    
    return result;
  }

  /// Share multiple files
  /// 
  /// [files] - List of files to share
  /// [subject] - Optional subject for the share
  /// [text] - Optional message to accompany the files
  static Future<ShareResult> shareFiles({
    required List<File> files,
    String? subject,
    String? text,
  }) async {
    final xFiles = files.map((file) => XFile(file.path)).toList();
    
    final result = await Share.shareXFiles(
      xFiles,
      subject: subject,
      text: text,
    );
    
    return result;
  }

  /// Share text only (no file)
  static Future<ShareResult> shareText(String text, {String? subject}) async {
    return await Share.share(text, subject: subject);
  }

  /// Get file name from path
  static String getFileName(File file) {
    return file.path.split('/').last;
  }

  /// Get file extension
  static String getFileExtension(File file) {
    final name = getFileName(file);
    return name.contains('.') ? name.split('.').last : '';
  }

  /// Check if share is available on platform
  static bool isShareAvailable() {
    // share_plus is available on all platforms
    return true;
  }
}
