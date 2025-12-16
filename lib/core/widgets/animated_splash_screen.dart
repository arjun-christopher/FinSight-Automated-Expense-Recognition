import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated splash screen that displays when app launches
/// Shows FinSight logo with gradient background animation
class AnimatedSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final Duration duration;

  const AnimatedSplashScreen({
    super.key,
    required this.onComplete,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _gradientController;
  late AnimationController _rippleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _gradientAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    // Gradient animation (rotating colors)
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _gradientController,
    );

    // Ripple animation
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: Curves.easeOut,
      ),
    );
  }

  void _startAnimations() async {
    // Start fade and scale
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();

    // Start gradient rotation
    _gradientController.repeat();

    // Start ripple
    await Future.delayed(const Duration(milliseconds: 500));
    _rippleController.forward();

    // Wait for duration, then complete
    await Future.delayed(widget.duration);
    widget.onComplete();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _gradientController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _gradientAnimation,
          _fadeAnimation,
          _scaleAnimation,
          _rippleAnimation,
        ]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: _buildAnimatedGradient(),
            ),
            child: Stack(
              children: [
                // Ripple effect background
                _buildRippleEffect(),

                // Logo and branding
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with scale and fade
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildLogo(),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Tagline
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Smart Expense Tracking',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),

                // Version number at bottom
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    // Try to load logo from assets, fallback to placeholder
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        'assets/images/Logo.png',
        width: 180,
        height: 180,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback: Custom painted logo
          return SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: LogoPlaceholderPainter(),
            ),
          );
        },
      ),
    );
  }

  LinearGradient _buildAnimatedGradient() {
    final angle = _gradientAnimation.value * 2 * math.pi;

    return LinearGradient(
      begin: Alignment(math.cos(angle), math.sin(angle)),
      end: Alignment(-math.cos(angle), -math.sin(angle)),
      colors: const [
        Color(0xFF2E7D32), // Primary green - matching logo
        Color(0xFF4CAF50), // Medium green
        Color(0xFF26A69A), // Teal transition
        Color(0xFF00BCD4), // Cyan accent - matching logo
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
  }

  Widget _buildRippleEffect() {
    return Positioned.fill(
      child: CustomPaint(
        painter: RipplePainter(
          animationValue: _rippleAnimation.value,
          color: Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }
}

/// Painter for ripple effect
class RipplePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  RipplePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height);

    for (int i = 0; i < 3; i++) {
      final progress = (animationValue + i * 0.3) % 1.0;
      final radius = maxRadius * progress;
      final opacity = (1.0 - progress) * 0.3;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Placeholder logo painter (used if image fails to load)
class LogoPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Draw hexagon
    final hexagonPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        hexagonPath.moveTo(x, y);
      } else {
        hexagonPath.lineTo(x, y);
      }
    }
    hexagonPath.close();

    // Draw gradient hexagon
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2E7D32), Color(0xFF00BCD4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(hexagonPath, paint);

    // Draw horizontal lines (data representation)
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final lineSpacing = size.height * 0.12;
    final startY = center.dy - lineSpacing * 1.5;

    for (int i = 0; i < 3; i++) {
      final y = startY + i * lineSpacing;
      final startX = center.dx - radius * 0.5;
      final endX = center.dx + radius * 0.2;
      canvas.drawLine(Offset(startX, y), Offset(endX, y), linePaint);
    }

    // Draw upward arrow
    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final arrowPath = Path();
    final arrowStartX = center.dx + radius * 0.1;
    final arrowStartY = center.dy + radius * 0.3;
    final arrowEndX = center.dx + radius * 0.5;
    final arrowEndY = center.dy - radius * 0.5;

    arrowPath.moveTo(arrowStartX, arrowStartY);
    arrowPath.lineTo(arrowEndX, arrowEndY);

    // Arrow head
    arrowPath.moveTo(arrowEndX - 8, arrowEndY + 8);
    arrowPath.lineTo(arrowEndX, arrowEndY);
    arrowPath.lineTo(arrowEndX + 8, arrowEndY + 8);

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
