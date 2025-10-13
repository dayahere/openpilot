# Monitor Container Build Progress
# Quick status checker for local-container-build.ps1

Write-Host "`n========== BUILD MONITOR ==========" -ForegroundColor Cyan
Write-Host "Checking container build progress...`n" -ForegroundColor Yellow

# Check for latest artifact directory
$artifactBase = "artifacts-local"
if (Test-Path $artifactBase) {
    $latestBuild = Get-ChildItem $artifactBase -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    if ($latestBuild) {
        Write-Host "Latest Build: $($latestBuild.Name)" -ForegroundColor Green
        Write-Host "Started: $($latestBuild.LastWriteTime)" -ForegroundColor Gray
        
        # Check for logs
        $logsDir = Join-Path $latestBuild.FullName "logs"
        if (Test-Path $logsDir) {
            Write-Host "`nBuild Logs Available:" -ForegroundColor Yellow
            Get-ChildItem $logsDir -File | ForEach-Object {
                $lines = (Get-Content $_.FullName | Measure-Object -Line).Lines
                Write-Host "  $($_.Name): $lines lines" -ForegroundColor White
            }
        }
        
        # Check for artifacts
        Write-Host "`nArtifacts Generated:" -ForegroundColor Yellow
        $artifacts = @{
            "VSCode" = Get-ChildItem (Join-Path $latestBuild.FullName "vscode") -Filter "*.vsix" -ErrorAction SilentlyContinue
            "Web" = Get-ChildItem (Join-Path $latestBuild.FullName "web") -Filter "*.tar.gz" -ErrorAction SilentlyContinue
            "Desktop" = Get-ChildItem (Join-Path $latestBuild.FullName "desktop") -Filter "*.tar.gz" -ErrorAction SilentlyContinue
            "Android" = Get-ChildItem (Join-Path $latestBuild.FullName "android") -Filter "*.apk" -ErrorAction SilentlyContinue
        }
        
        foreach ($platform in $artifacts.Keys) {
            if ($artifacts[$platform]) {
                $size = [math]::Round($artifacts[$platform].Length / 1MB, 2)
                Write-Host "  ✓ $platform : $($artifacts[$platform].Name) ($size MB)" -ForegroundColor Green
            } else {
                Write-Host "  ⏳ $platform : Building..." -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "No build directories found yet." -ForegroundColor Yellow
    }
} else {
    Write-Host "No artifacts directory yet - build is starting..." -ForegroundColor Yellow
}

# Check Docker containers
Write-Host "`nDocker Containers:" -ForegroundColor Yellow
$containers = docker ps -a --filter "name=openpilot" --format "{{.Names}}: {{.Status}}" 2>$null
if ($containers) {
    $containers | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
} else {
    Write-Host "  No active containers" -ForegroundColor Gray
}

# Check Docker images
Write-Host "`nDocker Images Built:" -ForegroundColor Yellow
$images = docker images --filter "reference=openpilot-*" --format "{{.Repository}}: {{.Size}}" 2>$null
if ($images) {
    $images | ForEach-Object {
        Write-Host "  $_" -ForegroundColor White
    }
} else {
    Write-Host "  No images built yet" -ForegroundColor Gray
}

Write-Host "`n=================================" -ForegroundColor Cyan
Write-Host "Run this script again to check progress" -ForegroundColor Yellow
Write-Host "Estimated total time: 15-25 minutes`n" -ForegroundColor Gray
