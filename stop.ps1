# Stop Script for Web Analytics Platform (Windows PowerShell)
# Run this script to stop all services: .\stop.ps1

param(
    [switch]$CleanVolumes = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🛑 Web Analytics Platform - Stop" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($CleanVolumes) {
    Write-Host "⚠️  Stopping services and removing volumes..." -ForegroundColor Yellow
    Write-Host "⚠️  This will DELETE ALL DATA!" -ForegroundColor Red
    Write-Host ""
    docker compose down -v
} else {
    Write-Host "🛑 Stopping services (data preserved)..." -ForegroundColor Yellow
    Write-Host ""
    docker compose down
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✅ All services stopped successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    if ($CleanVolumes) {
        Write-Host "🗑️  All data has been removed" -ForegroundColor Yellow
    } else {
        Write-Host "💾 Data volumes preserved" -ForegroundColor Green
        Write-Host ""
        Write-Host "To remove all data, run:" -ForegroundColor Yellow
        Write-Host "   .\stop.ps1 -CleanVolumes" -ForegroundColor White
    }
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Failed to stop services" -ForegroundColor Red
    exit 1
}

