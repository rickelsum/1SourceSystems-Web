# Network Architecture Diagram

## Project Organization

The infrastructure uses a **modular Docker Compose structure** with services organized into logical stacks:

```
1SourceSystems-Web/
├── docker-compose.yml      # Main orchestrator
├── start.sh               # Intelligent startup
├── stop.sh                # Graceful shutdown
├── traefik/               # Reverse proxy stack
├── db/                    # Database stack
├── portainer/             # Management stack
└── cloudflare/            # Cloudflare services
```

Each stack has its own `docker-compose.yml` and can be managed independently.

## High-Level Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           INTERNET                                      │
│                   (Your Dynamic IP: Updated by DDNS)                    │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 │ DNS Resolution
                                 │ portainer.1sourcesystems.com.au
                                 │ etc...
                                 │
                    ┌────────────▼────────────┐
                    │   Cloudflare DNS        │
                    │   (Always up-to-date)   │
                    └────────────┬────────────┘
                                 │
                                 │ HTTPS (443)
                                 │ HTTP (80) → redirects to HTTPS
                                 │
                    ┌────────────▼────────────┐
                    │    ISP Home Router      │
                    │   Port Forwarding:      │
                    │   80  → Server:80       │
                    │   443 → Server:443      │
                    └────────────┬────────────┘
                                 │
                    Local Network│ (192.168.x.x or 10.0.x.x)
                                 │
                    ┌────────────▼────────────┐
                    │    Your Docker Server   │
                    │    (Ubuntu + Docker)    │
                    └─────────────────────────┘
```

## Detailed Docker Network Architecture

```
┌───────────────────────────────────────────────────────────────────────────┐
│                         DOCKER HOST                                       │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                     TRAEFIK (Reverse Proxy)                     │    │
│  │  • Listens on ports 80 & 443                                    │    │
│  │  • Terminates SSL/TLS                                           │    │
│  │  • Routes by hostname                                           │    │
│  │  • Manages Let's Encrypt certificates                           │    │
│  └───────┬──────────────────────────────────────────┬──────────────┘    │
│          │                                           │                   │
│          │  External Network                         │  Internal Network │
│          │  (bridge)                                 │  (bridge)         │
│  ┌───────▼───────────────────────┐    ┌─────────────▼──────────────┐   │
│  │   EXTERNALLY ACCESSIBLE       │    │    INTERNAL ONLY           │   │
│  │   (via Traefik routing)       │    │    (no external access)    │   │
│  │                               │    │                            │   │
│  │  ┌─────────────────────┐     │    │  ┌──────────────────┐     │   │
│  │  │   Portainer         │     │    │  │  PostgreSQL      │     │   │
│  │  │   portainer.1sou... │     │    │  │  (Database)      │     │   │
│  │  │   :9000             │     │    │  │  :5432           │     │   │
│  │  └─────────────────────┘     │    │  └──────────────────┘     │   │
│  │                               │    │          ▲                 │   │
│  │  ┌─────────────────────┐     │    │          │                 │   │
│  │  │   n8n               │◄────┼────┼──────────┘                 │   │
│  │  │   n8n.1source...    │     │    │                            │   │
│  │  │   :5678             │     │    │                            │   │
│  │  └─────────────────────┘     │    │                            │   │
│  │                               │    │                            │   │
│  │  ┌─────────────────────┐     │    │                            │   │
│  │  │   Adminer           │◄────┼────┼──────────────┐             │   │
│  │  │   db.1source...     │     │    │              │             │   │
│  │  │   :8080             │     │    │              │             │   │
│  │  └─────────────────────┘     │    │              │             │   │
│  │                               │    └──────────────┼─────────────┘   │
│  │  ┌─────────────────────┐     │                   │                 │
│  │  │  Cloudflare DDNS    │     │                   │                 │
│  │  │  (Updates DNS)      │     │                   │                 │
│  │  └─────────────────────┘     │                   │                 │
│  └───────────────────────────────┘                   │                 │
│                                                       │                 │
│  Both networks connected ◄───────────────────────────┘                 │
│  (Bridge between external and internal)                                │
│                                                                         │
└───────────────────────────────────────────────────────────────────────────┘
```

## Traffic Flow Examples

### Example 1: n8n Accessing PostgreSQL

```
1. n8n workflow needs database access
   │
2. n8n connects to: postgres:5432 (internal network)
   │
3. PostgreSQL processes query
   │
4. Returns data to n8n
   │
   Note: This traffic NEVER leaves the Docker host
   PostgreSQL is NOT accessible from internet
```

### Example 2: IP Address Changes

```
1. ISP assigns new IP to your router
   │
2. cloudflare-ddns container checks public IP (every 5 minutes)
   │
3. Detects IP has changed
   │
4. Updates Cloudflare DNS A record via API
   │
5. DNS propagates globally (1-2 minutes)
   │
6. All subdomains now point to new IP
   │
   Result: Zero downtime, automatic failover
```

## Port Mapping

### External (Internet) → Router

| Protocol | External Port | Purpose |
|----------|--------------|---------|
| HTTP     | 80           | Initial connection, Let's Encrypt challenge, redirect to HTTPS |
| HTTPS    | 443          | All encrypted traffic |

### Router → Docker Host

| Protocol | Router Port | Host Port | Service |
|----------|-------------|-----------|---------|
| TCP      | 80          | 80        | Traefik |
| TCP      | 443         | 443       | Traefik |

### Traefik → Containers (Internal Routing)

| Hostname | Container | Internal Port |
|----------|-----------|---------------|
| portainer.1sourcesystems.com.au | portainer | 9000 |
| n8n.1sourcesystems.com.au | n8n | 5678 |
| db.1sourcesystems.com.au | adminer | 8080 |
| traefik.1sourcesystems.com.au | traefik | 8080 (API) |

### Internal-Only Services (No External Access)

| Service | Port | Accessed By |
|---------|------|-------------|
| postgres | 5432 | n8n, adminer only |

## Security Layers

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: ISP Router Firewall                                │
│ • Only ports 80 & 443 forwarded                             │
│ • All other ports blocked by default                        │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│ Layer 2: Server Firewall (UFW)                              │
│ • Only allows 80/tcp and 443/tcp                            │
│ • All other ports denied                                    │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│ Layer 3: Traefik (Reverse Proxy)                            │
│ • SSL/TLS termination                                       │
│ • Security headers (HSTS, etc.)                             │
│ • Rate limiting                                             │
│ • Only routes registered services                           │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│ Layer 4: Docker Networks                                    │
│ • External network: Accessible via Traefik                  │
│ • Internal network: Isolated, no external access            │
│ • Services on internal network are completely protected     │
└─────────────────────────────────────────────────────────────┘
```

## DNS Update Flow (Dynamic IP)

```
┌─────────────────────────────────────────────────────────────────┐
│  Your ISP assigns new IP                                        │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ After IP change
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  cloudflare-ddns container checks:                              │
│  • Current public IP (from external service)                    │
│  • Cloudflare DNS A record for 1sourcesystems.com.au           │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ IPs don't match?
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  cloudflare-ddns updates Cloudflare via API:                    │
│  • Updates A record: @ → <new-ip>                              │
│  • All CNAMEs automatically follow                              │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ DNS propagates (1-2 min)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  All domains now point to new IP:                               │
│  • ai.1sourcesystems.com.au → new IP                           │
│  • portainer.1sourcesystems.com.au → new IP                    │
│  • etc...                                                        │
└─────────────────────────────────────────────────────────────────┘
```

## Container Dependencies & Startup Order

The `start.sh` script ensures services start in the correct order:

```
Step 1: Networks & Volumes
          (Created by main docker-compose.yml)
                    │
                    ▼
Step 2:       ┌──────────────┐
              │   traefik/   │
              │   traefik    │ ← Must start first (reverse proxy)
              └──────┬───────┘
                     │
          ┌──────────┴──────────┐
          ▼                     ▼
Step 3: ┌──────┐          ┌──────────┐
        │ db/  │          │          │
        │postgres│        │          │
        │(waits for       │          │
        │ health)│        │          │
        └──┬───┘          │          │
           │              │          │
Step 4:    ▼              ▼
      ┌─────────┐   ┌──────────────┐
      │portainer│   │ cloudflare/  │
      │portainer│   │cloudflared   │
      │          │  │cloudflare-   │
      └─────────┘   │   ddns       │
                    └──────────────┘
```

**Startup Script Benefits:**
- Waits for PostgreSQL health check
- Ensures Traefik is ready before dependent services
- Color-coded progress output
- Final status verification

## Summary

### What's Exposed to Internet:
✅ Traefik (ports 80, 443)
✅ Portainer (via Traefik)
✅ n8n (via Traefik)
✅ Adminer (via Traefik)

### What's Internal Only:
🔒 PostgreSQL (database)
🔒 Docker socket (container management)

### Key Security Features:
- All HTTP → HTTPS redirect
- SSL/TLS 1.2+ only
- Security headers (HSTS, etc.)
- Network segmentation
- No direct container exposure
- Automatic certificate renewal
- Rate limiting available

## Managing Individual Stacks

### Using the Orchestrator

```bash
# Start all services with proper ordering
./start.sh

# Stop all services gracefully
./stop.sh

# Or use docker compose from root
docker compose up -d
docker compose down
```

### Managing Individual Stacks

Each stack can be managed independently:

```bash
# Traefik stack
cd traefik && docker compose up -d

# Database stack
cd db && docker compose up -d

# Portainer stack
cd portainer && docker compose up -d

# Cloudflare stack
cd cloudflare && docker compose up -d
```

### Benefits of Modular Architecture

1. **Independent Updates**: Update AI services without touching database
2. **Easier Debugging**: Focus logs and troubleshooting on specific stack
3. **Flexible Deployment**: Deploy only needed services
4. **Better Organization**: Related services grouped logically
5. **Cleaner Configuration**: Each stack has focused, readable compose file
6. **Team Collaboration**: Different team members can own different stacks
