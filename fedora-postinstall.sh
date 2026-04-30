#!/usr/bin/env bash
#
# Fedora 44 Post-Installation Script
# Automated setup for Flatpak, Snap, development tools, and applications
#
# Usage: sudo ./fedora-postinstall.sh
# Requirements: Run as root or with sudo privileges
#
# Author: Updated for Fedora 44
# Date: 2025-11-22

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
    
    if [[ -z "${SUDO_USER:-}" ]]; then
        log_error "SUDO_USER not set. Please run with 'sudo' not as root directly"
        exit 1
    fi
}

# Get script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly USER_HOME="/home/$SUDO_USER"

# System update
update_system() {
    log_info "Updating system packages..."
    dnf upgrade -y --refresh
    log_success "System updated"
}

# Enable RPM Fusion repositories
enable_rpm_fusion() {
    log_info "Enabling RPM Fusion repositories..."
    local fedora_version=$(rpm -E %fedora)
    
    dnf install -y \
        "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm" \
        "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_version}.noarch.rpm"
    
    log_success "RPM Fusion repositories enabled"
}

# Setup Flatpak
setup_flatpak() {
    log_info "Setting up Flatpak..."
    dnf install -y flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    log_success "Flatpak configured with Flathub"
}

# Setup Snap
setup_snap() {
    log_info "Setting up Snap..."
    dnf install -y snapd
    systemctl enable --now snapd.socket
    ln -sf /var/lib/snapd/snap /snap
    log_success "Snap configured"
}

# Install Git
install_git() {
    if command -v git &> /dev/null; then
        log_info "Git already installed, skipping..."
        return
    fi
    
    log_info "Installing Git..."
    dnf install -y git
    log_success "Git installed"
}

# Install and configure Zsh
setup_zsh() {
    log_info "Installing Zsh and dependencies..."
    
    # Install Zsh and utilities if not already installed
    if ! command -v zsh &> /dev/null; then
        dnf install -y zsh util-linux-user
    else
        log_info "Zsh already installed, skipping..."
    fi
    
    local zsh_path=$(which zsh)
    local zshrc="${USER_HOME}/.zshrc"
    local omz_dir="${USER_HOME}/.oh-my-zsh"
    
    # Change default shell
    chsh -s "$zsh_path" "$SUDO_USER"
    log_success "Default shell changed to Zsh for $SUDO_USER"
    
    # Install Oh My Zsh
    if [[ ! -d "$omz_dir" ]]; then
        log_info "Installing Oh My Zsh..."
        sudo -u "$SUDO_USER" sh -c 'curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh -s -- --unattended'
    fi
    
    # Configure Zsh if .zshrc exists
    if [[ -f "$zshrc" ]]; then
        # Backup original
        cp "$zshrc" "${zshrc}.backup"
        
        # Set theme
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="robbyrussell"/' "$zshrc"
        
        # Install custom plugins
        local plugins_dir="${omz_dir}/custom/plugins"
        
        if [[ ! -d "${plugins_dir}/zsh-autosuggestions" ]]; then
            sudo -u "$SUDO_USER" git clone --depth=1 \
                https://github.com/zsh-users/zsh-autosuggestions \
                "${plugins_dir}/zsh-autosuggestions"
        fi
        
        if [[ ! -d "${plugins_dir}/zsh-syntax-highlighting" ]]; then
            sudo -u "$SUDO_USER" git clone --depth=1 \
                https://github.com/zsh-users/zsh-syntax-highlighting \
                "${plugins_dir}/zsh-syntax-highlighting"
        fi
        
        # Enable plugins
        sed -i 's/^plugins=.*/plugins=(git command-not-found sudo history-substring-search zsh-autosuggestions zsh-syntax-highlighting)/' "$zshrc"
        
        # Source custom configuration
        if [[ -f "${SCRIPT_DIR}/zshrc-config.sh" ]]; then
            if ! grep -q "zshrc-config.sh" "$zshrc"; then
                cat >> "$zshrc" << EOF

# Custom Fedora 44 configuration
if [[ -f "${SCRIPT_DIR}/zshrc-config.sh" ]]; then
    source "${SCRIPT_DIR}/zshrc-config.sh"
fi
EOF
            fi
        fi
        
        # Fix permissions
        chown -R "${SUDO_USER}:${SUDO_USER}" "$omz_dir" "${zshrc}"*
        
        log_success "Zsh configured with Oh My Zsh and custom plugins"
    fi
}

# Install Wine
install_wine() {
    if command -v wine &> /dev/null; then
        log_info "Wine already installed, skipping..."
        return
    fi
    
    log_info "Installing Wine..."
    dnf install -y wine
    log_success "Wine installed"
}

# Install NVM and Node.js
install_nvm() {
    local nvm_dir="${USER_HOME}/.nvm"
    
    if [[ -d "$nvm_dir" ]] && [[ -s "${nvm_dir}/nvm.sh" ]]; then
        log_info "NVM already installed, skipping..."
        return
    fi
    
    log_info "Installing NVM (Node Version Manager)..."
    
    # Install NVM for the user
    sudo -u "$SUDO_USER" bash -c '
        export NVM_DIR="'"$nvm_dir"'"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
        
        # Load NVM
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        # Install latest LTS Node.js
        nvm install --lts
        nvm alias default lts/*
        
        # Update npm to latest version
        npm install -g npm@latest
        
        # Install global packages
        npm install -g yarn
        npm install -g @angular/cli
        npm install -g http-server
    '
    
    log_success "NVM and Node.js LTS installed"
    log_success "npm updated to latest version"
    log_success "Global packages installed: yarn, @angular/cli, http-server"
}

# Install Docker
install_docker() {
    if command -v docker &> /dev/null; then
        log_info "Docker already installed, skipping..."
        
        # Still add user to docker group if not already member
        if ! groups "$SUDO_USER" | grep -q docker; then
            usermod -aG docker "$SUDO_USER"
            log_success "Added $SUDO_USER to docker group"
            log_warning "You must log out and back in for Docker group changes to take effect"
        fi
        return
    fi
    
    log_info "Installing Docker..."
    
    dnf install -y dnf-plugins-core
    
    # Add Docker repository only if not already present
    if [[ ! -f /etc/yum.repos.d/docker-ce.repo ]]; then
        dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
    else
        log_info "Docker repository already configured, skipping..."
    fi
    
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    systemctl enable --now docker
    
    # Add user to docker group
    usermod -aG docker "$SUDO_USER"
    
    # Create symlink for legacy docker-compose command (v1 compatibility)
    if [[ ! -f /usr/local/bin/docker-compose ]]; then
        ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
        log_success "Docker Compose legacy command symlink created"
    fi
    
    log_success "Docker and Docker Compose installed and enabled"
    log_warning "You must log out and back in for Docker group changes to take effect"
}

# Install Flatpak applications
install_flatpak_apps() {
    log_info "Installing Flatpak applications..."
    
    local apps=(
        "com.axosoft.GitKraken"
        "org.filezillaproject.Filezilla"
        "org.signal.Signal"
        "org.telegram.desktop"
        "org.qbittorrent.qBittorrent"
        "com.github.IsmaelMartinez.teams_for_linux"
        "io.github.ungoogled_software.ungoogled_chromium"
        "org.kde.krita"
        "md.obsidian.Obsidian"
    )
    
    for app in "${apps[@]}"; do
        if flatpak list --app | grep -q "$app"; then
            log_info "$app already installed, skipping..."
        elif flatpak install -y flathub "$app" 2>/dev/null; then
            log_success "Installed: $app"
        else
            log_warning "Failed to install: $app"
        fi
    done
}

# Configure Flatpak permissions
configure_flatpak_permissions() {
    log_info "Configuring Flatpak permissions for Wayland and file access..."
    
    # Helper function to override permissions
    override_app() {
        local app=$1
        shift
        for permission in "$@"; do
            flatpak override --user "$app" "$permission" 2>/dev/null || true
        done
    }
    
    # Signal - communication permissions
    override_app "org.signal.Signal" \
        --filesystem=home \
        --filesystem=xdg-download \
        --socket=wayland \
        --socket=fallback-x11 \
        --device=all
    
    # Telegram - file access
    override_app "org.telegram.desktop" \
        --filesystem=home \
        --filesystem=xdg-download
    
    # Teams for Linux - full permissions
    override_app "com.github.IsmaelMartinez.teams_for_linux" \
        --filesystem=home \
        --filesystem=xdg-download \
        --socket=wayland \
        --socket=fallback-x11 \
        --device=all \
        --share=network \
        --share=ipc
    
    # Krita - file access
    override_app "org.kde.krita" \
        --filesystem=home \
        --filesystem=xdg-documents \
        --filesystem=xdg-pictures
    
    # Obsidian - file access
    override_app "md.obsidian.Obsidian" \
        --filesystem=home \
        --filesystem=xdg-documents
    
    # Ungoogled Chromium - full permissions
    override_app "io.github.ungoogled_software.ungoogled_chromium" \
        --filesystem=home \
        --filesystem=xdg-download \
        --socket=wayland \
        --socket=fallback-x11 \
        --device=all \
        --share=network \
        --share=ipc
    
    log_success "Flatpak permissions configured"
}

# Install native Vivaldi browser via RPM repo
install_vivaldi() {
    if rpm -q vivaldi-stable &> /dev/null; then
        log_info "Vivaldi already installed natively, skipping..."
        return
    fi

    log_info "Installing Vivaldi Browser via RPM repository..."

    if [[ ! -f /etc/yum.repos.d/vivaldi-fedora.repo ]]; then
        dnf config-manager addrepo --from-repofile=https://repo.vivaldi.com/stable/vivaldi-fedora.repo
    else
        log_info "Vivaldi repository already configured, skipping..."
    fi

    if dnf reinstall -y vivaldi-stable; then
        log_success "Vivaldi Browser installed"
    else
        log_warning "Failed to install Vivaldi Browser"
    fi
}

# Install native Sublime Text via RPM repo
install_sublime_text() {
    if rpm -q sublime-text &> /dev/null; then
        log_info "Sublime Text already installed natively, skipping..."
        return
    fi

    log_info "Installing Sublime Text via RPM repository..."

    rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg

    if [[ ! -f /etc/yum.repos.d/sublime-text.repo ]]; then
        dnf config-manager addrepo --from-repofile=https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
    else
        log_info "Sublime Text repository already configured, skipping..."
    fi

    if dnf install -y sublime-text; then
        log_success "Sublime Text installed"
    else
        log_warning "Failed to install Sublime Text"
    fi
}

# Install Snap applications
install_snap_apps() {
    log_info "Installing Snap applications..."
    
    local snaps=(
        "mysql-workbench-community"
        "thunderbird"
        "postman"
        "teams-for-linux"
    )
    
    for snap_pkg in "${snaps[@]}"; do
        if snap list | grep -q "^${snap_pkg} "; then
            log_info "$snap_pkg already installed, skipping..."
        elif snap install "$snap_pkg" 2>/dev/null; then
            log_success "Installed: $snap_pkg"
        else
            log_warning "Failed to install: $snap_pkg"
        fi
    done
}

# Install additional applications via DNF
install_dnf_apps() {
    log_info "Installing additional applications via DNF..."
    
    # Firefox Developer Edition
    if rpm -q firefox-dev &> /dev/null; then
        log_info "Firefox Developer Edition already installed, skipping..."
    elif dnf copr enable -y the4runner/firefox-dev && dnf install -y firefox-dev; then
        log_success "Firefox Developer Edition installed via COPR"
    else
        log_warning "Failed to install Firefox Developer Edition"
    fi
    
    # Visual Studio Code
    if rpm -q code &> /dev/null; then
        log_info "Visual Studio Code already installed, skipping..."
    else
        log_info "Installing Visual Studio Code..."
        rpm --import https://packages.microsoft.com/keys/microsoft.asc
        cat > /etc/yum.repos.d/vscode.repo << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
        if dnf install -y code; then
            log_success "Visual Studio Code installed"
        else
            log_warning "Failed to install Visual Studio Code"
        fi
    fi
    
    # Mega Sync
    if rpm -q megasync &> /dev/null; then
        log_info "Mega Sync already installed, skipping..."
    else
        log_info "Installing Mega Sync..."
        local mega_rpm="/tmp/megasync-Fedora_43.x86_64.rpm"
        if wget -O "$mega_rpm" https://mega.nz/linux/repo/Fedora_43/x86_64/megasync-Fedora_43.x86_64.rpm 2>/dev/null; then
            if dnf install -y "$mega_rpm"; then
                log_success "Mega Sync installed"
            else
                log_warning "Failed to install Mega Sync"
            fi
            rm -f "$mega_rpm"
        else
            log_warning "Failed to download Mega Sync"
        fi
    fi
    
    # Flameshot
    if rpm -q flameshot &> /dev/null; then
        log_info "Flameshot already installed, skipping..."
    elif dnf install -y flameshot; then
        log_success "Flameshot installed"
    else
        log_warning "Failed to install Flameshot"
    fi
    
    # Google Chrome (native DNF package)
    if rpm -q google-chrome-stable &> /dev/null; then
        log_info "Google Chrome already installed, skipping..."
    else
        log_info "Installing Google Chrome..."
        dnf install -y fedora-workstation-repositories
        dnf config-manager --setopt=google-chrome.enabled=1
        if dnf install -y google-chrome-stable; then
            log_success "Google Chrome installed"

            # Configure Chrome Wayland flags
            local chrome_flags_dir="${USER_HOME}/.config"
            mkdir -p "$chrome_flags_dir"
            cat > "${chrome_flags_dir}/chrome-flags.conf" << 'EOF'
--enable-features=WebRTCPipeWireCapturer
--ozone-platform-hint=auto
EOF
            chown -R "${SUDO_USER}:${SUDO_USER}" "$chrome_flags_dir"
            log_success "Chrome Wayland flags configured"
        else
            log_warning "Failed to install Google Chrome"
        fi
    fi
    
    # Cameractrls
    if flatpak list --app | grep -q "hu.irl.cameractrls"; then
        log_info "Cameractrls already installed, skipping..."
    elif flatpak install -y flathub hu.irl.cameractrls 2>/dev/null; then
        log_success "Cameractrls installed via Flatpak"
    else
        log_warning "Failed to install Cameractrls"
    fi
}

# Display final summary
show_summary() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}           Fedora 43 Post-Installation Complete         ${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}✓${NC} System updated to latest packages"
    echo -e "${GREEN}✓${NC} RPM Fusion repositories enabled"
    echo -e "${GREEN}✓${NC} Flatpak configured with Flathub"
    echo -e "${GREEN}✓${NC} Snap support enabled"
    echo -e "${GREEN}✓${NC} Zsh installed with Oh My Zsh"
    echo -e "${GREEN}✓${NC} Git installed"
    echo -e "${GREEN}✓${NC} Wine compatibility layer installed"
    echo -e "${GREEN}✓${NC} NVM and Node.js LTS installed"
    echo -e "${GREEN}✓${NC} npm, Yarn, Angular CLI, and http-server installed"
    echo -e "${GREEN}✓${NC} Docker and Docker Compose installed"
    echo ""
    echo -e "${BLUE}📦 Installed Applications:${NC}"
    echo "   • Flatpak: GitKraken, FileZilla, Signal, Telegram,"
    echo "     qBittorrent, Teams, Ungoogled Chromium,"
    echo "     Krita, Obsidian, Cameractrls"
    echo "   • Snap: MySQL Workbench, Thunderbird, Postman, Teams"
    echo "   • DNF/RPM: Firefox Dev, VS Code, Mega Sync, Flameshot,"
    echo "     Google Chrome, Vivaldi, Sublime Text"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT - Action Required:${NC}"
    echo "   1. Log out and log back in for changes to take effect:"
    echo "      • Zsh will become your default shell"
    echo "      • Docker group membership will be activated"
    echo "   2. Snap apps may require: ${BLUE}snap refresh${NC}"
    echo "   3. Verify NVM installation: ${BLUE}source ~/.bashrc${NC} or reopen terminal"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Main execution
main() {
    check_root
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}       Fedora 44 Post-Installation Script              ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    update_system
    enable_rpm_fusion
    setup_flatpak
    setup_snap
    install_git
    setup_zsh
    install_wine
    install_nvm
    install_docker
    install_vivaldi
    install_sublime_text
    install_flatpak_apps
    configure_flatpak_permissions
    install_snap_apps
    install_dnf_apps
    
    show_summary
}

# Run main function
main
