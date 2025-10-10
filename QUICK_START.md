# Quick Start Guide - 1SourceSystems AI Lab

## TL;DR - Get Running in 10 Minutes

### Step 1: Create Environment File (2 min)
```bash
cd /home/rick/Workspaces/Source/1SourceSystems-AI-Lab
cp .env.example .env
nano .env
```

Fill in:
- `CF_API_EMAIL`: Your Cloudflare email
- `CF_DNS_API_TOKEN`: Get from https://dash.cloudflare.com/profile/api-tokens
- `POSTGRES_PASSWORD`: Choose a strong password

### Step 2: Configure Cloudflare DNS (3 min)

Go to Cloudflare DNS for `1sourcesystems.com.au`:

1. **A Record** (your main domain):
   - Type: `A`
   - Name: `@`
   - Content: `<your-current-public-ip>` (get from https://ifconfig.me)
   - Proxy: **OFF** (grey cloud)

2. **CNAME Records** (one for each service):
   ```
   ai        →  1sourcesystems.com.au  (Proxy: OFF)
   portainer →  1sourcesystems.com.au  (Proxy: OFF)
   n8n       →  1sourcesystems.com.au  (Proxy: OFF)
   db        →  1sourcesystems.com.au  (Proxy: OFF)
   traefik   →  1sourcesystems.com.au  (Proxy: OFF)
   ```

### Step 3: Configure Firewall & Router (2 min)

**On Server:**
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
```

**On Router:**
- Forward port `80` → your server's local IP
- Forward port `443` → your server's local IP

📖 **Need help with router setup?** See [ROUTER_SETUP.md](ROUTER_SETUP.md) for detailed step-by-step instructions for common Australian ISP routers (Telstra, Optus, TPG, etc.)

### Step 4: Launch! (3 min)
```bash
sudo docker-compose up -d
sudo docker-compose logs -f traefik
```

Wait for "acme: Certificate obtained" message (1-2 minutes)

### Step 5: Access Your Services

After 5-10 minutes (DNS propagation):

- 🤖 **AI Chat**: https://ai.1sourcesystems.com.au
- 🐳 **Container Mgmt**: https://portainer.1sourcesystems.com.au
- 🔄 **Automation**: https://n8n.1sourcesystems.com.au
- 🗄️ **Database Admin**: https://db.1sourcesystems.com.au
- 📊 **Traefik Dashboard**: https://traefik.1sourcesystems.com.au

## Dynamic IP? No Problem! ✅

The `cloudflare-ddns` container automatically updates your DNS when your IP changes. Zero manual work!

## Troubleshooting

### Can't access services after 10 minutes?

```bash
# Check all containers running
sudo docker-compose ps

# Check Traefik logs for SSL certificate
sudo docker-compose logs traefik | grep -i acme

# Check DDNS is updating your IP
sudo docker-compose logs cloudflare-ddns

# Verify DNS
dig ai.1sourcesystems.com.au
```

### Ports blocked by ISP?

If your ISP blocks ports 80/443, see README.md for Cloudflare Tunnel alternative.

### SSL certificate not generating?

1. Verify Cloudflare API token has "Edit zone DNS" permission
2. Ensure DNS records have Proxy **OFF** (grey cloud)
3. Check `traefik/letsencrypt/acme.json` permissions: `chmod 600`

## What's Running?

| Service | Purpose | Network |
|---------|---------|---------|
| **traefik** | Reverse proxy & SSL | Both |
| **cloudflare-ddns** | Auto-update DNS | - |
| **ollama** | AI models (Llama, etc) | Internal only |
| **open-webui** | Chat interface | External |
| **portainer** | Docker management UI | External |
| **postgres** | Database for n8n | Internal only |
| **n8n** | Workflow automation | External |
| **adminer** | Database admin UI | External |

## Security Notes

🔒 **Internal Network Services** (not accessible from internet):
- Ollama (AI backend)
- PostgreSQL (database)

🌐 **External Network Services** (accessible via HTTPS):
- Everything else (protected by SSL + security headers)

## Next Steps

1. ✅ Change default PostgreSQL password in `.env`
2. ✅ Set up first Ollama model: Visit https://ai.1sourcesystems.com.au
3. ✅ Secure Portainer: Create admin account on first login
4. ✅ Set up backups (see README.md)
5. ✅ Explore n8n workflows

## Need Help?

See full documentation in [README.md](README.md)

Common issues:
- **DNS not resolving**: Wait 10 minutes for propagation
- **SSL errors**: Check Cloudflare API token and DNS proxy settings
- **Port forwarding issues**: Test with `nc -zv <your-ip> 80`
