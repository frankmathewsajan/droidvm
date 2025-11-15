
DroidVM
Home
Quick Start
Guide
API
Examples
Live Stats
Blog
About
GitHub
DroidVM
Your Old Phone is a Cloud Server Now

That phone in your drawer? It's not e-waste. It's an ARM Linux box waiting for a purpose.

Get Started
See Live Stats
GitHub
Live from an actual phone
Updated: 01:18:46
Platform

Linux (aarch64)

CPU Cores

6

Memory

3.61GB / 7.30GB

Processes

23 running

tmux sessions:

cloudflared
droidvm-tools
main
ngrok-8000
This website is served from the same phone

What You Get
SSH Access from Anywhere
Connect to your phone like a real server with SSH, tmux, and persistent sessions

HTTPS APIs on Custom Domains
Run web services with real domain names and automatic SSL certificates

No Port Forwarding
Use Cloudflare Tunnel or Tailscale VPN for secure, easy access

Zero Monthly Fees
Turn e-waste into infrastructure without subscriptions or vendor lock-in

Real Cloud Infrastructure
Powered by a Vivo V2158

7.30GB
Total RAM

6
CPU Cores

24/7
Uptime

Ready to Give Your Phone a Second Life?
Get started in 5 minutes with our quick setup guide

Start Building
DroidVM
Old phones deserve a second life

Links
Quick Start
Full Guide
API Docs
Examples
Connect
© 2025 Shravan | MIT License

This website is hosted on a phone
Edit with
×


DroidVM
Home
Quick Start
Guide
API
Examples
Live Stats
Blog
About
GitHub
Quick Start
Get DroidVM running on your old Android phone in 5 minutes

Before You Begin
Android phone (Android 7+)

At least 3GB RAM recommended

WiFi connection

Stable internet access

Termux installed

Download from F-Droid

1
Install Termux
Install Termux from F-Droid (not Play Store, it's outdated):

Download Termux from F-Droid →
2
Run Setup Command
Open Termux and run this one command:

Copy
pkg install curl -y
curl -sSL https://droidvm.dev/setup | bash
3
Follow the Wizard
The interactive setup wizard will guide you through:

Installing base packages (SSH, tmux, Python)
Setting up SSH server
Configuring Tailscale (optional)
Setting up Cloudflare Tunnel (optional)
Installing DroidVM Tools API
What Happens Next?
After the setup completes, you'll have:

SSH access to your phone on port 8022
tmux for persistent sessions
Python 3.12 with uv package manager
DroidVM Tools API running on localhost:8000
(Optional) Public HTTPS URL via Cloudflare Tunnel
Expected Output
When setup completes successfully, you'll see:

Copy
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

Happy hacking! 🚀
Troubleshooting
Setup script fails
Make sure you have a stable internet connection and enough storage space (at least 1GB free)

Can't SSH into phone
Check if SSH server is running: sshd

Phone kills Termux
Go to Settings → Apps → Termux → Battery and set to "Unrestricted"

Next Steps
Read the Full Guide
Learn everything about DroidVM setup and configuration

View Full Guide →
Explore the API
Discover what you can do with the DroidVM Tools API

API Documentation →
DroidVM
Old phones deserve a second life

Links
Quick Start
Full Guide
API Docs
Examples
Connect
© 2025 Shravan | MIT License

This website is hosted on a phone
Edit with
×



DroidVM
Home
Quick Start
Guide
API
Examples
Live Stats
Blog
About
GitHub
Complete Guide
Everything you need to know about building and running DroidVM

What You'll Learn
This comprehensive guide covers everything from basic Termux setup to running production-ready services on your old Android phone.

By the end, you'll have a fully functional cloud-accessible server with SSH access, web services, and monitoring tools.

Guide Sections
Initial Setup
Install Termux, set up SSH, and configure your base environment

Read More
Tailscale Private Access
Set up secure VPN access to your phone from anywhere

Read More
Cloudflare Tunnel
Expose services to the public internet with HTTPS

Read More
DroidVM Tools API
Monitor and manage your phone server with the built-in API

Read More
Philosophy
DroidVM is built on a simple idea: old phones are computers, not e-waste.

Every step in this guide prioritizes:

• Simplicity - No root, no bootloader unlocks
• Security - Secure defaults with SSH keys and VPNs
• Reliability - tmux sessions that survive disconnects
• Learning - Understand what you're building
Prefer a Quick Start?
Get up and running in 5 minutes

Quick Start Guide
DroidVM
Old phones deserve a second life

Links
Quick Start
Full Guide
API Docs
Examples
Connect
© 2025 Shravan | MIT License

This website is hosted on a phone
Edit with
×


DroidVM
Home
Quick Start
Guide
API
Examples
Live Stats
Blog
About
GitHub
API Documentation
Explore the DroidVM Tools API endpoints

Base URL
https://api.droidvm.dev
All endpoints return JSON responses. The API is read-only and does not require authentication.

Endpoints
GET
/
API information and status

Try it
Example Response:

Copy
{
  "name": "DroidVM Tools API",
  "version": "0.1.0",
  "status": "running",
  "timestamp": "2025-11-15T19:17:49.672458"
}
GET
/health
Health check endpoint

Try it
Example Response:

Copy
{
  "status": "healthy",
  "timestamp": "2025-11-15T19:17:49.672458"
}
GET
/status
Complete system status including CPU, memory, processes, and tmux sessions

Try it
Example Response:

Copy
{
  "success": true,
  "data": {
    "timestamp": "2025-11-15T19:17:49.672458",
    "system": {
      "hostname": "localhost",
      "platform": "Linux",
      "architecture": "aarch64",
      "python_version": "3.12.12"
    },
    "memory": {
      "total": "7.30GB",
      "available": "4.42GB",
      "used": "2.88GB",
      "percentage": 39.4
    },
    "cpu": {
      "physical_cores": 6,
      "total_cores": 6
    },
    "processes": {
      "total": 20,
      "by_status": {"sleeping": 19, "running": 1}
    },
    "tmux_sessions": [
      {"name": "droidvm-tools", "attached": false}
    ]
  }
}
GET
/system/info
System platform information

Try it
Example Response:

Copy
{
  "hostname": "localhost",
  "platform": "Linux",
  "platform_release": "4.19.191+",
  "architecture": "aarch64",
  "python_version": "3.12.12"
}
GET
/system/cpu
CPU information and usage

Try it
Example Response:

Copy
{
  "physical_cores": 6,
  "total_cores": 6,
  "cpu_usage_percent": 5.2
}
GET
/system/memory
Memory usage statistics

Try it
Example Response:

Copy
{
  "total": "7.30GB",
  "available": "4.42GB",
  "used": "2.88GB",
  "percentage": 39.4,
  "swap_total": "8.00GB",
  "swap_used": "3.42GB"
}
GET
/system/processes
Process count and statistics

Try it
Example Response:

Copy
{
  "total": 20,
  "by_status": {
    "sleeping": 19,
    "running": 1
  }
}
GET
/system/tmux
List active tmux sessions

Try it
Example Response:

Copy
{
  "sessions": [
    {
      "name": "droidvm-tools",
      "created": "2025-11-15T17:48:38",
      "attached": false
    }
  ]
}
GET
/network/info
Network interface information

Try it
Example Response:

Copy
{
  "hostname": "localhost",
  "interfaces": {
    "lo": ["127.0.0.1"],
    "wlan0": ["192.168.1.45"]
  }
}
GET
/network/tailscale
Tailscale VPN status and IP

Try it
Example Response:

Copy
{
  "ip": "100.94.102.37",
  "status": "connected"
}
CLI Tools
DroidVM Tools also includes CLI commands you can run directly on your phone:

Copy
# Get comprehensive system status
uv run droidvm-tools status

# Check CPU information
uv run droidvm-tools cpu

# View memory usage
uv run droidvm-tools memory

# List tmux sessions
uv run droidvm-tools tmux

# Get JSON output
uv run droidvm-tools status --json
DroidVM
Old phones deserve a second life

Links
Quick Start
Full Guide
API Docs
Examples
Connect
© 2025 Shravan | MIT License

This website is hosted on a phone
Edit with
×


DroidVM
Home
Quick Start
Guide
API
Examples
Live Stats
Blog
About
GitHub
Examples
Real-world use cases and ready-to-run code for your DroidVM

Getting Started with Examples
All examples use Starlette or FastAPI and can be run directly on your phone:

Copy
# Create a new directory for your app
mkdir ~/my-app
cd ~/my-app

# Create main.py with example code
nano main.py

# Install dependencies
pip install starlette uvicorn

# Run in a tmux session
tmux new -s my-app
uvicorn main:app --host 0.0.0.0 --port 8100

# Detach: Ctrl+b, d
Personal Status API
Return your current status based on calendar or manual toggle

Copy
from starlette.applications import Starlette
from starlette.responses import JSONResponse
from starlette.routing import Route

status = {"available": True, "message": "Available"}

async def get_status(request):
    return JSONResponse(status)

async def set_status(request):
    global status
    data = await request.json()
    status.update(data)
    return JSONResponse(status)

app = Starlette(routes=[
    Route('/status', get_status),
    Route('/status', set_status, methods=['POST']),
])
Webhook Handler
Receive GitHub webhooks or trigger home automation

Copy
from starlette.applications import Starlette
from starlette.responses import JSONResponse
from starlette.routing import Route
import subprocess

async def handle_webhook(request):
    payload = await request.json()
    
    # Trigger action based on webhook
    if payload.get('event') == 'push':
        subprocess.run(['notify-send', 'New push!'])
    
    return JSONResponse({"status": "processed"})

app = Starlette(routes=[
    Route('/webhook', handle_webhook, methods=['POST']),
])
Feature Flags Service
Simple JSON API for feature toggles without deployments

Copy
from starlette.applications import Starlette
from starlette.responses import JSONResponse
from starlette.routing import Route
import json

flags = {
    "new_ui": True,
    "dark_mode": True,
    "beta_features": False
}

async def get_flags(request):
    return JSONResponse(flags)

async def toggle_flag(request):
    flag = request.path_params['flag']
    if flag in flags:
        flags[flag] = not flags[flag]
    return JSONResponse(flags)

app = Starlette(routes=[
    Route('/flags', get_flags),
    Route('/flags/{flag}/toggle', toggle_flag, methods=['POST']),
])
Personal File Server
Upload and download files to your phone

Copy
from starlette.applications import Starlette
from starlette.responses import FileResponse
from starlette.routing import Route
import os

UPLOAD_DIR = "/storage/emulated/0/files"

async def upload_file(request):
    form = await request.form()
    file = form['file']
    path = os.path.join(UPLOAD_DIR, file.filename)
    
    with open(path, 'wb') as f:
        f.write(await file.read())
    
    return JSONResponse({"uploaded": file.filename})

async def download_file(request):
    filename = request.path_params['filename']
    path = os.path.join(UPLOAD_DIR, filename)
    return FileResponse(path)

app = Starlette(routes=[
    Route('/upload', upload_file, methods=['POST']),
    Route('/files/{filename}', download_file),
])
Home Automation Hub
Control smart devices and receive sensor data

Copy
from starlette.applications import Starlette
from starlette.responses import JSONResponse
from starlette.routing import Route

devices = {
    "living_room_light": {"state": "off", "brightness": 0},
    "bedroom_temp": {"value": 22.5, "unit": "C"}
}

async def get_devices(request):
    return JSONResponse(devices)

async def control_device(request):
    device_id = request.path_params['device_id']
    data = await request.json()
    
    if device_id in devices:
        devices[device_id].update(data)
    
    return JSONResponse(devices[device_id])

app = Starlette(routes=[
    Route('/devices', get_devices),
    Route('/devices/{device_id}', control_device, 
          methods=['POST']),
])
Deploying to Cloudflare Tunnel
Once your app is running, add it to your Cloudflare Tunnel config:

Copy
# Edit Cloudflare config
nano /root/.cloudflared/config.yml

# Add new ingress rule
ingress:
  - hostname: myapp.droidvm.dev
    service: http://localhost:8100
  # ... rest of config

# Restart cloudflared
tmux attach -t cloudflared
# Ctrl+C, then:
cloudflared tunnel run shravan-tunnel
Need More Ideas?
• RSS Reader Backend - Aggregate feeds and serve via API
• URL Shortener - Create short links with your domain
• Chat Bot - Telegram/Discord bot running 24/7
• Cron Jobs - Scheduled tasks with Python scripts
• Personal Dashboard - Aggregate all your services
• API Proxy - Rate limit or cache external APIs
DroidVM
Old phones deserve a second life

Links
Quick Start
Full Guide
API Docs
Examples
Connect
© 2025 Shravan | MIT License

This website is hosted on a phone
Edit with
×


DroidVM
Home
Quick Start
Guide
API
Examples
Live Stats
Blog
About
GitHub
Live Stats
Updated 01:19:52
System Information
Hostname

localhost

Platform

Linux

Architecture

aarch64

Python Version

3.12.12

Kernel

4.19.191+

CPU
Physical Cores

6

Total Cores

6

Memory
RAM Usage

3.63GB / 7.30GB

49.8%
Swap Usage

3.76GB / 8.00GB

47.0%
Processes
Total

23

sleeping: 22
running: 1
tmux Sessions
cloudflared

Created: 15/11/2025, 22:47:09

Detached
droidvm-tools

Created: 15/11/2025, 17:48:38

Detached
main

Created: 15/11/2025, 13:39:03

Detached
ngrok-8000

Created: 15/11/2025, 22:18:49

Detached
These stats come from:

Vivo V2158

Location: Drawer in Shravan's home

Serving this website right now

DroidVM
Old phones deserve a second life

Links
Quick Start
Full Guide
API Docs
Examples
Connect
© 2025 Shravan | MIT License

This website is hosted on a phone
Edit with
×


DroidVM
Home
Quick Start
Guide
API
Examples
Live Stats
Blog
About
GitHub
About DroidVM
The story of turning old phones into cloud servers

The Story
DroidVM started with a simple observation: I had an old Android phone sitting in a drawer, doing nothing. Meanwhile, I was paying for cloud VMs to run simple services and webhooks.

The phone had 7GB of RAM, 6 CPU cores, WiFi connectivity, and a built-in battery backup. It was basically a tiny ARM server waiting to be useful again.

After experimenting with Termux, SSH, tmux, Tailscale, and Cloudflare Tunnel, I realized something beautiful: this wasn't just a hack. It was legitimate infrastructure.

Now my old phone runs APIs, serves webhooks, monitors systems, and yes—it even hosts this documentation website you're reading right now.

E-Waste Problem
Millions of old phones end up in landfills every year, despite having perfectly functional hardware. DroidVM proves they can have a second life as useful infrastructure.

Phones Are Computers
Modern phones have more computing power than servers from just a decade ago. They're ARM Linux boxes with WiFi, storage, and battery—everything needed for a personal server.

DIY Infrastructure
Cloud services are great, but owning your infrastructure means no vendor lock-in, no monthly fees, and complete control. DroidVM democratizes server ownership.

Learning by Building
DroidVM is an educational project at heart. Building it teaches Linux, networking, tunneling, APIs, and systems programming—all from a phone you already own.

What Makes This Special
No Root Required
Everything runs in Termux userland. No bootloader unlocks, no custom ROMs, no warranty voiding.

Real HTTPS Domains
Cloudflare Tunnel provides legitimate SSL certificates and custom domains without port forwarding.

Production Ready
tmux sessions, monitoring APIs, proper logging—this isn't a toy. It's infrastructure you can rely on for personal projects.

Self-Hosted Documentation
This entire website runs on the same phone it documents. That's the kind of beautiful meta we love.

Credits & Thanks
Built by: Shravan, out of pure stubbornness and a refusal to let a phone become e-waste

Made possible by:

• Termux team - for the amazing Linux userland on Android
• Cloudflare - for free tunnels and HTTPS
• Tailscale - for making VPNs actually easy
• Open source community - for Python, FastAPI, Starlette, and everything else
The Inception

This entire website—every page, every API call, every live stat—is hosted on the phone it documents.

A website about turning a phone into a server, served from that same phone.

That's the exact kind of unnecessary but beautiful chaos we built this for.

Get Involved
DroidVM is open source and we'd love your contributions, feedback, and wild ideas.

GitHub Repository →
Report Issues or Suggest Features →
DroidVM
Old phones deserve a second life

Links
Quick Start
Full Guide
API Docs
Examples
Connect
© 2025 Shravan | MIT License

This website is hosted on a phone
Edit with
×