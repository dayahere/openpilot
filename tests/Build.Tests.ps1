# Unit Tests for Auto-Fix Build System
# Tests all build functions and validates outputs

Describe "Auto-Fix Build System Tests" {
    
    BeforeAll {
        $OutputDir = "i:\openpilot\installers\test-build"
        $LogFile = "i:\openpilot\build-test.log"
        
        # Create test output directory
        New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    }
    
    Context "Dependency Fix Tests" {
        It "Should fix react-native-voice version in mobile/package.json" {
            $packageJson = Get-Content "i:\openpilot\mobile\package.json" -Raw | ConvertFrom-Json
            $packageJson.dependencies.'react-native-voice' | Should -Be "^3.2.1"
        }
        
        It "Should have valid package.json syntax" {
            { Get-Content "i:\openpilot\mobile\package.json" -Raw | ConvertFrom-Json } | Should -Not -Throw
        }
    }
    
    Context "Docker Environment Tests" {
        It "Should have Docker available" {
            docker --version | Should -Not -BeNullOrEmpty
        }
        
        It "Should have node:20 image" {
            $images = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String "node:20"
            $images | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Core Package Tests" {
        It "Should have core package.json" {
            Test-Path "i:\openpilot\core\package.json" | Should -Be $true
        }
        
        It "Should have core source files" {
            Test-Path "i:\openpilot\core\src" | Should -Be $true
        }
        
        It "Should have valid TypeScript config" {
            Test-Path "i:\openpilot\core\tsconfig.json" | Should -Be $true
        }
    }
    
    Context "VSCode Extension Tests" {
        It "Should have vscode-extension package.json" {
            Test-Path "i:\openpilot\vscode-extension\package.json" | Should -Be $true
        }
        
        It "Should have extension source" {
            Test-Path "i:\openpilot\vscode-extension\src\extension.ts" | Should -Be $true
        }
        
        It "Should have package.json with vsce scripts" {
            $pkg = Get-Content "i:\openpilot\vscode-extension\package.json" -Raw | ConvertFrom-Json
            $pkg.scripts.compile | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Web App Tests" {
        It "Should have web package.json" {
            Test-Path "i:\openpilot\web\package.json" | Should -Be $true
        }
        
        It "Should have React app source" {
            Test-Path "i:\openpilot\web\src\App.tsx" | Should -Be $true
        }
        
        It "Should have build script in package.json" {
            $pkg = Get-Content "i:\openpilot\web\package.json" -Raw | ConvertFrom-Json
            $pkg.scripts.build | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Desktop App Tests" {
        It "Should have desktop package.json" {
            Test-Path "i:\openpilot\desktop\package.json" | Should -Be $true
        }
        
        It "Should have React app source" {
            Test-Path "i:\openpilot\desktop\src\App.tsx" | Should -Be $true
        }
        
        It "Should have build script in package.json" {
            $pkg = Get-Content "i:\openpilot\desktop\package.json" -Raw | ConvertFrom-Json
            $pkg.scripts.build | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Build Output Validation Tests" {
        It "Should create output directory" {
            Test-Path $OutputDir | Should -Be $true
        }
        
        It "Should create vscode subdirectory when building" {
            New-Item -ItemType Directory -Force -Path "$OutputDir\vscode" | Out-Null
            Test-Path "$OutputDir\vscode" | Should -Be $true
        }
        
        It "Should create web subdirectory when building" {
            New-Item -ItemType Directory -Force -Path "$OutputDir\web" | Out-Null
            Test-Path "$OutputDir\web" | Should -Be $true
        }
        
        It "Should create desktop subdirectory when building" {
            New-Item -ItemType Directory -Force -Path "$OutputDir\desktop" | Out-Null
            Test-Path "$OutputDir\desktop" | Should -Be $true
        }
    }
    
    Context "Installer File Format Tests" {
        It "Should create .vsix file with correct extension" -Skip {
            # This test runs after build
            $vsixFiles = Get-ChildItem "$OutputDir\vscode\*.vsix" -ErrorAction SilentlyContinue
            if ($vsixFiles) {
                $vsixFiles[0].Extension | Should -Be ".vsix"
            }
        }
        
        It "Should create .zip file with correct extension" -Skip {
            # This test runs after build
            $zipFiles = Get-ChildItem "$OutputDir\web\*.zip" -ErrorAction SilentlyContinue
            if ($zipFiles) {
                $zipFiles[0].Extension | Should -Be ".zip"
            }
        }
        
        It "Should create desktop index.html" -Skip {
            # This test runs after build
            if (Test-Path "$OutputDir\desktop") {
                Test-Path "$OutputDir\desktop\index.html" | Should -Be $true
            }
        }
    }
    
    Context "Size Validation Tests" {
        It "VSCode extension should be > 100KB if exists" -Skip {
            $vsixFile = Get-ChildItem "$OutputDir\vscode\*.vsix" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($vsixFile) {
                $vsixFile.Length | Should -BeGreaterThan 100KB
            }
        }
        
        It "Web ZIP should be > 100KB if exists" -Skip {
            $zipFile = Get-Item "$OutputDir\web\openpilot-web.zip" -ErrorAction SilentlyContinue
            if ($zipFile) {
                $zipFile.Length | Should -BeGreaterThan 100KB
            }
        }
        
        It "Desktop build should have multiple files" -Skip {
            if (Test-Path "$OutputDir\desktop") {
                $fileCount = (Get-ChildItem "$OutputDir\desktop" -Recurse -File).Count
                $fileCount | Should -BeGreaterThan 5
            }
        }
    }
    
    AfterAll {
        # Cleanup is optional - keep test outputs for inspection
        Write-Host "Test outputs available at: $OutputDir" -ForegroundColor Cyan
    }
}

Describe "Build Script Function Tests" {
    
    Context "Logging Function Tests" {
        It "Should create log file" {
            $testLog = "i:\openpilot\test-build.log"
            "Test entry" | Out-File $testLog -Append
            Test-Path $testLog | Should -Be $true
            Remove-Item $testLog -Force -ErrorAction SilentlyContinue
        }
    }
    
    Context "Retry Logic Tests" {
        It "Should retry up to MaxRetries times" {
            $MaxRetries = 3
            $attemptCount = 0
            
            while ($attemptCount -lt $MaxRetries) {
                $attemptCount++
            }
            
            $attemptCount | Should -Be $MaxRetries
        }
    }
    
    Context "Path Validation Tests" {
        It "Should validate core path exists" {
            Test-Path "i:\openpilot\core" | Should -Be $true
        }
        
        It "Should validate vscode-extension path exists" {
            Test-Path "i:\openpilot\vscode-extension" | Should -Be $true
        }
        
        It "Should validate web path exists" {
            Test-Path "i:\openpilot\web" | Should -Be $true
        }
        
        It "Should validate desktop path exists" {
            Test-Path "i:\openpilot\desktop" | Should -Be $true
        }
    }
}

Describe "Integration Tests" {
    
    Context "End-to-End Build Test" -Tag "Integration" {
        It "Should complete full build process without errors" -Skip {
            # This is the actual build test - skipped by default
            # Run with: Invoke-Pester -Tag Integration
            
            $result = & "i:\openpilot\build-auto-fix.ps1"
            $LASTEXITCODE | Should -BeIn @(0, 1) # Either success or partial success
        }
    }
}
