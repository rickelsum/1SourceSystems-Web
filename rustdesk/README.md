# RustDesk Self-Hosted Remote Desktop

RustDesk is a self-hosted, open-source remote desktop solution that provides high-performance graphical access to your VMs and workstations.

## What is RustDesk?

RustDesk is like TeamViewer or AnyDesk, but:

- **Self-Hosted**: Your traffic stays on your infrastructure
- **Open Source**: Fully transparent and auditable
- **Fast**: Optimized for low latency
- **Cross-Platform**: Works on Linux, Windows, macOS, Android, iOS
- **Free**: No licensing costs
- **Secure**: End-to-end encryption with your own keys

## Architecture

```
RustDesk Client (Your Laptop)
    ↓
Twingate Tunnel (Secure Connection to Home Network)
    ↓
RustDesk Server (ID Server - hbbs)
    ├─ Registers clients
    ├─ Facilitates peer discovery
    └─ Coordinates connections
    ↓
RustDesk Relay (hbbr)
    └─ Relays traffic when direct P2P fails
    ↓
RustDesk Client (Kali VM / Other VMs)
```

## How It Works with Twingate

1. **Twingate** provides secure network access to your home lab
2. **RustDesk** provides the remote desktop functionality
3. Both work together seamlessly:
   - When away from home: Connect Twingate first, then use RustDesk
   - When at home: Use RustDesk directly (no Twingate needed)

## Server Components

This setup runs two RustDesk server components:

1. **ID Server (hbbs)** - Port 21115, 21116, 21118
   - Registers RustDesk clients
   - Handles NAT traversal
   - Facilitates peer-to-peer connections

2. **Relay Server (hbbr)** - Port 21117, 21119
   - Relays connections when P2P fails
   - Ensures connectivity even behind strict firewalls

## Quick Setup Guide

### Step 1: Configure Environment Variables (Optional)

The RustDesk servers work out of the box with default settings. Optional configuration in `.env`:

```bash
# RustDesk Server Configuration (Optional)
# Default relay server address (auto-detected from your Ubuntu VM IP)
RUSTDESK_RELAY_SERVER=192.168.1.11:21117

# Enforce encryption (1=yes, 0=no)
RUSTDESK_ENCRYPTED_ONLY=1
```

**Current detected IP**: `192.168.1.11`

### Step 2: Start RustDesk Server

```bash
# From the main project directory
docker compose -f rustdesk/docker-compose.yml up -d

# Check server status
docker logs rustdesk-server -f
docker logs rustdesk-relay -f
```

You should see:
```
Key: [long base64 string]
Listening on 0.0.0.0:21115
Listening on 0.0.0.0:21116
Listening on 0.0.0.0:21118
```

### Step 3: Get Your Server's Public Key

The public key is required to configure RustDesk clients:

```bash
# Extract the public key
docker exec rustdesk-server cat /root/id_ed25519.pub
```

Copy this key - you'll need it for client configuration.

**Example output**:
```
8sF2JhG5kL9mN3pQ7rT1vW4xY6zA2cE5gI8kM0oS4uW=
```

### Step 4: Install RustDesk Client on Your Devices

#### On Kali VM (or any Linux VM you want to control)

```bash
# Download and install RustDesk
wget https://github.com/rustdesk/rustdesk/releases/download/1.2.3/rustdesk-1.2.3-x86_64.deb
sudo dpkg -i rustdesk-1.2.3-x86_64.deb

# Or use snap
sudo snap install rustdesk
```

#### On Your Arch Laptop (Controller)

```bash
# Install from AUR
yay -S rustdesk
# or
paru -S rustdesk

# Alternative: Download from GitHub releases
# https://github.com/rustdesk/rustdesk/releases
```

#### On Windows (Optional)

Download from [RustDesk Releases](https://github.com/rustdesk/rustdesk/releases)

### Step 5: Configure RustDesk Clients

Configure BOTH the controlled machine (Kali VM) AND your controller (Arch laptop):

#### 5a. On Kali VM (The Machine You Want to Control)

1. **Open RustDesk**
2. Click the **menu icon (...)** → **ID/Relay Server**
3. Fill in:
   - **ID Server**: `192.168.1.11`
   - **Relay Server**: `192.168.1.11`
   - **API Server**: (leave blank)
   - **Key**: (paste the public key from Step 3)
4. Click **OK**

The RustDesk client will show an ID number (e.g., `123456789`). **Save this ID** - you'll use it to connect.

#### 5b. On Your Arch Laptop (Your Controller)

1. **Open RustDesk**
2. Click the **menu icon (...)** → **ID/Relay Server**
3. Fill in **exactly the same settings** as Kali VM:
   - **ID Server**: `192.168.1.11`
   - **Relay Server**: `192.168.1.11`
   - **API Server**: (leave blank)
   - **Key**: (paste the public key from Step 3)
4. Click **OK**

### Step 6: Connect to Your Kali VM

#### When at Home (Same Network)

1. **On your Arch laptop**, open RustDesk
2. Enter the **Kali VM's ID** (from Step 5a)
3. Click **Connect**
4. Accept the connection on Kali VM (first time only)
5. You're connected!

#### When Away from Home (Remote Access)

1. **Connect Twingate first** on your Arch laptop
   ```bash
   # Ensure Twingate is connected
   twingate status
   # Should show: Connected to yourname-homelab
   ```

2. **Open RustDesk** on your Arch laptop
3. Enter the **Kali VM's ID**
4. Click **Connect**
5. RustDesk will route through Twingate to reach your home network
6. Connection established!

## Advanced Configuration

### Unattended Access (No Accept Required)

To connect to your Kali VM without manual acceptance:

**On Kali VM**:
1. Open RustDesk
2. Click **menu (...)** → **Settings** → **Security**
3. Set a **permanent password**
4. Enable **Unattended Access**

**On your Arch laptop**:
- When connecting, enter the permanent password instead of waiting for acceptance

### Custom Encryption Keys

If you want to set your own encryption key instead of auto-generated:

```bash
# Generate a new key pair
docker exec rustdesk-server rustdesk-utils genkeypair

# Copy the keys to your data directory
docker exec rustdesk-server cat /root/id_ed25519 > rustdesk/data/id_ed25519
docker exec rustdesk-server cat /root/id_ed25519.pub > rustdesk/data/id_ed25519.pub

# Restart servers
docker compose -f rustdesk/docker-compose.yml restart
```

### Port Forwarding for Remote Access (Alternative to Twingate)

If you prefer not to use Twingate, you can expose RustDesk ports:

**On your router**:
- Forward port `21115-21119` (TCP & UDP) to `192.168.1.11`

**Configure clients to use your public IP**:
- **ID Server**: `your-public-ip:21116`
- **Relay Server**: `your-public-ip:21117`

**Not recommended** because:
- Exposes ports to the internet
- No Zero Trust security
- Twingate is more secure and easier

### Web Client Access (Optional)

RustDesk has a web client for browser-based access:

1. Access at: `http://192.168.1.11:21118`
2. Enter the target machine's ID
3. Connect directly from your browser

To expose via Traefik for HTTPS access:

```yaml
# Add to rustdesk/docker-compose.yml labels for rustdesk-server
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=1sourcesystems-web_external"
  - "traefik.http.routers.rustdesk-http.entrypoints=web"
  - "traefik.http.routers.rustdesk-http.rule=Host(`rustdesk.1sourcesystems.com.au`)"
  - "traefik.http.routers.rustdesk-http.middlewares=https-redirect@file"
  - "traefik.http.routers.rustdesk-https.entrypoints=websecure"
  - "traefik.http.routers.rustdesk-https.rule=Host(`rustdesk.1sourcesystems.com.au`)"
  - "traefik.http.routers.rustdesk-https.tls=true"
  - "traefik.http.services.rustdesk.loadbalancer.server.port=21118"
```

## File Sharing Between Machines

RustDesk supports file transfer:

1. **During a session**, click the **File Transfer** icon
2. Browse files on both machines
3. Drag and drop to transfer
4. Works in both directions

## Clipboard Sharing

**Automatic clipboard sync** works by default:
- Copy on your Arch laptop → Paste on Kali VM
- Copy on Kali VM → Paste on your Arch laptop

## Performance Tuning

### Video Quality Settings

On the controller (your Arch laptop):
1. Click **menu (...)** during connection
2. Adjust:
   - **Display Quality**: Auto, Best, Balanced, Low
   - **FPS**: 30 (default), 60 (smooth)
   - **Codec**: VP9, H264, H265

### Network Optimization

For best performance:
- Use **wired connection** when possible
- On WiFi, use **5GHz band**
- Reduce FPS if connection is slow
- Use **View Only** mode when you don't need control

## Monitoring and Logs

### View Server Logs

```bash
# ID Server logs
docker logs rustdesk-server -f

# Relay Server logs
docker logs rustdesk-relay -f

# Check server status
docker ps | grep rustdesk
```

### Connection Statistics

On the RustDesk client:
1. During a session, click **menu (...)**
2. View **Connection Info**
3. Shows: Latency, FPS, Codec, Bitrate

## Security Best Practices

1. **Use Strong Passwords**: Set complex permanent passwords for unattended access
2. **Keep Keys Secure**: Back up `rustdesk/data/id_ed25519*` files securely
3. **Use Twingate**: Don't expose RustDesk ports directly to the internet
4. **Enable Encryption**: Keep `RUSTDESK_ENCRYPTED_ONLY=1`
5. **Limit Access**: Only install RustDesk on trusted devices
6. **Monitor Connections**: Regularly review connection logs
7. **Update Regularly**: Keep RustDesk client and server updated

## Backup Your Configuration

**Important files to backup**:

```bash
# Backup encryption keys
cp rustdesk/data/id_ed25519 ~/backups/
cp rustdesk/data/id_ed25519.pub ~/backups/

# Backup entire configuration
tar czf rustdesk-backup-$(date +%Y%m%d).tar.gz rustdesk/
```

**To restore**:
```bash
# Extract backup
tar xzf rustdesk-backup-20250101.tar.gz

# Restart servers
docker compose -f rustdesk/docker-compose.yml restart
```

## Troubleshooting

### Servers Won't Start

**Check logs**:
```bash
docker logs rustdesk-server
docker logs rustdesk-relay
```

**Common issues**:
- Port conflict (21115-21119 already in use)
- Permission issues with `./data` directory

**Solutions**:
```bash
# Check for port conflicts
sudo netstat -tulpn | grep 2111

# Fix permissions
sudo chown -R $(whoami):$(whoami) rustdesk/data
chmod 755 rustdesk/data

# Restart
docker compose -f rustdesk/docker-compose.yml restart
```

### Can't Connect to VM

**1. Check client configuration**:
- ID Server: `192.168.1.11` (correct?)
- Relay Server: `192.168.1.11` (correct?)
- Public key matches server's key?

**2. Verify server is reachable**:
```bash
# From your laptop
ping 192.168.1.11

# Test RustDesk port
nc -zv 192.168.1.11 21116
```

**3. If away from home, check Twingate**:
```bash
# Ensure Twingate is connected
twingate status
```

**4. Check firewall on Ubuntu VM**:
```bash
# Check UFW status
sudo ufw status

# Allow RustDesk ports if blocked
sudo ufw allow 21115:21119/tcp
sudo ufw allow 21116/udp
```

### Connection is Slow

**Try these**:
1. **Reduce quality**: Click menu → Display Quality → Low
2. **Lower FPS**: Click menu → FPS → 15
3. **Check network**:
   ```bash
   # Ping test
   ping 192.168.1.11

   # Speed test
   iperf3 -c 192.168.1.11
   ```
4. **Use wired connection** instead of WiFi
5. **Close bandwidth-heavy apps** (torrents, streaming)

### "Invalid ID or Offline"

**This means**:
- The target machine is offline, OR
- The target machine isn't connected to your RustDesk server

**Check**:
1. Is the target VM running?
   ```bash
   # On Proxmox
   qm status <vm-id>
   ```

2. Is RustDesk client running on target VM?
   ```bash
   # SSH into Kali
   ps aux | grep rustdesk
   ```

3. Is target configured with correct server?
   - Open RustDesk on target
   - Check ID/Relay Server settings
   - Should point to `192.168.1.11`

### Key Mismatch Error

**If you see "Key mismatch"**:

1. **Get the current public key**:
   ```bash
   docker exec rustdesk-server cat /root/id_ed25519.pub
   ```

2. **Update all clients** with this exact key

3. **Restart RustDesk client** on all machines

## Multiple VMs Setup

To control multiple VMs (Kali, Ubuntu, Windows, etc.):

**For each VM**:
1. Install RustDesk client
2. Configure to use `192.168.1.11` as ID/Relay server
3. Add the same public key
4. Note down each VM's ID

**From your Arch laptop**:
- Save each VM's ID with a label (e.g., "Kali: 123456789", "Ubuntu: 987654321")
- Connect to any VM by entering its ID

**Tip**: Create a bookmark file with all your VM IDs for quick access.

## Comparison: RustDesk vs. Alternatives

| Feature | RustDesk | VNC | RDP | Parsec |
|---------|----------|-----|-----|--------|
| **Self-Hosted** | ✅ | ✅ | ❌ | ❌ |
| **Cross-Platform** | ✅ | ✅ | Partial | ✅ |
| **Performance** | Excellent | Good | Good | Excellent |
| **Encryption** | E2E | Optional | TLS | E2E |
| **NAT Traversal** | ✅ | ❌ | ❌ | ✅ |
| **File Transfer** | ✅ | ❌ | ✅ | ❌ |
| **Free** | ✅ | ✅ | Windows only | Limited |

## Integration with Your Setup

### RustDesk + Twingate Workflow

**Complete remote access workflow**:

1. **Connect Twingate** (for network access)
   ```bash
   # On your Arch laptop
   twingate connect
   ```

2. **Access Proxmox Web UI** (for VM management)
   ```
   https://192.168.1.x:8006
   ```

3. **Use RustDesk** (for graphical desktop)
   - Open RustDesk
   - Connect to Kali VM ID
   - Full desktop access

4. **SSH for CLI** (if preferred)
   ```bash
   ssh kali@192.168.1.x
   ```

### Works Alongside Cloudflare Tunnel

- **Cloudflare Tunnel**: Public services (Open WebUI, n8n)
- **Twingate**: Private network access (Proxmox, SSH)
- **RustDesk**: Remote desktop (Kali, VMs)

All three complement each other perfectly!

## Useful Commands

```bash
# Start RustDesk servers
docker compose -f rustdesk/docker-compose.yml up -d

# Stop RustDesk servers
docker compose -f rustdesk/docker-compose.yml down

# View ID server logs
docker logs rustdesk-server -f

# View relay server logs
docker logs rustdesk-relay -f

# Get public key
docker exec rustdesk-server cat /root/id_ed25519.pub

# Restart servers
docker compose -f rustdesk/docker-compose.yml restart

# Update to latest version
docker compose -f rustdesk/docker-compose.yml pull
docker compose -f rustdesk/docker-compose.yml up -d

# Check server status
docker ps | grep rustdesk

# Test connectivity to server
nc -zv 192.168.1.11 21116
```

## Environment Variables Reference

Optional in `.env` file:

```bash
# RustDesk Relay Server Address
# Default: Auto-detected Ubuntu VM IP
RUSTDESK_RELAY_SERVER=192.168.1.11:21117

# Enforce Encrypted Connections Only
# 1 = yes (recommended), 0 = no
RUSTDESK_ENCRYPTED_ONLY=1
```

## Next Steps

After setting up RustDesk:

1. **Configure all your VMs** with RustDesk client
2. **Set permanent passwords** for unattended access
3. **Test remote access** via Twingate
4. **Create VM ID bookmarks** for quick access
5. **Set up mobile access** with RustDesk Android/iOS app

## Resources

- [RustDesk Official Site](https://rustdesk.com/)
- [RustDesk GitHub](https://github.com/rustdesk/rustdesk)
- [RustDesk Documentation](https://rustdesk.com/docs/en/)
- [RustDesk Server Setup Guide](https://rustdesk.com/docs/en/self-host/)

## Support

For RustDesk-specific issues:
- [RustDesk Discord](https://discord.com/invite/nDceKgxnkV)
- [GitHub Issues](https://github.com/rustdesk/rustdesk/issues)

For issues with this setup:
```bash
docker logs rustdesk-server -f
docker logs rustdesk-relay -f
```
