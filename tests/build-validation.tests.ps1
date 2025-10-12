# Automated Build Test Suite
# Tests all build requirements and validates fixes

BeforeAll {
    $script:RootPath = "i:\openpilot"
    $script:TestResults = @{
        PreBuild = @()
        PostBuild = @()
        Fixes = @()
    }
}

Describe "Pre-Build Requirements" {
    
    It "Docker should be available" {
        { docker --version } | Should -Not -Throw
    }
    
    It "Node.js 20 image should be available" {
        $images = docker images node:20 --format "{{.Repository}}:{{.Tag}}"
        $images | Should -Contain "node:20"
    }
    
    It "Workspace package.json should exist" {
        Test-Path "$script:RootPath\package.json" | Should -Be $true
    }
    
    It "Workspace should not include mobile (react-native-voice fix)" {
        $pkg = Get-Content "$script:RootPath\package.json" | ConvertFrom-Json
        $pkg.workspaces | Should -Not -Contain "mobile"
    }
    
    It "Core tsconfig.json should be standalone" {
        $tsconfig = Get-Content "$script:RootPath\core\tsconfig.json" | ConvertFrom-Json
        $tsconfig.PSObject.Properties.Name | Should -Not -Contain "extends"
    }
    
    It "VSCode tsconfig.json should be standalone" {
        $tsconfig = Get-Content "$script:RootPath\vscode-extension\tsconfig.json" | ConvertFrom-Json
        $tsconfig.PSObject.Properties.Name | Should -Not -Contain "extends"
        $tsconfig.compilerOptions.composite | Should -Be $false
    }
    
    It "Root package.json should have ajv dependencies" {
        $pkg = Get-Content "$script:RootPath\package.json" | ConvertFrom-Json
        $pkg.devDependencies.ajv | Should -Not -BeNullOrEmpty
        $pkg.devDependencies.'ajv-keywords' | Should -Not -BeNullOrEmpty
    }
}

Describe "Source Code Fixes" {
    
    It "VSCode completionProvider should use correct InlineCompletionTriggerKind" {
        $content = Get-Content "$script:RootPath\vscode-extension\src\providers\completionProvider.ts" -Raw
        $content | Should -Match "InlineCompletionTriggerKind\.(Invoke|Automatic)"
        $content | Should -Not -Match "vscode\.0"
    }
    
    It "Core package should have proper tsconfig" {
        $tsconfig = Get-Content "$script:RootPath\core\tsconfig.json" | ConvertFrom-Json
        $tsconfig.compilerOptions.outDir | Should -Be "./dist"
        $tsconfig.compilerOptions.rootDir | Should -Be "./src"
    }
    
    It "Desktop package.json should have react-scripts" {
        $pkg = Get-Content "$script:RootPath\desktop\package.json" | ConvertFrom-Json
        $pkg.devDependencies.'react-scripts' | Should -Not -BeNullOrEmpty
    }
}

Describe "Build Process" -Tag "Build" {
    
    BeforeAll {
        # Clean previous builds
        Remove-Item "$script:RootPath\core\dist" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$script:RootPath\vscode-extension\out" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$script:RootPath\web\build" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$script:RootPath\desktop\build" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    It "Core package should build successfully" {
        Push-Location "$script:RootPath"
        $output = docker run --rm -v "${PWD}:/app" -w /app/core node:20 bash -c "npm run build 2>&1"
        Pop-Location
        
        Test-Path "$script:RootPath\core\dist\index.js" | Should -Be $true
        Test-Path "$script:RootPath\core\dist\index.d.ts" | Should -Be $true
    }
    
    It "VSCode extension should compile successfully" {
        Push-Location "$script:RootPath"
        $output = docker run --rm -v "${PWD}:/app" -w /app/vscode-extension node:20 bash -c "npm run compile 2>&1"
        Pop-Location
        
        Test-Path "$script:RootPath\vscode-extension\out\extension.js" | Should -Be $true
    }
    
    It "Web app should build successfully" {
        Push-Location "$script:RootPath"
        $output = docker run --rm -v "${PWD}:/app" -w /app/web node:20 bash -c "CI=true npm run build 2>&1"
        Pop-Location
        
        Test-Path "$script:RootPath\web\build\index.html" | Should -Be $true
    }
    
    It "Desktop app should build successfully" {
        Push-Location "$script:RootPath"
        $output = docker run --rm -v "${PWD}:/app" -w /app/desktop node:20 bash -c "CI=true npm run build 2>&1"
        Pop-Location
        
        Test-Path "$script:RootPath\desktop\build\index.html" | Should -Be $true
    }
}

Describe "Artifact Generation" -Tag "Artifacts" {
    
    It "VSCode .vsix file should be packageable" {
        Push-Location "$script:RootPath"
        $output = docker run --rm -v "${PWD}:/app" -w /app/vscode-extension node:20 bash -c "npm install -g @vscode/vsce && vsce package --out . 2>&1"
        Pop-Location
        
        $vsixFile = Get-ChildItem "$script:RootPath\vscode-extension\*.vsix" | Select-Object -First 1
        $vsixFile | Should -Not -BeNullOrEmpty
        $vsixFile.Length | Should -BeGreaterThan 100KB
    }
    
    It "Web app should be compressible to .zip" {
        if (Test-Path "$script:RootPath\web\build") {
            Compress-Archive -Path "$script:RootPath\web\build\*" -DestinationPath "$script:RootPath\test-web.zip" -Force
            Test-Path "$script:RootPath\test-web.zip" | Should -Be $true
            (Get-Item "$script:RootPath\test-web.zip").Length | Should -BeGreaterThan 100KB
            Remove-Item "$script:RootPath\test-web.zip" -Force
        }
    }
    
    It "Desktop app should be compressible to .zip" {
        if (Test-Path "$script:RootPath\desktop\build") {
            Compress-Archive -Path "$script:RootPath\desktop\build\*" -DestinationPath "$script:RootPath\test-desktop.zip" -Force
            Test-Path "$script:RootPath\test-desktop.zip" | Should -Be $true
            (Get-Item "$script:RootPath\test-desktop.zip").Length | Should -BeGreaterThan 100KB
            Remove-Item "$script:RootPath\test-desktop.zip" -Force
        }
    }
}

Describe "Auto-Fix Validation" {
    
    It "Build script should have retry logic" {
        $scriptContent = Get-Content "$script:RootPath\build-all-platforms-auto.ps1" -Raw
        $scriptContent | Should -Match "MaxRetries"
        $scriptContent | Should -Match "for.*attempt.*MaxRetries"
    }
    
    It "Build script should have fix functions" {
        $scriptContent = Get-Content "$script:RootPath\build-all-platforms-auto.ps1" -Raw
        $scriptContent | Should -Match "function Fix-CoreIssues"
        $scriptContent | Should -Match "function Fix-VSCodeIssues"
        $scriptContent | Should -Match "function Fix-WebIssues"
        $scriptContent | Should -Match "function Fix-DesktopIssues"
    }
    
    It "Build script should track build state" {
        $scriptContent = Get-Content "$script:RootPath\build-all-platforms-auto.ps1" -Raw
        $scriptContent | Should -Match "\`$script:BuildState"
        $scriptContent | Should -Match "Success.*Attempts.*Errors"
    }
}

Describe "Error Handling" {
    
    It "Build script should log errors" {
        $scriptContent = Get-Content "$script:RootPath\build-all-platforms-auto.ps1" -Raw
        $scriptContent | Should -Match "Add-Content.*logFile"
        $scriptContent | Should -Match "Write-Log.*ERROR"
    }
    
    It "Build script should continue on error" {
        $scriptContent = Get-Content "$script:RootPath\build-all-platforms-auto.ps1" -Raw
        $scriptContent | Should -Match "ErrorActionPreference.*Continue"
    }
}

Describe "Requirements Validation" {
    
    It "All source fixes should be applied" {
        # VSCode fix
        $completionProvider = Get-Content "$script:RootPath\vscode-extension\src\providers\completionProvider.ts" -Raw
        $completionProvider | Should -Not -Match "vscode\.0"
        
        # Core tsconfig
        $coreTs = Get-Content "$script:RootPath\core\tsconfig.json" | ConvertFrom-Json
        $coreTs.compilerOptions.outDir | Should -Be "./dist"
        
        # VSCode tsconfig
        $vscodeTs = Get-Content "$script:RootPath\vscode-extension\tsconfig.json" | ConvertFrom-Json
        $vscodeTs.compilerOptions.composite | Should -Be $false
    }
    
    It "All dependency fixes should be applied" {
        $rootPkg = Get-Content "$script:RootPath\package.json" | ConvertFrom-Json
        $rootPkg.devDependencies.ajv | Should -Match "8\."
        $rootPkg.devDependencies.'ajv-keywords' | Should -Match "5\."
    }
}

AfterAll {
    Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Cyan
    Write-Host "All tests validate build requirements and fixes" -ForegroundColor Green
    Write-Host "Run: .\build-all-platforms-auto.ps1 to build all platforms" -ForegroundColor Yellow
}
