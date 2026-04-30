# Fedora 43 Post-Installation Scripts

Automated post-installation setup for Fedora 43, including package managers, development tools, and applications.

## 📋 Overview

These scripts provide a complete post-installation setup for Fedora 43, focusing on:
- Modern package managers (Flatpak, Snap)
- Development environment (Git, NVM, Docker)
- Enhanced shell experience (Zsh with Oh My Zsh)
- Essential applications for productivity

## 📦 What Gets Installed

### System Components
- **RPM Fusion Repositories** - Free and non-free software repositories
- **Flatpak** - Universal Linux application system with Flathub
- **Snap** - Alternative package management system
- **Wine** - Windows compatibility layer

### Development Tools
- **Git** - Version control system
- **Zsh** - Modern shell with Oh My Zsh framework
  - Plugins: git, command-not-found, sudo, history-substring-search, zsh-autosuggestions, zsh-syntax-highlighting
- **NVM** - Node Version Manager with latest LTS Node.js
- **Docker** - Container platform with Docker Compose

### Applications

#### Flatpak Applications
- GitKraken (Git GUI)
- FileZilla (FTP client)
- Signal (Secure messaging)
- Telegram (Messaging)
- Vivaldi (Web browser)
- Sublime Text (Text editor)
- Slack (Team communication)
- qBittorrent (Torrent client)
- Teams for Linux
- Opera (Web browser)
- Google Chrome (Web browser)

#### Snap Applications
- MySQL Workbench
- Thunderbird (Email client)
- Postman (API testing)
- Teams for Linux

#### DNF Applications
- CameraCtrl (Webcam configuration)

## 🚀 Usage

### Prerequisites
- Fresh Fedora 43 installation
- Sudo privileges
- Internet connection

### Installation

1. Clone or download the scripts to your system
2. Make the main script executable:
   ```bash
   chmod +x fedora-postinstall.sh
   ```
3. Run the script with sudo:
   ```bash
   sudo ./fedora-postinstall.sh
   ```

### Post-Installation Steps

After the script completes:

1. **Log out and log back in** to activate:
   - Zsh as your default shell
   - Docker group membership

2. **Verify installations**:
   ```bash
   # Check Zsh
   echo $SHELL
   
   # Check NVM
   nvm --version
   
   # Check Docker
   docker --version
   docker ps
   
   # Check Node.js
   node --version
   npm --version
   ```

3. **Update Snap packages** (if needed):
   ```bash
   snap refresh
   ```

## 📝 Script Details

### fedora-postinstall.sh

Main installation script with modular functions:

- `check_root()` - Validates sudo execution
- `update_system()` - Updates all system packages
- `enable_rpm_fusion()` - Enables RPM Fusion repositories
- `setup_flatpak()` - Configures Flatpak with Flathub
- `setup_snap()` - Enables Snap support
- `setup_zsh()` - Installs and configures Zsh with Oh My Zsh
- `install_wine()` - Installs Wine compatibility layer
- `install_nvm()` - Installs NVM and Node.js LTS
- `install_docker()` - Installs Docker and Docker Compose
- `install_flatpak_apps()` - Installs Flatpak applications
- `configure_flatpak_permissions()` - Fixes Wayland and file access permissions
- `install_snap_apps()` - Installs Snap applications
- `install_dnf_apps()` - Installs additional DNF packages
- `show_summary()` - Displays installation summary

**Features:**
- Color-coded output (info, success, warning, error)
- Robust error handling with `set -euo pipefail`
- Graceful failure handling for optional applications
- Automatic permission fixing for Flatpak apps (Wayland support)
- User-context aware (installs NVM and Zsh configs for sudo user)

### zshrc-config.sh

Custom Zsh configuration providing:

**History Management:**
- 10,000 command history
- Shared history across sessions
- Duplicate filtering
- Space-prefixed command hiding

**Completion:**
- Case-insensitive matching
- Menu-based selection
- Colored output
- Grouped results

**Aliases:**
- Directory listing shortcuts
- System management (update, install, remove)
- Safety nets (rm -i, cp -i, mv -i)
- Git shortcuts
- Docker commands
- Network utilities

**Functions:**
- `mkcd()` - Create directory and cd into it
- `extract()` - Universal archive extraction

**Environment:**
- NVM integration
- Editor defaults (nano)
- Better history search with arrow keys

## 🔧 Customization

### Modifying Application Lists

Edit the arrays in the main script:

```bash
# In install_flatpak_apps()
local apps=(
    "com.axosoft.GitKraken"
    "org.filezillaproject.Filezilla"
    # Add or remove apps here
)

# In install_snap_apps()
local snaps=(
    "mysql-workbench-community"
    # Add or remove snaps here
)
```

### Customizing Zsh Configuration

Edit `zshrc-config.sh` to add:
- Your own aliases
- Custom functions
- Environment variables
- Key bindings

### Changing Zsh Theme

Edit the theme line in `fedora-postinstall.sh`:
```bash
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="your-theme-here"/' "$zshrc"
```

Popular themes: `agnoster`, `powerlevel10k`, `robbyrussell` (default)

## 🐛 Troubleshooting

### Flatpak Applications Won't Access Files

Run permission fix manually:
```bash
flatpak override --user APP_ID --filesystem=home
```

### Docker Permission Denied

Ensure you're in the docker group and logged out/in:
```bash
groups | grep docker
```

### NVM Not Found After Installation

Source your shell config or reopen the terminal:
```bash
source ~/.zshrc
```

### Snap Apps Not Appearing

Snap daemon may need time to start:
```bash
sudo systemctl status snapd
sudo systemctl restart snapd
```

## 📚 Additional Resources

- [Fedora Documentation](https://docs.fedoraproject.org/)
- [Flatpak Documentation](https://docs.flatpak.org/)
- [Oh My Zsh](https://ohmyz.sh/)
- [Docker Documentation](https://docs.docker.com/)
- [NVM GitHub](https://github.com/nvm-sh/nvm)

## 🔒 Security Notes

- Script requires sudo/root privileges
- All packages are installed from official repositories
- Flatpak apps are sandboxed with permission overrides for usability
- Docker group membership grants significant system access

## 📄 License

These scripts are provided as-is for personal use. Modify as needed for your setup.

## 🤝 Contributing

Feel free to modify and extend these scripts for your specific needs. Consider:
- Adding more applications
- Creating optional installation profiles
- Adding rollback functionality
- Implementing dry-run mode

## 📅 Changelog

### Version 2.0 (2025-11-22)
- Refactored for Fedora 43
- Modular function-based architecture
- Improved error handling and logging
- Color-coded output
- Enhanced Zsh configuration
- Better NVM installation (user-context aware)
- Comprehensive documentation
- Flatpak permission auto-configuration
- Updated to NVM v0.40.0

### Version 1.0
- Initial release for Fedora
