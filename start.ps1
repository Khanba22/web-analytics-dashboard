# Quick Start Script for Web Analytics Platform (Windows PowerShell)
# Run this script to start all services: .\start.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚀 Web Analytics Platform - Quick Start" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "🔍 Checking Docker..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🏗️  Building and starting all services..." -ForegroundColor Yellow
Write-Host "⏱️  This may take 2-3 minutes on first run..." -ForegroundColor Yellow
Write-Host ""

# Start services
docker compose up -d --build

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✅ All services started successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Dashboard: http://localhost:3000" -ForegroundColor Cyan
    Write-Host "🔌 API:       http://localhost:8000" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📤 To send a test event, run:" -ForegroundColor Yellow
    Write-Host "   curl -X POST http://localhost:8000/api/events -H 'Content-Type: application/json' -d '{\"event_type\": \"page_visited\", \"user_id\": \"user_001\", \"session_id\": \"session_001\", \"page_path\": \"/home\"}'" -ForegroundColor White
    Write-Host ""
    Write-Host "📋 To view logs:" -ForegroundColor Yellow
    Write-Host "   docker compose logs -f" -ForegroundColor White
    Write-Host ""
    Write-Host "🛑 To stop all services:" -ForegroundColor Yellow
    Write-Host "   docker compose down" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Failed to start services" -ForegroundColor Red
    Write-Host "Run 'docker compose logs' to see errors" -ForegroundColor Yellow
    exit 1
}

