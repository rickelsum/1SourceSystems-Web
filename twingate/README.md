# Twingate Zero Trust Network Access

Twingate provides secure, Zero Trust network access to your entire Proxmox lab without exposing ports or requiring VPN configuration.

## What is Twingate?

Twingate creates a **secure overlay network** that allows you to access your home lab from anywhere:

- **Zero Trust Architecture**: Every connection is authenticated and encrypted
- **No Port Forwarding**: Works entirely on outbound connections
- **Split Tunneling**: Only routes traffic to your home lab, not all internet traffic
- **Better than VPN**: Faster, more secure, easier to manage
- **Free Tier Available**: Perfect for home labs (up to 5 users, unlimited devices)

## Architecture

```
Your Laptop (Away from Home)
    ↓ (Twingate Client)
    ↓ (Encrypted Connection)
Twingate Cloud Service
    ↓ (Encrypted Connection)
Twingate Connector (Docker Container)
    ↓ (Local Network Access)
    ├─ Proxmox Web UI (192.168.x.x:8006)
    ├─ Kali VM SSH (192.168.x.x:22)
    ├─ Any other VMs/services
    └─ Docker services on internal network
```

## Benefits for Your Setup

1. **Access Proxmox Web UI** from anywhere (https://proxmox-ip:8006)
2. **SSH into Kali VM** and any other VMs
3. **Access internal Docker services** (like Ollama, PostgreSQL)
4. **Manage your entire lab** remotely without exposing anything publicly
5. **Works with Cloudflare Tunnel** - They complement each other:
   - Cloudflare Tunnel: For **public-facing** services (Open WebUI, n8n, Portainer)
   - Twingate: For **private infrastructure** access (Proxmox, VMs, internal services)

## Quick Setup Guide

### Step 1: Create Twingate Account

1. Go to [https://www.twingate.com/](https://www.twingate.com/)
2. Sign up for a free account
3. Choose a network name (e.g., `yourname-homelab`)
4. You'll get a URL like: `https://yourname-homelab.twingate.com`

### Step 2: Create a Connector

1. Log in to Twingate Admin Console
2. Navigate to **Networks** → **Connectors**
3. Click **Add Connector**
4. Give it a name: `proxmox-docker-connector`
5. Click **Generate Tokens**
6. **Copy the three values**:
   - `TWINGATE_ACCESS_TOKEN`
   - `TWINGATE_REFRESH_TOKEN`
   - `TWINGATE_NETWORK`

### Step 3: Add Tokens to .env File

Add these lines to your `/home/rick/Workspace/Source/1SourceSystems-Web/.env` file:

```bash
# Twingate Connector Tokens
TWINGATE_ACCESS_TOKEN=your-access-token-here
TWINGATE_REFRESH_TOKEN=your-refresh-token-here
TWINGATE_NETWORK=yourname-homelab.twingate.com
```

**IMPORTANT**: Never commit these tokens to git! They're already protected by `.gitignore`.

### Step 4: Start the Connector

```bash
# From the main project directory
docker compose -f twingate/docker-compose.yml up -d

# Check connector status
docker logs twingate-connector -f
```

You should see:
```
Connector started successfully
Connected to Twingate network: yourname-homelab.twingate.com
```

In the Twingate Admin Console, the connector status should show **ONLINE** (green).

### Step 5: Define Resources (What You Can Access)

Now tell Twingate what services you want to access:

#### 5a. Add Proxmox Web UI

1. In Twingate Admin Console, go to **Resources** → **Add Resource**
2. Fill in:
   - **Name**: Proxmox Web UI
   - **Address**: `192.168.x.x` (Your Proxmox host's LAN IP)
   - **Protocols**: HTTPS
   - **Ports**: 8006
   - **Remote Network**: Select your connector
3. Click **Add Resource**

#### 5b. Add Kali VM SSH

1. **Resources** → **Add Resource**
2. Fill in:
   - **Name**: Kali VM SSH
   - **Address**: `192.168.x.x` (Your Kali VM's LAN IP)
   - **Protocols**: TCP
   - **Ports**: 22
   - **Remote Network**: Select your connector
3. Click **Add Resource**

#### 5c. Add Internal Docker Services (Optional)

Access services like Ollama or PostgreSQL that are only on the internal network:

**Ollama (AI Backend)**:
- **Name**: Ollama API
- **Address**: `ollama` (Docker hostname) or `172.19.0.x` (Container IP)
- **Protocols**: TCP
- **Ports**: 11434

**PostgreSQL**:
- **Name**: PostgreSQL Database
- **Address**: `postgres` (Docker hostname) or `172.19.0.x` (Container IP)
- **Protocols**: TCP
- **Ports**: 5432

**Tip**: Use `docker inspect postgres` to find the container's IP address on the internal network.

#### 5d. Add Wildcard for Entire Network (Advanced)

To access ANY device on your network:
- **Name**: Home Lab Network
- **Address**: `192.168.0.0/16` (or your specific subnet like `192.168.1.0/24`)
- **Protocols**: Any
- **Ports**: Any

**Warning**: This is very permissive. Only use this if you trust all devices on your network.

### Step 6: Install Twingate Client on Your Arch Laptop

```bash
# On your Arch laptop
yay -S twingate
# or
paru -S twingate

# Start Twingate service
sudo systemctl enable --now twingate
```

**Alternative**: Download from [Twingate Downloads](https://www.twingate.com/download)

### Step 7: Connect and Test

On your Arch laptop:

1. Open Twingate client (tray icon or `twingate` command)
2. Log in with your Twingate account
3. Click **Connect**
4. Status should show: **Connected to yourname-homelab**

Now test access:

```bash
# Test Proxmox (replace with your actual IP)
curl -k https://192.168.1.100:8006

# SSH into Kali VM
ssh kali@192.168.1.101

# Access Proxmox Web UI in browser
firefox https://192.168.1.100:8006
```

It will work as if you were on your home network!

## Usage

### Connecting Remotely

When away from home:

1. **Open Twingate client** on your laptop
2. **Click Connect**
3. All your resources are now accessible as if you were home

### Disconnecting

Click **Disconnect** in the Twingate client when you don't need access.

**Tip**: Twingate uses split tunneling by default, so only traffic to your home lab goes through the tunnel. Your other internet traffic remains unaffected.

## Advanced Configuration

### Multiple Connectors for High Availability

Deploy a second connector for redundancy:

```bash
# Copy the same .env values
# Run a second instance
docker compose -f twingate/docker-compose.yml up -d --scale twingate-connector=2
```

Twingate will automatically load balance and failover between connectors.

### Access Docker Internal Network

The connector is on both `external` and `internal` Docker networks, allowing you to access:

- Services only on the internal network (Ollama, PostgreSQL)
- Services on the external network
- Services on your host network (Proxmox, VMs)

To access an internal Docker service:

1. Find the container IP:
   ```bash
   docker inspect ollama | grep IPAddress
   ```

2. Add as a Twingate Resource:
   - **Address**: `172.19.0.x` (the IP you found)
   - **Port**: `11434` (for Ollama)

### Monitoring Connector Health

```bash
# View connector logs
docker logs twingate-connector -f

# Check connector status
docker ps | grep twingate

# View detailed stats
docker exec twingate-connector wget -qO- http://localhost:9999/healthcheck
```

## Security Best Practices

1. **Use Groups**: In Twingate, create groups (e.g., "Admins", "Users") and assign resource access by group
2. **Principle of Least Privilege**: Only give access to resources users need
3. **Enable MFA**: Turn on Multi-Factor Authentication in Twingate settings
4. **Monitor Access**: Review access logs in Twingate Admin Console
5. **Rotate Tokens**: Regenerate connector tokens periodically (every 90 days)
6. **Use Service Accounts**: Create separate Twingate users for automation/scripts

## Troubleshooting

### Connector Won't Start

**Check logs**:
```bash
docker logs twingate-connector
```

**Common issues**:
- Invalid tokens in `.env` file
- Network connectivity issues
- Docker network not created

**Solution**:
1. Verify tokens in Twingate Admin Console
2. Regenerate tokens if needed
3. Update `.env` file
4. Restart connector: `docker compose -f twingate/docker-compose.yml restart`

### Connector Shows Offline

1. **Check container is running**:
   ```bash
   docker ps | grep twingate
   ```

2. **Restart the connector**:
   ```bash
   docker compose -f twingate/docker-compose.yml restart
   ```

3. **Check network connectivity**:
   ```bash
   docker exec twingate-connector ping -c 3 google.com
   ```

### Can't Access Resources

1. **Verify client is connected**:
   - Twingate client should show "Connected"
   - Green indicator in system tray

2. **Check resource configuration**:
   - Correct IP address in Twingate Admin Console?
   - Correct ports specified?
   - Resource assigned to your user/group?

3. **Test from connector**:
   ```bash
   # Test if connector can reach the resource
   docker exec twingate-connector ping -c 3 192.168.1.100
   ```

4. **Check firewall on target**:
   - Proxmox firewall allowing connections?
   - VM firewall rules correct?

### Split Tunneling Not Working

By default, Twingate only routes traffic to defined resources.

To check:
1. Open Twingate client settings
2. Verify "Split Tunneling" is enabled
3. Only resources in your Twingate network should route through the tunnel

## Twingate vs. Other Solutions

| Feature | Twingate | Traditional VPN | Cloudflare Tunnel |
|---------|----------|----------------|-------------------|
| **Use Case** | Private infrastructure access | Private infrastructure | Public services |
| **Port Forwarding** | Not required | Not required | Not required |
| **Split Tunneling** | Yes (smart routing) | Limited | N/A |
| **Zero Trust** | Yes | No | Yes |
| **Setup Complexity** | Easy | Moderate | Easy |
| **Performance** | Excellent | Variable | Excellent |
| **Best For** | Home lab access | General VPN needs | Public web apps |

## Integration with Your Existing Setup

### Twingate + Cloudflare Tunnel = Perfect Combo

- **Cloudflare Tunnel**: Public services (Open WebUI, n8n, Portainer)
  - Anyone can access (with authentication)
  - Optimized for web traffic
  - DDoS protection

- **Twingate**: Private infrastructure (Proxmox, VMs, SSH, RDP)
  - Only you can access
  - Access everything on your network
  - Perfect for management

### Access Patterns

**Public Access** (via Cloudflare Tunnel):
```
User → Cloudflare → Tunnel → Traefik → Open WebUI
```

**Private Admin Access** (via Twingate):
```
Your Laptop → Twingate → Connector → Proxmox/Kali/VMs
```

Both run simultaneously and don't interfere with each other!

## Useful Commands

```bash
# Start Twingate connector
docker compose -f twingate/docker-compose.yml up -d

# Stop Twingate connector
docker compose -f twingate/docker-compose.yml down

# View logs
docker logs twingate-connector -f

# Restart connector
docker compose -f twingate/docker-compose.yml restart

# Check connector status
docker ps | grep twingate

# Update connector to latest version
docker compose -f twingate/docker-compose.yml pull
docker compose -f twingate/docker-compose.yml up -d
```

## Environment Variables Reference

Required in `.env` file:

```bash
# Twingate Connector Authentication
TWINGATE_ACCESS_TOKEN=your-access-token-here
TWINGATE_REFRESH_TOKEN=your-refresh-token-here
TWINGATE_NETWORK=yourname-homelab.twingate.com

# Optional: Custom connector name
# TWINGATE_LABEL_HOSTNAME=proxmox-docker-connector

# Optional: Enable debug logging (7 = most verbose)
# TWINGATE_LOG_LEVEL=7
```

## Next Steps

After setting up Twingate:

1. **Set up RustDesk** for graphical remote desktop (see `../rustdesk/README.md`)
2. **Create Twingate groups** for better access control
3. **Add more resources** as you spin up new VMs
4. **Install client on mobile devices** for access on the go
5. **Configure MFA** in Twingate for enhanced security

## Resources

- [Twingate Documentation](https://docs.twingate.com/)
- [Twingate Admin Console](https://yourname-homelab.twingate.com)
- [Twingate Docker Hub](https://hub.docker.com/r/twingate/connector)
- [Twingate Community](https://community.twingate.com/)

## Support

For Twingate-specific issues:
- [Twingate Support](https://help.twingate.com/)
- [Community Forum](https://community.twingate.com/)

For connector issues in this setup:
```bash
docker logs twingate-connector -f
```
