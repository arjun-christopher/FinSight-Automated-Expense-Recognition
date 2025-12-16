#!/usr/bin/env python3
"""
Automated Flutter APK Build Script
Handles Flutter and Android SDK setup, fixes common issues, and builds APK
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path
import time

class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_step(message):
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}► {message}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}\n")

def print_success(message):
    print(f"{Colors.OKGREEN}✓ {message}{Colors.ENDC}")

def print_warning(message):
    print(f"{Colors.WARNING}⚠ {message}{Colors.ENDC}")

def print_error(message):
    print(f"{Colors.FAIL}✗ {message}{Colors.ENDC}")

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

class FlutterAPKBuilder:
    def __init__(self):
        self.project_dir = Path("/workspaces/FinSight-Automated-Expense-Recognition")
        self.flutter_dir = Path("/tmp/flutter")
        self.android_sdk_dir = Path("/tmp/android-sdk")
        self.java_home = Path("/usr/lib/jvm/java-17-openjdk-amd64")
        
        # Environment variables
        self.env = os.environ.copy()
        self.env['ANDROID_HOME'] = str(self.android_sdk_dir)
        self.env['JAVA_HOME'] = str(self.java_home)
        self.env['PATH'] = f"{self.flutter_dir}/bin:{self.android_sdk_dir}/cmdline-tools/latest/bin:{self.android_sdk_dir}/platform-tools:{self.env.get('PATH', '')}"
        
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
            print_success(f"Java is installed: {stdout.split()[0] if stdout else 'Java 17'}")
        return success
    
    def setup_flutter(self):
        """Install or verify Flutter installation"""
        print_step("Setting Up Flutter")
        
        if self.flutter_dir.exists():
            print_success("Flutter directory exists")
            # Verify it's working
            success, _, _ = run_command(f"{self.flutter_dir}/bin/flutter --version", 
                                       env=self.env, capture_output=True)
            if success:
                print_success("Flutter is working")
                return True
            else:
                print_warning("Flutter directory exists but not working, reinstalling...")
                shutil.rmtree(self.flutter_dir)
        
        print_warning("Flutter not found, installing...")
        success, _, _ = run_command(
            f"git clone https://github.com/flutter/flutter.git -b stable --depth 1 {self.flutter_dir}",
            env=self.env
        )
        
        if not success:
            print_error("Failed to clone Flutter")
            return False
        
        print_success("Flutter installed successfully")
        
        # Configure Flutter
        run_command(f"{self.flutter_dir}/bin/flutter config --no-analytics", env=self.env)
        run_command(f"{self.flutter_dir}/bin/flutter precache", env=self.env)
        
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
        
        success, _, _ = run_command(f"wget -O {sdk_zip} {sdk_url}", env=self.env)
        if not success:
            print_error("Failed to download Android SDK")
            return False
        
        # Extract to cmdline-tools/latest
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
        print("Accepting SDK licenses...")
        license_cmd = f"yes | {sdkmanager} --licenses"
        run_command(license_cmd, env=self.env)
        
        # Install required components
        components = [
            "platform-tools",
            "platforms;android-34",
            "build-tools;34.0.0"
        ]
        
        print(f"Installing components: {', '.join(components)}")
        # Quote each component to handle semicolons properly
        quoted_components = ' '.join([f'"{comp}"' for comp in components])
        install_cmd = f'{sdkmanager} {quoted_components}'
        success, _, _ = run_command(install_cmd, env=self.env)
        
        if success:
            print_success("Android SDK components installed")
        else:
            print_error("Failed to install some SDK components")
        
        return success
    
    def fix_launcher_icons(self):
        """Fix launcher icon issues"""
        print_step("Fixing Launcher Icons")
        
        res_dir = self.project_dir / "android" / "app" / "src" / "main" / "res"
        
        # Remove mipmap directories with corrupted PNGs
        for mipmap_dir in res_dir.glob("mipmap-*"):
            if mipmap_dir.is_dir():
                print(f"Removing {mipmap_dir.name}...")
                shutil.rmtree(mipmap_dir)
        
        # Fix widget layout to use drawable instead of mipmap
        widget_layout = res_dir / "layout" / "expense_widget.xml"
        if widget_layout.exists():
            content = widget_layout.read_text()
            if "@mipmap/ic_launcher" in content:
                print("Fixing widget layout icon reference...")
                content = content.replace("@mipmap/ic_launcher", "@drawable/ic_launcher")
                widget_layout.write_text(content)
        
        print_success("Launcher icons fixed")
        return True
    
    def configure_flutter_sdk(self):
        """Configure Flutter to use the Android SDK"""
        print_step("Configuring Flutter SDK")
        
        flutter_bin = self.flutter_dir / "bin" / "flutter"
        success, _, _ = run_command(
            f"{flutter_bin} config --android-sdk {self.android_sdk_dir}",
            env=self.env
        )
        
        if success:
            print_success("Flutter configured")
        return success
    
    def clean_build(self):
        """Clean previous build artifacts"""
        print_step("Cleaning Previous Build")
        
        flutter_bin = self.flutter_dir / "bin" / "flutter"
        run_command(f"cd {self.project_dir} && {flutter_bin} clean", env=self.env)
        
        # Also clean Android build
        android_build = self.project_dir / "android" / "app" / "build"
        if android_build.exists():
            shutil.rmtree(android_build)
        
        print_success("Build cleaned")
        return True
    
    def build_apk(self, build_type="debug"):
        """Build the Flutter APK"""
        print_step(f"Building {build_type.upper()} APK")
        
        flutter_bin = self.flutter_dir / "bin" / "flutter"
        
        # Build command
        if build_type == "release":
            build_cmd = f"cd {self.project_dir} && {flutter_bin} build apk"
        else:
            build_cmd = f"cd {self.project_dir} && {flutter_bin} build apk --debug"
        
        print("This may take a few minutes...")
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
            print(f"\nError output:\n{stderr}")
            return False, None
    
    def run(self, build_type="debug", skip_clean=False):
        """Main execution flow"""
        print(f"\n{Colors.BOLD}{Colors.OKCYAN}")
        print("╔════════════════════════════════════════════════════════╗")
        print("║     Flutter APK Automated Build Script                ║")
        print("║     FinSight Expense Recognition App                   ║")
        print("╚════════════════════════════════════════════════════════╝")
        print(f"{Colors.ENDC}\n")
        
        start_time = time.time()
        
        steps = [
            ("Checking Java", self.check_java),
            ("Setting up Flutter", self.setup_flutter),
            ("Setting up Android SDK", self.setup_android_sdk),
            ("Installing SDK components", self.install_sdk_components),
            ("Fixing launcher icons", self.fix_launcher_icons),
            ("Configuring Flutter", self.configure_flutter_sdk),
        ]
        
        if not skip_clean:
            steps.append(("Cleaning build", self.clean_build))
        
        # Execute setup steps
        for step_name, step_func in steps:
            try:
                if not step_func():
                    print_error(f"Failed at step: {step_name}")
                    return False
            except Exception as e:
                print_error(f"Exception in {step_name}: {str(e)}")
                return False
        
        # Build APK
        try:
            success, apk_path = self.build_apk(build_type)
            if not success:
                return False
            
            elapsed_time = time.time() - start_time
            print(f"\n{Colors.BOLD}{Colors.OKGREEN}")
            print("╔════════════════════════════════════════════════════════╗")
            print("║              BUILD COMPLETED SUCCESSFULLY!             ║")
            print("╚════════════════════════════════════════════════════════╝")
            print(f"{Colors.ENDC}")
            print(f"\n⏱️  Total time: {elapsed_time:.1f} seconds")
            print(f"\n📱 APK Location: {apk_path}")
            print("\n📋 Next Steps:")
            print("   1. Right-click the APK in VS Code and select 'Download'")
            print("   2. Transfer to your Android device")
            print("   3. Install/Update the app")
            
            return True
            
        except Exception as e:
            print_error(f"Exception during build: {str(e)}")
            return False

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Automated Flutter APK Builder')
    parser.add_argument('--release', action='store_true', 
                       help='Build release APK (default: debug)')
    parser.add_argument('--skip-clean', action='store_true',
                       help='Skip cleaning previous build')
    
    args = parser.parse_args()
    
    build_type = "release" if args.release else "debug"
    
    builder = FlutterAPKBuilder()
    success = builder.run(build_type=build_type, skip_clean=args.skip_clean)
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
