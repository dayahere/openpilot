#!/usr/bin/env python3
"""
Auto-fix script for OpenPilot
Runs linters, formatters, and tests, then attempts to fix any issues found.
"""

import subprocess
import sys
import os
from pathlib import Path

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

def run_command(command, cwd=None):
    """Run a shell command and return the result."""
    print(f"{Colors.BLUE}Running: {command}{Colors.END}")
    try:
        result = subprocess.run(
            command,
            shell=True,
            cwd=cwd,
            capture_output=True,
            text=True
        )
        return result
    except Exception as e:
        print(f"{Colors.RED}Error running command: {e}{Colors.END}")
        return None

def check_python_code():
    """Check and fix Python code quality."""
    print(f"\n{Colors.BLUE}{'='*60}{Colors.END}")
    print(f"{Colors.BLUE}Checking Python Code{Colors.END}")
    print(f"{Colors.BLUE}{'='*60}{Colors.END}\n")
    
    # Find Python files
    python_files = list(Path('.').rglob('*.py'))
    if not python_files:
        print(f"{Colors.YELLOW}No Python files found{Colors.END}")
        return True
    
    # Format with black
    print(f"{Colors.BLUE}Formatting with black...{Colors.END}")
    result = run_command('black .')
    if result and result.returncode == 0:
        print(f"{Colors.GREEN}✓ Black formatting complete{Colors.END}")
    else:
        print(f"{Colors.RED}✗ Black formatting failed{Colors.END}")
    
    # Sort imports
    print(f"{Colors.BLUE}Sorting imports with isort...{Colors.END}")
    result = run_command('isort .')
    if result and result.returncode == 0:
        print(f"{Colors.GREEN}✓ Import sorting complete{Colors.END}")
    else:
        print(f"{Colors.RED}✗ Import sorting failed{Colors.END}")
    
    # Run flake8
    print(f"{Colors.BLUE}Checking with flake8...{Colors.END}")
    result = run_command('flake8 . --max-line-length=100 --extend-ignore=E203,W503')
    if result and result.returncode == 0:
        print(f"{Colors.GREEN}✓ Flake8 checks passed{Colors.END}")
        return True
    else:
        print(f"{Colors.YELLOW}⚠ Flake8 found issues:{Colors.END}")
        if result:
            print(result.stdout)
        return False

def check_typescript_code():
    """Check and fix TypeScript code quality."""
    print(f"\n{Colors.BLUE}{'='*60}{Colors.END}")
    print(f"{Colors.BLUE}Checking TypeScript Code{Colors.END}")
    print(f"{Colors.BLUE}{'='*60}{Colors.END}\n")
    
    # Format with prettier
    print(f"{Colors.BLUE}Formatting with prettier...{Colors.END}")
    result = run_command('npm run format:all')
    if result and result.returncode == 0:
        print(f"{Colors.GREEN}✓ Prettier formatting complete{Colors.END}")
    else:
        print(f"{Colors.RED}✗ Prettier formatting failed{Colors.END}")
    
    # Run ESLint with auto-fix
    print(f"{Colors.BLUE}Checking with ESLint...{Colors.END}")
    
    projects = ['core', 'vscode-extension', 'desktop', 'web']
    all_passed = True
    
    for project in projects:
        project_path = Path(project)
        if project_path.exists():
            print(f"{Colors.BLUE}Linting {project}...{Colors.END}")
            result = run_command(f'npm run lint --fix', cwd=project)
            if result and result.returncode == 0:
                print(f"{Colors.GREEN}✓ {project} lint passed{Colors.END}")
            else:
                print(f"{Colors.YELLOW}⚠ {project} has lint issues{Colors.END}")
                all_passed = False
    
    return all_passed

def run_tests():
    """Run all tests."""
    print(f"\n{Colors.BLUE}{'='*60}{Colors.END}")
    print(f"{Colors.BLUE}Running Tests{Colors.END}")
    print(f"{Colors.BLUE}{'='*60}{Colors.END}\n")
    
    # Python tests
    if Path('pytest.ini').exists() or any(Path('.').rglob('test_*.py')):
        print(f"{Colors.BLUE}Running Python tests...{Colors.END}")
        result = run_command('pytest --tb=short')
        if result and result.returncode == 0:
            print(f"{Colors.GREEN}✓ Python tests passed{Colors.END}")
        else:
            print(f"{Colors.RED}✗ Python tests failed{Colors.END}")
            if result:
                print(result.stdout)
            return False
    
    # TypeScript tests
    print(f"{Colors.BLUE}Running TypeScript tests...{Colors.END}")
    result = run_command('npm run test:all')
    if result and result.returncode == 0:
        print(f"{Colors.GREEN}✓ TypeScript tests passed{Colors.END}")
        return True
    else:
        print(f"{Colors.RED}✗ TypeScript tests failed{Colors.END}")
        if result:
            print(result.stdout)
        return False

def check_dependencies():
    """Check if all dependencies are installed."""
    print(f"\n{Colors.BLUE}{'='*60}{Colors.END}")
    print(f"{Colors.BLUE}Checking Dependencies{Colors.END}")
    print(f"{Colors.BLUE}{'='*60}{Colors.END}\n")
    
    # Check Node modules
    if not Path('node_modules').exists():
        print(f"{Colors.YELLOW}Installing Node.js dependencies...{Colors.END}")
        result = run_command('npm install')
        if result and result.returncode == 0:
            print(f"{Colors.GREEN}✓ Node.js dependencies installed{Colors.END}")
        else:
            print(f"{Colors.RED}✗ Failed to install Node.js dependencies{Colors.END}")
            return False
    
    # Check Python packages
    print(f"{Colors.BLUE}Checking Python dependencies...{Colors.END}")
    result = run_command('pip install -r requirements.txt')
    if result and result.returncode == 0:
        print(f"{Colors.GREEN}✓ Python dependencies installed{Colors.END}")
        return True
    else:
        print(f"{Colors.RED}✗ Failed to install Python dependencies{Colors.END}")
        return False

def build_projects():
    """Build all projects."""
    print(f"\n{Colors.BLUE}{'='*60}{Colors.END}")
    print(f"{Colors.BLUE}Building Projects{Colors.END}")
    print(f"{Colors.BLUE}{'='*60}{Colors.END}\n")
    
    result = run_command('npm run build:all')
    if result and result.returncode == 0:
        print(f"{Colors.GREEN}✓ Build successful{Colors.END}")
        return True
    else:
        print(f"{Colors.RED}✗ Build failed{Colors.END}")
        if result:
            print(result.stdout)
            print(result.stderr)
        return False

def main():
    """Main auto-fix pipeline."""
    print(f"\n{Colors.BLUE}{'='*60}{Colors.END}")
    print(f"{Colors.BLUE}OpenPilot Auto-Fix & Quality Check{Colors.END}")
    print(f"{Colors.BLUE}{'='*60}{Colors.END}\n")
    
    steps = [
        ("Checking Dependencies", check_dependencies),
        ("Checking Python Code", check_python_code),
        ("Checking TypeScript Code", check_typescript_code),
        ("Building Projects", build_projects),
        ("Running Tests", run_tests),
    ]
    
    results = []
    for step_name, step_func in steps:
        try:
            result = step_func()
            results.append((step_name, result))
        except Exception as e:
            print(f"{Colors.RED}✗ {step_name} failed with error: {e}{Colors.END}")
            results.append((step_name, False))
    
    # Summary
    print(f"\n{Colors.BLUE}{'='*60}{Colors.END}")
    print(f"{Colors.BLUE}Summary{Colors.END}")
    print(f"{Colors.BLUE}{'='*60}{Colors.END}\n")
    
    all_passed = True
    for step_name, result in results:
        status = f"{Colors.GREEN}✓ PASSED{Colors.END}" if result else f"{Colors.RED}✗ FAILED{Colors.END}"
        print(f"{step_name}: {status}")
        if not result:
            all_passed = False
    
    if all_passed:
        print(f"\n{Colors.GREEN}{'='*60}{Colors.END}")
        print(f"{Colors.GREEN}All checks passed! 🎉{Colors.END}")
        print(f"{Colors.GREEN}{'='*60}{Colors.END}\n")
        return 0
    else:
        print(f"\n{Colors.YELLOW}{'='*60}{Colors.END}")
        print(f"{Colors.YELLOW}Some checks failed. Please review the errors above.{Colors.END}")
        print(f"{Colors.YELLOW}{'='*60}{Colors.END}\n")
        return 1

if __name__ == '__main__':
    sys.exit(main())
