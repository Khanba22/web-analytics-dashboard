#!/bin/bash
# Web Analytics Platform - Complete Setup and Start Script (Linux/Mac)
# This script handles everything: checks, setup, build, and start

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse arguments
SKIP_CHECKS=false
CLEAN=false
REBUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-checks) SKIP_CHECKS=true; shift ;;
        --clean) CLEAN=true; shift ;;
        --rebuild) REBUILD=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Helper functions
print_success() { echo -e "${GREEN}$1${NC}"; }
print_info() { echo -e "${CYAN}$1${NC}"; }
print_warning() { echo -e "${YELLOW}$1${NC}"; }
print_error() { echo -e "${RED}$1${NC}"; }

# Banner
clear
print_info "======================================================================"
print_info "  🚀 Web Analytics Platform - Complete Setup & Start"
print_info "======================================================================"
echo ""

# Step 1: Check prerequisites
if [ "$SKIP_CHECKS" = false ]; then
    print_info "📋 Step 1/5: Checking Prerequisites..."
    echo ""
    
    # Check Docker
    echo "  Checking Docker..."
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        print_success "  ✅ Docker found: $DOCKER_VERSION"
    else
        print_error "  ❌ Docker not found. Please install Docker."
        echo ""
        echo "  Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check if Docker is running
    echo "  Checking if Docker daemon is running..."
    if docker info &> /dev/null; then
        print_success "  ✅ Docker daemon is running"
    else
        print_error "  ❌ Docker daemon is not running."
        echo "  Please start Docker and try again."
        exit 1
    fi
    
    # Check Docker Compose
    echo "  Checking Docker Compose..."
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version)
        print_success "  ✅ Docker Compose found: $COMPOSE_VERSION"
    else
        print_error "  ❌ Docker Compose not found."
        exit 1
    fi
    
    # Check available memory
    echo "  Checking system resources..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        FREE_MEM=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
        FREE_MEM_GB=$((FREE_MEM * 4096 / 1024 / 1024 / 1024))
    else
        # Linux
        FREE_MEM_GB=$(free -g | awk '/^Mem:/{print $7}')
    fi
    
    if [ "$FREE_MEM_GB" -lt 4 ]; then
        print_warning "  ⚠️  Low memory: ${FREE_MEM_GB}GB free. Recommended: 4GB+"
        echo "  Platform may run slowly."
    else
        print_success "  ✅ System memory: ${FREE_MEM_GB}GB free"
    fi
    
    echo ""
fi

# Step 2: Clean up if requested
if [ "$CLEAN" = true ]; then
    print_info "🧹 Step 2/5: Cleaning Up Previous Installation..."
    echo ""
    print_warning "  ⚠️  This will remove all containers, volumes, and data!"
    read -p "  Continue? (yes/no): " confirmation
    
    if [ "$confirmation" = "yes" ]; then
        echo "  Stopping and removing containers..."
        docker compose down -v 2>/dev/null || true
        print_success "  ✅ Cleanup complete"
    else
        echo "  Skipping cleanup"
    fi
    echo ""
else
    print_info "🧹 Step 2/5: Cleanup (Skipped - use --clean flag to clean)"
    echo ""
fi

# Step 3: Check configuration files
print_info "📝 Step 3/5: Validating Configuration Files..."
echo ""

REQUIRED_FILES=(
    "docker-compose.yml"
    "global_config.yaml"
    "ingestion_api/app.py"
    "python_consumer/app.py"
    "pyspark_cron/etl_job.py"
    "frontend/package.json"
    "postgres_init/01_schema.sql"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "  ✅ $file"
    else
        print_error "  ❌ $file (missing)"
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo ""
    print_error "  Missing required files. Please ensure all project files are present."
    exit 1
fi

echo ""

# Step 4: Build and start services
print_info "🏗️  Step 4/5: Building and Starting Services..."
echo ""

if [ "$REBUILD" = true ]; then
    echo "  Building with --no-cache (full rebuild)..."
    docker compose build --no-cache
fi

echo "  Starting all services..."
docker compose up -d --build

if [ $? -eq 0 ]; then
    print_success "  ✅ All services started successfully!"
else
    print_error "  ❌ Failed to start services"
    echo ""
    echo "  View logs with: docker compose logs"
    exit 1
fi

echo ""

# Step 5: Wait for services to be healthy
print_info "⏳ Step 5/5: Waiting for Services to Initialize..."
echo ""
echo "  This may take 2-3 minutes for first-time setup..."
echo ""

MAX_WAIT=180
ELAPSED=0
WAIT_INTERVAL=5

while [ $ELAPSED -lt $MAX_WAIT ]; do
    ALL_HEALTHY=true
    
    # Check health of services with healthchecks
    for service in zookeeper kafka postgres; do
        HEALTH=$(docker inspect --format='{{.State.Health.Status}}' $service 2>/dev/null || echo "none")
        if [ "$HEALTH" != "healthy" ]; then
            ALL_HEALTHY=false
            break
        fi
    done
    
    # Check if other services are running
    for service in ingestion-api python-consumer pyspark-cron nextjs-dashboard; do
        STATUS=$(docker inspect --format='{{.State.Status}}' $service 2>/dev/null || echo "not found")
        if [ "$STATUS" != "running" ]; then
            ALL_HEALTHY=false
            break
        fi
    done
    
    if [ "$ALL_HEALTHY" = true ]; then
        break
    fi
    
    sleep $WAIT_INTERVAL
    ELAPSED=$((ELAPSED + WAIT_INTERVAL))
    echo -ne "  Waiting... ${ELAPSED}s\r"
done

echo ""

if [ "$ALL_HEALTHY" = true ]; then
    print_success "  ✅ All services are healthy and ready!"
else
    print_warning "  ⚠️  Some services may still be initializing..."
    echo "  The platform should be ready in a few more moments."
fi

echo ""

# Final Summary
print_info "======================================================================"
print_success "  ✅ Platform Started Successfully!"
print_info "======================================================================"
echo ""

print_info "📊 Access Points:"
echo "  • Dashboard:    http://localhost:3000"
echo "  • API:          http://localhost:8000"
echo "  • API Health:   http://localhost:8000/health"
echo "  • Postgres:     localhost:5432"
echo ""

print_info "📤 Send Test Events:"
echo "  • Quick test:   ./test_events.sh"
echo "  • Simulator:    python3 event_simulator.py"
echo ""

print_info "📋 Useful Commands:"
echo "  • View logs:    docker compose logs -f"
echo "  • Stop:         docker compose down"
echo "  • Stop + clean: docker compose down -v"
echo ""

print_info "⏱️  Next Steps:"
echo "  1. Send test events using: python3 event_simulator.py"
echo "  2. Wait 5-10 minutes for ETL to process events"
echo "  3. Open dashboard: http://localhost:3000"
echo ""

print_success "🎉 Happy Analytics!"
echo ""

