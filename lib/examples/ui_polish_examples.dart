import 'package:flutter/material.dart';
import '../core/widgets/animated_cards.dart';
import '../core/widgets/animated_buttons.dart';
import '../core/animations/app_animations.dart';

/// Complete example demonstrating all UI polish features
class UIPolishShowcase extends StatefulWidget {
  const UIPolishShowcase({super.key});

  @override
  State<UIPolishShowcase> createState() => _UIPolishShowcaseState();
}

class _UIPolishShowcaseState extends State<UIPolishShowcase> {
  bool _isLoading = false;
  bool _showBadge = true;
  bool _switchValue = false;
  bool _checkboxValue = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UI Polish Showcase'),
        actions: [
          AnimatedIconButton(
            icon: Icons.refresh,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing...')),
              );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Animated Cards Section
            const Text(
              'Animated Cards',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            SlideInCard(
              index: 0,
              child: AnimatedCard(
                onTap: () => _showMessage('Card tapped!'),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interactive Card',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Tap me to see the animation!'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            SlideInCard(
              index: 1,
              child: ExpandableCard(
                header: const Text(
                  'Expandable Card',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                expandedContent: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This content is hidden until you tap the card.'),
                    SizedBox(height: 8),
                    Text('Perfect for showing details on demand!'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            SlideInCard(
              index: 2,
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Glass Card',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Beautiful glassmorphic effect',
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Animated Buttons Section
            const Text(
              'Animated Buttons',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            AnimatedButton(
              onPressed: () async {
                setState(() => _isLoading = true);
                await Future.delayed(const Duration(seconds: 2));
                if (mounted) {
                  setState(() => _isLoading = false);
                  _showSuccessAnimation();
                }
              },
              isLoading: _isLoading,
              child: const Text('Primary Button'),
            ),

            const SizedBox(height: 12),

            AnimatedButton(
              onPressed: () => _showMessage('Secondary button pressed'),
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              elevation: 0,
              child: const Text('Secondary Button'),
            ),

            const SizedBox(height: 12),

            AnimatedButton(
              onPressed: null,
              isDisabled: true,
              child: const Text('Disabled Button'),
            ),

            const SizedBox(height: 32),

            // Interactive Elements
            const Text(
              'Interactive Elements',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            AnimatedCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Animated Switch'),
                      AnimatedSwitch(
                        value: _switchValue,
                        onChanged: (value) {
                          setState(() => _switchValue = value);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Animated Checkbox'),
                      AnimatedCheckbox(
                        value: _checkboxValue,
                        onChanged: (value) {
                          setState(() => _checkboxValue = value ?? false);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Badge'),
                      AnimatedBadge(
                        label: '5',
                        show: _showBadge,
                        child: IconButton(
                          icon: const Icon(Icons.notifications),
                          onPressed: () {
                            setState(() => _showBadge = !_showBadge);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Loading States
            const Text(
              'Loading States',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                LoadingAnimation(),
                PulseAnimation(
                  child: Icon(Icons.favorite, color: Colors.red, size: 40),
                ),
              ],
            ),

            const SizedBox(height: 16),

            const ShimmerCard(
              width: double.infinity,
              height: 80,
              margin: EdgeInsets.symmetric(vertical: 8),
            ),

            const SizedBox(height: 32),

            // Success Animation
            Center(
              child: ElevatedButton(
                onPressed: _showSuccessAnimation,
                child: const Text('Show Success Animation'),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: AnimatedFAB(
        icon: const Icon(Icons.add),
        label: 'Add',
        isExtended: true,
        onPressed: () => _showMessage('FAB pressed!'),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SuccessAnimation(),
              const SizedBox(height: 24),
              const Text(
                'Success!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Operation completed successfully',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AnimatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example: Animated List
class AnimatedListExample extends StatelessWidget {
  const AnimatedListExample({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(10, (index) => 'Item ${index + 1}');

    return Scaffold(
      appBar: AppBar(title: const Text('Animated List')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return SlideInCard(
            index: index,
            child: AnimatedCard(
              margin: const EdgeInsets.only(bottom: 12),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tapped ${items[index]}')),
                );
              },
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text('${index + 1}'),
                ),
                title: Text(items[index]),
                subtitle: const Text('Tap to interact'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Example: Page Transition
class PageTransitionExample extends StatelessWidget {
  const PageTransitionExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Transitions')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  FadePageRoute(
                    child: const DestinationPage(title: 'Fade Transition'),
                  ),
                );
              },
              child: const Text('Fade Transition'),
            ),
            const SizedBox(height: 16),
            AnimatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  SlidePageRoute(
                    child: const DestinationPage(title: 'Slide Transition'),
                  ),
                );
              },
              child: const Text('Slide Transition'),
            ),
            const SizedBox(height: 16),
            AnimatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  ScaleFadePageRoute(
                    child: const DestinationPage(title: 'Scale + Fade'),
                  ),
                );
              },
              child: const Text('Scale + Fade Transition'),
            ),
          ],
        ),
      ),
    );
  }
}

class DestinationPage extends StatelessWidget {
  final String title;

  const DestinationPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            AnimatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
