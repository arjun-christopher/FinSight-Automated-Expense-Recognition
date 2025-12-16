#!/bin/bash

# FinSight App Runner Script
# This script sets up the environment and runs the Flutter app

# Set up environment variables
export PATH="$PATH:/tmp/flutter/bin:/tmp/android-sdk/platform-tools:/tmp/android-sdk/emulator"
export ANDROID_HOME=/tmp/android-sdk

echo "🚀 FinSight App Runner"
echo "====================="
echo ""

# Check for connected devices
echo "📱 Checking for connected devices..."
adb devices -l

echo ""
echo "Available options:"
echo "1. Run on connected device (default)"
echo "2. Build APK for manual installation"
echo "3. Build release APK (signed)"
echo ""

# Navigate to project directory
cd /workspaces/FinSight-Automated-Expense-Recognition

# Default: Run on connected device
read -p "Select option (1-3, default 1): " choice
choice=${choice:-1}

case $choice in
    1)
        echo ""
        echo "🏃 Running app on connected device..."
        echo "Make sure your device is connected and USB debugging is enabled!"
        echo ""
        flutter run
        ;;
    2)
        echo ""
        echo "🔨 Building debug APK..."
        flutter build apk --debug
        echo ""
        echo "✅ APK built successfully!"
        echo "📦 Location: build/app/outputs/flutter-apk/app-debug.apk"
        echo ""
        echo "To install on device:"
        echo "  adb install build/app/outputs/flutter-apk/app-debug.apk"
        ;;
    3)
        echo ""
        echo "🔨 Building release APK..."
        flutter build apk --release
        echo ""
        echo "✅ APK built successfully!"
        echo "📦 Location: build/app/outputs/flutter-apk/app-release.apk"
        echo ""
        echo "To install on device:"
        echo "  adb install build/app/outputs/flutter-apk/app-release.apk"
        ;;
    *)
        echo "Invalid option selected."
        exit 1
        ;;
esac
