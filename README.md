# 1SourceSystems AI Lab - Docker Infrastructure

This setup provides a complete AI and automation infrastructure with automatic SSL certificates, external and internal network segmentation, and secure access via your domain.

## Architecture Overview

### Network Segmentation

**External Network** (accessible via internet):
- Traefik (reverse proxy)
- Open WebUI (AI interface)
- Portainer (container management)
- n8n (workflow automation)
- Adminer (database admin)

**Internal Network** (only accessible between containers):
- Ollama (AI model backend)
- PostgreSQL (database)

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

## Dynamic IP Support

**Good news!** This setup works perfectly with dynamic IPs from your ISP. The included `cloudflare-ddns` service automatically updates your Cloudflare DNS records whenever your IP changes. No manual intervention needed!

### How It Works:
1. The DDNS container checks your public IP every 5 minutes
2. If your IP changes, it automatically updates Cloudflare DNS
3. All your subdomains continue working seamlessly
4. SSL certificates remain valid (they're tied to your domain, not IP)

## Setup Instructions

### 1. Cloudflare Configuration

#### Get Cloudflare API Token
1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Go to **My Profile** → **API Tokens**
3. Click **Create Token**
4. Use the **Edit zone DNS** template
5. Configure:
   - **Permissions**: Zone → DNS → Edit
   - **Zone Resources**: Include → Specific zone → `1sourcesystems.com.au`
6. Create token and copy it (you'll only see it once!)

#### Configure DNS Records
In Cloudflare DNS settings for `1sourcesystems.com.au`:

1. Create an **A record** pointing to your server's public IP:
   ```
   Type: A
   Name: @
   Content: <your-server-public-ip>
   Proxy: OFF (DNS only - grey cloud)
   TTL: Auto
   ```

2. Create **CNAME records** for each subdomain:
   ```
   Type: CNAME
   Name: ai
   Content: 1sourcesystems.com.au
   Proxy: OFF (DNS only)

   Type: CNAME
   Name: portainer
   Content: 1sourcesystems.com.au
   Proxy: OFF (DNS only)

   Type: CNAME
   Name: n8n
   Content: 1sourcesystems.com.au
   Proxy: OFF (DNS only)

   Type: CNAME
   Name: db
   Content: 1sourcesystems.com.au
   Proxy: OFF (DNS only)

   Type: CNAME
   Name: traefik
   Content: 1sourcesystems.com.au
   Proxy: OFF (DNS only)
   ```

**Important**: Keep proxy status OFF (grey cloud) to allow Let's Encrypt DNS challenge to work properly.

### 2. Environment Configuration

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your credentials:
   ```bash
   nano .env
   ```

3. Update these values:
   - `CF_API_EMAIL`: Your Cloudflare account email
   - `CF_DNS_API_TOKEN`: The API token you created
   - `POSTGRES_PASSWORD`: A strong password for PostgreSQL

### 3. Firewall Configuration

Allow HTTP and HTTPS through your firewall:

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
```

If your server is behind a router, forward ports 80 and 443 to your server's local IP.

### 4. Launch Services

```bash
# Stop any existing containers
sudo docker-compose down

# Start all services
sudo docker-compose up -d

# Watch the logs (optional)
sudo docker-compose logs -f traefik
```

### 5. Verify SSL Certificates

Traefik will automatically request a wildcard SSL certificate from Let's Encrypt. This may take 1-2 minutes.

Check the logs:
```bash
sudo docker-compose logs traefik | grep -i acme
```

Look for successful certificate generation messages.

### 6. Access Your Services

After DNS propagates (5-10 minutes), access your services via:

- https://ai.1sourcesystems.com.au - Open WebUI
- https://portainer.1sourcesystems.com.au - Portainer
- https://n8n.1sourcesystems.com.au - n8n
- https://db.1sourcesystems.com.au - Adminer
- https://traefik.1sourcesystems.com.au - Traefik Dashboard

## Security Features

### Network Isolation
- **Internal network**: Completely isolated from the internet
- **External network**: Only exposed services can be accessed
- Ollama and PostgreSQL are NOT accessible from the internet

### SSL/TLS
- Automatic wildcard SSL certificate from Let's Encrypt
- All HTTP traffic redirected to HTTPS
- TLS 1.2+ enforced
- Secure cipher suites configured

### Headers
- Security headers automatically applied
- HSTS enabled with preload
- SSL redirect enforced

## Troubleshooting

### Certificate Issues

If certificates aren't generating:

1. Check Cloudflare API token permissions
2. Verify DNS records are set correctly and not proxied
3. Check Traefik logs: `sudo docker-compose logs traefik`
4. Ensure `acme.json` has correct permissions: `chmod 600 traefik/letsencrypt/acme.json`

### DNS Not Resolving

1. Check DNS propagation: `dig ai.1sourcesystems.com.au`
2. Verify Cloudflare DNS records are set to **DNS Only** (grey cloud)
3. Wait 5-10 minutes for DNS to propagate

### Service Not Accessible

1. Check if container is running: `sudo docker-compose ps`
2. Check Traefik routes: View dashboard at https://traefik.1sourcesystems.com.au
3. Check service logs: `sudo docker-compose logs <service-name>`

### Firewall Issues

If you're behind a router:
1. Forward ports 80 and 443 to your server's local IP
2. Some ISPs block port 80/443 - check with your provider
3. Consider using Cloudflare Tunnel as an alternative

## Database Access via Adminer

Access: https://db.1sourcesystems.com.au

Login credentials:
- **System**: PostgreSQL
- **Server**: postgres
- **Username**: (value from .env POSTGRES_USER)
- **Password**: (value from .env POSTGRES_PASSWORD)
- **Database**: (value from .env POSTGRES_DB)

## Useful Commands

```bash
# View all running containers
sudo docker-compose ps

# View logs for a specific service
sudo docker-compose logs -f <service-name>

# Restart a specific service
sudo docker-compose restart <service-name>

# Stop all services
sudo docker-compose down

# Start all services
sudo docker-compose up -d

# Update all services to latest images
sudo docker-compose pull
sudo docker-compose up -d

# View Traefik routes
sudo docker-compose exec traefik cat /etc/traefik/traefik.yml
```

## Alternative Access Methods

### Option 1: Current Setup with DDNS ⭐ (Recommended)
**Best for**: Most home users with dynamic IPs

✅ **Pros**:
- Automatic IP updates via cloudflare-ddns container (included!)
- Free SSL certificates
- Full control over your infrastructure
- Fast direct connection (no proxy overhead)

⚠️ **Requirements**:
- Router must allow port forwarding (80, 443)
- ISP must not block ports 80/443

### Option 2: Cloudflare Tunnel (Zero Trust)
**Best for**: ISPs that block ports 80/443, CGNAT, or maximum security

✅ **Pros**:
- No port forwarding needed at all
- Works with any ISP (even mobile hotspots or CGNAT)
- Built-in DDoS protection from Cloudflare
- No need to expose any ports to internet

⚠️ **Cons**:
- Slightly more complex setup
- Small latency overhead (traffic proxied through Cloudflare)

**When to use**: If your ISP blocks ports 80/443 or you're behind CGNAT

### Option 3: Tailscale VPN (Most Secure)
**Best for**: Private access only, no public exposure

✅ **Pros**:
- Zero public exposure (most secure)
- Peer-to-peer when possible (often faster than you'd think)
- No firewall configuration needed
- Works from anywhere

⚠️ **Cons**:
- Only accessible to devices in your Tailscale network
- Requires Tailscale app on each device
- Not suitable if you want public access

**Setup**:
1. Install Tailscale on your server and devices
2. Access via Tailscale IP: `http://<tailscale-ip>:8081` (or use MagicDNS)
3. Keep firewall closed completely

### Comparison Table

| Feature | DDNS (Current) | Cloudflare Tunnel | Tailscale |
|---------|----------------|-------------------|-----------|
| Setup complexity | ⭐ Easy | ⭐⭐ Moderate | ⭐ Easy |
| Port forwarding | Required | Not needed | Not needed |
| ISP restrictions | Must allow 80/443 | Works with any ISP | Works with any ISP |
| Performance | ⭐⭐⭐ Direct | ⭐⭐ Proxied | ⭐⭐⭐ P2P when possible |
| Public access | ✅ Yes | ✅ Yes | ❌ Private only |
| DDoS protection | Your firewall | ⭐⭐⭐ Cloudflare | N/A (not exposed) |
| Cost | Free | Free | Free (up to 100 devices) |

## Backup Strategy

Important directories to backup:
- `./traefik/letsencrypt/` - SSL certificates
- Docker volumes (see volumes section in docker-compose.yml)

```bash
# Backup all volumes
sudo docker run --rm -v 1sourcesystems-ai-lab_postgres_data:/data -v $(pwd):/backup ubuntu tar czf /backup/postgres_backup.tar.gz /data
```

## Security Best Practices

1. **Change default passwords** in `.env` file
2. **Enable Cloudflare proxy** after SSL works (optional)
3. **Enable rate limiting** in Traefik if needed
4. **Regular backups** of database and volumes
5. **Monitor logs** for suspicious activity
6. **Keep images updated** with `docker-compose pull`

## Support

For issues or questions:
- Check logs first: `sudo docker-compose logs`
- Review Traefik dashboard for routing issues
- Verify Cloudflare DNS and API settings
