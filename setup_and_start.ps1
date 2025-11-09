# Web Analytics Platform - Complete Setup and Start Script
# This script handles everything: checks, setup, build, and start

param(
    [switch]$SkipChecks = $false,
    [switch]$Clean = $false,
    [switch]$Rebuild = $false
)

$ErrorActionPreference = "Stop"

# Color functions
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success { Write-ColorOutput Green $args }
function Write-Info { Write-ColorOutput Cyan $args }
function Write-Warning { Write-ColorOutput Yellow $args }
function Write-Error-Custom { Write-ColorOutput Red $args }

# Banner
Clear-Host
Write-Info "=" * 70
Write-Info "  Web Analytics Platform - Complete Setup & Start"
Write-Info "=" * 70
Write-Output ""

# Step 1: Check prerequisites
if (-not $SkipChecks) {
    Write-Info "Step 1/5: Checking Prerequisites..."
    Write-Output ""
    
    # Check Docker
    Write-Output "  Checking Docker..."
    try {
        $dockerVersion = docker --version
        Write-Success "  Docker found: $dockerVersion"
    } catch {
        Write-Error-Custom "  Docker not found. Please install Docker Desktop."
        Write-Output ""
        Write-Output "  Download from: https://www.docker.com/products/docker-desktop"
        exit 1
    }
    
    # Check if Docker is running
    Write-Output "  Checking if Docker is running..."
    try {
        docker info | Out-Null
        Write-Success "  Docker daemon is running"
    } catch {
        Write-Error-Custom "  Docker daemon is not running."
        Write-Output "  Please start Docker Desktop and try again."
        exit 1
    }
    
    # Check Docker Compose
    Write-Output "  Checking Docker Compose..."
    try {
        $composeVersion = docker compose version
        Write-Success "  Docker Compose found: $composeVersion"
    } catch {
        Write-Error-Custom "  Docker Compose not found."
        exit 1
    }
    
    # Check available memory
    Write-Output "  Checking system resources..."
    $os = Get-CimInstance Win32_OperatingSystem
    $freeMemoryGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    
    if ($freeMemoryGB -lt 4) {
        Write-Warning "  Warning: Low memory: ${freeMemoryGB}GB free. Recommended: 4GB+"
        Write-Output "  Platform may run slowly. Close other applications for best performance."
    } else {
        Write-Success "  System memory: ${freeMemoryGB}GB free"
    }
    
    Write-Output ""
}

# Step 2: Clean up if requested
if ($Clean) {
    Write-Info "Step 2/5: Cleaning Up Previous Installation..."
    Write-Output ""
    Write-Warning "  Warning: This will remove all containers, volumes, and data!"
    $confirmation = Read-Host "  Continue? (yes/no)"
    
    if ($confirmation -eq "yes") {
        Write-Output "  Stopping and removing containers..."
        docker compose down -v 2>$null
        Write-Success "  Cleanup complete"
    } else {
        Write-Output "  Skipping cleanup"
    }
    Write-Output ""
} else {
    Write-Info "Step 2/5: Cleanup (Skipped - use -Clean flag to clean)"
    Write-Output ""
}

# Step 3: Check configuration files
Write-Info "Step 3/5: Validating Configuration Files..."
Write-Output ""

$requiredFiles = @(
    "docker-compose.yml",
    "global_config.yaml",
    "ingestion_api/app.py",
    "python_consumer/app.py",
    "pyspark_cron/etl_job.py",
    "frontend/package.json",
    "postgres_init/01_schema.sql"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Success "  $file"
    } else {
        Write-Error-Custom "  $file (missing)"
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Output ""
    Write-Error-Custom "  Missing required files. Please ensure all project files are present."
    exit 1
}

Write-Output ""

# Step 4: Build and start services
Write-Info "Step 4/5: Building and Starting Services..."
Write-Output ""

if ($Rebuild) {
    Write-Output "  Building with --no-cache (full rebuild)..."
    $buildArgs = "--no-cache"
} else {
    Write-Output "  Building services..."
    $buildArgs = ""
}

try {
    if ($buildArgs) {
        docker compose build $buildArgs
    }
    
    Write-Output ""
    Write-Output "  Starting all services..."
    docker compose up -d --build
    
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose failed"
    }
    
    Write-Success "  All services started successfully!"
} catch {
    Write-Error-Custom "  Failed to start services"
    Write-Output ""
    Write-Output "  View logs with: docker compose logs"
    exit 1
}

Write-Output ""

# Step 5: Wait for services to be healthy
Write-Info "Step 5/5: Waiting for Services to Initialize..."
Write-Output ""

Write-Output "  This may take 2-3 minutes for first-time setup..."
Write-Output ""

$maxWaitTime = 180  # 3 minutes
$waitInterval = 5
$elapsedTime = 0

$services = @(
    @{Name="Zookeeper"; Container="zookeeper"; HealthCheck=$true},
    @{Name="Kafka"; Container="kafka"; HealthCheck=$true},
    @{Name="Postgres"; Container="postgres"; HealthCheck=$true},
    @{Name="Ingestion API"; Container="ingestion-api"; HealthCheck=$false},
    @{Name="Python Consumer"; Container="python-consumer"; HealthCheck=$false},
    @{Name="PySpark ETL"; Container="pyspark-cron"; HealthCheck=$false},
    @{Name="Dashboard"; Container="nextjs-dashboard"; HealthCheck=$false}
)

function Get-ContainerStatus($containerName) {
    try {
        $status = docker inspect --format='{{.State.Status}}' $containerName 2>$null
        return $status
    } catch {
        return "not found"
    }
}

function Get-ContainerHealth($containerName) {
    try {
        $health = docker inspect --format='{{.State.Health.Status}}' $containerName 2>$null
        return $health
    } catch {
        return "none"
    }
}

$allHealthy = $false
while (-not $allHealthy -and $elapsedTime -lt $maxWaitTime) {
    $allHealthy = $true
    $statusMessages = @()
    
    foreach ($service in $services) {
        $status = Get-ContainerStatus $service.Container
        
        if ($status -ne "running") {
            $allHealthy = $false
            $statusMessages += "  $($service.Name): $status"
        } elseif ($service.HealthCheck) {
            $health = Get-ContainerHealth $service.Container
            if ($health -eq "healthy") {
                $statusMessages += "  $($service.Name): healthy"
            } else {
                $allHealthy = $false
                $statusMessages += "  $($service.Name): $health"
            }
        } else {
            $statusMessages += "  $($service.Name): running"
        }
    }
    
    # Clear and display status
    if ($elapsedTime -gt 0) {
        # Move cursor up to overwrite previous status
        for ($i = 0; $i -lt ($services.Count + 1); $i++) {
            Write-Host "`r`033[1A`033[K" -NoNewline
        }
    }
    
    Write-Output "  Status (${elapsedTime}s elapsed):"
    foreach ($msg in $statusMessages) {
        Write-Output $msg
    }
    
    if (-not $allHealthy) {
        Start-Sleep -Seconds $waitInterval
        $elapsedTime += $waitInterval
    }
}

Write-Output ""

if ($allHealthy) {
    Write-Success "  All services are healthy and ready!"
} else {
    Write-Warning "  Some services may still be initializing..."
    Write-Output "  The platform should be ready in a few more moments."
}

Write-Output ""

# Final Summary
Write-Info "=" * 70
Write-Success "  Platform Started Successfully!"
Write-Info "=" * 70
Write-Output ""

Write-Info "Access Points:"
Write-Output "  - Dashboard:    http://localhost:3000"
Write-Output "  - API:          http://localhost:8000"
Write-Output "  - API Health:   http://localhost:8000/health"
Write-Output "  - Postgres:     localhost:5432"
Write-Output ""

Write-Info "Send Test Events:"
Write-Output "  - PowerShell:   .\test_events.ps1"
Write-Output "  - Simulator:    python event_simulator.py"
Write-Output ""

Write-Info "Useful Commands:"
Write-Output "  - View logs:    docker compose logs -f"
Write-Output "  - Stop:         docker compose down"
Write-Output "  - Stop + clean: docker compose down -v"
Write-Output ""

Write-Info "Next Steps:"
Write-Output "  1. Send test events using: .\test_events.ps1"
Write-Output "  2. Wait 5-10 minutes for ETL to process events"
Write-Output "  3. Open dashboard: http://localhost:3000"
Write-Output ""

Write-Success "Happy Analytics!"
Write-Output ""

