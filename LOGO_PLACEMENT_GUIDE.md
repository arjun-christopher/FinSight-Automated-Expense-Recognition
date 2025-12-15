# Logo Asset Placement Instructions

## Quick Start

You provided two logo images:
1. **Hexagonal icon** (green-to-cyan gradient with arrow)
2. **Full logo** ("FinSight" text with icon)

Follow these steps to integrate them into your app:

## Step 1: Prepare Logo Files

### Required Files and Sizes

You need to create **4 logo files** from your provided images:

#### 1. `finsight_icon.png` (1024x1024)
- **Source**: Your hexagonal gradient icon image
- **Purpose**: Main app icon for Android and iOS
- **Requirements**: 
  - Square format (1024x1024 pixels)
  - PNG with transparency
  - High resolution
- **Place in**: `assets/icons/finsight_icon.png`

#### 2. `finsight_logo_splash.png` (512x512)
- **Source**: Your hexagonal icon (centered)
- **Purpose**: Splash screen logo
- **Requirements**:
  - Square format (512x512 pixels)
  - PNG with transparency
  - Centered in the square
- **Place in**: `assets/images/finsight_logo_splash.png`

#### 3. `finsight_branding.png` (300x100)
- **Source**: Your full "FinSight" logo with text
- **Purpose**: Branding at bottom of splash screen
- **Requirements**:
  - Wide format (300x100 pixels or similar aspect ratio)
  - PNG with transparency
  - Logo + text combination
- **Place in**: `assets/images/finsight_branding.png`

#### 4. `finsight_logo.png` (flexible size)
- **Source**: Your hexagonal icon
- **Purpose**: Use in app UI (AppBar, headers, etc.)
- **Requirements**:
  - Square or appropriate aspect ratio
  - At least 256x256 pixels
  - PNG with transparency
- **Place in**: `assets/icons/finsight_logo.png`

## Step 2: Create Directory Structure

Run this command in your terminal:

```bash
cd /workspaces/FinSight-Automated-Expense-Recognition
mkdir -p assets/icons assets/images assets/animations
```

## Step 3: Place Your Logo Files

Copy your prepared logo files to these locations:

```
/workspaces/FinSight-Automated-Expense-Recognition/
  assets/
    ├── icons/
    │   ├── finsight_icon.png      ← Your hexagonal icon (1024x1024)
    │   └── finsight_logo.png      ← Your hexagonal icon (256x256+)
    └── images/
        ├── finsight_logo_splash.png  ← Your icon for splash (512x512)
        └── finsight_branding.png     ← Your full logo with text (300x100)
```

## Step 4: Generate App Icons and Splash Screens

Once the logo files are in place, run these commands:

```bash
# Navigate to project directory
cd /workspaces/FinSight-Automated-Expense-Recognition

# Install dependencies (if not already done)
flutter pub get

# Generate app icons for Android and iOS
flutter pub run flutter_launcher_icons

# Generate native splash screens
flutter pub run flutter_native_splash:create
```

## Step 5: Verify Integration

After running the commands, check that these were generated:

### Android
- `android/app/src/main/res/mipmap-*/ic_launcher.png` (various sizes)
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/values/styles.xml` (splash styles)

### iOS
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (all icon sizes)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/` (splash images)

## Step 6: Test the Branding

1. **Hot Restart** the app (not hot reload):
   ```bash
   # In VS Code: Press Shift+Cmd+F5 (Mac) or Shift+Ctrl+F5 (Windows/Linux)
   # Or terminate and restart the app
   ```

2. **Check these locations**:
   - ✅ App icon on device home screen
   - ✅ Animated splash screen on app launch
   - ✅ Logo in dashboard AppBar
   - ✅ Logo in Android widget (if installed)

## Troubleshooting

### "Image not found" errors

If you see fallback icons instead of your logo:

1. **Verify file names match exactly**:
   - `finsight_icon.png` (not `FinSight_icon.png`)
   - All lowercase, no spaces

2. **Check file locations**:
   ```bash
   ls -la assets/icons/
   ls -la assets/images/
   ```

3. **Verify pubspec.yaml** includes assets:
   ```yaml
   flutter:
     assets:
       - assets/icons/
       - assets/images/
       - assets/animations/
   ```

4. **Run pub get again**:
   ```bash
   flutter pub get
   ```

5. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Icons not updating on device

1. **Uninstall the app** completely from the device
2. **Rebuild and reinstall**:
   ```bash
   flutter clean
   flutter run
   ```

3. **For Android**, clear launcher cache:
   - Settings → Apps → Launcher → Storage → Clear Cache

### Widget not showing logo

1. **Regenerate the widget**:
   - Uninstall app
   - Reinstall app
   - Add widget again to home screen

2. **Check widget layout** references correct drawable:
   ```xml
   android:src="@mipmap/ic_launcher"
   ```

## Using Your Existing Logo Images

Since you already provided the logo images:

### Option A: Use Image Editing Software

1. Open your hexagonal icon in an image editor (Photoshop, GIMP, etc.)
2. Resize to the required dimensions:
   - 1024x1024 → `finsight_icon.png`
   - 512x512 → `finsight_logo_splash.png`
   - 256x256 → `finsight_logo.png`
3. Save as PNG with transparency

4. Open your full "FinSight" text logo
5. Resize to 300x100 → `finsight_branding.png`
6. Save as PNG with transparency

### Option B: Use Command-Line Tools (ImageMagick)

If you have ImageMagick installed:

```bash
# Resize hexagonal icon to different sizes
convert your_icon.png -resize 1024x1024 assets/icons/finsight_icon.png
convert your_icon.png -resize 512x512 assets/images/finsight_logo_splash.png
convert your_icon.png -resize 256x256 assets/icons/finsight_logo.png

# Resize full logo with text
convert your_full_logo.png -resize 300x100 assets/images/finsight_branding.png
```

### Option C: Use Online Tools

1. Go to an online image resizer:
   - [ResizeImage.net](https://resizeimage.net/)
   - [ILoveIMG](https://www.iloveimg.com/resize-image)
   - [Simple Image Resizer](https://www.simpleimageresizer.com/)

2. Upload your images and resize to required dimensions
3. Download and rename appropriately
4. Place in the correct asset folders

## Color Information

Your logo uses these colors (for reference):

- **Primary Green**: `#2E7D32`
- **Accent Cyan**: `#00BCD4`
- **Gradient**: Linear gradient from top-left green to bottom-right cyan

This matches the app's theme colors perfectly!

## Next Steps After Placement

Once all assets are in place:

1. ✅ Run `flutter pub get`
2. ✅ Run `flutter pub run flutter_launcher_icons`
3. ✅ Run `flutter pub run flutter_native_splash:create`
4. ✅ Hot restart the app
5. ✅ Test on a physical device
6. ✅ Check all logo appearances (icon, splash, AppBar, widget)

## File Checklist

Before generating icons and splash screens:

- [ ] `assets/icons/finsight_icon.png` exists (1024x1024)
- [ ] `assets/icons/finsight_logo.png` exists (256x256+)
- [ ] `assets/images/finsight_logo_splash.png` exists (512x512)
- [ ] `assets/images/finsight_branding.png` exists (300x100)
- [ ] All files are PNG format with transparency
- [ ] Files are high resolution and clear
- [ ] pubspec.yaml includes asset directories
- [ ] flutter_icons_config.yaml is configured

## Questions or Issues?

Common questions:

**Q: Can I use a different image format (JPG, SVG)?**  
A: PNG with transparency is required. Convert other formats to PNG first.

**Q: My icon has a white background, how do I remove it?**  
A: Use an image editor to remove the background and save with transparency, or use an online background remover tool.

**Q: The splash screen animation doesn't show my logo**  
A: Check that `finsight_logo_splash.png` exists in `assets/images/` and run `flutter pub get` again.

**Q: Do I need to create different sizes manually?**  
A: No! Create the largest sizes listed above, and the generation tools will create all other required sizes automatically.

---

**Need Help?** Check `BRANDING_INTEGRATION.md` for detailed usage examples and troubleshooting.
