#!/bin/bash
# Linux Setup Script for MQL5 Trading Environment (Wine-based)
# Security-focused setup for user and agent protection

SECURITY_MODE=true
INSTALL_MQL5=false
LOG_PATH="/tmp/linux-setup.log"

log_message() {
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$timestamp - $1" | tee -a "$LOG_PATH"
}

set_security_defaults() {
    log_message "Configuring Linux security defaults..."
    
    # Update and install security tools
    if command -v apt-get &> /dev/null; then
        log_message "Installing security packages..."
        sudo apt-get update -qq
        sudo apt-get install -y ufw fail2ban clamav -qq 2>&1 | tee -a "$LOG_PATH"
    fi
    
    # Configure firewall
    if command -v ufw &> /dev/null; then
        log_message "Configuring UFW firewall..."
        sudo ufw --force enable
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        log_message "Firewall configured and enabled"
    fi
}

set_agent_security() {
    log_message "Configuring agent security settings..."
    
    # Create secure folder for agent operations
    AGENT_PATH="$HOME/.agent-secure"
    if [ ! -d "$AGENT_PATH" ]; then
        mkdir -p "$AGENT_PATH"
        chmod 700 "$AGENT_PATH"
        log_message "Created secure agent folder: $AGENT_PATH"
    fi
    
    # Create security policy file
    cat > "$AGENT_PATH/security-policy.conf" <<EOF
# Agent Security Policy
ALLOW_NETWORK=true
ALLOW_FILE_WRITE=restricted
SANDBOX_MODE=enabled
MAX_MEMORY_MB=1024
MAX_CPU_PERCENT=50
ALLOWED_DOMAINS=localhost,trusted-api.com
EOF
    
    chmod 600 "$AGENT_PATH/security-policy.conf"
    log_message "Configured secure permissions for agent folder"
}

install_wine_mql5() {
    log_message "Setting up Wine for MQL5 environment..."
    
    # Install Wine if not present
    if ! command -v wine &> /dev/null; then
        log_message "Installing Wine..."
        if command -v apt-get &> /dev/null; then
            sudo dpkg --add-architecture i386
            sudo apt-get update -qq
            sudo apt-get install -y wine wine32 wine64 -qq 2>&1 | tee -a "$LOG_PATH"
        fi
    fi
    
    # Create Wine prefix for MQL5
    export WINEPREFIX="$HOME/.wine-mql5"
    if [ ! -d "$WINEPREFIX" ]; then
        log_message "Creating Wine prefix for MQL5..."
        WINEDLLOVERRIDES="mscoree,mshtml=" wineboot -u
        log_message "Wine prefix created: $WINEPREFIX"
    fi
    
    # Create MQL5 security configuration
    MQL5_PATH="$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/MetaQuotes/Terminal"
    mkdir -p "$MQL5_PATH"
    
    cat > "$MQL5_PATH/security.ini" <<EOF
; MQL5 Security Configuration
[Security]
EnableExpertAdvisors=true
AllowDllImports=false
AllowWebRequests=true
AllowedURLs=https://trusted-sources-only.com
EnableAutomatedTrading=true
MaxPositions=10
EOF
    
    log_message "MQL5 security configuration created"
}

set_network_security() {
    log_message "Configuring network security..."
    
    # Configure sysctl for network hardening
    cat > /tmp/network-hardening.conf <<EOF
# Network security hardening
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.tcp_syncookies=1
EOF
    
    sudo cp /tmp/network-hardening.conf /etc/sysctl.d/99-security.conf 2>/dev/null
    sudo sysctl -p /etc/sysctl.d/99-security.conf 2>/dev/null
    log_message "Network security hardening applied"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-security)
            SECURITY_MODE=false
            shift
            ;;
        --install-mql5)
            INSTALL_MQL5=true
            shift
            ;;
        --log-path)
            LOG_PATH="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Main execution
log_message "=== Linux Setup Script Started ==="
log_message "Security Mode: $SECURITY_MODE"
log_message "Install MQL5: $INSTALL_MQL5"

if [ "$SECURITY_MODE" = true ]; then
    set_security_defaults
    set_agent_security
    set_network_security
fi

if [ "$INSTALL_MQL5" = true ]; then
    install_wine_mql5
fi

log_message "=== Linux Setup Script Completed ==="
echo ""
echo "Setup completed. Log file: $LOG_PATH"
