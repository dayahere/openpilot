#!/usr/bin/env python3
"""
Test Runner - Runs all tests and generates coverage reports
"""

import os
import sys
import subprocess
from pathlib import Path

def run_command(cmd, cwd=None):
    """Run a command and return success status"""
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            cwd=cwd,
            capture_output=True,
            text=True
        )
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

def main():
    root = Path(__file__).parent.parent
    
    print("🧪 Running OpenPilot Test Suite...\n")
    
    # Core tests
    print("📦 Testing Core...")
    success, stdout, stderr = run_command("npm test", cwd=root / "core")
    if success:
        print("✅ Core tests passed")
    else:
        print(f"❌ Core tests failed:\n{stderr}")
    
    # Extension tests
    print("\n🔌 Testing VS Code Extension...")
    success, stdout, stderr = run_command("npm test", cwd=root / "vscode-extension")
    if success:
        print("✅ Extension tests passed")
    else:
        print(f"❌ Extension tests failed:\n{stderr}")
    
    # Desktop tests
    print("\n💻 Testing Desktop App...")
    success, stdout, stderr = run_command("npm test", cwd=root / "desktop")
    if success:
        print("✅ Desktop tests passed")
    else:
        print(f"❌ Desktop tests failed:\n{stderr}")
    
    # Coverage report
    print("\n📊 Generating Coverage Report...")
    run_command("npm run test:coverage", cwd=root / "core")
    
    print("\n✅ Test suite complete!")

if __name__ == "__main__":
    main()
