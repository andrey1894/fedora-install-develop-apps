# Fedora Post-Installation Scripts

Automated post-installation setup for Fedora, including package managers, development tools, and applications.

## 📋 Overview

These scripts provide a complete post-installation setup for Fedora, focusing on:
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
- qBittorrent (Torrent client)
- Teams for Linux
- Ungoogled Chromium (Web browser)
- Krita (Digital painting)
- Obsidian (Notes)

#### Native RPM Applications
- Vivaldi (Web browser)
- Sublime Text (Text editor)

#### Snap Applications
- MySQL Workbench
- Thunderbird (Email client)
- Postman (API testing)
- Teams for Linux

#### Optional DNF Applications

The script contains an `install_dnf_apps()` function, but it is currently disabled in `main()`. If you enable it, it installs:

- Firefox Developer Edition
- Visual Studio Code
- Mega Sync
- Flameshot
- Google Chrome
- CameraCtrls (via Flatpak)

#### Manual Installs

- JetBrains IDEs: use JetBrains Toolbox from the official site. JetBrains does not provide an official Fedora RPM for the Toolbox-based workflow.

Basic Toolbox install flow:

```bash
cd ~/Downloads
tar -xzf jetbrains-toolbox-*.tar.gz
cd jetbrains-toolbox-*/
./jetbrains-toolbox
```

Download page: https://www.jetbrains.com/toolbox-app/

## 🚀 Usage

### Prerequisites
- Fresh Fedora installation
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

### Active Install Paths

The script currently uses a mixed install model:

- Flatpak: most desktop apps such as GitKraken, FileZilla, Signal, Telegram, qBittorrent, Teams for Linux, Ungoogled Chromium, Krita, and Obsidian
- Native RPM: Vivaldi and Sublime Text
- Snap: MySQL Workbench, Thunderbird, Postman, and Teams for Linux
- Optional DNF bundle: present in the script as `install_dnf_apps()`, but currently not enabled in `main()`

This matters when you troubleshoot data locations, launchers, permissions, or profile migration.

### Re-Running the Script

The script is mostly safe to re-run. Many install functions check whether software is already present and skip work when possible.

Expected behavior on re-run:

- already-installed packages are usually skipped
- repository configuration may be reused if the repo file already exists
- user shell configuration may be updated again if the target lines are still managed by the script
- some steps still require a new login before they fully apply, especially shell and Docker group changes

If a previous run failed halfway through, re-running is usually the first thing to try after fixing the blocking problem.

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
- `install_vivaldi()` - Installs Vivaldi from the official RPM repository
- `install_sublime_text()` - Installs Sublime Text from the official RPM repository
- `install_flatpak_apps()` - Installs Flatpak applications
- `configure_flatpak_permissions()` - Fixes Wayland and file access permissions
- `install_snap_apps()` - Installs Snap applications
- `install_dnf_apps()` - Installs additional DNF packages when enabled
- `show_summary()` - Displays installation summary

**Features:**
- Color-coded output (info, success, warning, error)
- Robust error handling with `set -euo pipefail`
- Graceful failure handling for optional applications
- Native Vivaldi installation from the official repository
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

# Native Vivaldi is configured in install_vivaldi()

# In install_snap_apps()
local snaps=(
    "mysql-workbench-community"
    # Add or remove snaps here
)
```

To enable the optional DNF bundle, uncomment the `install_dnf_apps` call in `main()`.

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

### Common Failures

If the script stops early, these are the first things to check:

- `dnf config-manager: command not found`: install the plugin package:

```bash
sudo dnf install -y dnf-plugins-core
```

- repository metadata or package resolution problems: refresh metadata and retry:

```bash
sudo dnf clean all
sudo dnf makecache
```

- GPG or repository key issues for third-party repos: re-import the key or recreate the repo file, then run the script again
- temporary network or mirror failures: retry later or test with a normal `sudo dnf upgrade --refresh`

### Flatpak Applications Won't Access Files

Run permission fix manually:
```bash
flatpak override --user APP_ID --filesystem=home
```

If Flathub was not added correctly, verify the remote and add it again:

```bash
flatpak remotes
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

### Docker Permission Denied

Ensure you're in the docker group and logged out/in:
```bash
groups | grep docker
```

If Docker was installed correctly but still fails for your user, log out completely and log back in before testing again.

### NVM Not Found After Installation

Source your shell config or reopen the terminal:
```bash
source ~/.zshrc
```

If you are still in the same elevated shell session used during setup, open a fresh terminal as your normal user.

### Snap Apps Not Appearing

Snap daemon may need time to start:
```bash
sudo systemctl status snapd
sudo systemctl restart snapd
```

If the `snap` command exists but desktop integration still looks broken, also confirm the `/snap` symlink exists:

```bash
ls -ld /snap
```

### Fedora KDE Icons Not Refreshing

On Fedora KDE, application icons sometimes do not appear immediately after installing software. Rebuild the KDE system configuration cache:

```bash
kbuildsycoca6 --noincremental
```

If the menu entry or icon still does not appear, log out and back in to refresh the desktop session.

### Fedora KDE Launchers Still Missing

This is most common with manually installed applications such as JetBrains Toolbox apps.

Checks:

- make sure the app has been launched once so it can create its desktop entry
- look for launchers in `~/.local/share/applications/`
- rebuild KDE cache again with `kbuildsycoca6 --noincremental`

### Browser/Profile Confusion After Switching Install Method

If you move from Flatpak to native RPM browsers, your old profile data may not be in the same location.

- Flatpak apps usually keep data under `~/.var/app/...`
- native RPM apps usually keep data under `~/.config`, `~/.local/share`, or app-specific directories in your home folder

If an app opens with a fresh profile, check whether you restored data into the old Flatpak path while now running the native package.

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
- Refactored for the current Fedora post-install workflow
- Modular function-based architecture
- Improved error handling and logging
- Color-coded output
- Enhanced Zsh configuration
- Better NVM installation (user-context aware)
- Comprehensive documentation
- Flatpak permission auto-configuration
- Native Vivaldi RPM installation
- Updated to NVM v0.40.0

### Version 1.0
- Initial release for Fedora
