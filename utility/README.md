# Utility Services

This folder contains utility services for the 1SourceSystems-Web infrastructure.

## Services

### Health Check

An Alpine Linux container that performs health checks on all services via HTTPS.

**Features:**
- Tests all services (Traefik, Portainer, Adminer, Open-WebUI, n8n)
- Uses HTTPS with proper Host headers
- Retry logic for transient failures
- Color-coded output
- Automatic cleanup after completion

**Usage:**

Manually run health checks:
```bash
docker compose -f utility/docker-compose.yml run --rm health-check
```

The health check is automatically run by `./start.sh` after all services are started.

**What It Tests:**

| Service | URL | Expected |
|---------|-----|----------|
| Traefik Dashboard | https://traefik.1sourcesystems.com.au | HTTP 200 |
| Portainer | https://portainer.1sourcesystems.com.au | HTTP 200 |
| Adminer | https://db.1sourcesystems.com.au | HTTP 200 |
| Open-WebUI | https://ai.1sourcesystems.com.au | HTTP 200 |
| n8n | https://n8n.1sourcesystems.com.au | HTTP 200 |

**Script Details:**

- **Location**: `utility/health-check.sh`
- **Image**: `alpine:latest` (minimal footprint)
- **Network**: Connects to `1sourcesystems-web_external`
- **Restart Policy**: `no` (runs once and exits)

## Adding New Utility Services

To add new utility services:

1. Add the service to `docker-compose.yml`
2. Create any required scripts in this folder
3. Update this README with documentation

## Notes

- Utility services are ephemeral and don't run continuously
- They connect to the external network to test service availability
- The health-check container automatically removes itself after completion
