# Router Configuration Guide - Port Forwarding Setup

## What You Need to Configure

To allow external access to your Docker server, you need to forward ports **80** and **443** from your router to your server.

## Find Your Server's Local IP Address

First, find your Docker server's local IP address:

```bash
# On your server, run:
hostname -I | awk '{print $1}'
# OR
ip addr show | grep "inet " | grep -v 127.0.0.1
```

You'll get something like: `192.168.1.100` or `10.0.0.50`

**Write this down - you'll need it!**

## Router Configuration Steps

### Step 1: Access Your Router Admin Panel

**Common router addresses:**
- http://192.168.1.1
- http://192.168.0.1
- http://10.0.0.1
- http://192.168.1.254

**Common Australian ISP router addresses:**
- **Telstra**: http://192.168.0.1 or http://10.0.0.138
- **Optus**: http://192.168.0.1
- **TPG/iiNet**: http://10.1.1.1
- **Aussie Broadband**: http://192.168.1.1
- **Belong**: http://192.168.20.1

**Default credentials** (check sticker on router):
- Often: `admin` / `admin`
- Or: `admin` / `password`
- Or: Username blank / password on router sticker

### Step 2: Find Port Forwarding Settings

Look for these menu options (varies by router):
- **Port Forwarding**
- **Virtual Server**
- **NAT Forwarding**
- **Applications & Gaming**
- **Advanced → Port Forwarding**
- **Firewall → Port Forwarding**

### Step 3: Create Port Forwarding Rules

Create **TWO** rules:

#### Rule 1: HTTP (Port 80)
```
Service Name:     Docker-HTTP
Protocol:         TCP
External Port:    80
Internal IP:      <your-server-local-ip>
Internal Port:    80
Enabled:          Yes
```

#### Rule 2: HTTPS (Port 443)
```
Service Name:     Docker-HTTPS
Protocol:         TCP
External Port:    443
Internal IP:      <your-server-local-ip>
Internal Port:    443
Enabled:          Yes
```

### Example Screenshots Reference

**Telstra Routers:**
1. Login → Advanced → Port Forwarding
2. Add new rule for each port

**Optus/Sagemcom:**
1. Toolbox → Game & Application Sharing
2. Add custom service

**TPG/iiNet:**
1. Advanced Setup → NAT → Virtual Servers
2. Add service

**Netgear:**
1. Advanced → Advanced Setup → Port Forwarding
2. Add custom service

**TP-Link:**
1. Forwarding → Virtual Servers
2. Add New

**ASUS:**
1. WAN → Virtual Server/Port Forwarding
2. Enable Port Forwarding

## Step 4: Set Static DHCP Reservation (Important!)

To prevent your server's local IP from changing, reserve it:

1. Find **DHCP** settings in your router (often under LAN settings)
2. Look for **DHCP Reservation** or **Static IP** or **IP Address Reservation**
3. Add reservation:
   - **MAC Address**: Your server's MAC address
   - **IP Address**: The local IP you're using (e.g., 192.168.1.100)

**Find your MAC address:**
```bash
ip link show | grep "link/ether"
```

## Step 5: Verify Configuration

### Test from inside your network:
```bash
# On your laptop (same network), test if ports are open:
nc -zv <server-local-ip> 80
nc -zv <server-local-ip> 443
```

Should show: "Connection succeeded" or "open"

### Test from outside your network:

**After setting up DNS and starting Docker containers:**

Use a mobile phone (disconnect from WiFi, use cellular) and visit:
- http://ai.1sourcesystems.com.au

Or use online port checker:
- https://www.yougetsignal.com/tools/open-ports/
- Enter your public IP and test ports 80, 443

## Common Issues & Solutions

### Issue 1: Can't Access Router Admin Panel

**Solutions:**
- Check if you're connected to the router's WiFi/ethernet
- Try different common IPs listed above
- Check router manual or sticker for correct IP
- Reset router to factory defaults (last resort!)

### Issue 2: Port Forwarding Not Working

**Check these:**

1. **Firewall on server:**
   ```bash
   sudo ufw status
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

2. **Docker containers running:**
   ```bash
   sudo docker-compose ps
   ```

3. **Correct local IP in port forward rules:**
   ```bash
   # Verify server IP hasn't changed
   hostname -I
   ```

4. **ISP blocking ports:**
   ```bash
   # Test from outside network
   # If blocked, you'll need Cloudflare Tunnel (see README.md)
   ```

### Issue 3: Works Locally, Not Externally

**Possible causes:**
- ISP blocks ports 80/443 (common on residential connections)
- CGNAT (Carrier-Grade NAT) - you don't have a real public IP
- Router firewall blocking incoming connections

**Solutions:**
- Check with ISP if they block ports
- Use Cloudflare Tunnel instead (no port forwarding needed!)
- Some ISPs offer "public IP" option for small fee

### Issue 4: DNS Resolves but Connection Times Out

**Check:**
1. Port forwarding rules are correct
2. Server firewall allows traffic
3. Docker containers are running
4. Try accessing via IP directly: `http://<your-public-ip>`

### Issue 5: SSL Certificate Not Generating

**Must use port 80:**
- Let's Encrypt needs port 80 for HTTP challenge
- Can't use alternate ports
- If ISP blocks 80, use Cloudflare Tunnel

## ISP-Specific Notes

### Telstra (Australia)
- Most residential plans allow port forwarding
- Smart Modem Gen 2/3: Advanced → Port Forwarding
- May need to disable "Telstra Air" if it interferes

### Optus (Australia)
- Usually allows port forwarding
- Some plans may have CGNAT - check public IP matches actual
- Sagemcom routers: Toolbox → Game & Application Sharing

### TPG/iiNet (Australia)
- Generally good for port forwarding
- Router access: 10.1.1.1
- NAT settings under Advanced Setup

### Aussie Broadband (Australia)
- Excellent for self-hosting
- Provides real public IP (no CGNAT)
- Standard port forwarding works great

### NBN Fixed Wireless/Satellite
- May have CGNAT (check public IP)
- If CGNAT, use Cloudflare Tunnel

## Verify Your Public IP

Check if you have a real public IP or CGNAT:

```bash
# Find your public IP from server:
curl -4 ifconfig.me

# Then check your router's WAN IP (in router admin panel)
# If they MATCH = Good! You have a real public IP
# If DIFFERENT = CGNAT - you'll need Cloudflare Tunnel
```

## Alternative: DMZ (Not Recommended)

If port forwarding is too complex, some routers offer **DMZ** (Demilitarized Zone):

⚠️ **WARNING**: DMZ exposes ALL ports to internet - security risk!

Only use if:
- You understand the security implications
- Server firewall is properly configured
- No other option works

**DMZ Setup:**
1. Security → DMZ
2. Enable DMZ
3. Enter server's local IP
4. Save

## Testing After Setup

### 1. Local Network Test (from laptop on same WiFi):
```bash
curl http://<server-local-ip>:80
```

### 2. External Test (from mobile on cellular):
```bash
curl http://<your-public-ip>:80
```

### 3. DNS Test (after DNS propagates):
```bash
curl https://ai.1sourcesystems.com.au
```

## Quick Reference Card

```
┌─────────────────────────────────────────┐
│  Port Forwarding Quick Reference        │
├─────────────────────────────────────────┤
│  External Port 80  → Server IP : 80     │
│  External Port 443 → Server IP : 443    │
│                                         │
│  Protocol: TCP                          │
│  Enable: Yes                            │
│  Source: Any / All                      │
└─────────────────────────────────────────┘
```

## Complete Checklist

- [ ] Find server's local IP address
- [ ] Access router admin panel
- [ ] Create port forward: 80 → server:80
- [ ] Create port forward: 443 → server:443
- [ ] Set DHCP reservation for server's IP
- [ ] Configure server firewall (ufw)
- [ ] Test ports locally with nc
- [ ] Start Docker containers
- [ ] Configure Cloudflare DNS
- [ ] Wait for DNS propagation (5-10 min)
- [ ] Test external access from mobile/outside

## Need Help?

**Can't port forward? Consider these alternatives:**
1. **Cloudflare Tunnel** - No port forwarding needed! See README.md
2. **Tailscale VPN** - For private access only
3. **Contact ISP** - Some offer business plans with better port access

**ISP definitely blocks ports 80/443?**
→ Use Cloudflare Tunnel (see README.md "Alternative Access Methods")

## Resources

- **Port Checking Tool**: https://www.yougetsignal.com/tools/open-ports/
- **Find Your Public IP**: https://ifconfig.me
- **Router Manual**: Usually at manufacturer's website
- **Cloudflare Tunnel Guide**: See README.md Option 2
