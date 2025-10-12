#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Monitor build progress in real-time
#>

$logFile = Get-ChildItem "build-all-fixed-*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $logFile) {
    Write-Host "No build log found. Build may not have started yet." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n=== BUILD PROGRESS MONITOR ===" -ForegroundColor Cyan
Write-Host "Monitoring: $($logFile.Name)`n" -ForegroundColor Gray

while ($true) {
    Clear-Host
    Write-Host "`n=== BUILD PROGRESS ===" -ForegroundColor Cyan
    Write-Host "Log: $($logFile.Name)" -ForegroundColor Gray
    Write-Host "Last updated: $(Get-Date -Format 'HH:mm:ss')`n" -ForegroundColor Gray
    
    # Show last 30 lines
    Get-Content $logFile.FullName -Tail 30 | ForEach-Object {
        if ($_ -match "\[SUCCESS\]") {
            Write-Host $_ -ForegroundColor Green
        } elseif ($_ -match "\[ERROR\]") {
            Write-Host $_ -ForegroundColor Red
        } elseif ($_ -match "\[WARNING\]") {
            Write-Host $_ -ForegroundColor Yellow
        } elseif ($_ -match "===") {
            Write-Host $_ -ForegroundColor Cyan
        } else {
            Write-Host $_
        }
    }
    
    # Check if build is complete
    $content = Get-Content $logFile.FullName -Raw
    if ($content -match "All builds completed|Some builds failed") {
        Write-Host "`n=== BUILD FINISHED ===" -ForegroundColor Yellow
        break
    }
    
    Start-Sleep -Seconds 5
}

# Show final summary
Write-Host "`n=== FINAL SUMMARY ===" -ForegroundColor Cyan

$latestDir = Get-ChildItem "i:\openpilot\installers" -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($latestDir) {
    Write-Host "`nInstaller Directory: $($latestDir.FullName)" -ForegroundColor Yellow
    
    $artifacts = Get-ChildItem $latestDir.FullName -Recurse -File | Where-Object {$_.Extension -in '.vsix','.zip'}
    
    if ($artifacts) {
        Write-Host "`nGenerated Artifacts:" -ForegroundColor Green
        foreach ($artifact in $artifacts) {
            $size = [math]::Round($artifact.Length / 1MB, 2)
            Write-Host "  $($artifact.Name) - $size MB" -ForegroundColor White
        }
    } else {
        Write-Host "`nNo artifacts found yet." -ForegroundColor Yellow
    }
}
