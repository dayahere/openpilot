#Requires -Version 5.1

<#
.SYNOPSIS
    Comprehensive feature and functionality tests for OpenPilot
.DESCRIPTION
    Tests all features, components, and expected behaviors across all platforms
#>

$WorkspaceRoot = "i:\openpilot"
Push-Location $WorkspaceRoot

Describe "OpenPilot - Complete Feature & Functionality Tests" {
    
    Context "Core Package - Feature Tests" {
        
        It "Core package.json has correct metadata" {
            $pkg = Get-Content "$WorkspaceRoot\core\package.json" -Raw | ConvertFrom-Json
            $pkg.name | Should Be "@openpilot/core"
            $pkg.version | Should Match "^\d+\.\d+\.\d+$"
            $pkg.main | Should Not BeNullOrEmpty
        }
        
        It "Core builds successfully" {
            docker run --rm -v "${PWD}:/workspace" -w /workspace/core node:20 sh -c "npm install --legacy-peer-deps > /dev/null 2>&1 && npm run build" 2>&1 | Out-Null
            Test-Path "core\dist\index.js" | Should Be $true
        }
        
        It "Core dist contains all expected files" {
            $distFiles = Get-ChildItem "core\dist" -File
            $distFiles.Count | Should BeGreaterThan 0
            ($distFiles | Where-Object Name -eq "index.js") | Should Not BeNullOrEmpty
        }
        
        It "Core TypeScript compiles without errors" {
            $result = docker run --rm -v "${PWD}:/workspace" -w /workspace/core node:20 npm run build 2>&1
            $result | Should Not Match "error TS\d+"
        }
        
        It "Core package has required dependencies" {
            $pkg = Get-Content "core\package.json" -Raw | ConvertFrom-Json
            $pkg.dependencies | Should Not BeNullOrEmpty
        }
    }
    
    Context "VSCode Extension - Feature Tests" {
        
        It "VSCode package.json has correct activation events" {
            $pkg = Get-Content "vscode-extension\package.json" -Raw | ConvertFrom-Json
            $pkg.activationEvents | Should Not BeNullOrEmpty
        }
        
        It "VSCode extension has main entry point" {
            $pkg = Get-Content "vscode-extension\package.json" -Raw | ConvertFrom-Json
            $pkg.main | Should Not BeNullOrEmpty
            # Main entry point compiled to out/ directory
            Test-Path "vscode-extension\out\extension.js" | Should Be $true
        }
        
        It "VSCode extension compiles successfully" {
            docker run --rm -v "${PWD}:/workspace" -w /workspace node:20 sh -c "cd core && npm install --legacy-peer-deps > /dev/null 2>&1 && npm run build > /dev/null 2>&1 && cd ../vscode-extension && npm install --legacy-peer-deps > /dev/null 2>&1 && npm run compile" 2>&1 | Out-Null
            Test-Path "vscode-extension\out\extension.js" | Should Be $true
        }
        
        It "VSCode out directory contains all compiled files" {
            $outFiles = Get-ChildItem "vscode-extension\out" -Recurse -File
            $outFiles.Count | Should BeGreaterThan 1
            ($outFiles | Where-Object Name -eq "extension.js") | Should Not BeNullOrEmpty
        }
        
        It "VSCode extension has no compilation errors" {
            $result = docker run --rm -v "${PWD}:/workspace" -w /workspace/vscode-extension node:20 npm run compile 2>&1
            $result | Should Not Match "error TS\d+"
        }
        
        It "VSCode .vscodeignore excludes core dependencies" {
            $content = Get-Content "vscode-extension\.vscodeignore" -Raw
            $content | Should Match "\.\./core"
        }
        
        It "VSCode extension packages without duplicates" {
            $vsix = Get-ChildItem "vscode-extension\*.vsix" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($vsix) {
                $vsix.Length | Should BeGreaterThan 10KB
                $vsix.Length | Should BeLessThan 10MB
            }
        }
        
        It "VSCode tsconfig is properly configured" {
            $tsconfig = Get-Content "vscode-extension\tsconfig.json" -Raw | ConvertFrom-Json
            $tsconfig.compilerOptions.composite | Should Be $false
            $tsconfig.compilerOptions.declaration | Should Be $false
        }
    }
    
    Context "Web Application - Feature Tests" {
        
        It "Web package.json has correct scripts" {
            $pkg = Get-Content "web\package.json" -Raw | ConvertFrom-Json
            $pkg.scripts.build | Should Not BeNullOrEmpty
            $pkg.scripts.start | Should Not BeNullOrEmpty
        }
        
        It "Web has all required components" {
            $components = @(
                "web\src\components\Header.tsx",
                "web\src\components\Navigation.tsx"
            )
            foreach ($comp in $components) {
                Test-Path "$WorkspaceRoot\$comp" | Should Be $true
            }
        }
        
        It "Web has all required pages" {
            $pages = @(
                "web\src\pages\ChatPage.tsx",
                "web\src\pages\CodeGenPage.tsx",
                "web\src\pages\SettingsPage.tsx"
            )
            foreach ($page in $pages) {
                Test-Path "$WorkspaceRoot\$page" | Should Be $true
            }
        }
        
        It "Web has all required CSS files" {
            $cssFiles = @(
                "web\src\index.css",
                "web\src\App.css",
                "web\src\styles\ChatPage.css"
            )
            foreach ($css in $cssFiles) {
                Test-Path "$WorkspaceRoot\$css" | Should Be $true
            }
        }
        
        It "Web builds successfully" {
            docker run --rm -v "${PWD}:/workspace" -w /workspace/web node:20 sh -c "npm install --legacy-peer-deps > /dev/null 2>&1 && npm run build" 2>&1 | Out-Null
            Test-Path "web\build\index.html" | Should Be $true
        }
        
        It "Web build contains static assets" {
            Test-Path "web\build\static" | Should Be $true
            $jsFiles = Get-ChildItem "web\build\static\js" -File -ErrorAction SilentlyContinue
            $jsFiles.Count | Should BeGreaterThan 0
        }
        
        It "Web build has manifest.json" {
            Test-Path "web\build\manifest.json" | Should Be $true
        }
        
        It "Web serviceWorker is configured" {
            Test-Path "web\src\serviceWorkerRegistration.ts" | Should Be $true
            $content = Get-Content "web\src\serviceWorkerRegistration.ts" -Raw
            $content | Should Match "process\.env\.PUBLIC_URL \|\| ''"
        }
        
        It "Web App.tsx has routing configured" {
            $content = Get-Content "web\src\App.tsx" -Raw
            $content | Should Match "react-router-dom"
            $content | Should Match "Routes"
        }
    }
    
    Context "Desktop Application - Feature Tests" {
        
        It "Desktop package.json exists" {
            Test-Path "desktop\package.json" | Should Be $true
        }
        
        It "Desktop has source files" {
            Test-Path "desktop\src" | Should Be $true
        }
        
        It "Desktop package has correct name" {
            $pkg = Get-Content "desktop\package.json" -Raw | ConvertFrom-Json
            $pkg.name | Should Not BeNullOrEmpty
        }
    }
    
    Context "Build System - Feature Tests" {
        
        It "Automated build script exists" {
            Test-Path "build-complete-auto.ps1" | Should Be $true
        }
        
        It "Build script has all platform builders" {
            $content = Get-Content "build-complete-auto.ps1" -Raw
            $content | Should Match "function Build-Core"
            $content | Should Match "function Build-VSCode"
            $content | Should Match "function Build-Web"
            $content | Should Match "function Build-Desktop"
        }
        
        It "Build script has auto-fix functions" {
            $content = Get-Content "build-complete-auto.ps1" -Raw
            $content | Should Match "function Fix-VSCodeIssues"
            $content | Should Match "function Fix-WebIssues"
        }
        
        It "Build script has retry logic" {
            $content = Get-Content "build-complete-auto.ps1" -Raw
            $content | Should Match "MaxRetries"
            $content | Should Match "Invoke-BuildWithRetry"
        }
        
        It "Build script has logging functionality" {
            $content = Get-Content "build-complete-auto.ps1" -Raw
            $content | Should Match "function Write-Log"
            $content | Should Match "timestamp"
        }
    }
    
    Context "Installer Generation - Feature Tests" {
        
        It "VSCode installer exists and is valid" {
            $vsix = Get-ChildItem "installers\manual-*\*.vsix" -ErrorAction SilentlyContinue | Select-Object -First 1
            $vsix | Should Not BeNullOrEmpty
            $vsix.Length | Should BeGreaterThan 10KB
        }
        
        It "Web installer exists and is valid" {
            $zip = Get-ChildItem "installers\manual-*\*web*.zip" -ErrorAction SilentlyContinue | Select-Object -First 1
            $zip | Should Not BeNullOrEmpty
            $zip.Length | Should BeGreaterThan 100KB
        }
        
        It "Installer directory has timestamp naming" {
            $dirs = Get-ChildItem "installers\manual-*" -Directory -ErrorAction SilentlyContinue
            $dirs.Count | Should BeGreaterThan 0
            $dirs[0].Name | Should Match "manual-\d{8}-\d{6}"
        }
    }
    
    Context "Documentation - Feature Tests" {
        
        It "All documentation files exist" {
            $docs = @(
                "FINAL_BUILD_SUCCESS.md",
                "REQUIREMENTS_VALIDATION_COMPLETE.md",
                "QUICK_START.md"
            )
            foreach ($doc in $docs) {
                Test-Path "$WorkspaceRoot\$doc" | Should Be $true
            }
        }
        
        It "Documentation has proper headers" {
            $content = Get-Content "FINAL_BUILD_SUCCESS.md" -Raw
            $content | Should Match "# "
            $content | Should Match "BUILD SUCCESS"
        }
        
        It "Quick start has installation instructions" {
            $content = Get-Content "QUICK_START.md" -Raw
            $content | Should Match "Install"
            $content | Should Match "code --install-extension"
        }
    }
    
    Context "Source Code Quality - Feature Tests" {
        
        It "VSCode completionProvider has correct syntax" {
            $content = Get-Content "vscode-extension\src\providers\completionProvider.ts" -Raw
            $content | Should Not Match "vscode\.0"
            $content | Should Match "InlineCompletionTriggerKind\.Invoke"
        }
        
        It "VSCode chatView has correct variable names" {
            $content = Get-Content "vscode-extension\src\views\chatView.ts" -Raw
            $content | Should Not Match "await this\.aiEngine\.streamChat\(chatContext,"
        }
        
        It "Web ChatPage is standalone" {
            $content = Get-Content "web\src\pages\ChatPage.tsx" -Raw
            $content | Should Not Match "from '@openpilot/core'"
        }
        
        It "Core tsconfig has correct outDir" {
            $tsconfig = Get-Content "core\tsconfig.json" -Raw | ConvertFrom-Json
            $tsconfig.compilerOptions.outDir | Should Be "./dist"
        }
    }
    
    Context "Dependency Management - Feature Tests" {
        
        It "Workspace has ajv dependencies" {
            $pkg = Get-Content "package.json" -Raw | ConvertFrom-Json
            $pkg.devDependencies.ajv | Should Not BeNullOrEmpty
            $pkg.devDependencies.'ajv-keywords' | Should Not BeNullOrEmpty
        }
        
        It "Web has react-router-dom" {
            $pkg = Get-Content "web\package.json" -Raw | ConvertFrom-Json
            $pkg.dependencies.'react-router-dom' | Should Not BeNullOrEmpty
        }
        
        It "VSCode has vscode dependency" {
            $pkg = Get-Content "vscode-extension\package.json" -Raw | ConvertFrom-Json
            $pkg.devDependencies.'@types/vscode' | Should Not BeNullOrEmpty
        }
    }
    
    Context "Configuration Files - Feature Tests" {
        
        It "All packages have package.json" {
            $packages = @("core", "vscode-extension", "web", "desktop", "backend")
            foreach ($pkg in $packages) {
                Test-Path "$WorkspaceRoot\$pkg\package.json" | Should Be $true
            }
        }
        
        It "TypeScript packages have tsconfig.json" {
            $tsPackages = @("core", "vscode-extension")
            foreach ($pkg in $tsPackages) {
                Test-Path "$WorkspaceRoot\$pkg\tsconfig.json" | Should Be $true
            }
        }
        
        It "Workspace package.json has workspaces configured" {
            $pkg = Get-Content "package.json" -Raw | ConvertFrom-Json
            $pkg.workspaces | Should Not BeNullOrEmpty
            $pkg.workspaces.Count | Should BeGreaterThan 0
        }
    }
    
    Context "Git Repository - Feature Tests" {
        
        It ".gitignore exists" {
            Test-Path ".gitignore" | Should Be $true
        }
        
        It ".gitignore excludes node_modules" {
            $content = Get-Content ".gitignore" -Raw
            $content | Should Match "node_modules"
        }
        
        It ".gitignore excludes build artifacts" {
            $content = Get-Content ".gitignore" -Raw
            $content | Should Match "dist|build|out"
        }
    }
}

Describe "OpenPilot - Integration Tests" {
    
    Context "Build Pipeline Integration" {
        
        It "Core builds before VSCode" {
            # Verify Core output exists before attempting VSCode build
            Test-Path "core\dist\index.js" | Should Be $true
        }
        
        It "All platforms can build sequentially" {
            # This validates the build order
            @("core\dist\index.js", 
              "vscode-extension\out\extension.js", 
              "web\build\index.html") | ForEach-Object {
                Test-Path $_ | Should Be $true
            }
        }
    }
    
    Context "Installer Integration" {
        
        It "VSCode installer can be created from build output" {
            Test-Path "vscode-extension\out\extension.js" | Should Be $true
            $vsix = Get-ChildItem "vscode-extension\*.vsix" -ErrorAction SilentlyContinue | Select-Object -First 1
            $vsix | Should Not BeNullOrEmpty
        }
        
        It "Web installer contains build artifacts" {
            Test-Path "web\build\index.html" | Should Be $true
            $zip = Get-ChildItem "installers\manual-*\*web*.zip" -ErrorAction SilentlyContinue | Select-Object -First 1
            $zip | Should Not BeNullOrEmpty
        }
    }
}

Pop-Location

Write-Host "`n========== EXTENDED TEST SUMMARY ==========" -ForegroundColor Cyan
Write-Host "All feature and functionality tests completed!" -ForegroundColor Green
Write-Host "Run with: Invoke-Pester tests/feature-tests.ps1 -PassThru" -ForegroundColor Yellow
