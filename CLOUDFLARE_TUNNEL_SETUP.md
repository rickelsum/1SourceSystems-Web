# Cloudflare Tunnel Setup Guide

## What is Cloudflare Tunnel?

Cloudflare Tunnel creates a secure outbound-only connection from your server to Cloudflare's network. This means:
- ✅ **No port forwarding needed** on your router
- ✅ **No firewall changes required** (except allowing outbound connections)
- ✅ Works behind **any NAT or firewall**
- ✅ **No exposed public IP** - your server is never directly accessible
- ✅ **DDoS protection** built-in through Cloudflare
- ✅ **Free** with your Cloudflare account

## Setup Steps

### Step 1: Create a Cloudflare Tunnel

1. **Log in to Cloudflare Dashboard:**
   - Go to: https://one.dash.cloudflare.com/
   - Select your account
   - Navigate to: **Zero Trust** → **Networks** → **Tunnels**

2. **Create a New Tunnel:**
   - Click **"Create a tunnel"**
   - Choose **"Cloudflared"** as the connector type
   - Name your tunnel (e.g., `1sourcesystems-ai-lab`)
   - Click **"Save tunnel"**

3. **Get Your Tunnel Token:**
   - After creating the tunnel, you'll see installation instructions
   - **Copy the token** from the docker run command
   - It will look like: `eyJhIjoiY2I5ZDM5OGQ2YzI5NDUwM2I4YmY0ZGRhNDZiZjU5NjQiLCJ0IjoiYTBiMWMyZDMtZTRmNS02Nzg5LWEwYjEtYzJkM2U0ZjU2Nzg5IiwicyI6Ik1qQXlOQT09In0=`

   docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token eyJhIjoiZGYwOTJiMTljNTkxOTZiYWNjNjE1N2FjMDgyYmViMGEiLCJ0IjoiMjAxMjkxNzQtYjI1Yi00ZmZiLWJjMDgtN2RhMWQyYmY4YmU5IiwicyI6Ik9UUmlZamM0WldVdFptUTNPUzAwWXpBMkxUa3paR010Tnprd1l6QmtNMk5sTVRoayJ9

4. **Add Token to .env File:**
   ```bash
   nano .env
   ```
   Add this line:
   ```
   TUNNEL_TOKEN=your_token_here
   ```
   Save and exit (Ctrl+X, Y, Enter)

### Step 2: Configure Public Hostnames

In the Cloudflare Tunnel dashboard, add routes for each service:

#### Route 1: Open WebUI (AI)
- **Public hostname:** `ai.1sourcesystems.com.au`
- **Service type:** `HTTP`
- **URL:** `traefik:80` (or `http://traefik:80`)

#### Route 2: Portainer
- **Public hostname:** `portainer.1sourcesystems.com.au`
- **Service type:** `HTTP`
- **URL:** `traefik:80`

#### Route 3: n8n
- **Public hostname:** `n8n.1sourcesystems.com.au`
- **Service type:** `HTTP`
- **URL:** `traefik:80`

#### Route 4: Adminer (Database)
- **Public hostname:** `db.1sourcesystems.com.au`
- **Service type:** `HTTP`
- **URL:** `traefik:80`

#### Route 5: Traefik Dashboard
- **Public hostname:** `traefik.1sourcesystems.com.au`
- **Service type:** `HTTP`
- **URL:** `traefik:80`

### Step 3: Update SSL/TLS Settings in Cloudflare

Since the tunnel uses HTTP internally (Cloudflare handles SSL termination):

1. Go to **SSL/TLS** → **Overview**
2. Set encryption mode to: **"Flexible"** or **"Full"**
   - **Flexible:** HTTP between Cloudflare and your origin (recommended for tunnels)
   - **Full:** If you want to keep origin certificates

### Step 4: Start the Tunnel

```bash
docker-compose up -d cloudflared
```

### Step 5: Verify Tunnel Status

Check if the tunnel is connected:
```bash
docker logs cloudflared
```

You should see:
```
Connection established
Registered tunnel connection
```

In the Cloudflare dashboard, the tunnel status should show as **"HEALTHY"**.

## Important Notes

### About Origin Certificates

With Cloudflare Tunnel, you have two options:

**Option A: Remove Origin Certificates (Simpler)**
- Set Cloudflare SSL/TLS to "Flexible"
- Traffic: User → Cloudflare (HTTPS) → Tunnel → Your Server (HTTP)
- The tunnel connection is already encrypted
- You can remove the origin certificate configuration from Traefik

**Option B: Keep Origin Certificates (More Secure)**
- Set Cloudflare SSL/TLS to "Full" or "Full (strict)"
- Change tunnel routes to use `https://traefik:443` instead of `http://traefik:80`
- Keeps end-to-end encryption
- Tunnel traffic is double-encrypted

### DNS Records

Cloudflare Tunnel automatically manages DNS records when you create public hostname routes. You don't need to manually create:
- `ai.1sourcesystems.com.au`
- `n8n.1sourcesystems.com.au`

They're created automatically as CNAME records pointing to your tunnel.

### Port Forwarding

**You can now REMOVE port forwarding rules from your router** for ports 80 and 443. The tunnel doesn't need them!

### Traefik Configuration

With the tunnel, Traefik receives requests on port 80 from the tunnel (even though users access via HTTPS to Cloudflare). The tunnel handles the SSL termination at Cloudflare's edge.

If using Option A (Flexible SSL), you may want to:
1. Update Traefik to not redirect HTTP to HTTPS (since tunnel uses HTTP internally)
2. Or keep the redirect and change tunnel routes to use HTTPS

## Troubleshooting

### Tunnel won't start
- Check the token is correct in `.env`
- Check logs: `docker logs cloudflared`
- Ensure the container can reach the internet

### 502 Bad Gateway
- Check Traefik is running: `docker ps | grep traefik`
- Verify the service URL in Cloudflare dashboard
- Check tunnel logs for connection errors

### Services not accessible
- Verify public hostnames are configured in Cloudflare
- Check tunnel status is "HEALTHY"
- Verify DNS has propagated (can take a few minutes)

## Benefits You Get

1. **No more 522 errors** - Tunnel establishes reliable connection
2. **No ISP port blocking issues** - Uses outbound connections only
3. **Better security** - Your server IP is hidden
4. **DDoS protection** - Cloudflare shields your server
5. **Zero Trust access** - Can add authentication if needed
6. **Works anywhere** - Behind any firewall or NAT

## Next Steps After Setup

Once the tunnel is working, you can:
1. Remove port forwarding from your router
2. Optionally disable cloudflare-ddns container (not needed anymore)
3. Consider removing origin certificates if using Flexible SSL
4. Enable Cloudflare Access for authentication on sensitive services
