# UI Polish Quick Start Guide

Get started with the FinSight UI polish system in 5 minutes!

## 🚀 Quick Setup

The animation system is already integrated. Just import and use!

```dart
import 'package:finsight/core/widgets/animated_cards.dart';
import 'package:finsight/core/widgets/animated_buttons.dart';
import 'package:finsight/core/animations/app_animations.dart';
```

---

## 📝 Common Use Cases

### 1. Add Animation to a List (Most Common)

**Before:**
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return Card(
      child: ListTile(
        title: Text(items[index].name),
        onTap: () => navigate(items[index]),
      ),
    );
  },
)
```

**After:**
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return SlideInCard(               // ← Slide + fade animation
      index: index,                    // ← Stagger delay
      child: AnimatedCard(             // ← Press animation
        onTap: () => navigate(items[index]),
        child: ListTile(
          title: Text(items[index].name),
        ),
      ),
    );
  },
)
```

**Result:** Items slide in from bottom with staggered delays (50ms each)

---

### 2. Add Loading State to Button

**Before:**
```dart
ElevatedButton(
  onPressed: _isLoading ? null : _save,
  child: _isLoading 
    ? CircularProgressIndicator() 
    : Text('Save'),
)
```

**After:**
```dart
AnimatedButton(
  onPressed: _save,
  isLoading: _isLoading,
  child: Text('Save'),
)
```

**Result:** Button shows spinner, disables automatically, and animates press

---

### 3. Add Loading Placeholder

**Before:**
```dart
_isLoading 
  ? CircularProgressIndicator()
  : ExpenseCard(expense)
```

**After:**
```dart
_isLoading
  ? ShimmerCard(width: double.infinity, height: 80)
  : ExpenseCard(expense)
```

**Result:** Professional shimmer loading skeleton

---

### 4. Show Success Confirmation

**Before:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Saved!')),
);
```

**After:**
```dart
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
          SuccessAnimation(),            // ← Animated checkmark
          SizedBox(height: 24),
          Text('Saved!', style: TextStyle(fontSize: 24)),
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
```

**Result:** Beautiful animated success dialog

---

### 5. Add Expandable Section

**Before:**
```dart
Column(
  children: [
    Text('Header'),
    if (_expanded) ...[
      Text('Detail 1'),
      Text('Detail 2'),
    ],
  ],
)
```

**After:**
```dart
ExpandableCard(
  header: Text('Header'),
  expandedContent: Column(
    children: [
      Text('Detail 1'),
      Text('Detail 2'),
    ],
  ),
)
```

**Result:** Smooth expand/collapse with rotating chevron

---

## 🎨 Widget Cheat Sheet

### Cards
```dart
// Basic press effect
AnimatedCard(onTap: () {}, child: ...)

// Slide in (for lists)
SlideInCard(index: 0, child: ...)

// Expandable
ExpandableCard(header: ..., expandedContent: ...)

// 3D flip
FlipCard(front: ..., back: ...)

// Glass effect
GlassCard(child: ...)

// Loading placeholder
ShimmerCard(width: 200, height: 80)
```

### Buttons
```dart
// Primary button with loading
AnimatedButton(onPressed: ..., isLoading: false, child: Text('Save'))

// FAB with label
AnimatedFAB(icon: Icon(Icons.add), label: 'Add', onPressed: ...)

// Icon button
AnimatedIconButton(icon: Icons.settings, onPressed: ...)
```

### Interactive Elements
```dart
// Switch
AnimatedSwitch(value: true, onChanged: (v) {})

// Checkbox
AnimatedCheckbox(value: true, onChanged: (v) {})

// Badge
AnimatedBadge(label: '5', show: true, child: Icon(...))
```

### Animations
```dart
// Loading spinner
LoadingAnimation()

// Pulse effect
PulseAnimation(child: Icon(...))

// Success checkmark
SuccessAnimation()

// Shimmer effect
ShimmerLoading()
```

---

## 🎯 Integration Priority

### Start Here (High Impact, Easy)
1. **Expense List**: Add `SlideInCard` + `AnimatedCard`
2. **Save Buttons**: Replace with `AnimatedButton`
3. **Loading States**: Use `ShimmerCard`

### Then Do (Medium Impact)
4. **Dashboard Charts**: Wrap in `SlideInCard` with stagger
5. **Success Dialogs**: Add `SuccessAnimation`
6. **Settings Toggles**: Use `AnimatedSwitch`

### Finally (Polish)
7. **Page Transitions**: Use `FadePageRoute` / `SlidePageRoute`
8. **Icon Buttons**: Use `AnimatedIconButton`
9. **Badges**: Use `AnimatedBadge` for notifications

---

## ⚡ Performance Tips

### ✅ Do This
```dart
// Good: Use const where possible
const SlideInCard(
  index: 0,
  child: const Text('Static content'),
)

// Good: Limit animation scope
AnimatedCard(
  child: ExpensiveBuildWidget(),  // Only card animates
)

// Good: Dispose controllers
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

### ❌ Don't Do This
```dart
// Bad: Nested animations
AnimatedCard(
  child: AnimatedCard(           // Don't nest same type
    child: ...,
  ),
)

// Bad: Animating expensive operations
AnimatedBuilder(
  builder: (context, child) {
    return HeavyWidget();         // Rebuilds every frame
  },
)

// Bad: Very long durations
duration: Duration(seconds: 5)    // Too slow, use 200-500ms
```

---

## 🐛 Common Issues & Fixes

### Issue: "Animation jank on scroll"
**Solution:** Use `const` constructors and avoid rebuilding list
```dart
ListView.builder(
  itemBuilder: (context, index) {
    return SlideInCard(
      key: ValueKey(items[index].id),  // ← Add key
      index: index,
      child: const ItemWidget(),       // ← Make const
    );
  },
)
```

### Issue: "Button loading state not working"
**Solution:** Ensure state updates correctly
```dart
AnimatedButton(
  onPressed: () async {
    setState(() => _isLoading = true);   // ← Update before
    await saveData();
    if (mounted) {                       // ← Check mounted
      setState(() => _isLoading = false); // ← Update after
    }
  },
  isLoading: _isLoading,                 // ← Read state
  child: Text('Save'),
)
```

### Issue: "Shimmer card wrong size"
**Solution:** Specify dimensions
```dart
// Bad
ShimmerCard()  // Default 100x100

// Good
ShimmerCard(
  width: double.infinity,  // Full width
  height: 80,              // Fixed height
  margin: EdgeInsets.all(8),
)
```

### Issue: "Page transition not working"
**Solution:** Use correct route builder
```dart
// For direct navigation
Navigator.push(
  context,
  FadePageRoute(child: NextPage()),
);

// For GoRouter
GoRoute(
  path: '/next',
  pageBuilder: (context, state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: NextPage(),
      transitionsBuilder: (context, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  },
)
```

---

## 📚 More Resources

- **Full Documentation**: `UI_POLISH_GUIDE.md`
- **Visual Reference**: `UI_POLISH_VISUAL_REFERENCE.md`
- **Implementation Checklist**: `UI_POLISH_CHECKLIST.md`
- **Live Examples**: Run `lib/examples/ui_polish_examples.dart`

---

## 🎉 You're Ready!

Start with one page:
1. Open the expense list page
2. Wrap items in `SlideInCard(index: index, child: ...)`
3. Replace buttons with `AnimatedButton`
4. Hot reload and see the magic! ✨

For questions, check the full guide or run the examples app!
