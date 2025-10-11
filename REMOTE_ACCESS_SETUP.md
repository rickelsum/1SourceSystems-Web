# Remote Access Setup Guide

Quick reference guide for setting up Twingate and RustDesk for complete remote access to your Proxmox lab.

## Overview

Your setup now includes three complementary access methods:

| Solution | Purpose | When to Use |
|----------|---------|-------------|
| **Cloudflare Tunnel** | Public web services | Access Open WebUI, n8n, Portainer from anywhere |
| **Twingate** | Private network access | Access Proxmox, SSH to VMs, internal services |
| **RustDesk** | Remote desktop | Graphical access to Kali VM and other VMs |

## Quick Setup Checklist

### 1. Twingate Setup (30 minutes)

- [ ] Sign up at [twingate.com](https://twingate.com) (free tier)
- [ ] Create a Remote Network (e.g., "Proxmox Lab")
- [ ] Add a Connector → Generate tokens
- [ ] Add tokens to `.env` file:
  ```bash
  TWINGATE_ACCESS_TOKEN=...
  TWINGATE_REFRESH_TOKEN=...
  TWINGATE_NETWORK=yourname-homelab.twingate.com
  ```
- [ ] Start connector: `docker compose -f twingate/docker-compose.yml up -d`
- [ ] Verify connector shows **ONLINE** in Twingate dashboard
- [ ] Add Resources in Twingate dashboard:
  - [ ] Proxmox Web UI (`192.168.x.x:8006`)
  - [ ] Kali VM SSH (`192.168.x.x:22`)
  - [ ] Any other services you need
- [ ] Install Twingate client on Arch laptop
- [ ] Test connection: Connect Twingate → Access Proxmox

**Detailed guide**: [twingate/README.md](twingate/README.md)

### 2. RustDesk Setup (20 minutes)

- [ ] Start RustDesk servers: `docker compose -f rustdesk/docker-compose.yml up -d`
- [ ] Get public key: `docker exec rustdesk-server cat /root/id_ed25519.pub`
- [ ] Install RustDesk client on Kali VM
- [ ] Configure Kali VM RustDesk:
  - ID Server: `192.168.1.11`
  - Relay Server: `192.168.1.11`
  - Key: (paste public key)
- [ ] Note Kali VM's RustDesk ID
- [ ] Install RustDesk client on Arch laptop
- [ ] Configure Arch laptop RustDesk (same settings as Kali)
- [ ] Test connection: Enter Kali VM's ID → Connect

**Detailed guide**: [rustdesk/README.md](rustdesk/README.md)

## Startup and Shutdown

### Start All Services

```bash
# Start everything (recommended)
./start.sh
```

This automatically starts services in order:
1. Traefik
2. Database (PostgreSQL)
3. AI Services (Ollama, Open-WebUI, n8n)
4. Portainer
5. Cloudflare (Tunnel, DDNS)
6. **Twingate Connector** ← NEW
7. **RustDesk Server** ← NEW

### Stop All Services

```bash
# Stop everything gracefully
./stop.sh
```

### Start Individual Services

```bash
# Start only Twingate
docker compose -f twingate/docker-compose.yml up -d

# Start only RustDesk
docker compose -f rustdesk/docker-compose.yml up -d
```

## Remote Access Workflow

### Scenario 1: Access Proxmox from Anywhere

```bash
# On your Arch laptop (away from home)
1. Connect Twingate
2. Open browser: https://192.168.x.x:8006
3. Manage VMs, containers, storage, etc.
```

### Scenario 2: SSH into Kali VM

```bash
# On your Arch laptop (away from home)
1. Connect Twingate
2. ssh kali@192.168.x.x
3. Full terminal access
```

### Scenario 3: Remote Desktop to Kali VM

```bash
# On your Arch laptop (away from home)
1. Connect Twingate (for network access)
2. Open RustDesk client
3. Enter Kali VM's ID
4. Click Connect
5. Full graphical desktop access
```

### Scenario 4: Access Internal Docker Service

```bash
# Example: Access PostgreSQL directly
1. Connect Twingate
2. Use database client:
   Host: postgres (or container IP)
   Port: 5432
   User: n8n
   Password: (from .env)
```

## Monitoring and Logs

### Check Twingate Connector Status

```bash
# View logs
docker logs twingate-connector -f

# Check if running
docker ps | grep twingate

# Verify in Twingate dashboard
# Should show ONLINE (green dot)
```

### Check RustDesk Server Status

```bash
# View ID server logs
docker logs rustdesk-server -f

# View relay server logs
docker logs rustdesk-relay -f

# Get public key (for client configuration)
docker exec rustdesk-server cat /root/id_ed25519.pub
```

### Check All Services

```bash
# View all running containers
docker compose ps

# Check specific service
docker logs <container-name> -f
```

## Troubleshooting

### Twingate Connector Not Connecting

**Symptoms**: Connector shows offline in dashboard

**Solutions**:
1. Check logs: `docker logs twingate-connector`
2. Verify tokens in `.env` file
3. Regenerate tokens in Twingate dashboard if needed
4. Restart: `docker compose -f twingate/docker-compose.yml restart`

### Can't Access Proxmox via Twingate

**Checklist**:
- [ ] Twingate client shows "Connected"?
- [ ] Resource added in Twingate dashboard?
- [ ] Correct IP address configured?
- [ ] Proxmox VM is running?
- [ ] Test from Ubuntu VM: `curl -k https://proxmox-ip:8006`

### RustDesk Can't Connect

**Symptoms**: "Invalid ID or Offline"

**Solutions**:
1. Verify Kali VM is running
2. Verify RustDesk client is running on Kali VM
3. Check server configuration on both machines:
   - ID Server: `192.168.1.11`
   - Relay Server: `192.168.1.11`
   - Key matches server's public key
4. Test connectivity: `nc -zv 192.168.1.11 21116`

### RustDesk Connection is Slow

**Try**:
1. Reduce quality: RustDesk menu → Display Quality → Low
2. Lower FPS: RustDesk menu → FPS → 15
3. Use wired connection instead of WiFi
4. Check network latency: `ping 192.168.1.11`

## Security Best Practices

### Twingate

1. ✅ Enable MFA in Twingate settings
2. ✅ Use principle of least privilege (only grant access to needed resources)
3. ✅ Create groups for different access levels
4. ✅ Review access logs regularly
5. ✅ Rotate connector tokens every 90 days

### RustDesk

1. ✅ Use strong permanent passwords for unattended access
2. ✅ Keep `RUSTDESK_ENCRYPTED_ONLY=1` in `.env`
3. ✅ Backup encryption keys: `rustdesk/data/id_ed25519*`
4. ✅ Don't expose RustDesk ports directly to internet (use Twingate instead)
5. ✅ Update RustDesk clients and servers regularly

### General

1. ✅ Keep all Docker images updated: `docker compose pull && docker compose up -d`
2. ✅ Use strong passwords in `.env` file
3. ✅ Never commit `.env` to git
4. ✅ Enable firewall on Ubuntu VM: `sudo ufw enable`
5. ✅ Monitor logs for suspicious activity

## Environment Variables Reference

Add these to your `.env` file:

```bash
# Twingate (Required for Twingate)
TWINGATE_ACCESS_TOKEN=your-access-token
TWINGATE_REFRESH_TOKEN=your-refresh-token
TWINGATE_NETWORK=yournetwork.twingate.com

# RustDesk (Optional - uses defaults)
RUSTDESK_RELAY_SERVER=192.168.1.11:21117
RUSTDESK_ENCRYPTED_ONLY=1
```

See [.env.example](.env.example) for complete template.

## Useful Commands

### Twingate

```bash
# Start connector
docker compose -f twingate/docker-compose.yml up -d

# Stop connector
docker compose -f twingate/docker-compose.yml down

# View logs
docker logs twingate-connector -f

# Restart connector
docker compose -f twingate/docker-compose.yml restart
```

### RustDesk

```bash
# Start servers
docker compose -f rustdesk/docker-compose.yml up -d

# Stop servers
docker compose -f rustdesk/docker-compose.yml down

# Get public key
docker exec rustdesk-server cat /root/id_ed25519.pub

# View ID server logs
docker logs rustdesk-server -f

# View relay server logs
docker logs rustdesk-relay -f

# Test connectivity
nc -zv 192.168.1.11 21116
nc -zv 192.168.1.11 21117
```

### System-Wide

```bash
# Start all services
./start.sh

# Stop all services
./stop.sh

# View all running containers
docker compose ps

# Update all images
docker compose pull
./start.sh

# Check Docker networks
docker network ls | grep 1sourcesystems
```

## Next Steps

After completing setup:

1. **Install Twingate on mobile devices** for access on the go
2. **Set up RustDesk on more VMs** as you spin them up
3. **Configure unattended access** in RustDesk for permanent passwords
4. **Create Twingate groups** for better access control
5. **Test failover** by adding a second Twingate connector
6. **Document your VM IDs** for quick RustDesk access

## Support and Documentation

- [Twingate Setup Guide](twingate/README.md) - Complete Twingate documentation
- [RustDesk Setup Guide](rustdesk/README.md) - Complete RustDesk documentation
- [Main README](README.md) - Overview of entire infrastructure
- [Cloudflare Tunnel Setup](CLOUDFLARE_TUNNEL_SETUP.md) - Cloudflare Tunnel guide
- [Network Diagram](NETWORK_DIAGRAM.md) - Visual network architecture

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      Your Arch Laptop                           │
│  (Away from Home)                                               │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  Twingate    │  │  RustDesk    │  │   Browser    │         │
│  │   Client     │  │   Client     │  │              │         │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
│         │                  │                  │                  │
└─────────┼──────────────────┼──────────────────┼─────────────────┘
          │                  │                  │
          │ (Encrypted)      │ (Via Twingate)  │ (Via Cloudflare)
          │                  │                  │
┌─────────▼──────────────────▼──────────────────▼─────────────────┐
│                     Internet / Cloud                            │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  Twingate    │  │              │  │  Cloudflare  │         │
│  │  Cloud       │  │              │  │  Tunnel      │         │
│  └──────┬───────┘  └──────────────┘  └──────┬───────┘         │
└─────────┼─────────────────────────────────────┼─────────────────┘
          │                                      │
          │ (Outbound only)                      │ (Outbound only)
          │                                      │
┌─────────▼──────────────────────────────────────▼─────────────────┐
│              Your Home Network (Proxmox Lab)                     │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │           Ubuntu VM (Docker Server)                        │ │
│  │  IP: 192.168.1.11                                          │ │
│  │                                                             │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │ │
│  │  │  Twingate    │  │  RustDesk    │  │  Cloudflared │    │ │
│  │  │  Connector   │  │  Server      │  │  Tunnel      │    │ │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │ │
│  │         │                  │                  │             │ │
│  │         │ (Can access      │ (Can relay       │            │ │
│  │         │  entire network) │  connections)    │            │ │
│  │         │                  │                  │             │ │
│  │  ┌──────▼──────────────────▼──────────────────▼────────┐  │ │
│  │  │         Docker Network (internal + external)        │  │ │
│  │  │                                                      │  │ │
│  │  │  Traefik │ Ollama │ PostgreSQL │ Open-WebUI │ n8n  │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Proxmox     │  │   Kali VM    │  │  Other VMs   │          │
│  │  Host        │  │  (RustDesk   │  │              │          │
│  │  (Web UI)    │  │   Client)    │  │              │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│  192.168.x.x       192.168.x.x       192.168.x.x               │
└───────────────────────────────────────────────────────────────────┘

Access Paths:
1. Twingate: Laptop → Twingate Cloud → Connector → Any device
2. RustDesk: Laptop → Twingate → RustDesk Server → Kali VM
3. Cloudflare: Browser → Cloudflare → Tunnel → Traefik → Services
```

## Summary

You now have **complete remote access** to your entire Proxmox lab:

✅ **Public Services**: Open WebUI, n8n, Portainer (via Cloudflare Tunnel)
✅ **Private Infrastructure**: Proxmox, VMs, internal services (via Twingate)
✅ **Remote Desktop**: Kali VM and other VMs (via RustDesk + Twingate)

All three solutions work together seamlessly, providing secure, fast, and reliable access from anywhere in the world!
