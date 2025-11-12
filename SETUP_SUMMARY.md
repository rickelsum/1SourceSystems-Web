# Setup Summary - Twingate & RustDesk Integration

## What Was Added

Your Docker infrastructure has been successfully updated with **Twingate** and **RustDesk** for complete remote access to your Proxmox lab.

## Files Created

### New Service Directories

```
twingate/
├── docker-compose.yml          # Twingate connector configuration
└── README.md                   # Complete Twingate setup guide

rustdesk/
├── docker-compose.yml          # RustDesk server configuration
├── README.md                   # Complete RustDesk setup guide
└── data/                       # Auto-generated encryption keys (gitignored)
```

### Documentation Files

- **REMOTE_ACCESS_SETUP.md** - Quick reference guide for both services
- Updated **README.md** - Added remote access section
- Updated **.env.example** - Added Twingate and RustDesk variables
- Updated **.gitignore** - Protect sensitive files

### Updated Scripts

- **start.sh** - Now starts Twingate and RustDesk automatically (Steps 7-8)
- **stop.sh** - Gracefully stops Twingate and RustDesk (Steps 1-2)

## Architecture Overview

Your infrastructure now has three complementary access methods:

### 1. Cloudflare Tunnel (Public Services)
- **Purpose**: Expose web services to the public internet
- **Services**: n8n, Portainer, Adminer, Traefik
- **Access**: Anyone with URL (authenticated)
- **Setup Status**: ✅ Already configured

### 2. Twingate (Private Network Access) - NEW
- **Purpose**: Zero Trust access to entire home lab
- **Access**: Proxmox, VMs, SSH, internal Docker services
- **Security**: Encrypted, no port forwarding
- **Setup Status**: ⚠️ Requires configuration

### 3. RustDesk (Remote Desktop) - NEW
- **Purpose**: Graphical remote desktop access
- **Access**: Kali VM and other VMs
- **Performance**: Low latency, high quality
- **Setup Status**: ✅ Ready to configure clients

## Quick Start Guide

### Step 1: Configure Twingate (30 minutes)

1. **Sign up for Twingate**
   - Go to: https://www.twingate.com/
   - Sign up for free account
   - Choose network name (e.g., "rick-homelab")

2. **Create Connector**
   - In Twingate dashboard: Networks → Connectors → Add Connector
   - Generate tokens (you'll get 3 values)

3. **Add Tokens to .env**
   ```bash
   nano .env
   ```
   Add:
   ```bash
   TWINGATE_ACCESS_TOKEN=your-access-token-here
   TWINGATE_REFRESH_TOKEN=your-refresh-token-here
   TWINGATE_NETWORK=rick-homelab.twingate.com
   ```

4. **Start Connector**
   ```bash
   docker compose -f twingate/docker-compose.yml up -d
   docker logs twingate-connector -f
   ```
   Should see: "Connected to Twingate network"

5. **Define Resources in Twingate Dashboard**

   Add these resources (example IPs - adjust to your network):

   | Resource Name | Address | Protocol | Port |
   |--------------|---------|----------|------|
   | Proxmox Web UI | 192.168.1.100 | HTTPS | 8006 |
   | Kali VM SSH | 192.168.1.101 | TCP | 22 |
      | PostgreSQL | postgres (or 172.19.0.x) | TCP | 5432 |

6. **Install Twingate Client on Arch Laptop**
   ```bash
   yay -S twingate
   # or
   paru -S twingate

   sudo systemctl enable --now twingate
   ```

7. **Test**
   - Open Twingate client → Connect
   - Browser: https://192.168.1.100:8006 (Proxmox)
   - It should work!

**Detailed guide**: [twingate/README.md](twingate/README.md)

### Step 2: Configure RustDesk (20 minutes)

1. **Start RustDesk Servers** (Already running if you used ./start.sh)
   ```bash
   docker compose -f rustdesk/docker-compose.yml up -d
   docker logs rustdesk-server -f
   ```

2. **Get Public Key**
   ```bash
   docker exec rustdesk-server cat /root/id_ed25519.pub
   ```
   Copy this key - you'll need it for all clients.

3. **Install RustDesk on Kali VM**
   ```bash
   # SSH into Kali VM
   ssh kali@192.168.1.101

   # Download and install
   wget https://github.com/rustdesk/rustdesk/releases/download/1.2.3/rustdesk-1.2.3-x86_64.deb
   sudo dpkg -i rustdesk-1.2.3-x86_64.deb
   ```

4. **Configure RustDesk on Kali VM**
   - Open RustDesk
   - Click menu (...) → ID/Relay Server
   - Fill in:
     - ID Server: `192.168.1.11`
     - Relay Server: `192.168.1.11`
     - Key: (paste public key from step 2)
   - Click OK
   - **Note the ID number** (e.g., 123456789)

5. **Install RustDesk on Arch Laptop**
   ```bash
   yay -S rustdesk
   # or
   paru -S rustdesk
   ```

6. **Configure RustDesk on Arch Laptop**
   - Open RustDesk
   - Click menu (...) → ID/Relay Server
   - Fill in **SAME settings** as Kali VM:
     - ID Server: `192.168.1.11`
     - Relay Server: `192.168.1.11`
     - Key: (same public key)
   - Click OK

7. **Test Connection**
   - On Arch laptop, open RustDesk
   - Enter Kali VM's ID
   - Click Connect
   - Accept connection on Kali VM
   - You should see Kali's desktop!

**Detailed guide**: [rustdesk/README.md](rustdesk/README.md)

## Complete Remote Access Workflow

When you're away from home and want to access your lab:

### Scenario 1: Access Proxmox Web UI

```bash
# On your Arch laptop
1. Open Twingate → Connect
2. Open browser → https://192.168.1.100:8006
3. Log in and manage your VMs
```

### Scenario 2: SSH into Kali VM

```bash
# On your Arch laptop
1. Open Twingate → Connect
2. Terminal: ssh kali@192.168.1.101
3. You're in!
```

### Scenario 3: Remote Desktop to Kali VM

```bash
# On your Arch laptop
1. Open Twingate → Connect (for network access)
2. Open RustDesk client
3. Enter Kali VM's ID
4. Click Connect
5. Full graphical desktop access!
```

### Scenario 4: Access Internal Docker Service

```bash
# Example: Connect to PostgreSQL database
1. Open Twingate → Connect
2. Use database client (e.g., DBeaver, pgAdmin):
   Host: postgres (or 172.19.0.x)
   Port: 5432
   Database: n8n
   User: n8n
   Password: (from .env)
```

## Environment Variables

Add these to your `.env` file:

```bash
# Twingate Connector Tokens (REQUIRED)
TWINGATE_ACCESS_TOKEN=your-access-token-here
TWINGATE_REFRESH_TOKEN=your-refresh-token-here
TWINGATE_NETWORK=yournetwork.twingate.com

# RustDesk Configuration (OPTIONAL - uses defaults if not set)
RUSTDESK_RELAY_SERVER=192.168.1.11:21117
RUSTDESK_ENCRYPTED_ONLY=1
```

See [.env.example](.env.example) for complete template.

## Startup and Management

### Start All Services

```bash
./start.sh
```

This now starts:
1. Traefik (reverse proxy)
2. Database (PostgreSQL + Adminer)
3. n8n (Workflow Automation)
4. Portainer
5. Cloudflare (DDNS + Tunnel)
6. **Twingate Connector** ← NEW
7. **RustDesk Server** ← NEW
8. Health checks

### Stop All Services

```bash
./stop.sh
```

Gracefully stops all services in reverse order.

### Individual Service Management

```bash
# Twingate
docker compose -f twingate/docker-compose.yml up -d
docker compose -f twingate/docker-compose.yml down
docker logs twingate-connector -f

# RustDesk
docker compose -f rustdesk/docker-compose.yml up -d
docker compose -f rustdesk/docker-compose.yml down
docker logs rustdesk-server -f
docker logs rustdesk-relay -f
```

## Monitoring

### Check Twingate Status

```bash
# View logs
docker logs twingate-connector -f

# Check if running
docker ps | grep twingate

# Admin dashboard
https://yournetwork.twingate.com
# Should show connector as ONLINE (green)
```

### Check RustDesk Status

```bash
# View ID server logs
docker logs rustdesk-server -f

# View relay server logs
docker logs rustdesk-relay -f

# Get public key
docker exec rustdesk-server cat /root/id_ed25519.pub

# Check if running
docker ps | grep rustdesk
```

### Check All Services

```bash
# View all containers
docker compose ps

# Or use the start script's status check
./start.sh
# (will show status at the end)
```

## Network Ports

### RustDesk Ports (Opened on Ubuntu VM)

- `21115/tcp` - NAT type test
- `21116/tcp` - TCP hole punching
- `21116/udp` - UDP hole punching
- `21117/tcp` - Relay server
- `21118/tcp` - Web client support
- `21119/tcp` - Web client relay

These ports are accessible on your local network. When using Twingate, you don't need to expose them to the internet.

### Twingate Ports

No ports need to be opened! Twingate uses outbound connections only.

## Security Notes

### What's Protected

✅ **RustDesk encryption keys** - Auto-generated, gitignored
✅ **Twingate tokens** - In .env file, gitignored
✅ **All sensitive config** - Protected by .gitignore

### Best Practices

1. **Use Twingate for RustDesk access** - Don't expose RustDesk ports to internet
2. **Enable MFA on Twingate** - Add extra security layer
3. **Use strong passwords** - For RustDesk unattended access
4. **Keep tokens secure** - Never commit .env to git
5. **Rotate credentials** - Change Twingate tokens every 90 days
6. **Monitor access logs** - Review Twingate dashboard regularly

## Troubleshooting

### Twingate Not Connecting

**Problem**: Connector shows offline

**Solution**:
```bash
# Check logs
docker logs twingate-connector

# Verify tokens in .env
cat .env | grep TWINGATE

# Restart
docker compose -f twingate/docker-compose.yml restart
```

### RustDesk Can't Connect

**Problem**: "Invalid ID or Offline"

**Solution**:
```bash
# Check servers are running
docker ps | grep rustdesk

# Verify public key matches on clients
docker exec rustdesk-server cat /root/id_ed25519.pub

# Test connectivity (from laptop when on home network)
nc -zv 192.168.1.11 21116
nc -zv 192.168.1.11 21117
```

### Can't Access Proxmox via Twingate

**Checklist**:
- [ ] Twingate client shows "Connected"
- [ ] Resource added in Twingate dashboard
- [ ] Correct IP address configured
- [ ] Proxmox is running
- [ ] Port 8006 accessible from Ubuntu VM

**Test from Ubuntu VM**:
```bash
curl -k https://192.168.1.100:8006
```

## Next Steps

After basic setup:

1. **Add more Twingate resources** as you spin up new VMs
2. **Install RustDesk on other VMs** for remote desktop access
3. **Set up unattended access** in RustDesk (permanent passwords)
4. **Install Twingate on mobile** for access on the go
5. **Create Twingate groups** for better access control
6. **Test failover** with a second Twingate connector

## Documentation

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Main infrastructure overview |
| [REMOTE_ACCESS_SETUP.md](REMOTE_ACCESS_SETUP.md) | Quick reference for remote access |
| [twingate/README.md](twingate/README.md) | Complete Twingate guide |
| [rustdesk/README.md](rustdesk/README.md) | Complete RustDesk guide |
| [CLOUDFLARE_TUNNEL_SETUP.md](CLOUDFLARE_TUNNEL_SETUP.md) | Cloudflare Tunnel setup |
| [NETWORK_DIAGRAM.md](NETWORK_DIAGRAM.md) | Network architecture |
| [.env.example](.env.example) | Environment variable template |

## Summary

You now have a **complete remote access solution**:

✅ **Cloudflare Tunnel** - Public web services (n8n, Portainer)
✅ **Twingate** - Private infrastructure access (Proxmox, VMs, internal services)
✅ **RustDesk** - Remote desktop (Kali VM and other VMs)

All three work together seamlessly:
- **No port forwarding required**
- **Secure, encrypted connections**
- **Access from anywhere in the world**
- **Fast and reliable**

Your Proxmox lab is now fully accessible remotely while remaining secure! 🎉

## Quick Commands Reference

```bash
# Start everything
./start.sh

# Stop everything
./stop.sh

# Twingate
docker compose -f twingate/docker-compose.yml up -d
docker logs twingate-connector -f

# RustDesk
docker compose -f rustdesk/docker-compose.yml up -d
docker logs rustdesk-server -f
docker exec rustdesk-server cat /root/id_ed25519.pub

# Status
docker compose ps
```

## System IP Configuration

**Detected Ubuntu VM IP**: `192.168.1.11`

This IP is configured in:
- `rustdesk/docker-compose.yml` (RUSTDESK_RELAY_SERVER)
- `.env.example` (RUSTDESK_RELAY_SERVER)

**If your IP changes**, update these files and restart RustDesk servers.

---

**Need help?** Check the detailed guides in each service's README.md file!
