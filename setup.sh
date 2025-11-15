#!/data/data/com.termux/files/usr/bin/bash
#
# DroidVM Setup Script
# Turn your old Android phone into a cloud server
#
# Usage: curl -sSL https://droidvm.dev/setup | bash
#        or: ./setup.sh [--level basic|private|public|full]
#
# https://github.com/myselfshravan/droidvm-setup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Symbols
CHECK="✓"
CROSS="✗"
ARROW="→"
STAR="★"

# Version
VERSION="1.0.0"

# Globals
INSTALL_DIR="$HOME/droidvm-setup"
LOG_FILE="$INSTALL_DIR/setup.log"

# ==============================================================================
# Helper Functions
# ==============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║                                                   ║"
    echo "║              ${WHITE}DroidVM Setup v${VERSION}${CYAN}               ║"
    echo "║     Turn your phone into a cloud server          ║"
    echo "║                                                   ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    local step=$1
    local total=$2
    local message=$3
    echo -e "\n${BLUE}[${step}/${total}]${NC} ${WHITE}${message}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

print_success() {
    echo -e "${GREEN}${CHECK}${NC} $1"
}

print_error() {
    echo -e "${RED}${CROSS}${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC}  $1"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

check_termux() {
    if [[ ! -d "/data/data/com.termux" ]]; then
        print_error "This script must be run in Termux"
        exit 1
    fi
}

check_network() {
    if ! ping -c 1 google.com &> /dev/null; then
        print_error "No network connection"
        exit 1
    fi
}

check_storage() {
    local available=$(df -h $HOME | awk 'NR==2 {print $4}' | sed 's/G//')
    if (( $(echo "$available < 1" | bc -l) )); then
        print_warning "Low storage space: ${available}GB available"
    fi
    echo "$available"
}

# ==============================================================================
# Setup Functions
# ==============================================================================

preflight_checks() {
    echo -e "\n${WHITE}Running pre-flight checks...${NC}\n"

    # Check Termux
    if [[ -d "/data/data/com.termux" ]]; then
        print_success "Running in Termux"
    else
        print_error "Not running in Termux"
        exit 1
    fi

    # Check network
    if ping -c 1 google.com &> /dev/null; then
        print_success "Network connectivity"
    else
        print_error "No network connection"
        exit 1
    fi

    # Check storage
    local storage=$(check_storage)
    print_success "Storage available: ${storage}GB"

    # Check Android version
    local android_version=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    print_info "Android version: $android_version"

    echo ""
    print_warning "Important: Disable battery optimization for Termux!"
    print_info "Go to: Settings → Apps → Termux → Battery → Unrestricted"
    echo ""
    read -p "Press ENTER to continue (or Ctrl+C to exit)..."
}

setup_base_packages() {
    print_step 1 8 "Installing base packages"

    log "Starting base package installation"

    echo -e "${CYAN}Updating package lists...${NC}"
    pkg update -y >> "$LOG_FILE" 2>&1
    print_success "Package lists updated"

    echo -e "${CYAN}Upgrading existing packages...${NC}"
    pkg upgrade -y >> "$LOG_FILE" 2>&1
    print_success "Packages upgraded"

    echo -e "${CYAN}Installing core packages...${NC}"
    pkg install -y \
        openssh \
        tmux \
        git \
        wget \
        curl \
        python \
        proot-distro \
        >> "$LOG_FILE" 2>&1

    print_success "Core packages installed"
    log "Base packages installed successfully"
}

setup_ssh() {
    print_step 2 8 "Configuring SSH server"

    log "Setting up SSH"

    # Set password
    echo -e "\n${YELLOW}Set a password for SSH access:${NC}"
    passwd

    # Start SSH
    sshd

    # Get IP
    local ip=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

    print_success "SSH server started on port 8022"
    print_info "Connect with: ssh -p 8022 $(whoami)@${ip:-YOUR_IP}"

    # Add to bashrc for auto-start
    if ! grep -q "sshd" ~/.bashrc 2>/dev/null; then
        echo "# Auto-start SSH server" >> ~/.bashrc
        echo "sshd 2>/dev/null" >> ~/.bashrc
        print_success "SSH auto-start configured"
    fi

    log "SSH setup completed"
}

setup_tmux() {
    print_step 3 8 "Setting up tmux"

    log "Configuring tmux"

    # Create tmux config
    cat > ~/.tmux.conf << 'EOF'
# DroidVM tmux configuration

# Better prefix
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Start windows at 1
set -g base-index 1
setw -g pane-base-index 1

# Easy reload
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Split panes
bind | split-window -h
bind - split-window -v

# Status bar
set -g status-style bg=black,fg=white
set -g status-left "#[fg=green]#S "
set -g status-right "#[fg=cyan]%H:%M"

# Activity
setw -g monitor-activity on
set -g visual-activity on

# History
set -g history-limit 10000
EOF

    print_success "tmux configuration installed"

    # Add helpful aliases
    cat >> ~/.bashrc << 'EOF'

# DroidVM aliases
alias ta='tmux attach -t'
alias tl='tmux ls'
alias tn='tmux new -s'
EOF

    print_success "tmux aliases added"
    log "tmux setup completed"
}

setup_python() {
    print_step 4 8 "Configuring Python environment"

    log "Setting up Python"

    # Upgrade pip
    pip install --upgrade pip >> "$LOG_FILE" 2>&1
    print_success "pip upgraded"

    # Install uv (fast package manager)
    pip install uv >> "$LOG_FILE" 2>&1
    print_success "uv package manager installed"

    print_info "Python $(python --version | cut -d' ' -f2) ready"
    log "Python setup completed"
}

setup_tailscale_guide() {
    print_step 5 8 "Tailscale setup guide"

    echo -e "\n${WHITE}Tailscale gives you private VPN access from anywhere.${NC}\n"

    echo "Steps:"
    echo "  1. Install Tailscale app from Play Store"
    echo "  2. Open the app and sign in"
    echo "  3. Tap Connect"
    echo "  4. Note your Tailscale IP (100.x.x.x)"
    echo ""
    echo "Once connected, you can SSH from anywhere:"
    echo "  ssh -p 8022 $(whoami)@YOUR_TAILSCALE_IP"
    echo ""

    read -p "Press ENTER when done, or 's' to skip: " choice
    if [[ "$choice" == "s" ]]; then
        print_warning "Skipped Tailscale setup"
    else
        print_success "Tailscale guide completed"
    fi
}

setup_proot_ubuntu() {
    print_step 6 8 "Setting up Ubuntu environment"

    log "Installing proot Ubuntu"

    echo -e "${CYAN}Installing Ubuntu via proot-distro...${NC}"
    echo "This may take several minutes..."

    proot-distro install ubuntu >> "$LOG_FILE" 2>&1
    print_success "Ubuntu rootfs installed"

    # Pre-configure Ubuntu
    echo -e "${CYAN}Pre-configuring Ubuntu...${NC}"

    proot-distro login ubuntu -- bash -c "
        apt update
        apt install -y curl wget
    " >> "$LOG_FILE" 2>&1

    print_success "Ubuntu pre-configured with curl and wget"
    log "proot Ubuntu setup completed"
}

setup_cloudflared() {
    print_step 7 8 "Cloudflare Tunnel setup"

    echo -e "\n${WHITE}Cloudflare Tunnel gives you public HTTPS URLs.${NC}\n"

    read -p "Do you have a domain on Cloudflare? [y/n]: " has_domain

    if [[ "$has_domain" != "y" ]]; then
        print_warning "Skipping Cloudflare Tunnel setup"
        print_info "You can set this up later manually"
        return
    fi

    log "Starting Cloudflare Tunnel setup"

    # Install cloudflared in Ubuntu
    echo -e "${CYAN}Installing cloudflared in Ubuntu...${NC}"

    proot-distro login ubuntu -- bash -c "
        cd /root
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared
        chmod +x cloudflared
        mv cloudflared /usr/local/bin/
        cloudflared --version
    " 2>&1 | tee -a "$LOG_FILE"

    print_success "cloudflared installed"

    # Authenticate
    echo -e "\n${YELLOW}Authentication required:${NC}"
    echo "A URL will be printed. Open it in your browser and authorize."
    echo ""

    proot-distro login ubuntu -- cloudflared tunnel login

    print_success "Authenticated with Cloudflare"

    # Create tunnel
    read -p "Enter a name for your tunnel (e.g., droidvm-tunnel): " tunnel_name

    proot-distro login ubuntu -- cloudflared tunnel create "$tunnel_name" 2>&1 | tee -a "$LOG_FILE"

    print_success "Tunnel '$tunnel_name' created"

    # Get tunnel ID
    local tunnel_id=$(proot-distro login ubuntu -- cloudflared tunnel list | grep "$tunnel_name" | awk '{print $1}')

    # Configure ingress
    read -p "Enter subdomain for API (e.g., api): " subdomain
    read -p "Enter your domain (e.g., example.com): " domain

    proot-distro login ubuntu -- bash -c "
        cat > /root/.cloudflared/config.yml << EOFCFG
tunnel: $tunnel_id
credentials-file: /root/.cloudflared/${tunnel_id}.json

ingress:
  - hostname: ${subdomain}.${domain}
    service: http://localhost:8000
  - service: http_status:404
EOFCFG
    "

    print_success "Tunnel configuration created"

    # Create DNS route
    proot-distro login ubuntu -- cloudflared tunnel route dns "$tunnel_name" "${subdomain}.${domain}" 2>&1 | tee -a "$LOG_FILE"

    print_success "DNS route created for ${subdomain}.${domain}"

    # Start tunnel in tmux
    echo -e "${CYAN}Starting tunnel in background...${NC}"

    tmux new-session -d -s cloudflared "proot-distro login ubuntu -- cloudflared tunnel run $tunnel_name"

    print_success "Tunnel running in tmux session 'cloudflared'"
    print_info "Your API will be at: https://${subdomain}.${domain}"

    log "Cloudflare Tunnel setup completed"
}

setup_droidvm_tools() {
    print_step 8 8 "Installing DroidVM Tools API"

    log "Installing DroidVM Tools"

    echo -e "${CYAN}Cloning droidvm-tools...${NC}"
    git clone https://github.com/myselfshravan/droidvm-tools.git ~/droidvm-tools >> "$LOG_FILE" 2>&1
    print_success "Repository cloned"

    cd ~/droidvm-tools

    echo -e "${CYAN}Installing dependencies (this may take a while)...${NC}"
    uv sync >> "$LOG_FILE" 2>&1
    print_success "Dependencies installed"

    # Start in tmux
    tmux new-session -d -s droidvm-tools "cd ~/droidvm-tools && uv run start-server"
    print_success "API server started in tmux session 'droidvm-tools'"

    # Verify
    sleep 3
    if curl -s http://localhost:8000/health | grep -q "healthy"; then
        print_success "API is running and healthy"
    else
        print_warning "API might need a moment to start"
    fi

    log "DroidVM Tools setup completed"
}

finalize() {
    echo -e "\n${GREEN}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║                                                   ║"
    echo "║          🎉 DroidVM Setup Complete! 🎉           ║"
    echo "║                                                   ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"

    local ip=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

    echo -e "${WHITE}Your phone is now a cloud server!${NC}\n"

    echo "SSH Access:"
    echo "  ${ARROW} Local:     ssh -p 8022 $(whoami)@${ip:-YOUR_IP}"
    echo "  ${ARROW} Tailscale: ssh -p 8022 $(whoami)@YOUR_TAILSCALE_IP"
    echo ""

    echo "API Access:"
    echo "  ${ARROW} Local:  http://localhost:8000"
    echo "  ${ARROW} Public: https://YOUR_DOMAIN (if configured)"
    echo ""

    echo "tmux sessions:"
    tmux ls 2>/dev/null || echo "  (none running)"
    echo ""

    echo "Next steps:"
    echo "  1. Test API: curl http://localhost:8000/status"
    echo "  2. See logs: tmux attach -t droidvm-tools"
    echo "  3. Read docs: less ~/droidvm-setup/docs/README.md"
    echo ""

    echo -e "${CYAN}Need help? https://github.com/myselfshravan/droidvm-setup/issues${NC}"
    echo ""
    echo -e "${GREEN}Happy hacking! ${STAR}${NC}"

    log "Setup completed successfully"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    print_banner

    # Create install directory
    mkdir -p "$INSTALL_DIR"
    touch "$LOG_FILE"

    log "DroidVM Setup started - Version $VERSION"

    preflight_checks
    setup_base_packages
    setup_ssh
    setup_tmux
    setup_python
    setup_tailscale_guide
    setup_proot_ubuntu
    setup_cloudflared
    setup_droidvm_tools
    finalize
}

# Run main
main "$@"
