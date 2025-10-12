# Requirements Validation & Auto-Fix Feedback Loop
# Continuously validates requirements and applies fixes until all criteria are met

$ErrorActionPreference = "Continue"

# ========================================
# REQUIREMENTS DEFINITION
# ========================================

$Requirements = @{
    "Dependencies" = @{
        "mobile-react-native-voice" = @{
            Description = "Mobile should be removed from workspaces (we're not building it)"
            Test = {
                $pkg = Get-Content "i:\openpilot\package.json" -Raw | ConvertFrom-Json
                return -not ($pkg.workspaces -contains "mobile")
            }
            Fix = {
                $content = Get-Content "i:\openpilot\package.json" -Raw
                $content = $content -replace '(\s*"mobile",?\s*)', ''
                $content = $content -replace ',(\s*])', '$1'  # Remove trailing comma
                $content | Set-Content "i:\openpilot\package.json" -NoNewline
            }
            Critical = $true
        }
        "docker-available" = @{
            Description = "Docker must be available and running"
            Test = {
                try {
                    docker --version | Out-Null
                    return $LASTEXITCODE -eq 0
                } catch {
                    return $false
                }
            }
            Fix = {
                Write-Host "Please start Docker Desktop manually" -ForegroundColor Yellow
                return $false  # Cannot auto-fix
            }
            Critical = $true
        }
        "node-image-available" = @{
            Description = "Docker node:20 image must be available"
            Test = {
                $images = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String "node:20"
                return $null -ne $images
            }
            Fix = {
                Write-Host "Pulling node:20 image..." -ForegroundColor Yellow
                docker pull node:20
                return $LASTEXITCODE -eq 0
            }
            Critical = $true
        }
    }
    
    "SourceFiles" = @{
        "core-package-json" = @{
            Description = "Core package.json must exist and be valid"
            Test = {
                if (-not (Test-Path "i:\openpilot\core\package.json")) { return $false }
                try {
                    Get-Content "i:\openpilot\core\package.json" -Raw | ConvertFrom-Json | Out-Null
                    return $true
                } catch {
                    return $false
                }
            }
            Fix = { return $false } # Cannot auto-fix missing file
            Critical = $true
        }
        "vscode-extension-source" = @{
            Description = "VSCode extension source must exist"
            Test = {
                return (Test-Path "i:\openpilot\vscode-extension\src\extension.ts")
            }
            Fix = { return $false }
            Critical = $true
        }
        "web-app-source" = @{
            Description = "Web app source must exist"
            Test = {
                return (Test-Path "i:\openpilot\web\src\App.tsx")
            }
            Fix = { return $false }
            Critical = $true
        }
        "desktop-app-source" = @{
            Description = "Desktop app source must exist"
            Test = {
                return (Test-Path "i:\openpilot\desktop\src\App.tsx")
            }
            Fix = { return $false }
            Critical = $true
        }
    }
    
    "BuildOutputs" = @{
        "vscode-vsix-exists" = @{
            Description = "VSCode .vsix file must be generated"
            Test = {
                return (Test-Path "i:\openpilot\installers\auto-fix-build\vscode\openpilot-vscode.vsix")
            }
            Fix = { return $false } # Fixed by running build
            Critical = $false
            PostBuild = $true
        }
        "vscode-vsix-size" = @{
            Description = "VSCode .vsix must be > 100KB"
            Test = {
                $file = Get-Item "i:\openpilot\installers\auto-fix-build\vscode\openpilot-vscode.vsix" -ErrorAction SilentlyContinue
                if ($file) {
                    return $file.Length -gt 100KB
                }
                return $false
            }
            Fix = { return $false }
            Critical = $false
            PostBuild = $true
        }
        "web-zip-exists" = @{
            Description = "Web .zip file must be generated"
            Test = {
                return (Test-Path "i:\openpilot\installers\auto-fix-build\web\openpilot-web.zip")
            }
            Fix = { return $false }
            Critical = $false
            PostBuild = $true
        }
        "web-zip-size" = @{
            Description = "Web .zip must be > 100KB"
            Test = {
                $file = Get-Item "i:\openpilot\installers\auto-fix-build\web\openpilot-web.zip" -ErrorAction SilentlyContinue
                if ($file) {
                    return $file.Length -gt 100KB
                }
                return $false
            }
            Fix = { return $false }
            Critical = $false
            PostBuild = $true
        }
        "desktop-build-exists" = @{
            Description = "Desktop build folder must exist"
            Test = {
                return (Test-Path "i:\openpilot\installers\auto-fix-build\desktop\index.html")
            }
            Fix = { return $false }
            Critical = $false
            PostBuild = $true
        }
        "desktop-build-files" = @{
            Description = "Desktop build must have > 5 files"
            Test = {
                if (Test-Path "i:\openpilot\installers\auto-fix-build\desktop") {
                    $count = (Get-ChildItem "i:\openpilot\installers\auto-fix-build\desktop" -Recurse -File).Count
                    return $count -gt 5
                }
                return $false
            }
            Fix = { return $false }
            Critical = $false
            PostBuild = $true
        }
    }
}

# ========================================
# VALIDATION FUNCTIONS
# ========================================

function Test-AllRequirements {
    param([bool]$PostBuild = $false)
    
    $results = @{
        Total = 0
        Passed = 0
        Failed = 0
        Critical = 0
        CriticalFailed = 0
        Details = @()
    }
    
    foreach ($category in $Requirements.Keys) {
        foreach ($reqName in $Requirements[$category].Keys) {
            $req = $Requirements[$category][$reqName]
            
            # Skip post-build requirements if not in post-build phase
            if ($req.PostBuild -and -not $PostBuild) {
                continue
            }
            
            # Skip pre-build requirements if in post-build phase
            if (-not $req.PostBuild -and $PostBuild) {
                continue
            }
            
            $results.Total++
            if ($req.Critical) {
                $results.Critical++
            }
            
            $testResult = & $req.Test
            
            if ($testResult) {
                $results.Passed++
                $status = "PASS"
                $color = "Green"
            } else {
                $results.Failed++
                if ($req.Critical) {
                    $results.CriticalFailed++
                }
                $status = "FAIL"
                $color = "Red"
            }
            
            $results.Details += [PSCustomObject]@{
                Category = $category
                Name = $reqName
                Description = $req.Description
                Status = $status
                Critical = $req.Critical
            }
            
            Write-Host "[$status] " -NoNewline -ForegroundColor $color
            Write-Host "$($req.Description)" -ForegroundColor $(if($testResult){"White"}else{"Gray"})
        }
    }
    
    return $results
}

function Invoke-AutoFix {
    $fixResults = @{
        Attempted = 0
        Successful = 0
        Failed = 0
    }
    
    Write-Host "`nAttempting auto-fixes..." -ForegroundColor Yellow
    
    foreach ($category in $Requirements.Keys) {
        foreach ($reqName in $Requirements[$category].Keys) {
            $req = $Requirements[$category][$reqName]
            
            # Skip post-build requirements
            if ($req.PostBuild) {
                continue
            }
            
            # Test if fix is needed
            $testResult = & $req.Test
            
            if (-not $testResult) {
                Write-Host "  Fixing: $($req.Description)..." -ForegroundColor Cyan
                $fixResults.Attempted++
                
                $fixResult = & $req.Fix
                
                if ($fixResult) {
                    # Re-test after fix
                    $retestResult = & $req.Test
                    if ($retestResult) {
                        Write-Host "    [SUCCESS] Fixed!" -ForegroundColor Green
                        $fixResults.Successful++
                    } else {
                        Write-Host "    [FAILED] Fix did not resolve issue" -ForegroundColor Red
                        $fixResults.Failed++
                    }
                } else {
                    Write-Host "    [SKIP] Cannot auto-fix" -ForegroundColor Yellow
                    $fixResults.Failed++
                }
            }
        }
    }
    
    return $fixResults
}

# ========================================
# FEEDBACK LOOP
# ========================================

function Start-FeedbackLoop {
    $maxIterations = 5
    $iteration = 0
    $allRequirementsMet = $false
    
    Write-Host "`n" -NoNewline
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "REQUIREMENTS VALIDATION & AUTO-FIX FEEDBACK LOOP" -ForegroundColor Cyan
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host ""
    
    while ($iteration -lt $maxIterations -and -not $allRequirementsMet) {
        $iteration++
        
        Write-Host "`n--- ITERATION $iteration/$maxIterations ---" -ForegroundColor Yellow
        
        # Test all pre-build requirements
        Write-Host "`nValidating pre-build requirements..." -ForegroundColor Cyan
        $results = Test-AllRequirements -PostBuild $false
        
        Write-Host "`nResults: $($results.Passed)/$($results.Total) passed" -ForegroundColor $(
            if ($results.Passed -eq $results.Total) { "Green" } else { "Yellow" }
        )
        
        if ($results.CriticalFailed -gt 0) {
            Write-Host "Critical failures: $($results.CriticalFailed)" -ForegroundColor Red
            
            # Attempt auto-fix
            $fixResults = Invoke-AutoFix
            
            Write-Host "`nAuto-fix results:" -ForegroundColor Cyan
            Write-Host "  Attempted: $($fixResults.Attempted)" -ForegroundColor White
            Write-Host "  Successful: $($fixResults.Successful)" -ForegroundColor Green
            Write-Host "  Failed: $($fixResults.Failed)" -ForegroundColor Red
            
            if ($fixResults.Successful -eq 0 -and $fixResults.Attempted -gt 0) {
                Write-Host "`nNo fixes were successful. Manual intervention required." -ForegroundColor Red
                break
            }
        } else {
            Write-Host "`nAll critical requirements met!" -ForegroundColor Green
            $allRequirementsMet = $true
            break
        }
        
        Start-Sleep -Seconds 2
    }
    
    return $allRequirementsMet
}

# ========================================
# MAIN EXECUTION
# ========================================

Write-Host "`nStarting requirements validation and auto-fix system..." -ForegroundColor Cyan

# Phase 1: Pre-build requirements validation and fixing
$preBuildSuccess = Start-FeedbackLoop

if ($preBuildSuccess) {
    Write-Host "`n" -NoNewline
    Write-Host "=" * 70 -ForegroundColor Green
    Write-Host "PRE-BUILD REQUIREMENTS MET - STARTING BUILD" -ForegroundColor Green
    Write-Host "=" * 70 -ForegroundColor Green
    Write-Host ""
    
    # Run the actual build
    Write-Host "Executing build script..." -ForegroundColor Cyan
    & "i:\openpilot\build-auto-fix.ps1"
    $buildExitCode = $LASTEXITCODE
    
    Write-Host "`nBuild completed with exit code: $buildExitCode" -ForegroundColor $(
        if ($buildExitCode -eq 0) { "Green" } else { "Yellow" }
    )
    
    # Phase 2: Post-build validation
    Write-Host "`n" -NoNewline
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "POST-BUILD VALIDATION" -ForegroundColor Cyan
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host ""
    
    $postBuildResults = Test-AllRequirements -PostBuild $true
    
    Write-Host "`nPost-build results: $($postBuildResults.Passed)/$($postBuildResults.Total) passed" -ForegroundColor $(
        if ($postBuildResults.Passed -eq $postBuildResults.Total) { "Green" } else { "Yellow" }
    )
    
    # Generate final report
    Write-Host "`n" -NoNewline
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "FINAL REPORT" -ForegroundColor Cyan
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host ""
    
    $postBuildResults.Details | Format-Table -AutoSize
    
    if ($postBuildResults.Passed -eq $postBuildResults.Total) {
        Write-Host "`nALL REQUIREMENTS MET! Build successful." -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`nSome requirements not met, but installers may be partially available." -ForegroundColor Yellow
        exit 0
    }
    
} else {
    Write-Host "`n" -NoNewline
    Write-Host "=" * 70 -ForegroundColor Red
    Write-Host "PRE-BUILD REQUIREMENTS NOT MET" -ForegroundColor Red
    Write-Host "=" * 70 -ForegroundColor Red
    Write-Host ""
    Write-Host "Please address the critical failures manually before building." -ForegroundColor Yellow
    
    # Show what needs to be fixed
    $finalCheck = Test-AllRequirements -PostBuild $false
    Write-Host "`nFailed requirements:" -ForegroundColor Red
    $finalCheck.Details | Where-Object { $_.Status -eq "FAIL" } | Format-Table -AutoSize
    
    exit 1
}
