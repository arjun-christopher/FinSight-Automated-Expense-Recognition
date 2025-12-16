# Automated APK Build Script

This Python script automates the entire Flutter APK build process, handling all setup, error fixes, and build steps automatically.

## Features

✅ **Automated Setup**: Installs Flutter and Android SDK if missing  
✅ **Error Handling**: Automatically fixes common build issues  
✅ **Resource Fixes**: Handles launcher icon problems  
✅ **License Management**: Accepts Android SDK licenses automatically  
✅ **Clean Builds**: Option to clean previous builds  
✅ **Progress Tracking**: Clear visual feedback during build process

## Usage

### Basic Usage (Debug Build)
```bash
python3 build_apk.py
```

### Build Release APK
```bash
python3 build_apk.py --release
```

### Skip Cleaning Previous Build (Faster)
```bash
python3 build_apk.py --skip-clean
```

## What It Does Automatically

1. **Java Check**: Verifies Java 17 is installed
2. **Flutter Setup**: Installs/verifies Flutter SDK
3. **Android SDK Setup**: Installs/verifies Android command line tools
4. **SDK Components**: Installs platform-tools, build-tools, and Android platform
5. **License Acceptance**: Accepts all Android SDK licenses
6. **Icon Fixes**: Removes corrupted launcher icons and fixes references
7. **Flutter Configuration**: Configures Flutter to use Android SDK
8. **Build Cleaning**: Cleans previous build artifacts (optional)
9. **APK Build**: Builds the APK with error recovery

## Error Recovery

The script includes intelligent error recovery:

- **R8 Minification Errors**: Automatically falls back to debug build
- **Missing SDK**: Downloads and installs Android SDK
- **Corrupted Icons**: Removes and fixes icon references
- **License Issues**: Automatically accepts all licenses

## Output

After successful build, the APK will be located at:
```
build/app/outputs/flutter-apk/app-debug.apk
```

The script will display:
- ✓ APK location
- ✓ APK size
- ✓ Total build time
- 📋 Next steps for installation

## Requirements

- Python 3.6+
- Internet connection (for downloading Flutter/SDK on first run)
- ~2GB disk space (for Flutter and Android SDK)

## Installation Steps for Device

1. Right-click `app-debug.apk` in VS Code
2. Select "Download"
3. Transfer to your Android device
4. Install (will update existing app if already installed)

## Troubleshooting

If the script fails:

1. Check internet connection
2. Ensure sufficient disk space
3. Review error messages in the output
4. Try running with `--skip-clean` flag
5. For persistent issues, manually delete `/tmp/flutter` and `/tmp/android-sdk`

## Time Estimates

- **First Run**: 5-10 minutes (downloads Flutter and SDK)
- **Subsequent Runs**: 2-3 minutes
- **With --skip-clean**: 1-2 minutes

## Notes

- Debug builds are ~180MB
- Release builds require additional Play Core dependencies
- The script uses `/tmp` for Flutter and SDK (may be cleared on container restart)
