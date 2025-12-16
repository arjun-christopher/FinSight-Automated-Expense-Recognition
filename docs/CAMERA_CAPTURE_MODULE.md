# Camera Capture Module - Implementation Guide

## 📋 Overview

Complete camera capture module for receipt images with camera and gallery picker functionality, image preview, and proper state management.

## 🏗️ Architecture

```
Receipt Capture Page
       ↓
Riverpod Provider (receiptCaptureProvider)
       ↓
ReceiptCaptureNotifier (State Management)
       ↓
ImagePicker (camera/image_picker packages)
       ↓
File System (app documents directory)
```

## 📁 File Structure

```
lib/
├── features/
│   └── receipt/
│       ├── presentation/
│       │   └── pages/
│       │       └── receipt_capture_page.dart    # Main UI
│       ├── providers/
│       │   └── receipt_capture_provider.dart    # State management
│       └── widgets/
│           └── receipt_capture_widgets.dart     # Reusable widgets
```

## ✨ Features Implemented

### 1. Image Capture
- ✅ **Camera Capture** - Take photo with device camera
- ✅ **Gallery Picker** - Select image from photo library
- ✅ **Image Quality** - Optimized to 85% quality, max 1920px
- ✅ **File Management** - Automatic save to app directory

### 2. State Management (Riverpod)
- ✅ `ReceiptCaptureState` - Immutable state with image path
- ✅ `ReceiptCaptureNotifier` - Handles capture logic
- ✅ `receiptCaptureProvider` - Auto-dispose provider
- ✅ State tracking (idle, capturing, captured, error)

### 3. UI Components
- ✅ **Capture Options** - Visual buttons for camera/gallery
- ✅ **Image Preview** - Full-screen preview with zoom
- ✅ **Action Buttons** - Retake and confirm actions
- ✅ **Loading States** - Overlay during capture
- ✅ **Error Handling** - User-friendly error messages

### 4. Animations
- ✅ **Page Entry** - Fade + slide animation (600ms)
- ✅ **Button Press** - Scale animation for feedback
- ✅ **Smooth Transitions** - Between states

### 5. File Management
- ✅ **Persistent Storage** - Saves to app documents directory
- ✅ **Organized Structure** - `/receipts` subdirectory
- ✅ **Unique Filenames** - Timestamp-based naming
- ✅ **Cleanup** - Deletes old image on retake

## 📱 Platform Configuration

### Android Permissions (AndroidManifest.xml)
Already configured in Task 1:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
```

### iOS Permissions (Info.plist)
Already configured in Task 1:
```xml
<key>NSCameraUsageDescription</key>
<string>FinSight needs camera access to capture receipt images</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>FinSight needs photo library access to select receipt images</string>
```

## 🎨 User Flow

### Camera Capture Flow
```
1. User taps "Take Photo" button
   ↓
2. Camera app opens
   ↓
3. User takes photo
   ↓
4. Image saved to app directory (/receipts/receipt_[timestamp].jpg)
   ↓
5. Preview screen shows with Retake/Confirm buttons
   ↓
6. User taps "Use This Image"
   ↓
7. Success message appears
   ↓
8. Image path returned to caller
```

### Gallery Picker Flow
```
1. User taps "Choose from Gallery" button
   ↓
2. Photo picker opens
   ↓
3. User selects image
   ↓
4. Image copied to app directory
   ↓
5. Preview screen shows
   ↓
6. User confirms or retakes
```

## 🎯 State Flow

```
CaptureState.idle
       ↓
User taps Camera/Gallery
       ↓
CaptureState.capturing (loading overlay shows)
       ↓
Image picked/captured
       ↓
Image saved to file system
       ↓
CaptureState.captured (preview shows)
       ↓
User confirms
       ↓
Return image path
       ↓
Reset state
```

## 💻 Code Usage

### Basic Usage (Automatic)
The page is already integrated with bottom navigation. Users can:
1. Navigate to "Scan Receipt" tab
2. Choose camera or gallery
3. Preview and confirm image
4. Image path is available for processing

### Programmatic Usage

```dart
// Get capture notifier
final captureNotifier = ref.read(receiptCaptureProvider.notifier);

// Capture from camera
await captureNotifier.captureFromCamera();

// Pick from gallery
await captureNotifier.pickFromGallery();

// Get captured image path
final imagePath = captureNotifier.confirmAndGetPath();

// Get File object
final imageFile = captureNotifier.getImageFile();

// Retake image
await captureNotifier.retakeImage();

// Reset state
captureNotifier.reset();
```

### Watching State

```dart
// Watch capture state
final captureState = ref.watch(receiptCaptureProvider);

// Check state
if (captureState.hasImage) {
  print('Image captured: ${captureState.imagePath}');
}

if (captureState.isCapturing) {
  // Show loading
}

if (captureState.hasError) {
  print('Error: ${captureState.errorMessage}');
}
```

### Listen for State Changes

```dart
ref.listen(receiptCaptureProvider, (previous, next) {
  if (next.isCaptured) {
    // Image was captured
    print('Image path: ${next.imagePath}');
  }
  
  if (next.hasError) {
    // Handle error
    showErrorDialog(next.errorMessage);
  }
});
```

## 🎨 UI Components

### 1. CaptureButton
Large, visually appealing button with icon and label
```dart
CaptureButton(
  icon: Icons.camera_alt,
  label: 'Take Photo',
  onPressed: () => ...,
  color: Colors.blue,
)
```

### 2. ReceiptImagePreview
Full-screen image preview with actions
```dart
ReceiptImagePreview(
  imagePath: '/path/to/image.jpg',
  onRetake: () => ...,
  onConfirm: () => ...,
  showActions: true,
)
```

### 3. EmptyStateWidget
Empty state with icon, title, and subtitle
```dart
EmptyStateWidget(
  icon: Icons.camera_alt_outlined,
  title: 'No Image',
  subtitle: 'Capture a receipt to get started',
)
```

### 4. LoadingOverlay
Overlay with spinner and message
```dart
LoadingOverlay(
  message: 'Processing...',
)
```

## 📊 Image Specifications

### Capture Settings
- **Quality**: 85% (good balance)
- **Max Resolution**: 1920 x 1920 pixels
- **Format**: JPEG (from camera/gallery)
- **File Size**: ~200KB - 2MB (depends on content)

### Storage
- **Location**: `[AppDocuments]/receipts/`
- **Naming**: `receipt_[timestamp].jpg`
- **Example**: `receipt_1702656000000.jpg`

### File Path Example
```
/data/user/0/com.finsight.finsight/app_flutter/receipts/receipt_1702656000000.jpg
```

## 🔐 Error Handling

### Permission Errors
Automatically handled by `image_picker`:
- Shows system permission dialog on first use
- If denied, user must enable in settings
- Clear error message shown to user

### Capture Errors
```dart
try {
  await captureNotifier.captureFromCamera();
} catch (e) {
  // Error shown in snackbar
  // User can try again
}
```

### Common Error Scenarios
1. **Permission Denied**: "Failed to capture image: Permission denied"
2. **Camera Unavailable**: "Failed to capture image: Camera not available"
3. **Storage Full**: "Failed to save image: No space left"
4. **User Cancelled**: No error shown, state returns to idle

## 🎭 Animations

### Page Entry Animation
```dart
Duration: 600ms
- Fade: 0% → 100% opacity
- Slide: Offset(0, 0.3) → Offset.zero
- Curve: easeOutCubic
```

### Button Press Animation
```dart
Duration: 100ms
- Scale: 100% → 95% (on tap)
- Scale: 95% → 100% (on release)
- Curve: easeInOut
```

### State Transitions
```dart
- Smooth crossfade between idle/captured states
- Loading overlay fades in/out
- Preview scales in from center
```

## 📱 Screen States

### 1. Idle State (No Image)
```
┌─────────────────────────────────┐
│          Scan Receipt            │
├─────────────────────────────────┤
│                                  │
│          📷                      │
│     Capture Receipt              │
│  Take a photo or choose from     │
│     gallery to get started       │
│                                  │
│  ┌─────────────────────────┐   │
│  │  📷  Take Photo         │   │
│  └─────────────────────────┘   │
│                                  │
│  ┌─────────────────────────┐   │
│  │  🖼️  Choose from Gallery│   │
│  └─────────────────────────┘   │
│                                  │
└─────────────────────────────────┘
```

### 2. Capturing State (Loading)
```
┌─────────────────────────────────┐
│          Scan Receipt            │
├─────────────────────────────────┤
│                                  │
│         [DIMMED]                 │
│                                  │
│     ┌───────────────────┐       │
│     │   ⏳ Opening...   │       │
│     └───────────────────┘       │
│                                  │
└─────────────────────────────────┘
```

### 3. Captured State (Preview)
```
┌─────────────────────────────────┐
│  Scan Receipt             ✕     │
├─────────────────────────────────┤
│                                  │
│    ┌─────────────────────┐     │
│    │                      │     │
│    │   [Receipt Image]    │     │
│    │                      │     │
│    └─────────────────────┘     │
│                                  │
│  [🔄 Retake]  [✓ Use This Image]│
│                                  │
└─────────────────────────────────┘
```

## 🔄 Integration with Other Modules

### Future Integration (OCR Processing)
```dart
// After user confirms image
final imagePath = captureNotifier.confirmAndGetPath();

if (imagePath != null) {
  // Process with OCR
  final ocrResult = await ocrService.extractText(imagePath);
  
  // Create expense from OCR data
  final expense = Expense(
    amount: ocrResult.amount,
    merchant: ocrResult.merchant,
    date: ocrResult.date,
    // ...
  );
  
  // Navigate to expense form with pre-filled data
  context.push('/add-expense', extra: expense);
}
```

### Save to Database
```dart
// Create ReceiptImage record
final receiptImage = ReceiptImage(
  filePath: imagePath,
  isProcessed: false,
);

final receiptId = await receiptRepo.createReceiptImage(receiptImage);
```

## 🚀 Next Steps

Ready for integration with:
1. ✅ OCR text extraction (Google ML Kit)
2. ✅ Automatic expense creation
3. ✅ Receipt image storage in database
4. ✅ Edit existing receipts
5. ✅ Receipt gallery view

## 🎯 Performance Considerations

- ✅ **Image Compression**: 85% quality reduces file size
- ✅ **Resolution Limit**: Max 1920px prevents huge files
- ✅ **Auto-dispose Provider**: Prevents memory leaks
- ✅ **Lazy Loading**: Images loaded only when needed
- ✅ **File Cleanup**: Old images deleted on retake

## 🐛 Troubleshooting

### Issue: Camera not opening
**Solution**: Check permissions in device settings

### Issue: Image too large
**Solution**: Already handled - images auto-compressed

### Issue: App crashes on capture
**Solution**: Ensure permissions are granted

### Issue: Can't find saved images
**Solution**: Images stored in app-private directory (not gallery)

## 📝 Testing Checklist

- [x] Camera capture works
- [x] Gallery picker works
- [x] Image preview displays correctly
- [x] Retake button works
- [x] Confirm button works
- [x] File saved to correct location
- [x] Unique filenames generated
- [x] Old image deleted on retake
- [x] Permissions handled properly
- [x] Error messages display
- [x] Loading states show
- [x] Animations smooth
- [x] Works in light/dark mode
- [x] No memory leaks

## 💡 Tips

### Taking Good Receipt Photos
1. Good lighting
2. Flat surface
3. All corners visible
4. Text readable
5. Avoid glare

### Best Practices
- Always check `hasImage` before accessing path
- Handle errors gracefully
- Clean up resources (already done with auto-dispose)
- Test on both iOS and Android
- Test with different image sizes

## 🔗 Related Files

- Image Picker Package: `image_picker` (in pubspec.yaml)
- Camera Package: `camera` (in pubspec.yaml)
- Path Provider: `path_provider` (in pubspec.yaml)
- Receipt Model: `lib/core/models/receipt_image.dart`
- Receipt Repository: `lib/data/repositories/receipt_image_repository.dart`

---

**Module Status**: ✅ Complete and Production Ready

Camera capture fully functional with proper error handling, state management, and user experience. Ready for OCR integration.
