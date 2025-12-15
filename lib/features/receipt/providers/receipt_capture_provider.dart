import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

enum ImageSourceType { camera, gallery }

enum CaptureState { idle, capturing, captured, error }

class ReceiptCaptureState {
  final String? imagePath;
  final CaptureState state;
  final String? errorMessage;
  final ImageSourceType? sourceType;

  ReceiptCaptureState({
    this.imagePath,
    this.state = CaptureState.idle,
    this.errorMessage,
    this.sourceType,
  });

  ReceiptCaptureState copyWith({
    String? imagePath,
    CaptureState? state,
    String? errorMessage,
    ImageSourceType? sourceType,
  }) {
    return ReceiptCaptureState(
      imagePath: imagePath ?? this.imagePath,
      state: state ?? this.state,
      errorMessage: errorMessage,
      sourceType: sourceType ?? this.sourceType,
    );
  }

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get isCapturing => state == CaptureState.capturing;
  bool get isCaptured => state == CaptureState.captured;
  bool get hasError => state == CaptureState.error;
}

class ReceiptCaptureNotifier extends StateNotifier<ReceiptCaptureState> {
  final ImagePicker _picker = ImagePicker();

  ReceiptCaptureNotifier() : super(ReceiptCaptureState());

  Future<void> captureFromCamera() async {
    state = state.copyWith(
      state: CaptureState.capturing,
      errorMessage: null,
    );

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Good balance between quality and file size
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo != null) {
        // Save to app directory
        final savedPath = await _saveImage(photo.path);
        
        state = state.copyWith(
          imagePath: savedPath,
          state: CaptureState.captured,
          sourceType: ImageSourceType.camera,
        );
      } else {
        // User cancelled
        state = state.copyWith(
          state: CaptureState.idle,
        );
      }
    } catch (e) {
      state = state.copyWith(
        state: CaptureState.error,
        errorMessage: 'Failed to capture image: $e',
      );
    }
  }

  Future<void> pickFromGallery() async {
    state = state.copyWith(
      state: CaptureState.capturing,
      errorMessage: null,
    );

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        // Save to app directory
        final savedPath = await _saveImage(image.path);
        
        state = state.copyWith(
          imagePath: savedPath,
          state: CaptureState.captured,
          sourceType: ImageSourceType.gallery,
        );
      } else {
        // User cancelled
        state = state.copyWith(
          state: CaptureState.idle,
        );
      }
    } catch (e) {
      state = state.copyWith(
        state: CaptureState.error,
        errorMessage: 'Failed to pick image: $e',
      );
    }
  }

  Future<String> _saveImage(String sourcePath) async {
    try {
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${directory.path}/receipts');
      
      // Create receipts directory if it doesn't exist
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(sourcePath);
      final fileName = 'receipt_$timestamp$extension';
      final destinationPath = '${receiptsDir.path}/$fileName';

      // Copy file to app directory
      final sourceFile = File(sourcePath);
      await sourceFile.copy(destinationPath);

      return destinationPath;
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  Future<void> retakeImage() async {
    // Delete previous image if exists
    if (state.imagePath != null) {
      try {
        final file = File(state.imagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Failed to delete previous image: $e');
      }
    }

    // Reset state
    state = ReceiptCaptureState();
  }

  void clearError() {
    state = state.copyWith(
      state: CaptureState.idle,
      errorMessage: null,
    );
  }

  void reset() {
    state = ReceiptCaptureState();
  }

  String? confirmAndGetPath() {
    if (state.hasImage) {
      return state.imagePath;
    }
    return null;
  }

  // Get image file
  File? getImageFile() {
    if (state.imagePath != null) {
      return File(state.imagePath!);
    }
    return null;
  }
}

// Provider for receipt capture
final receiptCaptureProvider =
    StateNotifierProvider.autoDispose<ReceiptCaptureNotifier, ReceiptCaptureState>(
  (ref) => ReceiptCaptureNotifier(),
);
