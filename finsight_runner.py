#!/usr/bin/env python3
"""
FinSight Automated App Runner & Builder
Complete solution for running and building the FinSight Flutter app
Handles setup, building, and running with all dependencies
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path
import time
import argparse

class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_banner():
    print(f"\n{Colors.BOLD}{Colors.OKCYAN}")
    print("╔═══════════════════════════════════════════════════════════╗")
    print("║        FinSight App - Complete Runner & Builder           ║")
    print("║        Automated Expense Recognition Application          ║")
    print("╚═══════════════════════════════════════════════════════════╝")
    print(f"{Colors.ENDC}\n")

def print_step(message):
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*65}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}► {message}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*65}{Colors.ENDC}\n")

def print_success(message):
    print(f"{Colors.OKGREEN}✓ {message}{Colors.ENDC}")

def print_warning(message):
    print(f"{Colors.WARNING}⚠ {message}{Colors.ENDC}")

def print_error(message):
    print(f"{Colors.FAIL}✗ {message}{Colors.ENDC}")

def print_info(message):
    print(f"{Colors.OKBLUE}ℹ {message}{Colors.ENDC}")

def run_command(cmd, shell=True, check=True, env=None, capture_output=False):
    """Run a shell command with error handling"""
    try:
        if capture_output:
            result = subprocess.run(cmd, shell=shell, check=check, env=env, 
                                   capture_output=True, text=True)
            return result.returncode == 0, result.stdout, result.stderr
        else:
            result = subprocess.run(cmd, shell=shell, check=check, env=env)
            return result.returncode == 0, "", ""
    except subprocess.CalledProcessError as e:
        return False, "", str(e)

class FinSightRunner:
    def __init__(self):
        self.project_dir = Path("/workspaces/FinSight-Automated-Expense-Recognition")
        self.flutter_dir = Path("/tmp/flutter")
        self.android_sdk_dir = Path("/tmp/android-sdk")
        self.java_home = Path("/usr/lib/jvm/java-17-openjdk-amd64")
        
        # Environment variables
        self.env = os.environ.copy()
        self.env['ANDROID_HOME'] = str(self.android_sdk_dir)
        self.env['JAVA_HOME'] = str(self.java_home)
        self.env['PATH'] = f"{self.flutter_dir}/bin:{self.android_sdk_dir}/cmdline-tools/latest/bin:{self.android_sdk_dir}/platform-tools:{self.android_sdk_dir}/emulator:{self.env.get('PATH', '')}"
        
    def check_java(self):
        """Check if Java 17 is installed"""
        print_step("Checking Java Installation")
        
        if not self.java_home.exists():
            print_warning("Java 17 not found, installing...")
            success, _, _ = run_command("apt-get update && apt-get install -y openjdk-17-jdk", env=self.env)
            if not success:
                print_error("Failed to install Java 17")
                return False
        
        success, stdout, _ = run_command("java -version", env=self.env, capture_output=True)
        if success:
            print_success(f"Java is installed")
        return success
    
    def setup_flutter(self):
        """Install or verify Flutter installation"""
        print_step("Setting Up Flutter SDK")
        
        if self.flutter_dir.exists():
            print_success("Flutter directory exists")
            # Verify it's working
            success, stdout, _ = run_command(f"{self.flutter_dir}/bin/flutter --version", 
                                           env=self.env, capture_output=True)
            if success:
                print_success("Flutter is working correctly")
                return True
            else:
                print_warning("Flutter directory exists but not working, reinstalling...")
                shutil.rmtree(self.flutter_dir)
        
        print_warning("Flutter not found, installing (this may take a few minutes)...")
        success, _, _ = run_command(
            f"git clone https://github.com/flutter/flutter.git -b stable --depth 1 {self.flutter_dir}",
            env=self.env
        )
        
        if not success:
            print_error("Failed to clone Flutter repository")
            return False
        
        print_success("Flutter SDK installed successfully")
        
        # Configure Flutter
        print_info("Configuring Flutter...")
        run_command(f"{self.flutter_dir}/bin/flutter config --no-analytics", env=self.env)
        run_command(f"{self.flutter_dir}/bin/flutter precache --android", env=self.env)
        
        return True
    
    def setup_android_sdk(self):
        """Install or verify Android SDK installation"""
        print_step("Setting Up Android SDK")
        
        cmdline_tools = self.android_sdk_dir / "cmdline-tools" / "latest"
        
        if cmdline_tools.exists():
            print_success("Android SDK command line tools exist")
            # Verify they work
            success, _, _ = run_command(
                f"{cmdline_tools}/bin/sdkmanager --version",
                env=self.env, capture_output=True
            )
            if success:
                print_success("Android SDK tools are working")
                return True
            else:
                print_warning("SDK tools exist but not working, reinstalling...")
                shutil.rmtree(self.android_sdk_dir, ignore_errors=True)
        
        print_warning("Android SDK not found, installing...")
        
        # Download command line tools
        sdk_url = "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
        sdk_zip = "/tmp/commandlinetools.zip"
        
        print_info("Downloading Android SDK...")
        success, _, _ = run_command(f"wget -q -O {sdk_zip} {sdk_url}", env=self.env)
        if not success:
            print_error("Failed to download Android SDK")
            return False
        
        # Extract to cmdline-tools/latest
        print_info("Extracting Android SDK...")
        cmdline_tools.mkdir(parents=True, exist_ok=True)
        success, _, _ = run_command(
            f"unzip -q {sdk_zip} -d /tmp/cmdline-tools-tmp && "
            f"mv /tmp/cmdline-tools-tmp/cmdline-tools/* {cmdline_tools}/ && "
            f"rm -rf /tmp/cmdline-tools-tmp {sdk_zip}",
            env=self.env
        )
        
        if not success:
            print_error("Failed to extract Android SDK")
            return False
        
        print_success("Android SDK command line tools installed")
        return True
    
    def install_sdk_components(self):
        """Install required Android SDK components"""
        print_step("Installing Android SDK Components")
        
        sdkmanager = self.android_sdk_dir / "cmdline-tools" / "latest" / "bin" / "sdkmanager"
        
        # Accept licenses first
        print_info("Accepting SDK licenses...")
        license_cmd = f"yes | {sdkmanager} --licenses"
        run_command(license_cmd, env=self.env)
        
        # Install required components
        components = [
            "platform-tools",
            "platforms;android-34",
            "build-tools;34.0.0"
        ]
        
        print_info(f"Installing SDK components...")
        quoted_components = ' '.join([f'"{comp}"' for comp in components])
        install_cmd = f'{sdkmanager} {quoted_components}'
        success, _, _ = run_command(install_cmd, env=self.env)
        
        if success:
            print_success("Android SDK components installed successfully")
        else:
            print_error("Failed to install some SDK components")
        
        return success
    
    def configure_flutter_sdk(self):
        """Configure Flutter to use the Android SDK"""
        print_step("Configuring Flutter SDK")
        
        flutter_bin = self.flutter_dir / "bin" / "flutter"
        success, _, _ = run_command(
            f"{flutter_bin} config --android-sdk {self.android_sdk_dir}",
            env=self.env
        )
        
        if success:
            print_success("Flutter configured with Android SDK")
        return success
    
    def get_flutter_dependencies(self):
        """Get Flutter dependencies"""
        print_step("Installing Flutter Dependencies")
        
        flutter_bin = self.flutter_dir / "bin" / "flutter"
        print_info("Running flutter pub get...")
        success, _, _ = run_command(
            f"cd {self.project_dir} && {flutter_bin} pub get",
            env=self.env
        )
        
        if success:
            print_success("Dependencies installed")
        return success
    
    def clean_build(self):
        """Clean previous build artifacts"""
        print_step("Cleaning Previous Build")
        
        flutter_bin = self.flutter_dir / "bin" / "flutter"
        run_command(f"cd {self.project_dir} && {flutter_bin} clean", env=self.env)
        
        # Also clean Android build
        android_build = self.project_dir / "android" / "app" / "build"
        if android_build.exists():
            shutil.rmtree(android_build, ignore_errors=True)
        
        print_success("Build cleaned")
        return True
    
    def check_connected_devices(self):
        """Check for connected Android devices"""
        print_step("Checking for Connected Devices")
        
        adb = self.android_sdk_dir / "platform-tools" / "adb"
        success, stdout, _ = run_command(f"{adb} devices -l", env=self.env, capture_output=True)
        
        if success and stdout:
            lines = stdout.strip().split('\n')
            devices = [line for line in lines[1:] if line.strip() and not line.startswith('*')]
            
            if devices:
                print_success(f"Found {len(devices)} connected device(s):")
                for device in devices:
                    print(f"  • {device}")
                return True, len(devices)
            else:
                print_warning("No devices found")
                print_info("Make sure your device is:")
                print_info("  1. Connected via USB")
                print_info("  2. USB debugging is enabled")
                print_info("  3. Device is unlocked")
                return False, 0
        return False, 0
    
    def run_app(self):
        """Run the app on a connected device"""
        print_step("Running App on Device")
        
        # Check for devices first
        has_device, count = self.check_connected_devices()
        
        if not has_device:
            print_error("No devices connected. Cannot run app.")
            print_info("\nAlternatives:")
            print_info("  1. Connect a device and try again")
            print_info("  2. Build an APK and install manually")
            return False
        
        flutter_bin = self.flutter_dir / "bin" / "flutter"
        print_info("Starting app (this may take a minute)...")
        print_info("Press Ctrl+C to stop the app")
        
        # Run in foreground so user can see logs
        success, _, _ = run_command(
            f"cd {self.project_dir} && {flutter_bin} run",
            env=self.env,
            check=False  # Don't raise on Ctrl+C
        )
        
        return success
    
    def build_apk(self, build_type="debug"):
        """Build the Flutter APK"""
        print_step(f"Building {build_type.upper()} APK")
        
        flutter_bin = self.flutter_dir / "bin" / "flutter"
        
        # Build command
        if build_type == "release":
            build_cmd = f"cd {self.project_dir} && {flutter_bin} build apk --release"
        else:
            build_cmd = f"cd {self.project_dir} && {flutter_bin} build apk --debug"
        
        print_info("Building APK (this may take several minutes)...")
        success, stdout, stderr = run_command(build_cmd, env=self.env, capture_output=True)
        
        if success:
            apk_path = self.project_dir / "build" / "app" / "outputs" / "flutter-apk" / f"app-{build_type}.apk"
            if apk_path.exists():
                size = apk_path.stat().st_size / (1024 * 1024)  # Convert to MB
                print_success(f"APK built successfully!")
                print_success(f"Location: {apk_path}")
                print_success(f"Size: {size:.1f} MB")
                return True, apk_path
            else:
                print_error("APK file not found after build")
                return False, None
        else:
            print_error("Build failed")
            if "R8" in stderr or "minify" in stderr.lower():
                print_warning("R8 minification failed, trying debug build instead...")
                return self.build_apk("debug")
            if stderr:
                print(f"\nError details:\n{stderr[:500]}")
            return False, None
    
    def install_apk(self, apk_path):
        """Install APK on connected device"""
        print_step("Installing APK on Device")
        
        has_device, _ = self.check_connected_devices()
        if not has_device:
            print_error("No device connected for installation")
            return False
        
        adb = self.android_sdk_dir / "platform-tools" / "adb"
        print_info(f"Installing {apk_path.name}...")
        
        success, _, stderr = run_command(
            f"{adb} install -r {apk_path}",
            env=self.env,
            capture_output=True
        )
        
        if success:
            print_success("APK installed successfully!")
            print_info("You can now launch the app from your device")
            return True
        else:
            print_error(f"Installation failed: {stderr}")
            return False
    
    def run_setup(self):
        """Run initial setup"""
        print_banner()
        
        steps = [
            ("Checking Java", self.check_java),
            ("Setting up Flutter", self.setup_flutter),
            ("Setting up Android SDK", self.setup_android_sdk),
            ("Installing SDK components", self.install_sdk_components),
            ("Configuring Flutter", self.configure_flutter_sdk),
            ("Getting dependencies", self.get_flutter_dependencies),
        ]
        
        for step_name, step_func in steps:
            try:
                if not step_func():
                    print_error(f"Setup failed at: {step_name}")
                    return False
            except Exception as e:
                print_error(f"Exception in {step_name}: {str(e)}")
                return False
        
        print(f"\n{Colors.OKGREEN}{Colors.BOLD}")
        print("╔═══════════════════════════════════════════════════════════╗")
        print("║              SETUP COMPLETED SUCCESSFULLY!                ║")
        print("╚═══════════════════════════════════════════════════════════╝")
        print(f"{Colors.ENDC}\n")
        
        return True
    
    def interactive_menu(self):
        """Show interactive menu for user action"""
        print_banner()
        print(f"{Colors.BOLD}Select an action:{Colors.ENDC}\n")
        print("  1. Run app on connected device (debug mode)")
        print("  2. Build debug APK")
        print("  3. Build release APK")
        print("  4. Build and install debug APK")
        print("  5. Run initial setup/verify installation")
        print("  6. Clean build and rebuild debug APK")
        print("  0. Exit")
        print()
        
        choice = input(f"{Colors.OKCYAN}Enter choice (1-6, 0 to exit): {Colors.ENDC}").strip()
        return choice

def main():
    parser = argparse.ArgumentParser(
        description='FinSight App Runner & Builder - Complete automation tool'
    )
    parser.add_argument('--setup', action='store_true',
                       help='Run initial setup only')
    parser.add_argument('--run', action='store_true',
                       help='Run app on connected device')
    parser.add_argument('--build', choices=['debug', 'release'],
                       help='Build APK (debug or release)')
    parser.add_argument('--install', action='store_true',
                       help='Install APK after building (requires --build)')
    parser.add_argument('--clean', action='store_true',
                       help='Clean build before building')
    parser.add_argument('--interactive', action='store_true',
                       help='Show interactive menu')
    
    args = parser.parse_args()
    
    runner = FinSightRunner()
    start_time = time.time()
    
    # If no arguments, show interactive menu
    if len(sys.argv) == 1 or args.interactive:
        while True:
            choice = runner.interactive_menu()
            
            if choice == '0':
                print_info("Exiting...")
                sys.exit(0)
            elif choice == '1':
                # Run on device
                if not runner.run_app():
                    print_error("Failed to run app")
                input(f"\n{Colors.OKCYAN}Press Enter to continue...{Colors.ENDC}")
            elif choice == '2':
                # Build debug APK
                success, apk_path = runner.build_apk("debug")
                if not success:
                    print_error("Build failed")
                input(f"\n{Colors.OKCYAN}Press Enter to continue...{Colors.ENDC}")
            elif choice == '3':
                # Build release APK
                success, apk_path = runner.build_apk("release")
                if not success:
                    print_error("Build failed")
                input(f"\n{Colors.OKCYAN}Press Enter to continue...{Colors.ENDC}")
            elif choice == '4':
                # Build and install
                success, apk_path = runner.build_apk("debug")
                if success and apk_path:
                    runner.install_apk(apk_path)
                input(f"\n{Colors.OKCYAN}Press Enter to continue...{Colors.ENDC}")
            elif choice == '5':
                # Setup
                runner.run_setup()
                input(f"\n{Colors.OKCYAN}Press Enter to continue...{Colors.ENDC}")
            elif choice == '6':
                # Clean and rebuild
                runner.clean_build()
                success, apk_path = runner.build_apk("debug")
                input(f"\n{Colors.OKCYAN}Press Enter to continue...{Colors.ENDC}")
            else:
                print_error("Invalid choice")
                time.sleep(1)
    else:
        # Command line mode
        success = True
        
        if args.setup:
            success = runner.run_setup()
        
        if success and args.clean:
            runner.clean_build()
        
        if success and args.build:
            success, apk_path = runner.build_apk(args.build)
            
            if success and args.install and apk_path:
                runner.install_apk(apk_path)
        
        if success and args.run:
            success = runner.run_app()
        
        elapsed_time = time.time() - start_time
        print(f"\n⏱️  Total time: {elapsed_time:.1f} seconds")
        
        sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
