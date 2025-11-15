This is so good. You basically built a tiny, legit cloud node out of an old phone.

Let’s lock in the final version of the story with Cloudflare Tunnel, multi subdomains and all.

Below is a blog you can pretty much paste into your site and tweak.

---

# DroidVM: I Turned My Old Android Phone Into A Cloud VM With Its Own Subdomains

I started with a stupidly simple idea:

> Can I treat my old Android phone like a VM
> and run real web services on it that are reachable on the internet?

Fast forward a few hours and I have:

- A phone running Termux and Ubuntu (via proot-distro)
- tmux sessions keeping long running services alive
- A Starlette / FastAPI style API on `localhost:8000`
- Another app on `localhost:8090`
- A Cloudflare Tunnel that exposes both on real domains:

  - `https://api.droidvm.dev` → phone:8000
  - `https://app.droidvm.dev` → phone:8090

All of this is running on a device that was supposed to be retired.

---

## What DroidVM actually is

Here is the current setup in one picture.

- Android phone

  - Termux (base Linux environment)
  - proot-distro Ubuntu
  - tmux for persistence
  - Python app servers on ports 8000 and 8090
  - cloudflared tunnel running inside Ubuntu

Cloudflare then gives me nice HTTPS URLs, with proper DNS, without opening any router ports.

Something like this:

```text
          Internet
              |
     HTTPS to Cloudflare
              |
      Cloudflare Tunnel
              |
      cloudflared (Ubuntu in Termux)
              |
   --------------- on the phone ---------------
   |          |                               |
localhost:8000 → DroidVM Tools API (tmux: droidvm-tools)
localhost:8090 → Example app (tmux: main)
cloudflared   → Tunnel process (tmux: cloudflared)
```

So yes, there is a full mini homelab living inside an Android app.

---

## 1. Base environment: Termux + Ubuntu + tmux

### Termux on Android

Step zero is Termux. It gives you:

- a Linux like userland
- a shell
- a package manager

Install Termux from F Droid or a trusted APK. Open it and you will land at a prompt like:

```bash
~ $
```

[TODO: screenshot of Termux home screen with the shell prompt]

Update packages and install basics:

```bash
pkg update
pkg upgrade
pkg install python git tmux proot-distro
```

### Ubuntu inside Termux

I did not want to fight every random binary that expects a normal Linux. So I installed an Ubuntu rootfs inside Termux with proot-distro.

In Termux:

```bash
proot-distro install ubuntu
proot-distro login ubuntu
```

You should now see something like:

```bash
root@localhost:~#
```

Inside this Ubuntu:

```bash
apt update
apt install -y curl
curl https://api.ipify.org
```

If that prints your public IP, networking is working inside Ubuntu. Good.

### tmux sessions

tmux is the thing that keeps all of this from falling apart the moment a terminal window closes.

My tmux world looks like this:

```text
tmux sessions:

cloudflared     → running Cloudflare Tunnel
droidvm-tools   → running API on localhost:8000
main            → running example app on localhost:8090
```

Basic tmux usage:

```bash
tmux new -s main        # new session
tmux attach -t main     # attach
Ctrl+b then d           # detach
tmux ls                 # list sessions
```

We will use different sessions for each long running process.

[TODO: screenshot of `tmux ls` showing cloudflared, droidvm-tools, main]

---

## 2. Running services on the phone

The phone runs actual HTTP services on local ports.

You can use FastAPI, Starlette, Flask, plain Python HTTP server, anything. I used a Starlette style API for tools on port 8000 and another app on port 8090.

### DroidVM Tools API on port 8000

In Termux (Ubuntu not needed for this part):

```bash
tmux new -s droidvm-tools
```

Inside that session:

```bash
cd ~/droidvm-home  # or wherever your code lives
uvicorn main:app --host 0.0.0.0 --port 8000
```

You can sanity check it from Termux or Ubuntu:

```bash
curl http://localhost:8000
```

Example response:

```json
{
  "name": "DroidVM Tools API",
  "version": "0.1.0",
  "status": "running"
}
```

[TODO: screenshot of curl output for `http://localhost:8000`]

### Example app on port 8090

Same idea for a second app:

```bash
tmux new -s main
```

Inside that:

```bash
cd ~/droidvm-demo
uvicorn main:app --host 0.0.0.0 --port 8090
```

Check:

```bash
curl http://localhost:8090
```

If you get a meaningful response, your phone is now serving two HTTP services locally:

- `localhost:8000`
- `localhost:8090`

Now the fun part is making them globally reachable, without ever touching router port forwarding.

---

## 3. Cloudflare Tunnel: public domains for phone services

At this point I ditched ngrok and went all in on Cloudflare Tunnel.

Why:

- It lives happily inside Ubuntu in Termux
- It handles HTTPS for me
- It supports multiple hostnames and services with a single tunnel

You need:

- A domain managed by Cloudflare.
  I will use `droidvm.dev` in this example.
- Cloudflare account
- cloudflared binary running in Ubuntu on the phone

### Step 1: Install cloudflared inside Ubuntu

In the Ubuntu shell (inside Termux):

```bash
cd /root

wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared
chmod +x cloudflared
mv cloudflared /usr/local/bin/

cloudflared --version
```

You should see a version string.

### Step 2: Authenticate cloudflared with your Cloudflare account

Still in Ubuntu:

```bash
cloudflared tunnel login
```

This prints a URL.

- Open that URL in a browser
- Log into Cloudflare
- Select your account

This drops a `cert.pem` into:

```text
/root/.cloudflared/cert.pem
```

That file authorizes cloudflared to create tunnels and DNS entries.

[TODO: screenshot of Cloudflare Tunnel auth page in the browser]

### Step 3: Create a named tunnel

Pick a tunnel name, for example:

```bash
cloudflared tunnel create shravan-tunnel
```

This creates:

- A tunnel ID, something like `fab47e5c-2ab4-41db-a985-082630e66969`
- A credentials JSON at:

```text
/root/.cloudflared/fab47e5c-2ab4-41db-a985-082630e66969.json
```

You can list tunnels with:

```bash
cloudflared tunnel list
```

### Step 4: Configure ingress rules for multiple subdomains

Create or edit the Cloudflare Tunnel config at:

```bash
nano /root/.cloudflared/config.yml
```

Put this in:

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

This means:

- Requests to `https://api.droidvm.dev` are proxied to `http://localhost:8000` on the phone
- Requests to `https://app.droidvm.dev` are proxied to `http://localhost:8090`
- Everything else returns 404

[TODO: screenshot of the config.yml content]

### Step 5: Create DNS records from the phone

Because you have the cert, cloudflared can also create the DNS records for you.

In Ubuntu:

```bash
cloudflared tunnel route dns shravan-tunnel api.droidvm.dev
cloudflared tunnel route dns shravan-tunnel app.droidvm.dev
```

This creates CNAME records in Cloudflare that point those hostnames to the tunnel.

You can confirm in the Cloudflare dashboard under DNS. You should see `api.droidvm.dev` and `app.droidvm.dev` entries.

[TODO: screenshot of Cloudflare DNS panel showing api.droidvm.dev and app.droidvm.dev]

### Step 6: Run the tunnel in tmux on the phone

Now we wire it all together.

Back in Termux, start a tmux session for cloudflared:

```bash
tmux new -s cloudflared
```

Inside that session, drop into Ubuntu and run the tunnel:

```bash
proot-distro login ubuntu
cloudflared tunnel run shravan-tunnel
```

You will see logs like:

```text
INF Starting tunnel tunnelID=...
INF Connection established
INF Route propagating hostname=api.droidvm.dev
INF Route propagating hostname=app.droidvm.dev
```

Detach tmux:

- `Ctrl + b`, then `d`

Now your tmux world looks like:

```text
tmux ls

cloudflared     → cloudflared tunnel run shravan-tunnel
droidvm-tools   → uvicorn main:app --port 8000
main            → uvicorn main:app --port 8090
```

As long as:

- The phone is on
- Termux is alive
- Those tmux sessions are running

you have a live tunnel from the internet to your phone.

---

## 4. Final result: real domains hitting your phone

Here is what the final mapping looks like.

| Subdomain                 | Target on the phone     | Description       |
| ------------------------- | ----------------------- | ----------------- |
| `https://api.droidvm.dev` | `http://localhost:8000` | DroidVM Tools API |
| `https://app.droidvm.dev` | `http://localhost:8090` | Example app or UI |

Clients on the internet hit `https://api.droidvm.dev/status` and get JSON like:

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
      { "name": "cloudflared", "attached": true }
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

Everything above is coming from a phone that used to just sit on a shelf.

[TODO: screenshot of hitting [https://api.droidvm.dev/status](https://api.droidvm.dev/status) from a random device]

---

## 5. Gotchas and reality checks

A few things to keep in mind if you try this:

1. **Android will kill things if you let it**

   - Put Termux on unrestricted battery mode
   - Disable aggressive background killing in OEM settings

2. **Do not expose anything sensitive without auth**
   Cloudflare makes it easy to publish, which also makes it easy to publish something you did not mean to. Lock down anything that is not demo level.

3. **Phone is not a datacenter**
   It is fun to see it handle APIs, but it will not replace a real server under load.

4. **Termux and proot environments can break between Android or Termux upgrades**
   Keep this as a fun project or a personal tool, not your only prod.

---

## 6. Why this is fun

In the end, I got:

- A personal VM that lives in my pocket
- SSH + tmux access from anywhere
- A tools API that can orchestrate stuff at home
- Clean `https://api.droidvm.dev` and `https://app.droidvm.dev` endpoints, backed by a phone

The best part for me is not the tech, it is the feeling that this random device is now part of my toolbox again instead of e waste.

If you end up building your own DroidVM, add some weird endpoint on it and show people that it is powered by a phone. That is the exact kind of unnecessary but beautiful chaos the internet needs more of.
