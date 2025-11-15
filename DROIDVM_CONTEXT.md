# DroidVM: Complete Technical Context

> This document serves as the single source of truth for DroidVM - an old Android phone transformed into a cloud-accessible server. It is designed to be consumed by AI systems building documentation, websites, and tooling.

---

## 1. What is DroidVM?

DroidVM is an **old Android phone running as a tiny home server**, accessible from anywhere on the internet via custom domains.

**Core Philosophy:**
- Old phones are just ARM Linux boxes waiting to be useful
- You don't need root, bootloader unlocks, or custom ROMs
- Termux + proot-distro gives you real Linux without breaking anything
- Cloudflare Tunnel makes your phone a legitimate cloud node

**The Final Achievement:**
- Hit `https://api.droidvm.dev/status` from anywhere
- Get live system stats from a phone in a drawer
- No port forwarding, no ngrok limitations, real domains

---

## 2. Hardware & System Specifications

### Physical Device
```yaml
Model: Vivo V2158
OS: Android 14
RAM: 7.30 GB
Architecture: aarch64 (ARM64)
CPU Cores: 6
Kernel: 4.19.191+ (SMP PREEMPT)
```

### Software Stack
```yaml
Base Layer:
  - Android 14 (stock, no root)
  - Termux (F-Droid version)
  - Battery optimization: DISABLED for Termux

Linux Environment:
  - proot-distro with Ubuntu
  - Python 3.12.12 (in Termux)
  - tmux for session persistence

Key Packages:
  - openssh (port 8022)
  - tmux
  - python + pip
  - proot-distro
  - git
```

### Current Runtime State
```yaml
tmux_sessions:
  - name: droidvm-tools
    service: DroidVM Tools API
    port: 8000
    status: running

  - name: main
    service: Example app / experiments
    port: 8090
    status: running

  - name: cloudflared
    service: Cloudflare Tunnel (inside Ubuntu proot)
    status: running

processes:
  total: 20-25
  by_status:
    sleeping: 19-24
    running: 1
```

---

## 3. Access Methods

### 3.1 Local Network (Same WiFi)
```bash
# SSH access
ssh -p 8022 u0_a315@192.168.1.45

# API access
curl http://192.168.1.45:8000/status
curl http://192.168.1.45:8090/
```

### 3.2 Tailscale VPN (Private, Anywhere)
```bash
# SSH via Tailscale IP
ssh -p 8022 u0_a315@100.94.102.37

# API via Tailscale
curl http://100.94.102.37:8000/status

# Account: droidvmtailscale@gmail.com
```

### 3.3 Cloudflare Tunnel (Public Internet)
```yaml
Public URLs:
  - https://api.droidvm.dev  → localhost:8000
  - https://app.droidvm.dev  → localhost:8090

Features:
  - Automatic HTTPS (Cloudflare handles certs)
  - DDoS protection included
  - No port forwarding needed
  - Real domain names
  - Multiple subdomains on one tunnel
```

---

## 4. DroidVM Tools API

### 4.1 Overview
A FastAPI-based monitoring and management API built specifically for Termux/Android.

```yaml
Framework: FastAPI 0.103.2
Pydantic: v1.10.x (NOT v2 - avoids Rust compilation)
Server: Uvicorn 0.23.2
Python: 3.12
```

### 4.2 API Endpoints

**Root & Health**
```http
GET /
Response: {"name": "DroidVM Tools API", "version": "0.1.0", "status": "running", "timestamp": "..."}

GET /health
Response: {"status": "healthy", "timestamp": "..."}
```

**System Information**
```http
GET /system/info
GET /system/cpu
GET /system/memory
GET /system/disk
GET /system/battery
GET /system/processes
GET /system/tmux
```

**Network Information**
```http
GET /network/info
GET /network/stats
GET /network/connections
GET /network/tailscale
GET /network/ip
```

**Comprehensive Status**
```http
GET /status
Response: {
  "success": true,
  "data": {
    "timestamp": "2025-11-15T19:17:49.672458",
    "system": {
      "hostname": "localhost",
      "platform": "Linux",
      "platform_release": "4.19.191+",
      "platform_version": "#1 SMP PREEMPT Wed May 21 15:22:49 CST 2025",
      "architecture": "aarch64",
      "python_version": "3.12.12",
      "boot_time": "N/A"
    },
    "cpu": {
      "physical_cores": 6,
      "total_cores": 6,
      "max_frequency": "N/A",
      "min_frequency": "N/A",
      "current_frequency": "N/A",
      "cpu_usage_percent": 0,
      "cpu_usage_per_core": []
    },
    "memory": {
      "total": "7.30GB",
      "available": "4.42GB",
      "used": "2.88GB",
      "percentage": 39.4,
      "swap_total": "8.00GB",
      "swap_used": "3.42GB",
      "swap_percentage": 42.8
    },
    "battery": null,
    "network": {
      "tailscale_ip": null,
      "hostname": "localhost"
    },
    "tmux_sessions": [
      {"name": "droidvm-tools", "created": "2025-11-15T17:48:38", "attached": false},
      {"name": "main", "created": "2025-11-15T13:39:03", "attached": false}
    ],
    "processes": {
      "total": 20,
      "by_status": {"sleeping": 19, "running": 1}
    }
  }
}
```

### 4.3 CLI Tools
```bash
uv run droidvm-tools status     # Comprehensive overview
uv run droidvm-tools cpu        # CPU information
uv run droidvm-tools memory     # Memory usage
uv run droidvm-tools disk       # Disk partitions
uv run droidvm-tools battery    # Battery status (N/A on Termux)
uv run droidvm-tools network    # Network interfaces
uv run droidvm-tools netstat    # Network I/O stats
uv run droidvm-tools tailscale  # Tailscale VPN status
uv run droidvm-tools tmux       # List tmux sessions
uv run droidvm-tools version    # Version info
uv run droidvm-tools status --json  # Full JSON output
```

### 4.4 Known Limitations (Termux/Android)

**Not Available:**
- Battery info (psutil can't access `/sys/class/power_supply`)
- CPU frequency (can't read `/proc/cpuinfo` frequency fields)
- Boot time (can't read `/proc/uptime` reliably)
- Network I/O counters (permission denied on `/proc/net/dev`)
- Disk partitions list (can't read `/proc/filesystems`)

**Works Perfectly:**
- Memory usage (total, available, used, percentage)
- Swap memory usage
- Disk usage for specific paths (like `/`)
- Process listing and counting
- tmux session management
- Network hostname
- System platform info

**Key Technical Decisions:**
- Used Pydantic v1.x (no Rust/pydantic-core compilation needed)
- All psutil calls wrapped in try-except for graceful degradation
- Returns `null` or `"N/A"` instead of crashing on permission errors
- FastAPI 0.103.2 (last version with full Pydantic v1 support)

---

## 5. Cloudflare Tunnel Configuration

### 5.1 Tunnel Details
```yaml
Tunnel Name: shravan-tunnel
Tunnel ID: fab47e5c-2ab4-41db-a985-082630e66969
Credentials: /root/.cloudflared/fab47e5c-2ab4-41db-a985-082630e66969.json
Certificate: /root/.cloudflared/cert.pem
```

### 5.2 Ingress Configuration
File: `/root/.cloudflared/config.yml`
```yaml
tunnel: fab47e5c-2ab4-41db-a985-082630e66969
credentials-file: /root/.cloudflared/fab47e5c-2ab4-41db-a985-082630e66969.json

ingress:
  - hostname: api.droidvm.dev
    service: http://localhost:8000

  - hostname: app.droidvm.dev
    service: http://localhost:8090

  - service: http_status:404
```

### 5.3 DNS Records
Created via CLI:
```bash
cloudflared tunnel route dns shravan-tunnel api.droidvm.dev
cloudflared tunnel route dns shravan-tunnel app.droidvm.dev
```

### 5.4 Running the Tunnel
```bash
# In tmux session 'cloudflared'
tmux new -s cloudflared
proot-distro login ubuntu
cloudflared tunnel run shravan-tunnel
# Ctrl+b, d to detach
```

---

## 6. Evolution Timeline

### Phase 1: Basic Termux Setup
**Goal:** Make phone act like a remote machine

- Installed Termux from F-Droid
- Set up SSH server on port 8022
- Configured tmux for session persistence
- Installed Python 3.12
- Disabled Android battery optimization for Termux

**Result:** SSH access from same WiFi

### Phase 2: Tailscale Private Access
**Goal:** Access phone from anywhere privately

- Installed Tailscale Android app
- Got Tailscale IP: 100.94.102.37
- Now reachable from any network (laptop, office, etc.)

**Result:** Private remote VM accessible anywhere

### Phase 3: Python API Development
**Goal:** Run actual web services

- Initially tried FastAPI + Pydantic v2
- **Problem:** pydantic-core requires Rust compilation on ARM
- **Solution:** Downgraded to FastAPI 0.103.2 + Pydantic v1.10
- Built DroidVM Tools API with psutil monitoring
- Added extensive error handling for Termux permission issues

**Result:** Working API at localhost:8000

### Phase 4: ngrok Experiments
**Goal:** Public internet access

- Installed Ubuntu via proot-distro (for binary compatibility)
- Ran ngrok inside Ubuntu
- Got temporary public URL

**Problems:**
- ngrok free tier URL changes on restart
- Rate limits
- Random subdomain

**Result:** Proof of concept for public access

### Phase 5: Cloudflare Tunnel (Final)
**Goal:** Real domains, stable URLs, proper setup

- Migrated from ngrok to Cloudflare Tunnel
- Used personal domain: droidvm.dev
- Set up multiple subdomains (api.droidvm.dev, app.droidvm.dev)
- Automatic HTTPS, DDoS protection
- Stable, production-ready setup

**Result:** Professional cloud-accessible phone server

---

## 7. File Structure

### On Android Device (Termux)
```
/data/data/com.termux/files/home/
├── droidvm-tools/              # Main project (git repo)
│   ├── src/droidvm_tools/
│   │   ├── __init__.py
│   │   ├── server.py           # FastAPI server
│   │   ├── cli.py              # Typer CLI
│   │   └── tools/
│   │       ├── system.py       # System monitoring
│   │       └── network.py      # Network utilities
│   ├── pyproject.toml          # UV project config
│   ├── .venv/                  # Virtual environment
│   └── ...
└── droidvm-demo/               # Example app on port 8090
    └── main.py
```

### In proot Ubuntu
```
/root/
└── .cloudflared/
    ├── cert.pem
    ├── config.yml
    └── fab47e5c-2ab4-41db-a985-082630e66969.json
```

---

## 8. The Self-Hosting Inception

**Current State:**
- `api.droidvm.dev` → DroidVM Tools API (phone)
- `app.droidvm.dev` → Available for apps (phone)

**Future State:**
- `docs.droidvm.dev` → Documentation website (ALSO hosted on phone!)

This means: The documentation about how to build DroidVM will itself be hosted on DroidVM. Pure inception.

---

## 9. Why This Matters

### For Developers
- Free "cloud VM" that you already own
- No monthly fees, no vendor lock-in
- Learn Linux, networking, tunneling hands-on
- Great for webhooks, personal APIs, home automation

### For the Environment
- Turns e-waste into infrastructure
- Phone stays useful instead of landfill
- Low power consumption (~5W vs 50-100W for a server)

### For the Community
- Shows phones are just computers
- Democratizes server ownership
- Fun, educational project
- "Look what's possible" energy

---

## 10. Quick Reference

### Access Your DroidVM
```bash
# SSH (Tailscale)
ssh -p 8022 u0_a315@100.94.102.37

# API (Cloudflare)
curl https://api.droidvm.dev/status

# API Docs
open https://api.droidvm.dev/docs
```

### Manage Services
```bash
# List tmux sessions
tmux ls

# Attach to session
tmux attach -t droidvm-tools

# Restart API
tmux attach -t droidvm-tools
# Ctrl+C, then:
uv run start-server
# Ctrl+b, d to detach

# Check tunnel
tmux attach -t cloudflared
```

### Key URLs
- **API Status:** https://api.droidvm.dev/status
- **API Docs:** https://api.droidvm.dev/docs
- **App Slot:** https://app.droidvm.dev
- **Future Docs:** https://docs.droidvm.dev

---

## 11. Meta Information

**Project Owner:** Shravan
**Started:** November 2025
**Status:** Production-ready (for personal/demo use)
**Open Source:** Yes (MIT License)

**Repositories:**
- `droidvm-tools` - The API and tools running on the phone
- `droidvm-setup` (planned) - One-command setup for anyone

**Social Proof:**
- Live API returning real stats from actual phone
- Cloudflare Tunnel = legitimate infrastructure
- Been running stable for multiple days

---

## 12. For the AI Building docs.droidvm.dev

When you build the documentation website, keep these in mind:

1. **Show, don't just tell** - Embed live API responses
2. **Make it interactive** - Let users see real phone stats
3. **Be honest about limitations** - Battery and some CPU stats don't work
4. **Celebrate the hack** - This is beautifully cursed and that's the point
5. **Keep it simple** - The magic is in the simplicity
6. **Mobile-first** - Ironic if docs aren't mobile-friendly
7. **Dark mode** - It's 2025
8. **Self-aware footer** - "This website is hosted on an old phone"

**Tone:** Technical but approachable. Excited but not hype. Honest about limitations. Proud of the achievement.

---

This is DroidVM. An old phone, a lot of stubbornness, and a beautiful little server on the internet.
