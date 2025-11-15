# DroidVM Open Source Setup Tool

> Transform any old Android phone into a cloud-accessible server with ONE command.

---

## Repository: `droidvm-setup`

### The Dream
```bash
# On your Android phone, in Termux:
curl -sSL https://droidvm.dev/setup | bash
```

That's it. The script handles everything else.

---

## Repository Structure

```
droidvm-setup/
├── README.md                         # Beautiful landing page
├── LICENSE                           # MIT
├── setup.sh                          # THE ONE SCRIPT
│
├── scripts/                          # Modular setup components
│   ├── 00_preflight.sh              # Check requirements
│   ├── 01_termux_base.sh            # Core packages
│   ├── 02_ssh_setup.sh              # SSH server + security
│   ├── 03_tmux_setup.sh             # tmux with nice config
│   ├── 04_python_setup.sh           # Python + uv
│   ├── 05_tailscale_guide.sh        # Tailscale instructions
│   ├── 06_proot_ubuntu.sh           # Ubuntu via proot-distro
│   ├── 07_cloudflared_setup.sh      # Cloudflare Tunnel
│   ├── 08_droidvm_tools.sh          # Install the monitoring API
│   └── 99_finalize.sh               # Final setup + welcome
│
├── configs/                          # Configuration templates
│   ├── tmux.conf                    # Nice tmux defaults
│   ├── bashrc_additions             # Helpful aliases
│   ├── cloudflared_config.yml.template
│   └── motd.txt                     # Message of the day
│
├── docs/                             # Documentation
│   ├── README.md                    # Main docs
│   ├── QUICKSTART.md                # 5-minute setup
│   ├── FULL_GUIDE.md                # Complete walkthrough
│   ├── COMPONENTS.md                # What each part does
│   ├── TROUBLESHOOTING.md           # Common issues + fixes
│   ├── WHY_DROIDVM.md               # Philosophy + use cases
│   ├── ANDROID_TIPS.md              # Battery, permissions, etc.
│   └── SECURITY.md                  # Security considerations
│
├── examples/                         # Ready-to-run examples
│   ├── simple_api/                  # Basic Starlette API
│   ├── status_dashboard/            # Web dashboard
│   ├── webhook_handler/             # GitHub webhook receiver
│   ├── feature_flags/               # Simple feature flag service
│   └── file_server/                 # Personal file hosting
│
└── assets/                           # Branding + media
    ├── logo.png
    ├── banner.png
    └── screenshots/
```

---

## The Main Setup Script (`setup.sh`)

### Features

1. **Interactive Wizard**
   - Beautiful terminal UI with colors
   - Ask what features user wants
   - Explain each step before running

2. **Modular Architecture**
   - Each component is independent
   - Skip already-installed components
   - Resume from failures

3. **Smart Detection**
   - Check if running in Termux
   - Detect Android version
   - Verify network connectivity
   - Check available storage

4. **Progress Tracking**
   - Show current step clearly
   - Estimated time remaining
   - Log everything for debugging

5. **Error Recovery**
   - Clear error messages
   - Suggestions for fixes
   - Option to retry or skip

### Installation Levels

```bash
./setup.sh --level basic      # SSH + tmux + Python
./setup.sh --level private    # + Tailscale guide
./setup.sh --level public     # + Cloudflare Tunnel
./setup.sh --level full       # + DroidVM Tools API
./setup.sh                    # Interactive (asks what you want)
```

### Example Flow

```
╔═══════════════════════════════════════════╗
║         Welcome to DroidVM Setup          ║
║    Turn your phone into a cloud server    ║
╚═══════════════════════════════════════════╝

Pre-flight checks...
  ✓ Running in Termux
  ✓ Network connectivity
  ✓ 2.3GB free storage
  ✓ Android 14 detected

What would you like to set up?

  [1] Basic Server (SSH + tmux + Python)
  [2] Private Cloud (+ Tailscale VPN access)
  [3] Public Server (+ Cloudflare Tunnel)
  [4] Full DroidVM (+ Monitoring API + CLI tools)
  [5] Custom (choose components)

Your choice [4]:

Starting Full DroidVM setup...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/8] Installing base packages...
      pkg update && pkg upgrade
      Installing: openssh tmux python git proot-distro
      ✓ Done (45s)

[2/8] Configuring SSH server...
      Setting up port 8022...
      Creating strong password...
      ✓ Done (10s)

[3/8] Setting up tmux...
      Installing config at ~/.tmux.conf
      Creating startup session...
      ✓ Done (5s)

[4/8] Configuring Python environment...
      Installing uv package manager...
      ✓ Done (20s)

[5/8] Tailscale setup guide...
      ════════════════════════════════
      Tailscale gives you private VPN access from anywhere.

      Steps:
      1. Install Tailscale app from Play Store
      2. Open app and sign in
      3. Note your Tailscale IP (100.x.x.x)

      Press ENTER when done, or 's' to skip:

[6/8] Setting up Ubuntu environment...
      Installing proot-distro...
      Downloading Ubuntu rootfs...
      ✓ Done (180s)

[7/8] Cloudflare Tunnel setup...
      ════════════════════════════════
      This requires a domain on Cloudflare.

      Do you have a domain ready? [y/n]: y

      Installing cloudflared...
      Starting authentication...

      [!] Open this URL in your browser:
      https://dash.cloudflare.com/argotunnel?...

      Press ENTER after authorizing...

      Creating tunnel 'droidvm-tunnel'...
      ✓ Tunnel created: abc123-def456...

      Enter subdomain for API (e.g., api): api
      Enter your domain (e.g., example.com): droidvm.dev

      Creating DNS route: api.droidvm.dev
      ✓ DNS configured

      ✓ Done (120s)

[8/8] Installing DroidVM Tools API...
      Cloning droidvm-tools...
      Installing dependencies (this may take a while)...
      Creating tmux session...
      Starting API server...
      ✓ Done (90s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 DroidVM setup complete!

Your phone is now a cloud server:

  SSH Access:
    Local:    ssh -p 8022 u0_a315@192.168.1.45
    Tailscale: ssh -p 8022 u0_a315@100.94.102.37

  API Access:
    Local:    http://localhost:8000
    Public:   https://api.droidvm.dev

  tmux sessions running:
    droidvm-tools  → API server (port 8000)
    cloudflared    → Tunnel service

  Next steps:
    1. Check API: curl https://api.droidvm.dev/status
    2. See logs:   tmux attach -t droidvm-tools
    3. Read docs:  cat ~/droidvm-setup/docs/README.md

  Need help? https://github.com/myselfshravan/droidvm-setup/issues

Happy hacking! 🚀
```

---

## Key Scripts

### `00_preflight.sh`
```bash
# Check we're in Termux
# Check network
# Check storage space
# Check Android version
# Warn about battery optimization
```

### `01_termux_base.sh`
```bash
pkg update -y
pkg upgrade -y
pkg install -y \
  openssh \
  tmux \
  git \
  wget \
  curl \
  proot-distro \
  python \
  python-pip
```

### `02_ssh_setup.sh`
```bash
# Set password
# Start sshd
# Show connection info
# Add to .bashrc for auto-start
```

### `03_tmux_setup.sh`
```bash
# Copy nice tmux.conf
# Set up default session
# Add helpful aliases
```

### `06_proot_ubuntu.sh`
```bash
proot-distro install ubuntu
# Copy setup script into Ubuntu
# Pre-install curl, wget
```

### `07_cloudflared_setup.sh`
```bash
# Interactive Cloudflare setup
# Download binary
# Auth flow
# Create tunnel
# DNS routing
# Generate config
# Start in tmux
```

---

## README.md (Landing Page)

```markdown
<div align="center">
  <img src="assets/logo.png" width="200" />
  <h1>DroidVM Setup</h1>
  <p><strong>Turn your old Android phone into a cloud server in minutes</strong></p>

  <a href="#quickstart">Quick Start</a> •
  <a href="#features">Features</a> •
  <a href="#docs">Docs</a> •
  <a href="#examples">Examples</a>
</div>

---

## What is DroidVM?

Your old phone is not e-waste. It's a tiny ARM Linux box with:
- Enough RAM to run web services
- Built-in battery backup
- WiFi connectivity
- Low power consumption

DroidVM turns it into a **real cloud server** with:
- SSH access from anywhere
- HTTPS APIs on custom domains
- No port forwarding needed
- No monthly fees

## Quick Start

On your Android phone:

1. Install [Termux](https://f-droid.org/packages/com.termux/)
2. Open Termux and run:

```bash
pkg install curl -y
curl -sSL https://droidvm.dev/setup | bash
```

3. Follow the interactive wizard
4. Done! Your phone is now a cloud server.

## Features

- 🚀 **One command setup** - No manual configuration
- 📱 **No root required** - Works on stock Android
- 🔒 **Secure by default** - SSH keys, strong passwords
- 🌐 **Public HTTPS** - Via Cloudflare Tunnel
- 🔧 **Modular** - Pick only what you need
- 📊 **Built-in monitoring** - System stats API included
- 🎯 **Battle-tested** - Works on real hardware

## What You Get

| Feature | Description |
|---------|-------------|
| SSH Server | Remote terminal access (port 8022) |
| tmux | Persistent sessions that survive disconnects |
| Python 3.12 | Modern Python with uv package manager |
| Tailscale | Private VPN access from anywhere |
| Cloudflare Tunnel | Public HTTPS with custom domains |
| DroidVM Tools | System monitoring API + CLI |

## Requirements

- Android phone (7.0+, 3GB+ RAM recommended)
- Termux installed from F-Droid
- WiFi connection
- 30 minutes of patience

Optional:
- Cloudflare account (free) for public access
- Tailscale account (free) for private VPN

## Use Cases

- **Personal API server** - Feature flags, webhooks, automation
- **Development playground** - Test deployments on real infra
- **Home automation hub** - Connect IoT devices
- **Learning platform** - Linux, networking, Docker (eventually)
- **Bragging rights** - "My website runs on a phone"

## Security

⚠️ This is for personal use and learning. Don't put sensitive production data on a phone in your drawer.

See [SECURITY.md](docs/SECURITY.md) for best practices.

## License

MIT - Do whatever you want with it.

## Credits

Built by [Shravan](https://github.com/myselfshravan) out of pure stubbornness and a refusal to let a phone become e-waste.

Special thanks to:
- Termux team
- Cloudflare for free tunnels
- Everyone who said "but why?"

---

<div align="center">
  <strong>Old phones deserve better than a drawer.</strong>
  <br>
  Give yours a second life.
</div>
```

---

## Marketing / Social Proof

### Live Demo
- `https://api.droidvm.dev/status` - Returns real stats from actual phone
- Badge on README: "Powered by DroidVM - See live stats"

### Metrics to Show
- Uptime counter
- Requests served
- Memory usage
- "Running on: Vivo V2158"

### Social
- Tweet thread with screenshots
- Reddit post on r/selfhosted, r/homelab
- Hacker News submission
- Dev.to article
- YouTube demo video

---

## Future Roadmap

### v1.0 - Foundation
- [x] Core setup script
- [x] SSH + tmux + Python
- [x] Tailscale guide
- [x] Cloudflare Tunnel setup
- [x] DroidVM Tools API

### v1.1 - Polish
- [ ] Better error handling
- [ ] Automatic recovery
- [ ] Update mechanism
- [ ] Health checks

### v2.0 - Advanced
- [ ] Docker support (if possible)
- [ ] Multiple phone clustering
- [ ] Automatic SSL renewal
- [ ] Backup/restore scripts

### v3.0 - Ecosystem
- [ ] Plugin system
- [ ] App marketplace
- [ ] Community configs
- [ ] Phone compatibility database

---

This is the plan for democratizing old phone servers.

Let's make it happen.
