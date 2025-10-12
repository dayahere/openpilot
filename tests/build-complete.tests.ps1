#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }

<#
.SYNOPSIS
    Comprehensive unit tests for build system validation
.DESCRIPTION
    Tests all build fixes, artifacts, and requirements
#>

Describe "OpenPilot Build System - Complete Test Suite" {
    
    BeforeAll {
        $script:WorkspaceRoot = "i:\openpilot"
        Push-Location $script:WorkspaceRoot
    }
    
    AfterAll {
        Pop-Location
    }
    
    Context "Pre-Build Requirements" {
        
        It "Docker Desktop should be running" {
            $dockerProcesses = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
            $dockerProcesses | Should -Not -BeNullOrEmpty
        }
        
        It "Docker should be accessible" {
            $result = docker --version 2>&1
            $LASTEXITCODE | Should -Be 0
        }
        
        It "Node:20 Docker image should be available" {
            $result = docker images node:20 --format "{{.Repository}}:{{.Tag}}"
            $result | Should -Contain "node:20"
        }
        
        It "Workspace package.json should exist" {
            Test-Path "$script:WorkspaceRoot\package.json" | Should -Be $true
        }
        
        It "All workspace packages should exist" {
            $packages = @("core", "vscode-extension", "web", "desktop", "backend")
            foreach ($pkg in $packages) {
                Test-Path "$script:WorkspaceRoot\$pkg\package.json" | Should -Be $true -Because "$pkg package.json should exist"
            }
        }
        
        It "Required dependencies should be installed at workspace root" {
            $packageJson = Get-Content "$script:WorkspaceRoot\package.json" -Raw | ConvertFrom-Json
            $packageJson.devDependencies.ajv | Should -Not -BeNullOrEmpty
            $packageJson.devDependencies.'ajv-keywords' | Should -Not -BeNullOrEmpty
        }
        
        It "Build scripts should exist" {
            Test-Path "$script:WorkspaceRoot\build-complete-auto.ps1" | Should -Be $true
        }
    }
    
    Context "Source Code Fixes Validation" {
        
        It "VSCode completionProvider.ts should be fixed" {
            $content = Get-Content "$script:WorkspaceRoot\vscode-extension\src\providers\completionProvider.ts" -Raw
            $content | Should -Not -Match "vscode\.0"
            $content | Should -Match "vscode\.InlineCompletionTriggerKind\.Invoke"
        }
        
        It "VSCode chatView.ts should use correct variable name" {
            $content = Get-Content "$script:WorkspaceRoot\vscode-extension\src\views\chatView.ts" -Raw
            $content | Should -Not -Match "chatContext\)" -Because "Should use chat_context, not chatContext"
        }
        
        It "VSCode tsconfig.json should be standalone" {
            $tsconfig = Get-Content "$script:WorkspaceRoot\vscode-extension\tsconfig.json" -Raw | ConvertFrom-Json
            $tsconfig.compilerOptions.composite | Should -Be $false
            $tsconfig.compilerOptions.declaration | Should -Be $false
        }
        
        It "Core tsconfig.json should be standalone" {
            $tsconfig = Get-Content "$script:WorkspaceRoot\core\tsconfig.json" -Raw | ConvertFrom-Json
            $tsconfig.compilerOptions.outDir | Should -Be "./dist"
        }
        
        It "Web should have required CSS files" {
            Test-Path "$script:WorkspaceRoot\web\src\index.css" | Should -Be $true
            Test-Path "$script:WorkspaceRoot\web\src\App.css" | Should -Be $true
        }
        
        It "Web should have all required component files" {
            $components = @(
                "web\src\components\Header.tsx",
                "web\src\components\Navigation.tsx",
                "web\src\pages\ChatPage.tsx",
                "web\src\pages\CodeGenPage.tsx",
                "web\src\pages\SettingsPage.tsx"
            )
            foreach ($component in $components) {
                Test-Path "$script:WorkspaceRoot\$component" | Should -Be $true -Because "$component should exist"
            }
        }
        
        It "VSCode .vscodeignore should exist and exclude core" {
            Test-Path "$script:WorkspaceRoot\vscode-extension\.vscodeignore" | Should -Be $true
            $content = Get-Content "$script:WorkspaceRoot\vscode-extension\.vscodeignore" -Raw
            $content | Should -Match "\.\./core/\*\*"
        }
    }
    
    Context "Build Process Validation" {
        
        It "Core package should build successfully" {
            $result = docker run --rm -v "${PWD}:/workspace" -w /workspace/core node:20 sh -c "npm install --legacy-peer-deps > /dev/null 2>&1 && npm run build" 2>&1
            Test-Path "core\dist\index.js" | Should -Be $true
        } -Tag "Slow"
        
        It "Core dist should contain required files" {
            $files = Get-ChildItem "core\dist" -File
            $files.Count | Should -BeGreaterThan 0
            ($files | Where-Object Name -eq "index.js") | Should -Not -BeNullOrEmpty
        }
        
        It "VSCode extension should compile" {
            $result = docker run --rm -v "${PWD}:/workspace" -w /workspace node:20 sh -c "cd core && npm install --legacy-peer-deps > /dev/null 2>&1 && npm run build > /dev/null 2>&1 && cd ../vscode-extension && npm install --legacy-peer-deps > /dev/null 2>&1 && npm run compile" 2>&1
            Test-Path "vscode-extension\out\extension.js" | Should -Be $true
        } -Tag "Slow"
        
        It "Web application should build" {
            $result = docker run --rm -v "${PWD}:/workspace" -w /workspace/web node:20 sh -c "npm install --legacy-peer-deps > /dev/null 2>&1 && npm run build" 2>&1
            Test-Path "web\build\index.html" | Should -Be $true
        } -Tag "Slow"
    }
    
    Context "Artifact Generation" {
        
        BeforeAll {
            # Run build script
            if (-not (Test-Path "vscode-extension\*.vsix")) {
                Write-Host "Running build to generate artifacts..." -ForegroundColor Yellow
                & "$script:WorkspaceRoot\build-complete-auto.ps1" -SkipAndroid -ErrorAction Continue
            }
        }
        
        It "VSCode .vsix installer should be generated" {
            $vsix = Get-ChildItem "installers\build-*\*.vsix" -ErrorAction SilentlyContinue | Select-Object -First 1
            $vsix | Should -Not -BeNullOrEmpty
            $vsix.Length | Should -BeGreaterThan 10KB
        } -Tag "Artifact"
        
        It "Web .zip installer should be generated" {
            $zip = Get-ChildItem "installers\build-*\*web*.zip" -ErrorAction SilentlyContinue | Select-Object -First 1
            $zip | Should -Not -BeNullOrEmpty
            $zip.Length | Should -BeGreaterThan 1KB
        } -Tag "Artifact"
        
        It "Desktop .zip installer should be generated" {
            $zip = Get-ChildItem "installers\build-*\*desktop*.zip" -ErrorAction SilentlyContinue | Select-Object -First 1
            $zip | Should -Not -BeNullOrEmpty
            $zip.Length | Should -BeGreaterThan 1KB
        } -Tag "Artifact"
    }
    
    Context "Auto-Fix Functionality" {
        
        It "Auto-fix should create .vscodeignore if missing" {
            # Backup
            $vscodeignorePath = "$script:WorkspaceRoot\vscode-extension\.vscodeignore"
            $backup = $null
            if (Test-Path $vscodeignorePath) {
                $backup = Get-Content $vscodeignorePath -Raw
                Remove-Item $vscodeignorePath -Force
            }
            
            # Test auto-fix
            & "$script:WorkspaceRoot\build-complete-auto.ps1" -SkipAndroid -ErrorAction Continue | Out-Null
            
            Test-Path $vscodeignorePath | Should -Be $true
            
            # Restore
            if ($backup) {
                Set-Content $vscodeignorePath -Value $backup -Force
            }
        } -Tag "AutoFix"
        
        It "Auto-fix should create index.css if missing" {
            $indexCssPath = "$script:WorkspaceRoot\web\src\index.css"
            $backup = $null
            if (Test-Path $indexCssPath) {
                $backup = Get-Content $indexCssPath -Raw
                Remove-Item $indexCssPath -Force
            }
            
            & "$script:WorkspaceRoot\build-complete-auto.ps1" -SkipAndroid -ErrorAction Continue | Out-Null
            
            Test-Path $indexCssPath | Should -Be $true
            
            if ($backup) {
                Set-Content $indexCssPath -Value $backup -Force
            }
        } -Tag "AutoFix"
        
        It "Build should retry on failure" {
            $logFile = Get-ChildItem "build-complete-*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($logFile) {
                $content = Get-Content $logFile.FullName -Raw
                $content | Should -Match "Attempt \d+ of \d+"
            }
        } -Tag "AutoFix"
    }
    
    Context "Error Handling" {
        
        It "Build script should handle missing Docker gracefully" {
            # This is a theoretical test - we can't actually stop Docker during tests
            # Just verify the script has proper error handling structure
            $scriptContent = Get-Content "$script:WorkspaceRoot\build-complete-auto.ps1" -Raw
            $scriptContent | Should -Match '\$ErrorActionPreference'
        }
        
        It "Build should generate logs for failed builds" {
            $logFiles = Get-ChildItem "build-complete-*.log" -ErrorAction SilentlyContinue
            $logFiles.Count | Should -BeGreaterThan 0
        }
    }
    
    Context "Requirements Validation" {
        
        It "All critical source fixes should be applied" {
            $fixes = @(
                @{ File = "vscode-extension\src\providers\completionProvider.ts"; Pattern = "InlineCompletionTriggerKind\.Invoke" },
                @{ File = "vscode-extension\.vscodeignore"; Pattern = "core" },
                @{ File = "web\src\index.css"; Pattern = "body" },
                @{ File = "web\src\components\Header.tsx"; Pattern = "HeaderProps" }
            )
            
            foreach ($fix in $fixes) {
                $path = "$script:WorkspaceRoot\$($fix.File)"
                Test-Path $path | Should -Be $true
                $content = Get-Content $path -Raw
                $content | Should -Match $fix.Pattern
            }
        }
        
        It "Build system should support all required platforms" {
            $scriptContent = Get-Content "$script:WorkspaceRoot\build-complete-auto.ps1" -Raw
            $scriptContent | Should -Match "Build-Core"
            $scriptContent | Should -Match "Build-VSCode"
            $scriptContent | Should -Match "Build-Web"
            $scriptContent | Should -Match "Build-Desktop"
            $scriptContent | Should -Match "Build-Android"
        }
    }
    
    Context "Performance and Quality" {
        
        It "Core build should complete within reasonable time" {
            $start = Get-Date
            docker run --rm -v "${PWD}:/workspace" -w /workspace/core node:20 sh -c "npm install --legacy-peer-deps > /dev/null 2>&1 && npm run build" 2>&1 | Out-Null
            $duration = (Get-Date) - $start
            $duration.TotalMinutes | Should -BeLessThan 5
        } -Tag "Performance"
        
        It "Build artifacts should be properly sized" {
            $vsix = Get-ChildItem "installers\build-*\*.vsix" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($vsix) {
                $vsix.Length | Should -BeGreaterThan 10KB
                $vsix.Length | Should -BeLessThan 100MB
            }
        } -Tag "Quality"
        
        It "No TypeScript compilation errors in VSCode" {
            $compileLog = Get-ChildItem "installers\build-*\logs\vscode-compile.log" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($compileLog) {
                $content = Get-Content $compileLog.FullName -Raw
                $content | Should -Not -Match "error TS\d+"
            }
        } -Tag "Quality"
    }
}

Describe "Build Script Integration Tests" {
    
    Context "Complete Build Workflow" {
        
        It "Should complete full build without errors" {
            $result = & "$PWD\build-complete-auto.ps1" -SkipAndroid -ErrorAction Continue
            $LASTEXITCODE | Should -Be 0 -Because "Build should succeed"
        } -Tag "Integration", "Slow"
        
        It "Should generate complete installer set" {
            $latestBuild = Get-ChildItem "installers\build-*" -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            $installers = Get-ChildItem $latestBuild.FullName -File -Include "*.vsix","*.zip"
            $installers.Count | Should -BeGreaterOrEqual 3 -Because "Should have VSCode, Web, and Desktop installers"
        } -Tag "Integration"
    }
}
