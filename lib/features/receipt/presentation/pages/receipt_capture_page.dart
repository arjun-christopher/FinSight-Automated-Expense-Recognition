import 'dart:async';
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

    debugPrint('\n' + '='*70);
    debugPrint('📸 STARTING RECEIPT PROCESSING');
    debugPrint('Image: $imagePath');
    debugPrint('Time: ${DateTime.now()}');
    debugPrint('='*70 + '\n');

    // Show processing dialog
    if (!mounted) return;
    
    // Store dialog context for reliable closing
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) {
        dialogContext = ctx;
        return const ProcessingDialog();
      },
    );

    final completer = Completer<void>();
    bool dialogDismissed = false;
    Timer? hardTimeoutTimer;
    
    void safeCloseDialog([String reason = 'normal']) {
      if (!dialogDismissed) {
        dialogDismissed = true;
        debugPrint('🔄 Closing dialog ($reason)');
        
        try {
          // Use stored dialog context for reliable closing
          if (dialogContext != null && dialogContext!.mounted) {
            Navigator.of(dialogContext!).pop();
            debugPrint('✅ Dialog closed via dialogContext');
          } else if (mounted) {
            // Fallback to main context
            Navigator.of(context).pop();
            debugPrint('✅ Dialog closed via main context');
          }
        } catch (e) {
          debugPrint('⚠️ Error closing dialog: $e');
        }
      }
    }
    
    // ABSOLUTE GUARANTEE: Dialog WILL close after 40 seconds
    hardTimeoutTimer = Timer(const Duration(seconds: 40), () {
      if (!completer.isCompleted) {
        debugPrint('\n' + '🚨'*35);
        debugPrint('🚨 ABSOLUTE TIMEOUT: 40 seconds elapsed - FORCE CLOSING');
        debugPrint('🚨'*35 + '\n');
        safeCloseDialog('hard-timeout');
        if (mounted) {
          _showErrorSnackbar('Something is blocking the workflow. Check logs.');
        }
        if (!completer.isCompleted) completer.complete();
      }
    });

    try {
      debugPrint('🏭 Creating workflow...');
      final workflow = OcrWorkflowFactory.createProductionWorkflow();
      debugPrint('✓ Workflow created');

      final stopwatch = Stopwatch()..start();
      int stepCount = 0;
      
      debugPrint('\n🏁 Starting processReceipt()...');
      final processFuture = workflow.processReceipt(
        imagePath: imagePath,
        useClassifier: true,
        onStepComplete: (step) {
          stepCount++;
          debugPrint('👉 Step $stepCount: ${step.name} [${stopwatch.elapsedMilliseconds}ms]');
        },
      );
      
      debugPrint('⏳ Awaiting result with 35s timeout (Cloud OCR)...');
      final result = await processFuture.timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          debugPrint('⏱️ Timeout after ${stopwatch.elapsedMilliseconds}ms');
          throw TimeoutException('Processing exceeded 35 seconds');
        },
      );

      stopwatch.stop();
      hardTimeoutTimer?.cancel();
      debugPrint('\n🎉 Processing COMPLETED in ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('Success: ${result.success}');
      
      // CRITICAL: Close dialog BEFORE navigation
      debugPrint('🔒 Closing dialog before navigation...');
      safeCloseDialog('success');
      
      // Wait a bit for dialog to close
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (!completer.isCompleted) completer.complete();

      if (!mounted) return;

      if (result.success) {
        debugPrint('🧑‍💻 Navigating to confirmation...');
        await context.push('/expense-confirmation', extra: result);
        debugPrint('✅ Navigation complete');
      } else {
        _showErrorSnackbar(result.errorMessage ?? 'Processing failed');
      }
    } on TimeoutException catch (_) {
      hardTimeoutTimer?.cancel();
      debugPrint('\n⏱️ TIMEOUT CAUGHT');
      safeCloseDialog('timeout');
      await Future.delayed(const Duration(milliseconds: 100));
      if (!completer.isCompleted) completer.complete();
      if (mounted) {
        _showErrorSnackbar('Processing timed out. Try with a clearer image.');
      }
    } catch (e, stackTrace) {
      hardTimeoutTimer?.cancel();
      debugPrint('\n❌ EXCEPTION CAUGHT: $e');
      debugPrint('Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}');
      safeCloseDialog('error');
      await Future.delayed(const Duration(milliseconds: 100));
      if (!completer.isCompleted) completer.complete();
      if (mounted) {
        _showErrorSnackbar('Error: ${e.toString().replaceAll("Exception: ", "").substring(0, 100)}');
      }
    } finally {
      debugPrint('\n' + '='*70);
      debugPrint('🏁 RECEIPT PROCESSING FINISHED');
      debugPrint('Dialog dismissed: $dialogDismissed');
      debugPrint('='*70 + '\n');
      
      // FORCE close dialog in finally block
      if (!dialogDismissed) {
        debugPrint('⚠️ Dialog still open in finally block! Force closing...');
        safeCloseDialog('finally');
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      hardTimeoutTimer?.cancel();
      if (!completer.isCompleted) completer.complete();
    }
    
    await completer.future;
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
