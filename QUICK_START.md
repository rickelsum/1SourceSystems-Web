# Quick Start Guide - 1SourceSystems Web

## TL;DR - Get Running in 10 Minutes

This guide covers setup with **Cloudflare Tunnel** (recommended) for zero port forwarding.

### Step 1: Create Environment File (2 min)
```bash
git clone <your-repo>
cd 1SourceSystems-Web
cp .env.example .env
nano .env
```

Fill in:
- `TUNNEL_TOKEN`: Get from Cloudflare Zero Trust (see step 2)
- `CF_DNS_API_TOKEN`: Optional - for DDNS (staging subdomain)
- `POSTGRES_PASSWORD`: Choose a strong password
- `DOMAIN`: Your domain (e.g., 1sourcesystems.com.au)

### Step 2: Create Cloudflare Tunnel (3 min)

1. Go to [Cloudflare Zero Trust](https://one.dash.cloudflare.com/)
2. Navigate to **Networks** → **Tunnels**
3. Click **Create a tunnel**
4. Name it (e.g., `1sourcesystems-web`)
5. **Copy the tunnel token**
6. Add to `.env`: `TUNNEL_TOKEN=your-token-here`

### Step 3: Configure Public Hostnames (2 min)

In Cloudflare Tunnel dashboard, add these routes (all point to `http://traefik:80`):

| Public Hostname | Service | URL |
|----------------|---------|-----|
| portainer.yourdomain.com | HTTP | `traefik:80` |
| n8n.yourdomain.com | HTTP | `traefik:80` |
| db.yourdomain.com | HTTP | `traefik:80` |
| traefik.yourdomain.com | HTTP | `traefik:80` |

**Note**: DNS records are created automatically!

### Step 4: Get Origin Certificates (2 min)

1. Cloudflare Dashboard → **SSL/TLS** → **Origin Server**
2. Click **Create Certificate**
3. Save as:
   - `traefik/certs/origin-cert.pem`
   - `traefik/certs/origin-key.pem`

### Step 5: Launch! (1 min)
```bash
# Recommended: Use the startup script
./start.sh
```

The script automatically:
- Creates networks and volumes
- Starts services in correct order
- Waits for dependencies (e.g., PostgreSQL health check)
- Shows service status and URLs

### Step 6: Access Your Services

Immediately available (no DNS propagation wait!):

- 🐳 **Container Mgmt**: https://portainer.1sourcesystems.com.au
- 🔄 **Automation**: https://n8n.1sourcesystems.com.au
- 🗄️ **Database Admin**: https://db.1sourcesystems.com.au
- 📊 **Traefik Dashboard**: https://traefik.1sourcesystems.com.au

## Why Cloudflare Tunnel? ✅

- ✅ No port forwarding needed
- ✅ Works behind any firewall/NAT
- ✅ No exposed server IP
- ✅ Built-in DDoS protection
- ✅ Free SSL/TLS
- ✅ Works with ISP port blocking

## Troubleshooting

### Can't access services?

```bash
# Check all containers running
docker compose ps

# Check tunnel status
docker logs cloudflared

# Check Traefik logs
docker logs traefik

# Verify tunnel in Cloudflare dashboard
# Should show "HEALTHY" status
```

### 502 Bad Gateway?

1. Ensure Traefik is running: `docker ps | grep traefik`
2. Check public hostname routes in Cloudflare
3. Verify all routes point to `http://traefik:80`

### Tunnel not connecting?

1. Verify `TUNNEL_TOKEN` in `.env` is correct
2. Check tunnel logs: `docker logs cloudflared`
3. Ensure container can reach internet

## What's Running?

### Service Organization

**Traefik Stack** (`traefik/`)
- Reverse proxy with SSL/TLS termination

**Database Stack** (`db/`)
- PostgreSQL (internal only)
- Adminer (database admin UI)

**Management Stack** (`portainer/`)
- Portainer (container management)

**Cloudflare Stack** (`cloudflare/`)
- Cloudflare Tunnel (secure access)
- Cloudflare DDNS (optional - staging subdomain)

## Security Notes

🔒 **Internal Network Services** (not accessible from internet):
- PostgreSQL (database)

🌐 **External Network Services** (accessible via HTTPS):
- Everything else (protected by SSL + security headers)

## Managing Services

### Start/Stop Commands

```bash
# Start all services (recommended)
./start.sh

# Stop all services
./stop.sh

# View logs
docker compose logs -f <service-name>

# Update services
docker compose pull && docker compose up -d
```

## Next Steps

1. ✅ Change default PostgreSQL password in `.env`
2. ✅ Secure Portainer: Create admin account on first login
3. ✅ Set up backups (see README.md)
4. ✅ Explore n8n workflows

## Need Help?

See full documentation:
- [README.md](README.md) - Complete documentation
- [CLOUDFLARE_TUNNEL_SETUP.md](CLOUDFLARE_TUNNEL_SETUP.md) - Detailed tunnel setup
- [NETWORK_DIAGRAM.md](NETWORK_DIAGRAM.md) - Architecture diagrams
