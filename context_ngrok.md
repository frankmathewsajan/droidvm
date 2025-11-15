Alright, this is sick. You basically turned a dusty Android into a tiny Linux box on the internet.

Let’s turn this whole stunt into a blog.

Below is something you can almost copy paste into your blog engine. I’ll put placeholders where screenshots or clips would be perfect.

---

# DroidVM: How I Turned My Old Android Phone Into A Public Web Server

I had an old Android phone lying around, doing the classic ex-flagship retirement plan: sitting in a drawer at 4 percent battery.

One random day I asked myself:

> “Can I use this like a VM?
> SSH in, run tmux, host APIs, maybe even expose it to the internet?”

Short answer: yes.

I ended up building what I now call **DroidVM**. It is:

- An old Android phone
- Running Termux as a Linux userland
- With SSH, tmux, Python and Starlette
- Reachable from anywhere using Tailscale
- And finally exposed to the public via ngrok, running inside a tiny Ubuntu userland on the phone

Hit this URL and you get live system stats from a literal phone:

```json
{
  "success": true,
  "data": {
    "timestamp": "2025-11-15T22:23:55.120782",
    "system": {
      "hostname": "localhost",
      "platform": "Linux",
      "platform_release": "4.19.191+",
      "platform_version": "#1 SMP PREEMPT Wed May 21 15:22:49 CST 2025",
      "architecture": "aarch64",
      "python_version": "3.12.12"
    },
    "memory": {
      "total": "7.30GB",
      "available": "3.71GB",
      "used": "3.58GB",
      "percentage": 49.1
    },
    "tmux_sessions": [
      { "name": "droidvm-tools", "attached": false },
      { "name": "main", "attached": false },
      { "name": "ngrok-8000", "attached": false },
      { "name": "ngrok-8090", "attached": true }
    ],
    "processes": {
      "total": 23,
      "by_status": {
        "sleeping": 22,
        "running": 1
      }
    }
  }
}
```

All this, running on a Vivo phone that was supposed to be dead.

This post is the full story, but in a way that you can follow step by step and do it yourself.

---

## What we are going to build

From a dev’s point of view, this is what DroidVM gives you:

- SSH access into the phone:

  - `ssh -p 8022 u0_aXXX@PHONE_IP`

- tmux sessions with long running stuff:

  - app servers, cron-like scripts, whatever

- Python 3.12 userland via Termux
- A Starlette app serving JSON on port 8090
- Tailscale for private, anywhere access
- ngrok (inside a proot Ubuntu) giving you a public HTTPS URL

Rough mental picture:

```text
[ Your Laptop ]  <-- SSH / HTTP -->  [ DroidVM (Android + Termux) ]
                                           |
                                           | proot-distro
                                           v
                                  [ Ubuntu userland ]
                                           |
                                           v
                                      [ ngrok ]
                                           |
                                           v
                               https://something.ngrok-free.dev
```

You don’t need root on the phone.
You don’t need to unlock bootloaders.
You just need patience, Termux, and a bit of stubbornness.

---

## Prerequisites

- An Android phone

  - Ideally with at least 3–4 GB RAM
  - Must support installing Termux (Android 7+ is fine)

- A charger, because this thing stays plugged in
- A laptop to control it (I used a Mac, any OS is fine)
- Decent Wi-Fi
- A free ngrok account
- A free Tailscale account (for the private phase)

Optional but recommended:

- Basic Linux/terminal comfort
- A mild tolerance for chaos

---

## Step 1: Turn the phone into DroidVM

### 1.1 Install Termux

- Install Termux from F-Droid (recommended) or a trusted APK mirror
- Open Termux, you’ll land in a shell like:

```text
~ $
```

[placeholder: screenshot of Termux home screen with the shell prompt]

### 1.2 Fix Android battery murder settings

On the phone:

- Settings → Apps → Termux:

  - Battery: set to **Unrestricted** or “Don’t optimize”

- If your OEM has “background app clean up” or “deep sleep”:

  - Add Termux to the allowed / whitelisted list

Otherwise Android will randomly kill your “server” at 3 am.

### 1.3 Install basic packages

In Termux:

```bash
pkg update
pkg upgrade
pkg install openssh tmux python git
```

### 1.4 Set a password and start SSH

Still in Termux:

```bash
passwd
```

Set a password you will use to SSH in.

Then start the SSH server:

```bash
sshd
```

By default, Termux’s SSH listens on port `8022`.

### 1.5 Find the phone’s IP

In Termux:

```bash
ip addr show wlan0
```

Look for something like `192.168.1.45`. That is your phone’s LAN IP.

From your laptop:

```bash
ssh -p 8022 u0_aXXX@192.168.1.45
```

Use the password you just set.

If you see:

```bash
~ $ whoami
u0_aXXX
```

you are officially inside DroidVM.

[placeholder: screenshot of SSH session from laptop into the phone]

### 1.6 Use tmux on the phone

In the SSH session:

```bash
tmux new -s main
```

You’ll get a tmux status bar at the bottom.
You can now run commands inside tmux, detach, reattach later, and survive disconnects.

Detaching:

- `Ctrl + b`, then `d`

Reattaching:

```bash
tmux attach -t main
```

---

## Step 2: Use DroidVM as your personal remote dev box (Tailscale)

Before we go public, we want it to behave like a small private VM that you can reach from anywhere.

### 2.1 Install Tailscale on the phone (Android app)

On the phone:

- Install Tailscale from Play Store
- Log in with your account
- Tap Connect

Tailscale gives the phone a private IP like `100.94.102.37`.

[placeholder: screenshot of Tailscale app showing the 100.x.x.x IP]

### 2.2 Install Tailscale on your laptop

On your laptop:

- Install the Tailscale client
- Log in with the same account
- Connect

Now your laptop and phone are in the same private mesh network.

Test from laptop:

```bash
ping 100.94.102.37
ssh -p 8022 u0_aXXX@100.94.102.37
```

If that works, you can now reach DroidVM over the internet, as long as:

- Phone has internet
- Both devices have Tailscale on

---

## Step 3: Run a Starlette API on DroidVM

FastAPI gave me some drama under Python 3.12 + Termux because of pydantic-core and Rust builds.

So I went with **Starlette + Uvicorn**. It is super lightweight and perfect for this.

### 3.1 Create a project folder

SSH into DroidVM:

```bash
mkdir -p ~/droidvm-demo
cd ~/droidvm-demo
```

### 3.2 Install Starlette and Uvicorn

```bash
pip install "starlette==0.27.0" "uvicorn==0.23.2"
```

### 3.3 Create `main.py`

```bash
cat > main.py
```

Paste:

```python
from starlette.applications import Starlette
from starlette.responses import JSONResponse
from starlette.routing import Route
import socket
import platform
import psutil
from datetime import datetime

async def home(request):
    return JSONResponse({
        "message": "Hello from DroidVM 👋",
        "note": "Yes, this is running on an old Android phone via Termux."
    })

async def status(request):
    mem = psutil.virtual_memory()
    procs = list(psutil.process_iter())
    return JSONResponse({
        "success": True,
        "data": {
            "timestamp": datetime.utcnow().isoformat(),
            "system": {
                "hostname": socket.gethostname(),
                "platform": platform.system(),
                "platform_release": platform.release(),
                "platform_version": platform.version(),
                "architecture": platform.machine(),
                "python_version": platform.python_version(),
            },
            "memory": {
                "total": f"{mem.total/1024**3:.2f}GB",
                "available": f"{mem.available/1024**3:.2f}GB",
                "used": f"{mem.used/1024**3:.2f}GB",
                "percentage": mem.percent,
            },
            "processes": {
                "total": len(procs),
                "by_status": {
                    "sleeping": sum(p.status() == psutil.STATUS_SLEEPING for p in procs),
                    "running": sum(p.status() == psutil.STATUS_RUNNING for p in procs),
                }
            }
        }
    })

routes = [
    Route("/", home),
    Route("/status", status),
]

app = Starlette(debug=True, routes=routes)
```

Install psutil:

```bash
pip install psutil
```

### 3.4 Run it in tmux

Attach or create a tmux session:

```bash
tmux new -s main  # or tmux attach -t main if it already exists
```

Inside tmux:

```bash
cd ~/droidvm-demo
uvicorn main:app --host 0.0.0.0 --port 8090 --reload
```

You should see:

```text
Uvicorn running on http://0.0.0.0:8090
```

Now on your laptop (with Tailscale connected):

```bash
curl http://100.94.102.37:8090/status
```

You should see JSON like the one at the top of this post.

Boom. You now have a remote “VM” that lives in your drawer and answers API calls.

[placeholder: screenshot of `/status` JSON in the browser]

---

## Step 4: Take it public with ngrok inside Ubuntu-on-Termux

So far, only devices in your Tailscale network can reach DroidVM.

Now let’s get to the “this dude is crazy” part: a public HTTPS URL, straight into a phone, with no PC in the middle.

We will:

- Run **Ubuntu** inside Termux using `proot-distro`
- Run **ngrok** inside Ubuntu
- Point ngrok to `localhost:8090` (which is your Starlette app in Termux)

### 4.1 Install proot-distro and Ubuntu

In Termux:

```bash
pkg install proot-distro
proot-distro install ubuntu
```

Log in:

```bash
proot-distro login ubuntu
```

Prompt should look like:

```bash
root@localhost:~#
```

### 4.2 Make sure networking works inside Ubuntu

Inside Ubuntu:

```bash
apt update
apt install -y curl
curl https://api.ipify.org
```

You should see your public IP. That means DNS and outbound traffic are good.

### 4.3 Install ngrok via apt

Still inside Ubuntu:

```bash
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null

echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" \
  | tee /etc/apt/sources.list.d/ngrok.list >/dev/null

apt update
apt install -y ngrok
```

Check:

```bash
ngrok version
```

You should see something like `ngrok version 3.33.0`.

Add your auth token from the ngrok dashboard:

```bash
ngrok config add-authtoken YOUR_NGROK_TOKEN_HERE
```

### 4.4 Make sure the app is reachable on 8090 from Ubuntu

In a separate Termux session (or tmux window), ensure your app is running:

```bash
cd ~/droidvm-demo
tmux attach -t main  # or tmux new -s main
uvicorn main:app --host 0.0.0.0 --port 8090 --reload
```

Now back in Ubuntu:

```bash
curl http://127.0.0.1:8090/status
```

If you get your JSON, ngrok can see the app.

### 4.5 Start ngrok tunnel

Inside Ubuntu:

```bash
ngrok http 8090
```

You’ll see something like:

```text
Session Status  online
Forwarding      https://uncostly-shalanda-macropterous.ngrok-free.dev -> http://localhost:8090
```

Grab that URL, open it on any device in any network, and hit:

```text
https://uncostly-shalanda-macropterous.ngrok-free.dev/status
```

That’s a public internet request, going into your old phone, crossing Termux, hitting Starlette, and returning that JSON.

[placeholder: screenshot of ngrok terminal UI showing the Forwarding URL]
[placeholder: screenshot of `/status` on a normal 4G phone browser]

---

## Step 5: Make ngrok and Ubuntu survive your terminal

You probably don’t want to keep a Termux window open on the phone forever.

Use tmux at the Termux level to keep Ubuntu + ngrok running.

In Termux:

```bash
tmux new -s ngrok-tunnels
```

Inside tmux:

```bash
proot-distro login ubuntu
ngrok http 8090
```

Then detach:

- `Ctrl + b`, then `d`

Now:

- tmux keeps Ubuntu + ngrok alive
- Ubuntu keeps ngrok running
- ngrok keeps your tunnel alive

As long as:

- Phone stays powered
- Termux is not killed by Android
- Network is up

You can always reattach:

```bash
tmux attach -t ngrok-tunnels
```

---

## What you can do with DroidVM now

You basically have a tiny, slightly cursed, always-on ARM server.

Ideas:

- Personal status API:

  - `/status` showing system info, tmux sessions, processes

- Tiny feature flags:

  - DroidVM serving a JSON flag that your other apps read

- Webhooks:

  - Point GitHub webhooks to your ngrok URL, let DroidVM run scripts

- Remote job runner:

  - Trigger long running stuff through an endpoint, monitor via logs

- Monitoring / logging sink:

  - Send logs from your other machines into DroidVM for fun

And when you do not need ngrok, you can keep it private on Tailscale, which is honestly the best part as a dev.

---

## Caveats and reality checks

Let’s be honest for a second:

- This is not a production server.
- You are running everything in user space, inside an app, on a phone.
- If Android decides to kill Termux, everything dies.
- If ngrok free tier is overloaded or your tunnel sleeps, your URL dies.
- If you expose sensitive stuff without auth, that is on you.

But as a hack, as a “I turned my phone into a VM and put an API on the internet” story, this is ridiculous in the best way.

---

## Wrap up

This all started with a simple question:

> “How do I make my old Android phone act like a VM?”

The final setup:

- **DroidVM**:

  - Android 14 phone
  - Termux userland
  - SSH + tmux + Python 3.12
  - Starlette app at `0.0.0.0:8090`

- **Private access**:

  - Tailscale, so my laptop can hit `http://100.94.102.37:8090` from anywhere

- **Public access**:

  - Ubuntu inside Termux via `proot-distro`
  - ngrok inside Ubuntu tunneling `8090` to
    `https://something.ngrok-free.dev`

Anyone with an old phone, an internet connection, and some patience can build this.

If you do, please send me a screenshot of your `/status` endpoint. I want to see more cursed little servers living in drawers all over the world.
