# FinSight Runner - Complete Automation Tool

The `finsight_runner.py` script is a comprehensive automation tool that handles everything needed to build and run the FinSight app, from initial setup to deployment.

## Features

✅ **Complete Setup Automation**
- Java 17 installation and verification
- Flutter SDK download and configuration
- Android SDK installation
- Required SDK components installation
- Dependency management

✅ **Multiple Run Modes**
- Run on connected Android device
- Build debug APK
- Build release APK
- Install APK directly to device
- Clean builds

✅ **Interactive Menu**
- User-friendly menu interface
- Step-by-step guidance
- Error handling and recovery suggestions

✅ **Command Line Interface**
- Scriptable for CI/CD pipelines
- Flexible command combinations
- Progress reporting

## Quick Start

### Interactive Mode (Recommended for First Time)

Simply run without arguments to get an interactive menu:

```bash
python3 finsight_runner.py
```

Or explicitly:

```bash
python3 finsight_runner.py --interactive
```

This will show you a menu with options:
1. Run app on connected device (debug mode)
2. Build debug APK
3. Build release APK
4. Build and install debug APK
5. Run initial setup/verify installation
6. Clean build and rebuild debug APK
0. Exit

### Command Line Mode

#### Initial Setup
Run this first to install all dependencies:

```bash
python3 finsight_runner.py --setup
```

#### Run on Device
Connect your Android device and run:

```bash
python3 finsight_runner.py --run
```

#### Build Debug APK
```bash
python3 finsight_runner.py --build debug
```

#### Build Release APK
```bash
python3 finsight_runner.py --build release
```

#### Build and Install on Device
```bash
python3 finsight_runner.py --build debug --install
```

#### Clean Build
```bash
python3 finsight_runner.py --clean --build debug
```

## Common Workflows

### First Time Setup
```bash
# 1. Run setup
python3 finsight_runner.py --setup

# 2. Build and test
python3 finsight_runner.py --build debug --install
```

### Development Cycle
```bash
# Quick test on device
python3 finsight_runner.py --run

# Or build and install after changes
python3 finsight_runner.py --clean --build debug --install
```

### Release Build
```bash
# Clean build for release
python3 finsight_runner.py --clean --build release
```

## Requirements

- **Python 3.6+**: Should be pre-installed
- **Internet Connection**: Required for initial setup
- **USB Cable**: For running on physical device
- **USB Debugging**: Must be enabled on Android device

## Device Connection

### Enable USB Debugging on Android:

1. Go to **Settings** → **About Phone**
2. Tap **Build Number** 7 times to enable Developer Options
3. Go back to **Settings** → **Developer Options**
4. Enable **USB Debugging**
5. Connect device via USB and accept the authorization prompt

### Verify Device Connection:

The script will automatically check for connected devices. If you see "No devices found", make sure:
- Device is connected via USB
- USB debugging is enabled
- Device is unlocked
- You've accepted the computer authorization on your device

## Troubleshooting

### Build Fails

Try a clean build:
```bash
python3 finsight_runner.py --clean --build debug
```

### Dependencies Out of Date

Re-run setup:
```bash
python3 finsight_runner.py --setup
```

### Device Not Detected

1. Check USB cable connection
2. Verify USB debugging is enabled
3. Unlock your device
4. Try running: `adb devices` manually to see if device appears
5. Try revoking USB debugging authorizations on device and reconnecting

### Flutter/Android SDK Issues

The script automatically downloads and configures:
- Flutter SDK to `/tmp/flutter`
- Android SDK to `/tmp/android-sdk`

If issues persist, delete these directories and run setup again:
```bash
rm -rf /tmp/flutter /tmp/android-sdk
python3 finsight_runner.py --setup
```

## Output Locations

### Debug APK
```
build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK
```
build/app/outputs/flutter-apk/app-release.apk
```

## Environment Variables

The script automatically sets:
- `ANDROID_HOME=/tmp/android-sdk`
- `JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64`
- `PATH` includes Flutter and Android SDK tools

## Script Options Reference

| Option | Description |
|--------|-------------|
| `--setup` | Run initial setup and install all dependencies |
| `--run` | Run app on connected device in debug mode |
| `--build {debug,release}` | Build APK (specify debug or release) |
| `--install` | Install built APK on device (use with --build) |
| `--clean` | Clean previous build artifacts before building |
| `--interactive` | Show interactive menu |
| `-h, --help` | Show help message |

## Combining Options

You can combine multiple options:

```bash
# Clean, build debug, and install
python3 finsight_runner.py --clean --build debug --install

# Setup, then build release
python3 finsight_runner.py --setup --build release

# Clean and run on device
python3 finsight_runner.py --clean --run
```

## Alternative Solutions

### Manual Flutter Commands

If you prefer manual control:

```bash
# Get dependencies
/tmp/flutter/bin/flutter pub get

# Run on device
/tmp/flutter/bin/flutter run

# Build APK
/tmp/flutter/bin/flutter build apk --debug
```

### Using Android Studio

1. Open the project in Android Studio
2. Let Gradle sync
3. Click Run button or use Build → Build APK

### Direct ADB Installation

If you have an APK file:

```bash
/tmp/android-sdk/platform-tools/adb install -r path/to/app.apk
```

## CI/CD Integration

The script is perfect for CI/CD pipelines:

```bash
# In your CI script
python3 finsight_runner.py --setup --build release
```

Exit codes:
- `0` = Success
- `1` = Failure

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review logs for specific error messages
3. Ensure all prerequisites are met
4. Try a clean setup: delete `/tmp/flutter` and `/tmp/android-sdk`, then run `--setup` again

## Features Not Working?

If app features like notifications, exports, or backup aren't working:
1. Make sure you've built the latest version
2. Uninstall the old app from your device first
3. Run: `python3 finsight_runner.py --clean --build debug --install`
4. Check app permissions in device settings

---

**Happy Building! 🚀**
