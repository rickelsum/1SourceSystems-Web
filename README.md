# 1SourceSystems Web - Docker Infrastructure

This setup provides a complete web application infrastructure with **Cloudflare Tunnel** for secure access, external and internal network segmentation, and automatic SSL via Cloudflare.

## Project Structure

The infrastructure is organized into modular service stacks:

```
1SourceSystems-Web/
├── docker-compose.yml          # Main orchestrator (uses 'include' directive)
├── start.sh                    # Intelligent startup script
├── stop.sh                     # Graceful shutdown script
├── .env                        # Environment variables (not committed)
├── .env.example                # Environment template
│
├── traefik/                    # Reverse proxy stack
│   ├── docker-compose.yml
│   ├── traefik.yml            # Traefik configuration
│   ├── dynamic.yml            # Dynamic configuration
│   └── certs/                 # SSL certificates
│
├── db/                         # Database stack
│   └── docker-compose.yml     # PostgreSQL + Adminer
│
│
├── portainer/                  # Container management
│   └── docker-compose.yml
│
├── cloudflare/                 # Cloudflare services
│   └── docker-compose.yml     # DDNS + Tunnel
│
├── twingate/                   # Zero Trust network access
│   ├── docker-compose.yml
│   └── README.md              # Twingate setup guide
│
└── rustdesk/                   # Self-hosted remote desktop
    ├── docker-compose.yml
    ├── README.md              # RustDesk setup guide
    └── data/                  # Encryption keys (auto-generated)
```

## Architecture Overview

### Network Segmentation

**External Network** (accessible via Cloudflare Tunnel):
- Traefik (reverse proxy)
- Portainer (container management)
- n8n (workflow automation)
- Adminer (database admin)
- Cloudflared (Cloudflare Tunnel connector)
- Twingate Connector (Zero Trust network access)
- RustDesk Server (remote desktop server)

**Internal Network** (only accessible between containers):
- PostgreSQL (database)
- Twingate Connector (can access internal services)
- RustDesk Server (can access internal services)

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

| Service | URL/Access | Type | Purpose |
|---------|------------|------|---------|
| **Public Services (via Cloudflare Tunnel)** ||||
| Traefik Dashboard | https://traefik.1sourcesystems.com.au | External | Reverse proxy dashboard |
| Portainer | https://portainer.1sourcesystems.com.au | External | Docker management |
| n8n | https://n8n.1sourcesystems.com.au | External | Workflow automation |
| Adminer | https://db.1sourcesystems.com.au | External | Database admin |
| **Internal Services** ||||
| PostgreSQL | Internal only | Internal | Database |
| **Remote Access Services** ||||
| Twingate | Via client app | Zero Trust | Secure network access to entire lab |
| RustDesk | Via client app | Remote Desktop | Graphical access to VMs |

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
cd 1SourceSystems-Web

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
5. Name your tunnel (e.g., `1sourcesystems-web`)
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

**Recommended: Use the startup script**
```bash
# Start all services in correct dependency order
./start.sh
```

The script will:
- Create networks and volumes
- Start services in the correct order (Traefik → DB → Portainer → Cloudflare)
- Wait for PostgreSQL to be healthy before starting dependent services
- Display status and service URLs

**Alternative: Manual startup**
```bash
# Start all services
docker compose up -d

# Check tunnel status
docker logs cloudflared

# Check all services
docker compose ps
```

Look for in cloudflared logs:
```
Registered tunnel connection
Updated to new configuration
```

#### 8. Access Your Services

After tunnel connects (usually instant), access via:

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
- PostgreSQL is NOT accessible from the internet
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

### Service Management

```bash
# Start all services (recommended)
./start.sh

# Stop all services (graceful shutdown)
./stop.sh

# Start specific service stack
docker compose -f traefik/docker-compose.yml up -d
docker compose -f db/docker-compose.yml up -d

# View all running containers
docker compose ps

# View logs for a specific service
docker compose logs -f <service-name>

# View tunnel status
docker logs cloudflared -f

# Restart a specific service
docker compose restart <service-name>

# Stop all services and remove networks/volumes
docker compose down --volumes
```

### Updates and Maintenance

```bash
# Update all services to latest images
docker compose pull
docker compose up -d

# Check tunnel connectivity
docker exec cloudflared cloudflared tunnel info
```

## Backup Strategy

Important directories to backup:

- `traefik/certs/` - Cloudflare origin certificates
- Docker volumes (PostgreSQL, n8n data)

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

## Managing Individual Stacks

The modular structure allows you to manage services independently:

### Traefik (Reverse Proxy)
```bash
cd traefik
docker compose up -d
docker compose logs -f
```

### Database Services
```bash
cd db
docker compose up -d
docker compose logs -f postgres
```


### Benefits of Modular Structure
- **Independent Updates**: Update one stack without affecting others
- **Easier Debugging**: Focus on specific service stack
- **Better Organization**: Related services grouped together
- **Flexible Deployment**: Deploy only what you need
- **Cleaner Configuration**: Each stack has its own focused compose file

## Remote Access to Your Proxmox Lab

This setup includes two complementary remote access solutions:

### Twingate - Zero Trust Network Access

**What it does**: Provides secure access to your entire Proxmox network from anywhere.

**Use cases**:
- Access Proxmox Web UI (`https://proxmox-ip:8006`)
- SSH into Kali VM or any other VMs
- Access internal Docker services (PostgreSQL)
- Manage your entire home lab infrastructure

**How to set up**:
1. See detailed guide: [twingate/README.md](twingate/README.md)
2. Sign up at [twingate.com](https://twingate.com) (free tier available)
3. Add tokens to `.env` file
4. Start connector: Automatically started by `./start.sh`
5. Install Twingate client on your Arch laptop
6. Connect and access your entire lab!

**Benefits**:
- No port forwarding required
- Works with CGNAT and mobile hotspots
- Split tunneling (only lab traffic goes through tunnel)
- Zero Trust security model
- Access ANY device on your network

### RustDesk - Self-Hosted Remote Desktop

**What it does**: Provides graphical remote desktop access to your VMs.

**Use cases**:
- Remote desktop to Kali VM
- Remote desktop to any other VMs you spin up
- Full graphical interface access
- File transfer between machines
- Clipboard sharing

**How to set up**:
1. See detailed guide: [rustdesk/README.md](rustdesk/README.md)
2. Start servers: Automatically started by `./start.sh`
3. Get public key: `docker exec rustdesk-server cat /root/id_ed25519.pub`
4. Install RustDesk client on VMs and your laptop
5. Configure clients to use `192.168.1.11` as server
6. Connect remotely!

**Benefits**:
- Self-hosted (your data stays private)
- Open source and free
- Cross-platform (Linux, Windows, macOS, Android, iOS)
- High performance with low latency
- Works seamlessly with Twingate

### Combined Workflow: Complete Remote Lab Access

**When away from home**:

1. **Connect Twingate** on your Arch laptop
   - Provides secure network access to your home lab

2. **Access Proxmox Web UI** via browser
   - `https://192.168.x.x:8006` - Manage VMs, start/stop services

3. **Use RustDesk** for graphical access
   - Remote desktop to Kali VM or any other VM
   - Full GUI experience

4. **Use SSH** for command-line access
   - `ssh user@vm-ip` - Direct terminal access

**All of this works seamlessly** - Twingate provides the network layer, RustDesk provides the desktop layer!

### Twingate + Cloudflare Tunnel = Perfect Combo

These three solutions work together perfectly:

| Solution | Purpose | Use For |
|----------|---------|---------|
| **Cloudflare Tunnel** | Public web services | n8n, Portainer (for public access) |
| **Twingate** | Private infrastructure | Proxmox, VMs, SSH, internal Docker services |
| **RustDesk** | Remote desktop | Graphical access to VMs (Kali, Windows, etc.) |

**Example scenarios**:

- **Manage Proxmox**: Use Twingate → Only you can access
- **Work on Kali VM**: Use Twingate + RustDesk → Full desktop access
- **SSH to a VM**: Use Twingate → Direct terminal access
- **Access PostgreSQL**: Use Twingate → Connect to internal service

All three run simultaneously without conflicts!

## Additional Documentation

- [QUICK_START.md](QUICK_START.md) - Quick start guide
- [CLOUDFLARE_TUNNEL_SETUP.md](CLOUDFLARE_TUNNEL_SETUP.md) - Detailed tunnel setup guide
- [NETWORK_DIAGRAM.md](NETWORK_DIAGRAM.md) - Network architecture diagrams
- [twingate/README.md](twingate/README.md) - **Twingate setup and usage guide**
- [rustdesk/README.md](rustdesk/README.md) - **RustDesk setup and usage guide**
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
- [n8n](https://n8n.io/) - Workflow automation
- [Portainer](https://www.portainer.io/) - Container management
