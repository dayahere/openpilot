#!/usr/bin/env pwsh
# Real-time build monitor

$lastLogFile = Get-ChildItem "build-auto-*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $lastLogFile) {
    Write-Host "No build in progress" -ForegroundColor Yellow
    exit
}

Write-Host "`n=== AUTOMATED BUILD MONITOR ===" -ForegroundColor Cyan
Write-Host "Log: $($lastLogFile.Name)" -ForegroundColor Gray
Write-Host "Started: $($lastLogFile.LastWriteTime.ToString('HH:mm:ss'))`n" -ForegroundColor Gray

$lastSize = 0
$iteration = 0

while ($true) {
    Clear-Host
    
    Write-Host "`n=== BUILD PROGRESS [Iteration $iteration] ===" -ForegroundColor Cyan
    Write-Host "Time: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
    Write-Host "Log: $($lastLogFile.Name)`n" -ForegroundColor Gray
    
    # Check if log file is still being written
    $currentSize = (Get-Item $lastLogFile.FullName).Length
    $isActive = $currentSize -gt $lastSize
    $lastSize = $currentSize
    
    if ($isActive) {
        Write-Host "Status: ACTIVE (writing...)" -ForegroundColor Green
    } else {
        Write-Host "Status: Idle" -ForegroundColor Yellow
    }
    
    # Show last 25 lines with color coding
    Write-Host "`n--- Recent Activity ---`n" -ForegroundColor Cyan
    Get-Content $lastLogFile.FullName -Tail 25 | ForEach-Object {
        if ($_ -match "\[SUCCESS\]") {
            Write-Host $_ -ForegroundColor Green
        } elseif ($_ -match "\[ERROR\]") {
            Write-Host $_ -ForegroundColor Red
        } elseif ($_ -match "\[FIX\]") {
            Write-Host $_ -ForegroundColor Magenta
        } elseif ($_ -match "\[WARNING\]") {
            Write-Host $_ -ForegroundColor Yellow
        } elseif ($_ -match "===") {
            Write-Host $_ -ForegroundColor Cyan
        } elseif ($_ -match "^\[.*\].*Building") {
            Write-Host $_ -ForegroundColor Blue
        } else {
            Write-Host $_
        }
    }
    
    # Count successes and errors
    $content = Get-Content $lastLogFile.FullName
    $successes = ($content | Select-String -Pattern "\[SUCCESS\]").Count
    $errors = ($content | Select-String -Pattern "\[ERROR\]").Count
    $fixes = ($content | Select-String -Pattern "\[FIX\]").Count
    
    Write-Host "`n--- Statistics ---" -ForegroundColor Cyan
    Write-Host "  Successes: $successes" -ForegroundColor Green
    Write-Host "  Errors: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Gray" })
    Write-Host "  Fixes Applied: $fixes" -ForegroundColor Magenta
    
    # Check for completion
    if ($content -match "BUILD COMPLETE" -or $content -match "Some builds failed") {
        Write-Host "`n=== BUILD FINISHED ===" -ForegroundColor Yellow
        
        # Show final artifacts
        $latestInstaller = Get-ChildItem "installers" -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestInstaller) {
            Write-Host "`nArtifacts in: $($latestInstaller.Name)" -ForegroundColor Cyan
            $artifacts = Get-ChildItem $latestInstaller.FullName -Recurse -File
            if ($artifacts) {
                foreach ($art in $artifacts) {
                    $size = [math]::Round($art.Length / 1MB, 2)
                    Write-Host "  $($art.Name) - $size MB" -ForegroundColor Green
                }
            }
        }
        break
    }
    
    Write-Host "`nPress Ctrl+C to stop monitoring" -ForegroundColor Gray
    Start-Sleep -Seconds 3
    $iteration++
}

Write-Host ""
