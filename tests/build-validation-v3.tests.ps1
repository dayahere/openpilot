<#
.SYNOPSIS
    Build system validation tests (Compatible with Pester 3.4+)
.DESCRIPTION
    Tests for OpenPilot build system - all fixes and artifacts
#>

$WorkspaceRoot = "i:\openpilot"

Describe "OpenPilot Build System Validation" {
    
    Context "Pre-Build Requirements" {
        
        It "Docker should be accessible" {
            $result = docker --version 2>&1
            $LASTEXITCODE | Should Be 0
        }
        
        It "Workspace package.json exists" {
            Test-Path "$WorkspaceRoot\package.json" | Should Be $true
        }
        
        It "Core package exists" {
            Test-Path "$WorkspaceRoot\core\package.json" | Should Be $true
        }
        
        It "VSCode package exists" {
            Test-Path "$WorkspaceRoot\vscode-extension\package.json" | Should Be $true
        }
        
        It "Web package exists" {
            Test-Path "$WorkspaceRoot\web\package.json" | Should Be $true
        }
    }
    
    Context "Source Code Fixes" {
        
        It "VSCode completionProvider.ts is fixed" {
            $content = Get-Content "$WorkspaceRoot\vscode-extension\src\providers\completionProvider.ts" -Raw
            $content | Should Not Match "vscode\.0"
            $content | Should Match "InlineCompletionTriggerKind"
        }
        
        It "VSCode .vscodeignore exists" {
            Test-Path "$WorkspaceRoot\vscode-extension\.vscodeignore" | Should Be $true
        }
        
        It "Web index.css exists" {
            Test-Path "$WorkspaceRoot\web\src\index.css" | Should Be $true
        }
        
        It "Web App.css exists" {
            Test-Path "$WorkspaceRoot\web\src\App.css" | Should Be $true
        }
        
        It "Web Header component exists" {
            Test-Path "$WorkspaceRoot\web\src\components\Header.tsx" | Should Be $true
        }
        
        It "Web Navigation component exists" {
            Test-Path "$WorkspaceRoot\web\src\components\Navigation.tsx" | Should Be $true
        }
        
        It "Web ChatPage exists" {
            Test-Path "$WorkspaceRoot\web\src\pages\ChatPage.tsx" | Should Be $true
        }
        
        It "Web CodeGenPage exists" {
            Test-Path "$WorkspaceRoot\web\src\pages\CodeGenPage.tsx" | Should Be $true
        }
        
        It "Web SettingsPage exists" {
            Test-Path "$WorkspaceRoot\web\src\pages\SettingsPage.tsx" | Should Be $true
        }
    }
    
    Context "Build Artifacts" {
        
        It "Core dist/index.js exists" {
            Test-Path "$WorkspaceRoot\core\dist\index.js" | Should Be $true
        }
        
        It "VSCode extension.js exists" {
            Test-Path "$WorkspaceRoot\vscode-extension\out\extension.js" | Should Be $true
        }
        
        It "Web build exists" {
            Test-Path "$WorkspaceRoot\web\build\index.html" | Should Be $true
        }
        
        It "VSCode .vsix installer exists" {
            $vsix = Get-ChildItem "$WorkspaceRoot\installers\manual-*\*.vsix" -ErrorAction SilentlyContinue | Select-Object -First 1
            $vsix | Should Not BeNullOrEmpty
            $vsix.Length | Should BeGreaterThan 10KB
        }
        
        It "Web .zip installer exists" {
            $zip = Get-ChildItem "$WorkspaceRoot\installers\manual-*\*web*.zip" -ErrorAction SilentlyContinue | Select-Object -First 1
            $zip | Should Not BeNullOrEmpty
            $zip.Length | Should BeGreaterThan 1KB
        }
    }
    
    Context "Build Scripts" {
        
        It "Automated build script exists" {
            Test-Path "$WorkspaceRoot\build-complete-auto.ps1" | Should Be $true
        }
        
        It "Build script has auto-fix functions" {
            $content = Get-Content "$WorkspaceRoot\build-complete-auto.ps1" -Raw
            $content | Should Match "Fix-VSCodeIssues"
            $content | Should Match "Fix-WebIssues"
        }
        
        It "Build script has retry logic" {
            $content = Get-Content "$WorkspaceRoot\build-complete-auto.ps1" -Raw
            $content | Should Match "MaxRetries"
            $content | Should Match "Invoke-BuildWithRetry"
        }
    }
    
    Context "Documentation" {
        
        It "Final success documentation exists" {
            Test-Path "$WorkspaceRoot\FINAL_BUILD_SUCCESS.md" | Should Be $true
        }
        
        It "Documentation has build summary" {
            $content = Get-Content "$WorkspaceRoot\FINAL_BUILD_SUCCESS.md" -Raw
            $content | Should Match "BUILD SUCCESS"
            $content | Should Match "INSTALLERS"
        }
    }
}

Write-Host "`n========== TEST SUMMARY ==========" -ForegroundColor Cyan
Write-Host "All validation tests completed!" -ForegroundColor Green
