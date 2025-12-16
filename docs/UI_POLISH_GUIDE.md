# UI Polish Guide for FinSight

This guide explains the comprehensive UI polish system implemented across the FinSight app, including animations, transitions, and enhanced styling.

## Table of Contents
1. [Animation System](#animation-system)
2. [Animated Components](#animated-components)
3. [Page Transitions](#page-transitions)
4. [Enhanced Theme](#enhanced-theme)
5. [Implementation Examples](#implementation-examples)
6. [Best Practices](#best-practices)

---

## Animation System

The animation system is centralized in `lib/core/animations/app_animations.dart`.

### Animation Constants

```dart
// Duration constants
AppAnimations.durationFast      // 200ms - Quick feedback
AppAnimations.durationMedium    // 350ms - Standard animations
AppAnimations.durationSlow      // 500ms - Deliberate animations

// Curve constants
AppAnimations.curveStandard     // easeInOut - Balanced motion
AppAnimations.curveDecelerate   // fastOutSlowIn - Natural stops
AppAnimations.curveAccelerate   // slowInFastOut - Energetic starts
AppAnimations.curveBounce       // elasticOut - Playful bounce
```

### Animation Utilities

```dart
// Stagger animations in lists
final delay = AnimationUtils.staggerDelay(index);

// Fade in/out animations
Animation<double> fadeAnimation = AnimationUtils.createFadeAnimation(
  controller,
  begin: 0.0,
  end: 1.0,
);

// Slide animations
Animation<Offset> slideAnimation = AnimationUtils.createSlideAnimation(
  controller,
  begin: const Offset(0, 0.3),
  end: Offset.zero,
);

// Scale animations
Animation<double> scaleAnimation = AnimationUtils.createScaleAnimation(
  controller,
  begin: 0.8,
  end: 1.0,
);
```

---

## Animated Components

### 1. Animated Cards

#### AnimatedCard - Press Effect Card
```dart
AnimatedCard(
  onTap: () => print('Tapped!'),
  child: ListTile(
    title: Text('Interactive Card'),
    subtitle: Text('Press me for animation'),
  ),
)
```

**Features:**
- Scale down on press (0.98)
- Smooth spring animation
- Tap/long press callbacks

#### SlideInCard - List Item Animation
```dart
ListView.builder(
  itemBuilder: (context, index) {
    return SlideInCard(
      index: index,  // Staggered delay based on index
      child: Card(
        child: ListTile(title: Text('Item $index')),
      ),
    );
  },
)
```

**Features:**
- Slides in from bottom with fade
- Automatic staggered delays
- Perfect for lists

#### ExpandableCard - Accordion Style
```dart
ExpandableCard(
  header: Text('Click to expand'),
  expandedContent: Column(
    children: [
      Text('Hidden content'),
      Text('More details here'),
    ],
  ),
)
```

**Features:**
- Smooth expand/collapse
- Rotating chevron icon
- Auto-scrolls to show content

#### FlipCard - 3D Flip Animation
```dart
FlipCard(
  front: Card(child: Text('Front')),
  back: Card(child: Text('Back')),
)
```

**Features:**
- 3D flip animation
- Tap to flip both sides
- Maintains aspect ratio

#### GlassCard - Glassmorphic Effect
```dart
GlassCard(
  blur: 10.0,
  opacity: 0.2,
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text('Glass effect'),
  ),
)
```

**Features:**
- Backdrop blur effect
- Semi-transparent background
- Modern aesthetic

#### ShimmerCard - Loading Placeholder
```dart
ShimmerCard(
  width: double.infinity,
  height: 80,
  borderRadius: 12,
)
```

**Features:**
- Animated shimmer effect
- Customizable size/shape
- Loading state indicator

---

### 2. Animated Buttons

#### AnimatedButton - Primary Button
```dart
AnimatedButton(
  onPressed: () async {
    setState(() => _loading = true);
    await doSomething();
    setState(() => _loading = false);
  },
  isLoading: _loading,
  child: Text('Save'),
)
```

**Features:**
- Loading spinner state
- Disabled state styling
- Scale animation on press
- Ripple effect

#### AnimatedFAB - Floating Action Button
```dart
AnimatedFAB(
  icon: Icon(Icons.add),
  label: 'Add Expense',
  isExtended: true,  // Show label
  onPressed: () => navigateToAdd(),
)
```

**Features:**
- Extends/collapses on scroll
- Scale animation
- Rotation effect

#### AnimatedIconButton - Icon Buttons
```dart
AnimatedIconButton(
  icon: Icons.favorite,
  onPressed: () => toggleFavorite(),
  tooltip: 'Favorite',
)
```

**Features:**
- Scale + rotation animation
- Tooltip support
- Ripple effect

---

### 3. Interactive Elements

#### AnimatedSwitch
```dart
AnimatedSwitch(
  value: _value,
  onChanged: (value) => setState(() => _value = value),
)
```

#### AnimatedCheckbox
```dart
AnimatedCheckbox(
  value: _checked,
  onChanged: (value) => setState(() => _checked = value!),
)
```

#### AnimatedBadge
```dart
AnimatedBadge(
  label: '5',
  show: true,
  child: IconButton(
    icon: Icon(Icons.notifications),
    onPressed: () {},
  ),
)
```

---

### 4. Loading Animations

#### LoadingAnimation - Spinner
```dart
Center(child: LoadingAnimation())
```

#### PulseAnimation - Heartbeat Effect
```dart
PulseAnimation(
  child: Icon(Icons.favorite, color: Colors.red),
)
```

#### SuccessAnimation - Checkmark
```dart
SuccessAnimation()  // Shows animated checkmark
```

---

## Page Transitions

Custom page route animations for navigation.

### Fade Transition
```dart
Navigator.push(
  context,
  FadePageRoute(child: DetailsPage()),
);
```

### Slide Transition
```dart
Navigator.push(
  context,
  SlidePageRoute(
    child: DetailsPage(),
    direction: SlideDirection.left,
  ),
);
```

### Scale + Fade Transition
```dart
Navigator.push(
  context,
  ScaleFadePageRoute(child: DetailsPage()),
);
```

### Using with Go Router
```dart
GoRoute(
  path: '/details',
  pageBuilder: (context, state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: DetailsPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  },
),
```

---

## Enhanced Theme

### Shadow System
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [AppTheme.softShadow],  // or mediumShadow, hardShadow
  ),
)
```

**Available Shadows:**
- `AppTheme.softShadow` - Subtle elevation
- `AppTheme.mediumShadow` - Standard cards
- `AppTheme.hardShadow` - Prominent elements

### Extended Colors
```dart
// Success/Warning colors
AppTheme.successColor  // Green for confirmations
AppTheme.warningColor  // Orange for warnings
```

### Consistent Styling

**Border Radius:**
- Cards: 16dp
- Buttons: 12dp
- Inputs: 12dp
- Dialogs: 20dp
- Chips: 20dp

**Padding:**
- Buttons: 24h x 14v
- Inputs: 16h x 14v
- Cards: Custom per use case

**Elevation:**
- Cards: 0 (uses borders + shadows)
- FAB: 4 (highlight: 8)
- Dialogs: 8

---

## Implementation Examples

### Animated List with Stagger Effect
```dart
class AnimatedExpenseList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        return SlideInCard(
          index: index,
          child: AnimatedCard(
            onTap: () => navigateToDetails(expenses[index]),
            child: ExpenseListTile(expense: expenses[index]),
          ),
        );
      },
    );
  }
}
```

### Loading State with Shimmer
```dart
class LoadingExpenseList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return ShimmerCard(
          width: double.infinity,
          height: 80,
          margin: EdgeInsets.all(8),
        );
      },
    );
  }
}
```

### Success Dialog with Animation
```dart
void showSuccess(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SuccessAnimation(),
            SizedBox(height: 24),
            Text(
              'Expense Saved!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            AnimatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done'),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### Interactive Card with Multiple States
```dart
class InteractiveExpenseCard extends StatefulWidget {
  @override
  State<InteractiveExpenseCard> createState() => _InteractiveExpenseCardState();
}

class _InteractiveExpenseCardState extends State<InteractiveExpenseCard> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: () => navigateToDetails(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Grocery Shopping')),
              AnimatedIconButton(
                icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                onPressed: () => setState(() => _isFavorite = !_isFavorite),
              ),
            ],
          ),
          ExpandableCard(
            header: Text('Details'),
            expandedContent: Text('More information here...'),
          ),
        ],
      ),
    );
  }
}
```

---

## Best Practices

### 1. Animation Durations
- **Fast (200ms)**: Button presses, toggles, micro-interactions
- **Medium (350ms)**: Card animations, page transitions
- **Slow (500ms)**: Complex animations, attention-grabbing effects

### 2. Staggered Lists
Always use `SlideInCard` with proper index for list items:
```dart
SlideInCard(
  index: index,
  child: YourListItem(),
)
```

### 3. Loading States
Use shimmer cards for skeleton screens:
```dart
isLoading ? ShimmerCard() : ActualContent()
```

### 4. Success Feedback
Combine visual feedback for better UX:
```dart
// 1. Button loading state
AnimatedButton(isLoading: true)

// 2. Success animation
showDialog(...SuccessAnimation()...)

// 3. Snackbar confirmation
ScaffoldMessenger.of(context).showSnackBar(...)
```

### 5. Page Transitions
Choose appropriate transitions:
- **Fade**: Modals, overlays
- **Slide**: Navigation between pages
- **Scale**: Focus on specific content

### 6. Performance
- Use `const` constructors where possible
- Avoid nested animations
- Dispose controllers in stateful widgets
- Use `RepaintBoundary` for complex animations

### 7. Accessibility
- Maintain minimum touch targets (48x48)
- Provide tooltips for icon buttons
- Test with reduced motion settings
- Ensure sufficient color contrast

---

## Testing Animations

Run the UI polish showcase to see all animations:
```dart
import 'package:finsight/examples/ui_polish_examples.dart';

// Navigate to:
UIPolishShowcase()      // All components
AnimatedListExample()   // Staggered lists
PageTransitionExample() // Transitions
```

---

## Migration Guide

### Updating Existing Widgets

#### Before:
```dart
Card(
  child: ListTile(
    title: Text('Expense'),
    onTap: () => navigate(),
  ),
)
```

#### After:
```dart
SlideInCard(
  index: index,
  child: AnimatedCard(
    onTap: () => navigate(),
    child: ListTile(
      title: Text('Expense'),
    ),
  ),
)
```

#### Before:
```dart
ElevatedButton(
  onPressed: isLoading ? null : () => save(),
  child: isLoading ? CircularProgressIndicator() : Text('Save'),
)
```

#### After:
```dart
AnimatedButton(
  onPressed: () => save(),
  isLoading: isLoading,
  child: Text('Save'),
)
```

---

## Troubleshooting

### Animation Jank
- Check for expensive build operations
- Use `RepaintBoundary`
- Profile with Flutter DevTools

### Gesture Conflicts
- Wrap interactive children in `GestureDetector` with `behavior: HitTestBehavior.opaque`
- Use `IgnorePointer` to disable interactions

### Theme Not Applied
- Ensure `MaterialApp` uses `AppTheme.lightTheme` / `AppTheme.darkTheme`
- Hot restart after theme changes
- Check widget uses `Theme.of(context)` correctly

---

## Summary

The UI polish system provides:
✅ **Consistent Animations**: Centralized durations, curves, and utilities
✅ **Reusable Components**: 15+ animated widgets ready to use
✅ **Professional Theme**: Refined styling with shadows, borders, and colors
✅ **Page Transitions**: Custom route animations for smooth navigation
✅ **Performance**: Optimized animations running at 60fps
✅ **Accessibility**: Proper touch targets and reduced motion support

For live examples, run `lib/examples/ui_polish_examples.dart` in your app!
