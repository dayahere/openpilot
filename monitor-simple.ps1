# Continuous Build Monitor - Simple and Reliable
# Monitors build progress and shows real-time status

param(
    [int]$RefreshInterval = 30,  # seconds between checks
    [int]$MaxMonitorTime = 1800  # 30 minutes max
)

$ErrorActionPreference = "Continue"
$startTime = Get-Date
$OutputDir = "i:\openpilot\installers\auto-fix-build"
$LogFile = "i:\openpilot\build-auto-fix.log"
$MonitorLog = "i:\openpilot\monitor.log"

function Write-MonitorLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $MonitorLog -Value $entry
}

function Get-BuildProgress {
    $progress = @{
        CoreBuilt = $false
        VSCodeBuilt = $false
        WebBuilt = $false
        DesktopBuilt = $false
        DockerActive = $false
        Errors = @()
    }
    
    # Check Docker
    $dockerProcs = Get-Process -Name "docker*" -ErrorAction SilentlyContinue
    $progress.DockerActive = $null -ne $dockerProcs
    
    # Check outputs
    $progress.VSCodeBuilt = Test-Path "$OutputDir\vscode\*.vsix"
    $progress.WebBuilt = Test-Path "$OutputDir\web\*.zip"
    $progress.DesktopBuilt = Test-Path "$OutputDir\desktop\index.html"
    
    # Check log
    if (Test-Path $LogFile) {
        $recentLog = Get-Content $LogFile -Tail 30 -ErrorAction SilentlyContinue
        $progress.CoreBuilt = $recentLog | Where-Object { $_ -match "Core.*built.*successfully" }
        $progress.Errors = $recentLog | Where-Object { $_ -match "\[ERROR\]" }
    }
    
    return $progress
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          CONTINUOUS BUILD MONITOR - AUTO-FIX SYSTEM               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-MonitorLog "Monitor started" "INFO"

$iteration = 0

while ($true) {
    $iteration++
    $elapsed = (Get-Date) - $startTime
    
    # Check timeout
    if ($elapsed.TotalSeconds -gt $MaxMonitorTime) {
        Write-Host "`n[TIMEOUT] Maximum monitoring time reached" -ForegroundColor Red
        break
    }
    
    Clear-Host
    
    # Header
    Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          BUILD MONITOR - Iteration #$iteration" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Time info
    $elapsedMin = [math]::Floor($elapsed.TotalMinutes)
    $elapsedSec = $elapsed.Seconds
    Write-Host "⏱️  Elapsed: $elapsedMin min $elapsedSec sec" -ForegroundColor Gray
    Write-Host ""
    
    # Get status
    $progress = Get-BuildProgress
    
    # Docker status
    Write-Host "═══ DOCKER STATUS ═══" -ForegroundColor Yellow
    if ($progress.DockerActive) {
        Write-Host "  ✅ Docker processes active" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  No Docker processes detected" -ForegroundColor Red
    }
    Write-Host ""
    
    # Build status
    Write-Host "═══ BUILD PROGRESS ═══" -ForegroundColor Yellow
    
    $completed = 0
    $total = 4
    
    Write-Host "  Core Package:      " -NoNewline
    if ($progress.CoreBuilt) {
        Write-Host "✅ BUILT" -ForegroundColor Green
        $completed++
    } else {
        Write-Host "🔄 Building..." -ForegroundColor Yellow
    }
    
    Write-Host "  VSCode Extension:  " -NoNewline
    if ($progress.VSCodeBuilt) {
        $vsixFile = Get-Item "$OutputDir\vscode\*.vsix" -ErrorAction SilentlyContinue
        if ($vsixFile) {
            $sizeMB = [math]::Round($vsixFile.Length / 1KB, 2)
            Write-Host "✅ BUILT ($sizeMB KB)" -ForegroundColor Green
        } else {
            Write-Host "✅ BUILT" -ForegroundColor Green
        }
        $completed++
    } else {
        Write-Host "⏳ Pending" -ForegroundColor Gray
    }
    
    Write-Host "  Web App:           " -NoNewline
    if ($progress.WebBuilt) {
        $zipFile = Get-Item "$OutputDir\web\*.zip" -ErrorAction SilentlyContinue
        if ($zipFile) {
            $sizeMB = [math]::Round($zipFile.Length / 1MB, 2)
            Write-Host "✅ BUILT ($sizeMB MB)" -ForegroundColor Green
        } else {
            Write-Host "✅ BUILT" -ForegroundColor Green
        }
        $completed++
    } else {
        Write-Host "⏳ Pending" -ForegroundColor Gray
    }
    
    Write-Host "  Desktop App:       " -NoNewline
    if ($progress.DesktopBuilt) {
        $desktopFiles = Get-ChildItem "$OutputDir\desktop" -Recurse -File -ErrorAction SilentlyContinue
        if ($desktopFiles) {
            Write-Host "✅ BUILT ($($desktopFiles.Count) files)" -ForegroundColor Green
        } else {
            Write-Host "✅ BUILT" -ForegroundColor Green
        }
        $completed++
    } else {
        Write-Host "⏳ Pending" -ForegroundColor Gray
    }
    
    Write-Host ""
    
    # Progress bar
    $percent = [math]::Round(($completed / $total) * 100)
    $barLength = 50
    $filled = [math]::Floor($percent / 2)
    $empty = $barLength - $filled
    
    $bar = "[" + ("█" * $filled) + ("░" * $empty) + "] $percent%"
    Write-Host "  Overall: $bar" -ForegroundColor Cyan
    Write-Host ""
    
    # Recent log
    Write-Host "═══ RECENT LOG ACTIVITY ═══" -ForegroundColor Yellow
    if (Test-Path $LogFile) {
        $recent = Get-Content $LogFile -Tail 5 -ErrorAction SilentlyContinue
        if ($recent) {
            foreach ($line in $recent) {
                if ($line -match "\[SUCCESS\]") {
                    Write-Host "  $line" -ForegroundColor Green
                } elseif ($line -match "\[ERROR\]") {
                    Write-Host "  $line" -ForegroundColor Red
                } elseif ($line -match "\[WARNING\]") {
                    Write-Host "  $line" -ForegroundColor Yellow
                } else {
                    Write-Host "  $line" -ForegroundColor Gray
                }
            }
        }
    } else {
        Write-Host "  (No log file yet)" -ForegroundColor DarkGray
    }
    Write-Host ""
    
    # Errors
    if ($progress.Errors -and $progress.Errors.Count -gt 0) {
        Write-Host "═══ ERRORS DETECTED ═══" -ForegroundColor Red
        $progress.Errors | Select-Object -First 3 | ForEach-Object {
            Write-Host "  ⚠️  $_" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    # Check if complete
    if ($completed -eq $total) {
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║                    🎉 BUILD COMPLETE! 🎉                          ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "Generated Installers:" -ForegroundColor Cyan
        Write-Host "  📦 VSCode: $OutputDir\vscode\" -ForegroundColor White
        Write-Host "  📦 Web:    $OutputDir\web\" -ForegroundColor White
        Write-Host "  📦 Desktop: $OutputDir\desktop\" -ForegroundColor White
        Write-Host ""
        
        Write-MonitorLog "All builds completed!" "SUCCESS"
        
        # Open folder
        Write-Host "Opening output folder..." -ForegroundColor Cyan
        Start-Process explorer.exe -ArgumentList $OutputDir
        
        # Run tests
        Write-Host "`nRunning validation tests..." -ForegroundColor Cyan
        if (Test-Path "i:\openpilot\tests\AutoFix.Tests.ps1") {
            Invoke-Pester -Path "i:\openpilot\tests\AutoFix.Tests.ps1" -Output Detailed
        }
        
        break
    }
    
    # Footer
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Host "  Press Ctrl+C to stop | Refreshing in $RefreshInterval seconds..." -ForegroundColor DarkGray
    Write-Host ""
    
    Start-Sleep -Seconds $RefreshInterval
}

Write-Host "`n✅ Monitoring complete!" -ForegroundColor Green
Write-Host "Monitor log: $MonitorLog" -ForegroundColor Gray
Write-Host ""
