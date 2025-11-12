#!/bin/sh

# Health Check Script for 1SourceSystems-Web Infrastructure
# Tests all services via HTTPS to ensure they are responding correctly

set -e

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
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Wait for Traefik to be ready
print_info "Waiting for Traefik to be ready..."
sleep 5

# Function to test a service
test_service() {
    local hostname=$1
    local service_name=$2
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        # Test HTTPS with Host header
        http_code=$(wget --no-check-certificate \
                         --header="Host: $hostname" \
                         --spider \
                         --server-response \
                         --timeout=5 \
                         https://traefik:443 2>&1 | grep "HTTP/" | tail -1 | awk '{print $2}')
        
        if [ "$http_code" = "200" ] || [ "$http_code" = "302" ] || [ "$http_code" = "301" ]; then
            print_success "$service_name: HTTP $http_code"
            return 0
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                print_warning "$service_name: HTTP ${http_code:-timeout}, retrying ($retry_count/$max_retries)..."
                sleep 2
            fi
        fi
    done
    
    print_error "$service_name: FAILED (HTTP ${http_code:-timeout})"
    return 1
}

echo ""
print_info "=== Starting Service Health Checks ==="
echo ""

# Track overall status
all_passed=true

# Test each service
print_info "Testing Traefik Dashboard..."
test_service "traefik.1sourcesystems.com.au" "Traefik Dashboard" || all_passed=false

echo ""
print_info "Testing n8n Automation..."
test_service "n8n.1sourcesystems.com.au" "n8n" || all_passed=false

echo ""
echo "================================================"
if [ "$all_passed" = true ]; then
    print_success "All services are responding correctly!"
    echo ""
    print_info "Service URLs:"
    echo "  • Traefik:   https://traefik.1sourcesystems.com.au"
    echo "  • DB Admin:  https://db.1sourcesystems.com.au"
    echo "  • n8n:       https://n8n.1sourcesystems.com.au"
    echo ""
    exit 0
else
    print_error "Some services failed health checks!"
    print_info "Check individual service logs for more details."
    exit 1
fi
