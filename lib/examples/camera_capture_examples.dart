/// DEMO: Camera Capture Module Usage Examples

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/receipt/providers/receipt_capture_provider.dart';

// ============================================================
// EXAMPLE 1: Basic Camera Capture
// ============================================================

class BasicCaptureExample extends ConsumerWidget {
  const BasicCaptureExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // Trigger camera capture
        await ref.read(receiptCaptureProvider.notifier).captureFromCamera();
        
        // Get the captured image path
        final imagePath = ref.read(receiptCaptureProvider).imagePath;
        
        if (imagePath != null) {
          debugPrint('Image captured: $imagePath');
        }
      },
      child: const Text('Capture Receipt'),
    );
  }
}

// ============================================================
// EXAMPLE 2: Gallery Picker
// ============================================================

class GalleryPickerExample extends ConsumerWidget {
  const GalleryPickerExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // Open gallery picker
        await ref.read(receiptCaptureProvider.notifier).pickFromGallery();
        
        // Check state
        final captureState = ref.read(receiptCaptureProvider);
        
        if (captureState.hasImage) {
          debugPrint('Image selected: ${captureState.imagePath}');
        }
      },
      child: const Text('Pick from Gallery'),
    );
  }
}

// ============================================================
// EXAMPLE 3: Complete Flow with State Handling
// ============================================================

class CompleteFlowExample extends ConsumerWidget {
  const CompleteFlowExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captureState = ref.watch(receiptCaptureProvider);

    // Listen for state changes
    ref.listen(receiptCaptureProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Error occurred')),
        );
      }
      
      if (next.isCaptured) {
        debugPrint('Image captured successfully!');
      }
    });

    return Column(
      children: [
        // Show different UI based on state
        if (captureState.isCapturing)
          const CircularProgressIndicator()
        else if (captureState.hasImage)
          Image.file(captureState.imagePath as File)
        else
          const Text('No image captured yet'),

        // Action buttons
        Row(
          children: [
            ElevatedButton(
              onPressed: () async {
                await ref.read(receiptCaptureProvider.notifier).captureFromCamera();
              },
              child: const Text('Camera'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref.read(receiptCaptureProvider.notifier).pickFromGallery();
              },
              child: const Text('Gallery'),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// EXAMPLE 4: With Navigation
// ============================================================

class NavigationExample extends ConsumerWidget {
  const NavigationExample({super.key});

  Future<void> _captureAndProcess(BuildContext context, WidgetRef ref) async {
    // Capture image
    await ref.read(receiptCaptureProvider.notifier).captureFromCamera();
    
    final captureState = ref.read(receiptCaptureProvider);
    
    if (captureState.hasImage) {
      // Navigate to processing screen with image path
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => ProcessingScreen(
      //       imagePath: captureState.imagePath!,
      //     ),
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _captureAndProcess(context, ref),
      child: const Text('Capture & Process'),
    );
  }
}

// ============================================================
// EXAMPLE 5: Custom Image Handling
// ============================================================

class CustomHandlingExample extends ConsumerWidget {
  const CustomHandlingExample({super.key});

  Future<void> _handleImageCapture(WidgetRef ref) async {
    final captureNotifier = ref.read(receiptCaptureProvider.notifier);
    
    // Capture from camera
    await captureNotifier.captureFromCamera();
    
    // Get File object
    final imageFile = captureNotifier.getImageFile();
    
    if (imageFile != null) {
      // Do something with the file
      final fileSize = await imageFile.length();
      debugPrint('Image size: $fileSize bytes');
      
      // Get image path for storage
      final imagePath = captureNotifier.confirmAndGetPath();
      
      if (imagePath != null) {
        // Save to database or upload to server
        debugPrint('Saving image: $imagePath');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _handleImageCapture(ref),
      child: const Text('Custom Handling'),
    );
  }
}

// ============================================================
// EXAMPLE 6: Retake Functionality
// ============================================================

class RetakeExample extends ConsumerWidget {
  const RetakeExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captureState = ref.watch(receiptCaptureProvider);

    return Column(
      children: [
        if (captureState.hasImage) ...[
          // Show preview
          Image.file(File(captureState.imagePath!)),
          
          // Retake button
          ElevatedButton.icon(
            onPressed: () async {
              // Delete current and reset
              await ref.read(receiptCaptureProvider.notifier).retakeImage();
              
              // Capture new image
              await ref.read(receiptCaptureProvider.notifier).captureFromCamera();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retake'),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// EXAMPLE 7: State Validation
// ============================================================

class ValidationExample extends ConsumerWidget {
  const ValidationExample({super.key});

  bool _validateCapture(ReceiptCaptureState state) {
    // Check if image is captured
    if (!state.hasImage) {
      return false;
    }
    
    // Check if file exists
    final file = File(state.imagePath!);
    if (!file.existsSync()) {
      return false;
    }
    
    // Check file size (optional)
    final fileSize = file.lengthSync();
    if (fileSize == 0) {
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captureState = ref.watch(receiptCaptureProvider);

    return ElevatedButton(
      onPressed: _validateCapture(captureState)
          ? () {
              // Process valid image
              debugPrint('Valid image: ${captureState.imagePath}');
            }
          : null,
      child: const Text('Process Image'),
    );
  }
}

// ============================================================
// EXAMPLE 8: Integration with Expense Form
// ============================================================

class ExpenseFormIntegrationExample extends ConsumerStatefulWidget {
  const ExpenseFormIntegrationExample({super.key});

  @override
  ConsumerState<ExpenseFormIntegrationExample> createState() =>
      _ExpenseFormIntegrationExampleState();
}

class _ExpenseFormIntegrationExampleState
    extends ConsumerState<ExpenseFormIntegrationExample> {
  String? _capturedImagePath;

  Future<void> _captureReceipt() async {
    // Capture image
    await ref.read(receiptCaptureProvider.notifier).captureFromCamera();
    
    final imagePath = ref.read(receiptCaptureProvider.notifier).confirmAndGetPath();
    
    if (imagePath != null) {
      setState(() {
        _capturedImagePath = imagePath;
      });
      
      // TODO: Process with OCR
      // final ocrData = await processWithOCR(imagePath);
      
      // TODO: Pre-fill expense form
      // ref.read(expenseFormProvider.notifier).setAmount(ocrData.amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_capturedImagePath != null) ...[
          Text('Receipt captured!'),
          Image.file(File(_capturedImagePath!), height: 200),
        ],
        
        ElevatedButton(
          onPressed: _captureReceipt,
          child: const Text('Capture Receipt for Expense'),
        ),
      ],
    );
  }
}

// ============================================================
// EXAMPLE 9: Multiple Images (Future Enhancement)
// ============================================================

class MultipleImagesExample extends ConsumerStatefulWidget {
  const MultipleImagesExample({super.key});

  @override
  ConsumerState<MultipleImagesExample> createState() =>
      _MultipleImagesExampleState();
}

class _MultipleImagesExampleState
    extends ConsumerState<MultipleImagesExample> {
  final List<String> _capturedImages = [];

  Future<void> _captureMultiple() async {
    // Capture image
    await ref.read(receiptCaptureProvider.notifier).captureFromCamera();
    
    final imagePath = ref.read(receiptCaptureProvider.notifier).confirmAndGetPath();
    
    if (imagePath != null) {
      setState(() {
        _capturedImages.add(imagePath);
      });
      
      // Reset for next capture
      ref.read(receiptCaptureProvider.notifier).reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Captured ${_capturedImages.length} images'),
        
        ListView.builder(
          shrinkWrap: true,
          itemCount: _capturedImages.length,
          itemBuilder: (context, index) {
            return Image.file(File(_capturedImages[index]), height: 100);
          },
        ),
        
        ElevatedButton(
          onPressed: _captureMultiple,
          child: const Text('Add Another Receipt'),
        ),
      ],
    );
  }
}

// ============================================================
// EXAMPLE 10: Error Recovery
// ============================================================

class ErrorRecoveryExample extends ConsumerWidget {
  const ErrorRecoveryExample({super.key});

  Future<void> _captureWithRetry(
    BuildContext context,
    WidgetRef ref, {
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        await ref.read(receiptCaptureProvider.notifier).captureFromCamera();
        
        final captureState = ref.read(receiptCaptureProvider);
        
        if (captureState.hasImage) {
          debugPrint('Successfully captured on attempt ${attempts + 1}');
          return;
        }
        
        if (captureState.hasError) {
          attempts++;
          if (attempts < maxRetries) {
            // Show retry dialog
            final retry = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Capture Failed'),
                content: Text(
                  'Failed to capture image. Try again?\n'
                  'Attempt ${attempts + 1} of $maxRetries',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
            
            if (retry != true) break;
            
            // Clear error before retry
            ref.read(receiptCaptureProvider.notifier).clearError();
          }
        } else {
          // User cancelled
          break;
        }
      } catch (e) {
        debugPrint('Error on attempt ${attempts + 1}: $e');
        attempts++;
      }
    }
    
    if (attempts >= maxRetries) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed after multiple attempts')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _captureWithRetry(context, ref),
      child: const Text('Capture with Retry'),
    );
  }
}
