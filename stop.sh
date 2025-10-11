#!/bin/bash

# Script to stop all Docker Compose stacks in the correct order
# This ensures graceful shutdown in reverse dependency order

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

print_info "Stopping 1SourceSystems-Web infrastructure..."
echo ""

# Stop services in reverse order of dependencies

# Step 1: Stop RustDesk server (no dependencies)
print_info "Step 1: Stopping RustDesk server..."
if [ -f "rustdesk/docker-compose.yml" ]; then
    docker compose -f rustdesk/docker-compose.yml down
    print_success "RustDesk server stopped"
else
    print_warning "RustDesk not configured (skipping)"
fi
echo ""

# Step 2: Stop Twingate connector (no dependencies)
print_info "Step 2: Stopping Twingate connector..."
if [ -f "twingate/docker-compose.yml" ]; then
    docker compose -f twingate/docker-compose.yml down
    print_success "Twingate connector stopped"
else
    print_warning "Twingate not configured (skipping)"
fi
echo ""

# Step 3: Stop Cloudflare services (no dependencies)
print_info "Step 3: Stopping Cloudflare services..."
docker compose -f cloudflare/docker-compose.yml down
print_success "Cloudflare services stopped"
echo ""

# Step 4: Stop Portainer (no dependencies)
print_info "Step 4: Stopping Portainer..."
docker compose -f portainer/docker-compose.yml down
print_success "Portainer stopped"
echo ""

# Step 5: Stop AI services (depends on DB)
print_info "Step 5: Stopping AI services (n8n, Ollama, Open-WebUI)..."
docker compose -f ai/docker-compose.yml down
print_success "AI services stopped"
echo ""

# Step 6: Stop Database services
print_info "Step 6: Stopping database services..."
docker compose -f db/docker-compose.yml down
print_success "Database services stopped"
echo ""

# Step 7: Stop Traefik (reverse proxy - stop last)
print_info "Step 7: Stopping Traefik..."
docker compose -f traefik/docker-compose.yml down
print_success "Traefik stopped"
echo ""

# Final status check
print_info "Checking remaining containers..."
REMAINING=$(docker compose ps --all --quiet | wc -l)

if [ "$REMAINING" -eq 0 ]; then
    print_success "All services stopped successfully!"
else
    print_warning "Some containers may still be running:"
    docker compose ps
fi

echo ""
print_info "Networks and volumes have been preserved."
print_info "To remove networks and volumes, run: docker compose down --volumes"
echo ""
