#!/bin/bash

# Script to start all Docker Compose stacks in the correct dependency order
# This ensures services with dependencies start after their required services

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if docker compose is available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not available"
    exit 1
fi

print_info "Starting 1SourceSystems-Web infrastructure..."
echo ""

# Step 1: Ensure networks and volumes exist
print_info "Step 1: Ensuring networks and volumes exist..."
docker network create 1sourcesystems-web_external 2>/dev/null || true
docker network create 1sourcesystems-web_internal 2>/dev/null || true
docker volume create 1sourcesystems-web_postgres_data 2>/dev/null || true
docker volume create 1sourcesystems-web_n8n_data 2>/dev/null || true
print_success "Networks and volumes ready"
echo ""

# Step 2: Start Traefik (reverse proxy - must be first)
print_info "Step 2: Starting Traefik reverse proxy..."
docker compose --env-file .env -f traefik/docker-compose.yml up -d --remove-orphans
print_success "Traefik started"
echo ""

# Wait for Traefik to be healthy
print_info "Waiting for Traefik to be ready..."
sleep 3

# Step 3: Start Database services (PostgreSQL + Adminer)
print_info "Step 3: Starting database services (PostgreSQL + Adminer)..."
docker compose --env-file .env -f db/docker-compose.yml up -d --remove-orphans
print_success "Database services started"
echo ""

# Wait for PostgreSQL to be healthy
print_info "Waiting for PostgreSQL to be ready..."
timeout 30 bash -c 'until docker exec postgres pg_isready -U n8n &>/dev/null; do sleep 1; done' || {
    print_warning "PostgreSQL health check timed out, but continuing..."
}
print_success "PostgreSQL is ready"
echo ""

# Step 4: Start n8n (Workflow Automation)
print_info "Step 4: Starting n8n automation service..."
docker compose --env-file .env up -d --no-deps n8n
print_success "n8n service started"
echo ""

# Step 5: Start Cloudflare services (DDNS + Tunnel)
print_info "Step 5: Starting Cloudflare services (DDNS + Tunnel)..."
docker compose --env-file .env -f cloudflare/docker-compose.yml up -d --remove-orphans
print_success "Cloudflare services started"
echo ""

# Step 6: Start Twingate connector (Zero Trust network access)
print_info "Step 6: Starting Twingate connector..."
if [ -f "twingate/docker-compose.yml" ]; then
    docker compose --env-file .env -f twingate/docker-compose.yml up -d --remove-orphans
    print_success "Twingate connector started"
else
    print_warning "Twingate not configured (twingate/docker-compose.yml not found)"
fi
echo ""

# Step 7: Start RustDesk server (Remote desktop)
print_info "Step 7: Starting RustDesk server..."
if [ -f "rustdesk/docker-compose.yml" ]; then
    docker compose --env-file .env -f rustdesk/docker-compose.yml up -d --remove-orphans
    print_success "RustDesk server started"
else
    print_warning "RustDesk not configured (rustdesk/docker-compose.yml not found)"
fi
echo ""


# Step 8: Run Health Checks
print_info "Step 8: Running health checks on all services..."
echo ""
docker compose --env-file .env -f utility/docker-compose.yml run --rm health-check

# Final status check
print_info "Checking service status..."
echo ""
docker compose --env-file .env ps

echo ""
print_info "To stop all services, run: ./stop.sh or docker compose down"
