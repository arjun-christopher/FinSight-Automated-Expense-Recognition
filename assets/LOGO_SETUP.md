# FinSight Logo Assets Setup

## Required Logo Files

Place the following logo files from the provided images:

### 1. App Icon (1024x1024 PNG)
**Location:** `assets/icons/finsight_icon.png`
- Use the hexagonal logo with arrow (icon only, no text)
- Should be 1024x1024 pixels
- Transparent background

### 2. Splash Screen Logo (512x512 PNG)
**Location:** `assets/icons/finsight_logo_splash.png`
- Can use either:
  - Hexagonal icon only (simpler)
  - Full logo with "FinSight" text (branded)
- Should be 512x512 pixels or larger
- Transparent background

### 3. Branding Image (Optional)
**Location:** `assets/images/finsight_branding.png`
- "FinSight" text logo (horizontal)
- Transparent background
- Recommended: 300x100 pixels

### 4. App Logo for UI (SVG or PNG)
**Location:** `assets/images/finsight_logo.png`
- Full logo with text
- Transparent background
- Used in app header/AppBar

## Current Setup

The provided logo files show:
1. **Icon**: Hexagonal shape with green-to-cyan gradient, containing horizontal lines and upward arrow
2. **Full Logo**: Same icon + "FinSight" text

## Color Scheme

Primary Colors:
- Green: #2E7D32 (darker green)
- Teal/Cyan: #00BCD4 (brighter cyan)
- Gradient: Green to Cyan

## Generating Icons

After placing logo files, run:
```bash
# Generate app icons
flutter pub run flutter_launcher_icons

# Generate splash screen
flutter pub run flutter_native_splash:create
```

## Notes

- The hexagonal icon with gradient is perfect for the app
- Represents financial growth (upward arrow) and organization (lines/data)
- Green color scheme aligns with financial/money theme
- Professional and modern design
