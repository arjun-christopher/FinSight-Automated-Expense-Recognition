import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/receipt_capture_provider.dart';
import '../../widgets/receipt_capture_widgets.dart';
import '../../../../services/ocr_workflow_service.dart';

class ReceiptCapturePage extends ConsumerStatefulWidget {
  const ReceiptCapturePage({super.key});

  @override
  ConsumerState<ReceiptCapturePage> createState() => _ReceiptCapturePageState();
}

class _ReceiptCapturePageState extends ConsumerState<ReceiptCapturePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleCameraCapture() async {
    await ref.read(receiptCaptureProvider.notifier).captureFromCamera();
  }

  Future<void> _handleGalleryPick() async {
    await ref.read(receiptCaptureProvider.notifier).pickFromGallery();
  }

  Future<void> _handleRetake() async {
    await ref.read(receiptCaptureProvider.notifier).retakeImage();
  }

  Future<void> _handleConfirm() async {
    final imagePath = ref.read(receiptCaptureProvider.notifier).confirmAndGetPath();
    
    if (imagePath == null) return;

    // Show processing dialog
    if (!mounted) return;
    final dialogContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ProcessingDialog(),
    );

    try {
      // Create workflow service
      final workflow = OcrWorkflowFactory.createMockWorkflow();

      // Process receipt with aggressive timeout (20 seconds max)
      final stopwatch = Stopwatch()..start();
      final result = await workflow.processReceipt(
        imagePath: imagePath,
        useClassifier: true,
        onStepComplete: (step) {
          debugPrint('✓ Completed: ${step.name} [${stopwatch.elapsedMilliseconds}ms]');
        },
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint('❌ Timeout after ${stopwatch.elapsedMilliseconds}ms');
          throw Exception('Processing timed out after 20 seconds. Please try with a clearer, well-lit receipt image.');
        },
      );

      if (!mounted) return;
      
      // Close processing dialog
      Navigator.of(dialogContext).pop();

      if (result.success) {
        // Navigate to confirmation screen
        context.push('/expense-confirmation', extra: result);
        
        // Reset capture state
        ref.read(receiptCaptureProvider.notifier).reset();
      } else {
        // Show error
        _showErrorSnackbar('Processing failed: ${result.errorMessage ?? "Unknown error"}');
      }
    } catch (e) {
      if (!mounted) return;
      
      // Close processing dialog
      Navigator.of(dialogContext).pop();
      
      // Show error with helpful message
      final errorMessage = e.toString().contains('timed out')
          ? e.toString()
          : 'Error processing receipt: ${e.toString().replaceAll("Exception: ", "")}';
      _showErrorSnackbar(errorMessage);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final captureState = ref.watch(receiptCaptureProvider);

    // Listen for errors
    ref.listen(receiptCaptureProvider, (previous, next) {
      if (next.hasError && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(next.errorMessage!)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ref.read(receiptCaptureProvider.notifier).clearError();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        elevation: 0,
        actions: captureState.hasImage
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _handleRetake,
                  tooltip: 'Discard',
                ),
              ]
            : null,
      ),
      body: Stack(
        children: [
          // Main content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildContent(context, captureState),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (captureState.isCapturing)
            const LoadingOverlay(message: 'Opening...'),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReceiptCaptureState captureState) {
    if (captureState.hasImage) {
      // Show preview
      return ReceiptImagePreview(
        imagePath: captureState.imagePath!,
        onRetake: _handleRetake,
        onConfirm: _handleConfirm,
      );
    }

    // Show capture options
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: EmptyStateWidget(
              icon: Icons.camera_alt_outlined,
              title: 'Capture Receipt',
              subtitle:
                  'Take a photo of your receipt or choose from gallery to get started',
            ),
          ),
          const SizedBox(height: 24),
          CaptureButton(
            icon: Icons.camera_alt,
            label: 'Take Photo',
            onPressed: _handleCameraCapture,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          CaptureButton(
            icon: Icons.photo_library,
            label: 'Choose from Gallery',
            onPressed: _handleGalleryPick,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for faster processing:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...[
                    'Ensure good lighting',
                    'Hold camera steady',
                    'Capture full receipt in frame',
                    'Avoid blurry or skewed images',
                  ].map((tip) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                            ),
                            Expanded(
                              child: Text(
                                tip,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
