# Test Event Generator Script for Windows PowerShell
# Sends sample analytics events to test the platform
# Run: .\test_events.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📤 Sending Test Analytics Events" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$API_URL = "http://localhost:8000/api/events"
$EVENT_COUNT = 20

Write-Host "🎯 Sending $EVENT_COUNT sample events..." -ForegroundColor Yellow
Write-Host ""

for ($i = 1; $i -le $EVENT_COUNT; $i++) {
    $userId = "user_$(Get-Random -Minimum 1 -Maximum 10)"
    $sessionId = "session_$(Get-Random -Minimum 1 -Maximum 5)"
    $pages = @("/home", "/products", "/about", "/contact", "/blog")
    $pagePath = $pages | Get-Random
    
    # Random event type
    $eventTypes = @("page_visited", "page_visited", "button_clicked", "page_closed")
    $eventType = $eventTypes | Get-Random
    
    $body = @{
        event_type = $eventType
        user_id = $userId
        session_id = $sessionId
        page_path = $pagePath
    }
    
    # Add button_id for click events
    if ($eventType -eq "button_clicked") {
        $buttons = @("signup_btn", "login_btn", "cta_btn", "nav_btn")
        $body.button_id = $buttons | Get-Random
    }
    
    $json = $body | ConvertTo-Json -Compress
    
    try {
        $response = Invoke-RestMethod -Uri $API_URL -Method Post -Body $json -ContentType "application/json" -ErrorAction Stop
        Write-Host "✅ [$i/$EVENT_COUNT] Sent $eventType for $userId on $pagePath" -ForegroundColor Green
    } catch {
        Write-Host "❌ [$i/$EVENT_COUNT] Failed to send event: $_" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 100
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ Test events sent successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "⏳ Wait 5-10 minutes for ETL to process events" -ForegroundColor Yellow
Write-Host "📊 Then check dashboard at: http://localhost:3000" -ForegroundColor Cyan
Write-Host ""

