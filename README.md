# 1SourceSystems AI Lab - Docker Infrastructure

This setup provides a complete AI and automation infrastructure with **Cloudflare Tunnel** for secure access, external and internal network segmentation, and automatic SSL via Cloudflare.

## Architecture Overview

### Network Segmentation

**External Network** (accessible via Cloudflare Tunnel):
- Traefik (reverse proxy)
- Open WebUI (AI interface)
- Portainer (container management)
- n8n (workflow automation)
- Adminer (database admin)
- Cloudflared (Cloudflare Tunnel connector)

**Internal Network** (only accessible between containers):
- Ollama (AI model backend)
- PostgreSQL (database)

### How Cloudflare Tunnel Works

```
User → Cloudflare (HTTPS) → Tunnel → Docker Network → Traefik (HTTP) → Services
```

**Benefits**:
- ✅ **No port forwarding needed** - Works behind any firewall/NAT
- ✅ **No ISP port blocking issues** - Uses outbound connections only
- ✅ **Hidden server IP** - Your IP never exposed
- ✅ **DDoS protection** - Built-in with Cloudflare
- ✅ **Free SSL/TLS** - Managed by Cloudflare
- ✅ **Works anywhere** - Home, mobile, CGNAT, etc.

## Services & Access URLs

| Service | URL | Access | Purpose |
|---------|-----|--------|---------|
| Traefik Dashboard | https://traefik.1sourcesystems.com.au | External | Reverse proxy dashboard |
| Open WebUI | https://ai.1sourcesystems.com.au | External | AI chat interface |
| Portainer | https://portainer.1sourcesystems.com.au | External | Docker management |
| n8n | https://n8n.1sourcesystems.com.au | External | Workflow automation |
| Adminer | https://db.1sourcesystems.com.au | External | Database admin |
| Ollama | Internal only | Internal | AI model backend |
| PostgreSQL | Internal only | Internal | Database |

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- A domain managed by Cloudflare
- Cloudflare account (free tier works!)

### Setup Instructions

#### 1. Clone and Configure Environment

```bash
# Clone the repository
git clone <your-repo>
cd 1SourceSystems-AI-Lab

# Copy environment template
cp .env.example .env

# Edit with your values
nano .env
```

#### 2. Get Cloudflare API Token (for DDNS - Optional)

The DDNS service keeps a staging subdomain updated with your IP (useful for direct SSH access).

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Go to **My Profile** → **API Tokens**
3. Click **Create Token**
4. Use the **Edit zone DNS** template
5. Configure:
   - **Permissions**: Zone → DNS → Edit
   - **Zone Resources**: Include → Specific zone → your domain
6. Copy token and add to `.env` as `CF_DNS_API_TOKEN`

#### 3. Create Cloudflare Tunnel

1. Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Navigate to **Networks** → **Tunnels**
3. Click **Create a tunnel**
4. Select **Cloudflared** connector type
5. Name your tunnel (e.g., `1sourcesystems-ai-lab`)
6. Click **Save tunnel**
7. **Copy the tunnel token** from the setup instructions
8. Add token to `.env` as `TUNNEL_TOKEN=your-token-here`

#### 4. Configure Public Hostname Routes

In the Cloudflare Tunnel dashboard, add these routes:

For each subdomain, configure:
- **Type**: HTTP
- **URL**: `traefik:80`

Routes to add:

| Public Hostname | Service URL |
|----------------|-------------|
| `ai.yourdomain.com` | `http://traefik:80` |
| `portainer.yourdomain.com` | `http://traefik:80` |
| `n8n.yourdomain.com` | `http://traefik:80` |
| `db.yourdomain.com` | `http://traefik:80` |
| `traefik.yourdomain.com` | `http://traefik:80` |

**Note**: DNS records are automatically created by Cloudflare Tunnel. You don't need to manually create them!

#### 5. Get Cloudflare Origin Certificates (Already Configured)

The repository includes placeholders for Cloudflare origin certificates. To get your own:

1. Go to Cloudflare Dashboard → **SSL/TLS** → **Origin Server**
2. Click **Create Certificate**
3. Select:
   - **Generate private key and CSR with Cloudflare**
   - **Hostnames**: `*.yourdomain.com`, `yourdomain.com`
   - **Certificate Validity**: 15 years
4. Click **Create**
5. Copy the certificate and private key
6. Save them as:
   - `traefik/certs/origin-cert.pem` (certificate)
   - `traefik/certs/origin-key.pem` (private key)

**Note**: These files are already in `.gitignore` and won't be committed.

#### 6. Update Configuration Files

Update these files with your domain:
- `docker-compose.yml` - Replace `1sourcesystems.com.au` with your domain
- `.env` - Set `DOMAIN=yourdomain.com`

#### 7. Launch Services

```bash
# Start all services
docker-compose up -d

# Check tunnel status
docker logs cloudflared

# Check all services
docker-compose ps
```

Look for in cloudflared logs:
```
Registered tunnel connection
Updated to new configuration
```

#### 8. Access Your Services

After tunnel connects (usually instant), access via:

- https://ai.yourdomain.com - Open WebUI
- https://portainer.yourdomain.com - Portainer
- https://n8n.yourdomain.com - n8n
- https://db.yourdomain.com - Adminer
- https://traefik.yourdomain.com - Traefik Dashboard

**No waiting for DNS propagation!** Services are accessible immediately.

## Environment Variables

Required variables in `.env`:

```bash
# Cloudflare Tunnel Token (Required)
TUNNEL_TOKEN=your-tunnel-token-here

# Cloudflare API for DDNS (Optional - for staging subdomain)
CF_DNS_API_TOKEN=your-api-token-here

# Database Credentials (Required)
POSTGRES_USER=n8n
POSTGRES_PASSWORD=change-this-secure-password
POSTGRES_DB=n8n

# Domain (Required)
DOMAIN=yourdomain.com
```

## Security Features

### Network Isolation
- **Internal network**: Completely isolated from the internet
- **External network**: Only exposed through Cloudflare Tunnel
- Ollama and PostgreSQL are NOT accessible from the internet
- No ports exposed on your router

### SSL/TLS
- SSL termination handled by Cloudflare
- Cloudflare origin certificates for tunnel → server encryption
- All traffic encrypted end-to-end
- No certificate management needed

### Headers
- Security headers automatically applied via Traefik
- Additional protection from Cloudflare WAF

### Cloudflare Protection
- DDoS protection included
- WAF (Web Application Firewall) available
- Rate limiting available
- Bot protection available

## Troubleshooting

### Tunnel Not Connecting

1. **Check tunnel token**:
   ```bash
   docker logs cloudflared
   ```
   Look for authentication errors

2. **Verify token in .env**:
   ```bash
   cat .env | grep TUNNEL_TOKEN
   ```

3. **Check tunnel status in Cloudflare**:
   - Go to Zero Trust Dashboard → Networks → Tunnels
   - Status should show **HEALTHY** (green)

### Services Return 502 Bad Gateway

1. **Check Traefik is running**:
   ```bash
   docker ps | grep traefik
   ```

2. **Verify service is running**:
   ```bash
   docker-compose ps
   ```

3. **Check Traefik logs**:
   ```bash
   docker logs traefik
   ```

4. **Verify hostname routes in Cloudflare**:
   - Ensure all routes point to `http://traefik:80`
   - Check for typos in hostnames

### ERR_TOO_MANY_REDIRECTS

This was fixed in the current configuration, but if it occurs:

1. **Check Traefik entrypoint**:
   - Services should use `entrypoints=web` (port 80)
   - NOT `entrypoints=websecure` (port 443)

2. **Verify no SSL redirect in middleware**:
   ```bash
   cat traefik/dynamic.yml | grep sslRedirect
   ```
   Should be `false`

### Service Not Accessible

1. **Check if container is running**:
   ```bash
   docker-compose ps
   ```

2. **Check tunnel logs**:
   ```bash
   docker logs cloudflared -f
   ```

3. **Test from server**:
   ```bash
   curl -I https://ai.yourdomain.com
   ```

4. **Check Cloudflare tunnel dashboard**:
   - Verify tunnel is HEALTHY
   - Verify routes are configured correctly

## Database Access via Adminer

Access: https://db.yourdomain.com

Login credentials:
- **System**: PostgreSQL
- **Server**: `postgres`
- **Username**: (value from `.env` POSTGRES_USER)
- **Password**: (value from `.env` POSTGRES_PASSWORD)
- **Database**: (value from `.env` POSTGRES_DB)

## Useful Commands

```bash
# View all running containers
docker-compose ps

# View logs for a specific service
docker-compose logs -f <service-name>

# View tunnel status
docker logs cloudflared -f

# Restart a specific service
docker-compose restart <service-name>

# Stop all services
docker-compose down

# Start all services
docker-compose up -d

# Update all services to latest images
docker-compose pull
docker-compose up -d

# Check tunnel connectivity
docker exec cloudflared cloudflared tunnel info
```

## Backup Strategy

Important directories to backup:

- `traefik/certs/` - Cloudflare origin certificates
- Docker volumes (PostgreSQL, n8n, Open WebUI data)

```bash
# Backup PostgreSQL
docker exec postgres pg_dump -U n8n n8n > backup_$(date +%Y%m%d).sql

# Backup all volumes
docker run --rm \
  -v 1sourcesystems-ai-lab_postgres_data:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/postgres_backup.tar.gz /data
```

## Alternative Access Methods

### Why We Use Cloudflare Tunnel

This setup uses **Cloudflare Tunnel** because it:
- Works with **any ISP** (even those blocking ports 80/443)
- Works behind **CGNAT** or mobile hotspots
- Requires **no router configuration**
- Provides **DDoS protection**
- Hides your **server IP**
- Is completely **free**

### Other Options (Not Recommended for This Setup)

#### Direct Access with Port Forwarding
❌ **Not recommended** because:
- Requires router port forwarding
- ISP may block ports 80/443
- Your server IP is exposed
- No DDoS protection
- Doesn't work with CGNAT

#### Tailscale VPN
⚠️ **Only for private access**:
- Not suitable for public services
- Requires Tailscale on all devices
- Good for personal/private access only

## Security Best Practices

1. ✅ **Change default passwords** in `.env` file
2. ✅ **Keep origin certificates secure** (never commit to git)
3. ✅ **Regular backups** of database and volumes
4. ✅ **Monitor logs** for suspicious activity
5. ✅ **Keep images updated** with `docker-compose pull`
6. ✅ **Enable Cloudflare WAF** rules if needed
7. ✅ **Use strong passwords** for all services

## Files to Never Commit

The `.gitignore` file protects:
- `.env` - Contains secrets and tokens
- `traefik/certs/*.pem` - Origin certificates
- `traefik/certs/*.key` - Private keys
- `traefik/logs/` - Log files

Always use `.env.example` as a template for new setups.

## Additional Documentation

- [CLOUDFLARE_TUNNEL_SETUP.md](CLOUDFLARE_TUNNEL_SETUP.md) - Detailed tunnel setup guide
- [.env.example](.env.example) - Environment variables template

## Support

For issues or questions:

1. **Check tunnel status**:
   ```bash
   docker logs cloudflared
   ```

2. **Check Traefik logs**:
   ```bash
   docker logs traefik
   ```

3. **Verify Cloudflare Dashboard**:
   - Tunnel status (should be HEALTHY)
   - Public hostname routes (should all point to `http://traefik:80`)

4. **Test connectivity**:
   ```bash
   curl -I https://ai.yourdomain.com
   ```

## License

[Add your license here]

## Credits

Built with:
- [Traefik](https://traefik.io/) - Reverse proxy
- [Cloudflare Tunnel](https://www.cloudflare.com/products/tunnel/) - Secure access
- [Open WebUI](https://github.com/open-webui/open-webui) - AI interface
- [Ollama](https://ollama.ai/) - Local AI models
- [n8n](https://n8n.io/) - Workflow automation
- [Portainer](https://www.portainer.io/) - Container management
