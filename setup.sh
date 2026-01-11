#!/data/data/com.termux/files/usr/bin/bash
#
# DroidVM Setup Script
# Turn your old Android phone into a cloud server
# https://github.com/myselfshravan/droidvm

set -e
trap 'echo -e "\n${RED}⚠ Setup interrupted.${NC}"; exit 1' INT

# ==============================================================================
# Configuration
# ==============================================================================

VERSION="1.1.0"
INSTALL_DIR="$HOME/droidvm"
LOG_FILE="$INSTALL_DIR/setup.log"
REPO_URL="https://github.com/myselfshravan/droidvm.git"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Symbols
CHECK="✓"
CROSS="✗"
ARROW="→"

# Flags
SKIP_CLOUDFLARE=false

# ==============================================================================
# UI Functions
# ==============================================================================

print_banner() {
    clear
    cat <<EOF
${CYAN}
╔═══════════════════════════════════════════════════╗
║                                                   ║
║             ${WHITE}DroidVM Setup v${VERSION}${CYAN}               ║
║      Turn your phone into a cloud server          ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
${NC}
EOF
}

print_step() {
    echo -e "\n${BLUE}[$1/$2]${NC} ${WHITE}$3${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

print_success() { echo -e "${GREEN}${CHECK}${NC} $1"; }
print_error()   { echo -e "${RED}${CROSS}${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC}  $1"; }
print_info()    { echo -e "${CYAN}ℹ${NC}  $1"; }

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# ==============================================================================
# Checks & Prerequisites
# ==============================================================================

check_environment() {
    # 1. Check Termux
    if [[ ! -d "/data/data/com.termux" ]]; then
        print_error "This script must be run in Termux."
        exit 1
    fi

    # 2. Check Network
    if ! ping -c 1 google.com &> /dev/null; then
        print_error "No internet connection detected."
        exit 1
    fi

    # 3. Check Storage
    local available
    available=$(df -h "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    # Simple integer comparison to avoid bc dependency early on
    if [[ "${available%.*}" -lt 1 ]]; then
        print_warning "Low storage space: ${available}GB available."
    else
        print_success "Storage available: ${available}GB"
    fi
}

preflight_checks() {
    echo -e "\n${WHITE}Running pre-flight checks...${NC}\n"
    check_environment
    
    # Check Android Version
    local android_ver
    android_ver=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    print_info "Android version: $android_ver"

    # Battery Warning
    echo ""
    print_warning "Ensure battery optimization is DISABLED for Termux."
    echo "  (Settings → Apps → Termux → Battery → Unrestricted)"
    echo ""
    read -r -p "Press ENTER to continue..."
}

# ==============================================================================
# Core Setup
# ==============================================================================

setup_base_packages() {
    print_step 1 7 "Installing base packages"
    log "Starting base package installation"

    echo -e "${CYAN}Updating package lists and upgrading...${NC}"
    # Combine update/upgrade and suppress output unless error
    {
        pkg update -y 
        pkg upgrade -y -o Dpkg::Options::="--force-confnew"
    } >> "$LOG_FILE" 2>&1

    echo -e "${CYAN}Installing core dependencies...${NC}"
    local PACKAGES=(openssh tmux git wget curl python proot-distro tailscale)
    
    pkg install -y "${PACKAGES[@]}" >> "$LOG_FILE" 2>&1

    print_success "Core packages installed"
}

setup_ssh() {
    print_step 2 7 "Configuring SSH server"
    log "Setting up SSH"

    if ! pgrep sshd > /dev/null; then
        echo -e "${YELLOW}Setting SSH password (required)...${NC}"
        passwd
        sshd
        print_success "SSH server started"
    else
        print_info "SSH is already running"
    fi

    local ip
    ip=$(ifconfig wlan0 2>/dev/null | awk '/inet / {print $2}')
    print_info "Local IP: ${ip:-Unknown}"

    # Auto-start SSH logic
    if ! grep -q "sshd" ~/.bashrc; then
        echo -e "\n# Auto-start SSH\npgrep sshd >/dev/null || sshd" >> ~/.bashrc
        print_success "Added SSH auto-start to .bashrc"
    fi
}

setup_tmux() {
    print_step 3 7 "Setting up tmux"
    
    # Only write config if it doesn't exist
    if [[ ! -f ~/.tmux.conf ]]; then
        cat > ~/.tmux.conf << 'EOF'
# DroidVM Config
set -g prefix C-a
unbind C-b
bind C-a send-prefix
set -g base-index 1
setw -g pane-base-index 1
set -g status-style bg=black,fg=white
set -g history-limit 10000
EOF
        print_success "tmux configuration created"
    else
        print_info "Existing tmux config found, skipping overwrite"
    fi
}

setup_python() {
    print_step 4 7 "Configuring Python"
    
    # Install uv for speed, fallback to pip
    echo -e "${CYAN}Installing 'uv' package manager...${NC}"
    pip install uv >> "$LOG_FILE" 2>&1 || pip install --upgrade pip
    
    print_success "Python environment ready"
}

setup_ubuntu_proot() {
    print_step 5 7 "Setting up Ubuntu (Proot)"
    
    if proot-distro list | grep -q "ubuntu (installed)"; then
        print_info "Ubuntu is already installed"
    else
        echo -e "${CYAN}Downloading and installing Ubuntu rootfs...${NC}"
        proot-distro install ubuntu >> "$LOG_FILE" 2>&1
        print_success "Ubuntu installed"
    fi

    # Pre-configure inside Ubuntu
    log "Configuring Ubuntu internal packages"
    proot-distro login ubuntu -- bash -c "apt update -y && apt install -y curl wget" >> "$LOG_FILE" 2>&1
}

# ==============================================================================
# Networking Setup
# ==============================================================================

setup_tailscale() {
    print_step 6 7 "Tailscale VPN"
    
    echo -e "${WHITE}Tailscale allows remote access without port forwarding.${NC}"
    echo -e "1. We installed the Tailscale CLI."
    echo -e "2. You should also install the Android App for the VPN service slot."
    
    read -r -p "Do you want to run 'tailscale up' now? [y/N]: " ts_choice
    if [[ "$ts_choice" =~ ^[Yy]$ ]]; then
        sudo tailscale up 2>/dev/null || tailscale up
        print_success "Tailscale started"
    fi
}

setup_cloudflare() {
    print_step 7 7 "Cloudflare Tunnel"

    if [[ "$SKIP_CLOUDFLARE" == "true" ]]; then
        print_warning "Skipping Cloudflare setup by user request."
        return
    fi

    echo -e "${WHITE}This exposes your local server to the public web safely.${NC}"
    read -r -p "Do you have a Cloudflare domain? [y/N]: " cf_choice

    if [[ ! "$cf_choice" =~ ^[Yy]$ ]]; then
        print_info "Skipping Cloudflare setup."
        return
    fi

    # Install Cloudflared inside Ubuntu to keep Termux clean
    echo -e "${CYAN}Installing cloudflared inside Ubuntu container...${NC}"
    
    # Using a heredoc script passed to proot for cleaner execution
    cat << 'EOF' > "$INSTALL_DIR/cf_install.sh"
#!/bin/bash
if ! command -v cloudflared &> /dev/null; then
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -O /usr/local/bin/cloudflared
    chmod +x /usr/local/bin/cloudflared
fi
EOF
    
    # Copy script into proot path (simplification: just run command via login)
    proot-distro login ubuntu -- bash -c "$(cat "$INSTALL_DIR/cf_install.sh")" >> "$LOG_FILE" 2>&1
    rm "$INSTALL_DIR/cf_install.sh"
    
    print_success "cloudflared binary installed"

    echo -e "\n${YELLOW}=== Authentication ===${NC}"
    echo "Copy the URL below into your browser:"
    proot-distro login ubuntu -- cloudflared tunnel login
    
    # Interactive Tunnel Creation
    echo ""
    read -r -p "Enter a name for this tunnel (e.g., droidvm): " t_name
    proot-distro login ubuntu -- cloudflared tunnel create "$t_name" >> "$LOG_FILE" 2>&1
    
    read -r -p "Enter subdomain (e.g., api): " sub
    read -r -p "Enter domain (e.g., site.com): " dom
    
    # We need to extract the Tunnel ID securely
    local t_id
    t_id=$(proot-distro login ubuntu -- cloudflared tunnel list | grep "$t_name" | awk '{print $1}')

    if [[ -z "$t_id" ]]; then
        print_error "Failed to retrieve Tunnel ID. Check logs."
        return
    fi

    # Create Config inside Ubuntu
    proot-distro login ubuntu -- bash -c "cat > ~/.cloudflared/config.yml << CFG
tunnel: $t_id
credentials-file: /root/.cloudflared/${t_id}.json
ingress:
  - hostname: ${sub}.${dom}
    service: http://localhost:8000
  - service: http_status:404
CFG"

    # Route DNS
    proot-distro login ubuntu -- cloudflared tunnel route dns "$t_name" "${sub}.${dom}" >> "$LOG_FILE" 2>&1
    
    # Start in tmux
    tmux new-session -d -s cloudflared "proot-distro login ubuntu -- cloudflared tunnel run $t_name"
    print_success "Tunnel active at https://${sub}.${dom}"
}

finalize() {
    local ip
    ip=$(ifconfig wlan0 2>/dev/null | awk '/inet / {print $2}')

    cat <<EOF

${GREEN}
╔═══════════════════════════════════════════════════╗
║           🎉 DroidVM Setup Complete! 🎉           ║
╚═══════════════════════════════════════════════════╝
${NC}
${WHITE}Access Details:${NC}
  ${ARROW} SSH Local:     ssh -p 8022 $(whoami)@${ip:-<IP_ADDRESS>}
  ${ARROW} HTTP Local:    http://${ip:-localhost}:8000
  ${ARROW} Logs:          $LOG_FILE

${CYAN}Next Steps:${NC}
  1. Build your API in:  ~/droidvm
  2. Start coding!
  
${GREEN}Happy Hacking! ${STAR}${NC}
EOF
}

# ==============================================================================
# Main Execution
# ==============================================================================

# Argument parsing
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --skip-cloudflare) SKIP_CLOUDFLARE=true ;;
        --help) echo "Usage: ./setup.sh [--skip-cloudflare]"; exit 0 ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

mkdir -p "$INSTALL_DIR"
touch "$LOG_FILE"

print_banner
preflight_checks

setup_base_packages
setup_ssh
setup_tmux
setup_python
setup_ubuntu_proot
setup_tailscale
setup_cloudflare

finalize
