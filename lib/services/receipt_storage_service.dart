import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for managing receipt image storage in local file system
class ReceiptStorageService {
  static const String _receiptsFolderName = 'receipts';

  /// Get the receipts directory, creating it if it doesn't exist
  Future<Directory> _getReceiptsDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(path.join(appDocDir.path, _receiptsFolderName));
    
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    
    return receiptsDir;
  }

  /// Save a receipt image file and return the saved file path
  /// 
  /// [sourceFile] - The source image file to save
  /// [customFileName] - Optional custom file name (without extension)
  /// 
  /// Returns the absolute path of the saved file
  Future<String> saveReceiptImage(File sourceFile, {String? customFileName}) async {
    try {
      final receiptsDir = await _getReceiptsDirectory();
      final extension = path.extension(sourceFile.path);
      final fileName = customFileName != null 
          ? '$customFileName$extension'
          : '${DateTime.now().millisecondsSinceEpoch}$extension';
      
      final savedPath = path.join(receiptsDir.path, fileName);
      final savedFile = await sourceFile.copy(savedPath);
      
      return savedFile.path;
    } catch (e) {
      throw Exception('Failed to save receipt image: $e');
    }
  }

  /// Save image from bytes
  /// 
  /// [imageBytes] - The image data as bytes
  /// [fileName] - The file name (with extension)
  /// 
  /// Returns the absolute path of the saved file
  Future<String> saveReceiptImageFromBytes(List<int> imageBytes, String fileName) async {
    try {
      final receiptsDir = await _getReceiptsDirectory();
      final savedPath = path.join(receiptsDir.path, fileName);
      final file = File(savedPath);
      
      await file.writeAsBytes(imageBytes);
      
      return savedPath;
    } catch (e) {
      throw Exception('Failed to save receipt image from bytes: $e');
    }
  }

  /// Delete a receipt image file
  /// 
  /// [filePath] - The absolute path of the file to delete
  /// 
  /// Returns true if the file was successfully deleted
  Future<bool> deleteReceiptImage(String filePath) async {
    try {
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      
      return false;
    } catch (e) {
      throw Exception('Failed to delete receipt image: $e');
    }
  }

  /// Check if a receipt image file exists
  /// 
  /// [filePath] - The absolute path of the file to check
  /// 
  /// Returns true if the file exists
  Future<bool> receiptImageExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get the File object for a receipt image
  /// 
  /// [filePath] - The absolute path of the receipt image
  /// 
  /// Returns the File object or null if the file doesn't exist
  Future<File?> getReceiptImageFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (await file.exists()) {
        return file;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get the size of a receipt image file in bytes
  /// 
  /// [filePath] - The absolute path of the file
  /// 
  /// Returns the file size in bytes, or 0 if the file doesn't exist
  Future<int> getReceiptImageSize(String filePath) async {
    try {
      final file = File(filePath);
      
      if (await file.exists()) {
        return await file.length();
      }
      
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Delete all receipt images (use with caution!)
  /// 
  /// Returns the number of files deleted
  Future<int> deleteAllReceiptImages() async {
    try {
      final receiptsDir = await _getReceiptsDirectory();
      int deletedCount = 0;
      
      if (await receiptsDir.exists()) {
        final files = receiptsDir.listSync();
        
        for (final file in files) {
          if (file is File) {
            await file.delete();
            deletedCount++;
          }
        }
      }
      
      return deletedCount;
    } catch (e) {
      throw Exception('Failed to delete all receipt images: $e');
    }
  }

  /// Get the total storage size used by receipt images in bytes
  /// 
  /// Returns the total size in bytes
  Future<int> getTotalStorageUsed() async {
    try {
      final receiptsDir = await _getReceiptsDirectory();
      int totalSize = 0;
      
      if (await receiptsDir.exists()) {
        final files = receiptsDir.listSync();
        
        for (final file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Generate a unique file name for a receipt
  /// 
  /// [prefix] - Optional prefix for the file name
  /// [extension] - File extension (default: .jpg)
  /// 
  /// Returns a unique file name
  String generateUniqueFileName({String prefix = 'receipt', String extension = '.jpg'}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp$extension';
  }

  /// Get the receipts directory path
  /// 
  /// Returns the absolute path of the receipts directory
  Future<String> getReceiptsDirectoryPath() async {
    final receiptsDir = await _getReceiptsDirectory();
    return receiptsDir.path;
  }

  /// Clean up orphaned receipt files (files that are not in the database)
  /// 
  /// [validFilePaths] - List of file paths that should be kept
  /// 
  /// Returns the number of orphaned files deleted
  Future<int> cleanupOrphanedFiles(List<String> validFilePaths) async {
    try {
      final receiptsDir = await _getReceiptsDirectory();
      int deletedCount = 0;
      
      if (await receiptsDir.exists()) {
        final files = receiptsDir.listSync();
        
        for (final file in files) {
          if (file is File && !validFilePaths.contains(file.path)) {
            await file.delete();
            deletedCount++;
          }
        }
      }
      
      return deletedCount;
    } catch (e) {
      throw Exception('Failed to cleanup orphaned files: $e');
    }
  }
}
