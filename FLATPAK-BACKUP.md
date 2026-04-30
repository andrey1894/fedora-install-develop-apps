# Flatpak Application Data Backup & Restore Guide

This guide explains how to backup and restore user data from Flatpak applications, including browser profiles, application settings, and user data.

## 📋 Table of Contents
- [Quick Start: Post-Install Restore](#quick-start-post-install-restore)
- [Understanding Flatpak Data Storage](#understanding-flatpak-data-storage)
- [General Backup Method](#general-backup-method)
- [Browser-Specific Guides](#browser-specific-guides)
- [Application-Specific Examples](#application-specific-examples)
- [Automated Backup Script](#automated-backup-script)
- [Troubleshooting](#troubleshooting)

---

## Quick Start: Post-Install Restore

**If you just ran the fedora-postinstall.sh script and need to restore your tabs/data:**

### Before Running Post-Install (On Old System)

```bash
# Backup your browser data BEFORE reinstalling
# The actual profile data is in the .var/app folder
tar -czf ~/vivaldi-backup.tar.gz ~/.var/app/com.vivaldi.Vivaldi/

# Copy to external drive or another location
cp ~/vivaldi-backup.tar.gz /path/to/usb/
```

### After Running Post-Install (On New System)

```bash
# 1. Let the post-install script finish installing Vivaldi
# 2. DO NOT run Vivaldi yet!

# 3. Remove the fresh installation data
rm -rf ~/.var/app/com.vivaldi.Vivaldi/

# 4. Restore your backup
tar -xzf ~/vivaldi-backup.tar.gz -C ~/

# 5. Fix permissions (important!)
chown -R $USER:$USER ~/.var/app/com.vivaldi.Vivaldi/

# 6. Launch Vivaldi - your tabs and settings are back!
flatpak run com.vivaldi.Vivaldi
```

**Alternative Method (If above doesn't work):**

```bash
# Kill Vivaldi if running
flatpak kill com.vivaldi.Vivaldi

# Remove ALL Vivaldi data
rm -rf ~/.var/app/com.vivaldi.Vivaldi

# Extract backup directly
cd ~/.var/app/
tar -xzf ~/vivaldi-backup.tar.gz

# Fix ownership
chown -R $USER:$USER ~/.var/app/com.vivaldi.Vivaldi/

# Launch Vivaldi
flatpak run com.vivaldi.Vivaldi
```

**Troubleshooting: If you still see a fresh profile:**

```bash
# 1. Check if backup was extracted correctly
ls -la ~/.var/app/com.vivaldi.Vivaldi/.local/share/vivaldi/Default/

# You should see files like: Bookmarks, History, Preferences, Sessions/

# 2. If folder is empty or missing, your backup path was wrong
# Re-extract with verbose mode to see what's happening
tar -xzvf ~/vivaldi-backup.tar.gz -C ~/

# 3. Check the backup contents first
tar -tzf ~/vivaldi-backup.tar.gz | head -20

# 4. If backup contains .var/app/... path inside archive, extract differently:
cd ~
tar -xzf ~/vivaldi-backup.tar.gz --strip-components=0

# 5. Clear any cache that might interfere
rm -rf ~/.var/app/com.vivaldi.Vivaldi/cache/*
```

### If You Forgot to Backup Before Reinstalling

If your old system is still accessible:

```bash
# On old system (via SSH or direct access)
tar -czf /tmp/vivaldi-rescue.tar.gz ~/.var/app/com.vivaldi.Vivaldi/

# Transfer to new system
scp /tmp/vivaldi-rescue.tar.gz user@newsystem:~/

# On new system
flatpak kill com.vivaldi.Vivaldi
tar -xzf ~/vivaldi-rescue.tar.gz -C ~/
```

### All Browsers Quick Restore

```bash
# Backup all browsers at once (before reinstall)
cd ~/.var/app/
tar -czf ~/browsers-backup.tar.gz \
    com.vivaldi.Vivaldi/ \
    com.google.Chrome/ \
    com.opera.Opera/ \
    io.github.ungoogled_software.ungoogled_chromium/

# Restore all browsers (after post-install)
tar -xzf ~/browsers-backup.tar.gz -C ~/.var/app/
```

---

## Understanding Flatpak Data Storage

Flatpak applications store their data in isolated directories in your home folder:

```
~/.var/app/APPLICATION_ID/
├── cache/          # Temporary cache files
├── config/         # Application configuration
└── data/           # User data, profiles, settings
```

**Key Locations:**
- **Config & Data**: `~/.var/app/APPLICATION_ID/config/` and `~/.var/app/APPLICATION_ID/data/`
- **Cache**: `~/.var/app/APPLICATION_ID/cache/` (usually safe to skip in backups)

---

## General Backup Method

### Backup Single Application

```bash
# Backup entire application data
tar -czf ~/backup-APP_NAME-$(date +%Y%m%d).tar.gz -C ~/.var/app/ APPLICATION_ID/

# Example: Backup Vivaldi
tar -czf ~/backup-vivaldi-$(date +%Y%m%d).tar.gz -C ~/.var/app/ com.vivaldi.Vivaldi/
```

### Restore Single Application

```bash
# Stop the application first
flatpak kill com.vivaldi.Vivaldi

# Restore from backup
tar -xzf ~/backup-vivaldi-20251122.tar.gz -C ~/.var/app/

# Restart application
flatpak run com.vivaldi.Vivaldi
```

### Backup All Flatpak Data

```bash
# Backup all Flatpak app data
tar -czf ~/backup-flatpak-all-$(date +%Y%m%d).tar.gz ~/.var/app/
```

### Restore All Flatpak Data

```bash
# Extract to home directory
tar -xzf ~/backup-flatpak-all-20251122.tar.gz -C ~/
```

---

## Browser-Specific Guides

### Vivaldi Browser

**Application ID**: `com.vivaldi.Vivaldi`

**Important Data Locations:**
```
~/.var/app/com.vivaldi.Vivaldi/
├── .var/app/com.vivaldi.Vivaldi/.local/share/vivaldi/    # Where profile data actually is
├── current -> .local/share/vivaldi/                       # Symlink to profile location
├── x86_64/                                                # Binary files (skip for backup)
└── config/vivaldi/                                        # May exist on some systems
    ├── Default/              # Default profile
    │   ├── Bookmarks         # Bookmarks
    │   ├── Preferences       # Settings
    │   ├── Sessions/         # Session data (tabs)
    │   ├── History           # Browsing history
    │   └── Cookies           # Cookies
    └── Local State           # Global settings

Note: The actual profile is usually at:
~/.var/app/com.vivaldi.Vivaldi/.local/share/vivaldi/Default/
```

**Backup Vivaldi (All Users & Tabs):**
```bash
# Full backup (includes everything - RECOMMENDED)
tar -czf ~/backup-vivaldi-$(date +%Y%m%d).tar.gz \
    ~/.var/app/com.vivaldi.Vivaldi/

# Alternative: Backup only profile data (smaller, but complete)
tar -czf ~/backup-vivaldi-profile-$(date +%Y%m%d).tar.gz \
    ~/.var/app/com.vivaldi.Vivaldi/.local/share/vivaldi/
```

**Restore Vivaldi:**
```bash
# Stop Vivaldi
flatpak kill com.vivaldi.Vivaldi

# Restore full backup (RECOMMENDED)
tar -xzf ~/backup-vivaldi-20251122.tar.gz -C ~/
```

**Quick Copy Method (No Compression):**
```bash
# Backup
cp -r ~/.var/app/com.vivaldi.Vivaldi/ \
    ~/backup-vivaldi-$(date +%Y%m%d)/

# Restore
rm -rf ~/.var/app/com.vivaldi.Vivaldi/
cp -r ~/backup-vivaldi-20251122/ \
    ~/.var/app/com.vivaldi.Vivaldi/
```

---

### Google Chrome

**Application ID**: `com.google.Chrome`

```bash
# Backup
tar -czf ~/backup-chrome-$(date +%Y%m%d).tar.gz \
    ~/.var/app/com.google.Chrome/config/google-chrome/

# Restore
flatpak kill com.google.Chrome
tar -xzf ~/backup-chrome-20251122.tar.gz -C ~/
```

---

### Ungoogled Chromium

**Application ID**: `io.github.ungoogled_software.ungoogled_chromium`

```bash
# Backup
tar -czf ~/backup-chromium-$(date +%Y%m%d).tar.gz \
    ~/.var/app/io.github.ungoogled_software.ungoogled_chromium/config/chromium/

# Restore
flatpak kill io.github.ungoogled_software.ungoogled_chromium
tar -xzf ~/backup-chromium-20251122.tar.gz -C ~/
```

---

### Opera

**Application ID**: `com.opera.Opera`

```bash
# Backup
tar -czf ~/backup-opera-$(date +%Y%m%d).tar.gz \
    ~/.var/app/com.opera.Opera/config/opera/

# Restore
flatpak kill com.opera.Opera
tar -xzf ~/backup-opera-20251122.tar.gz -C ~/
```

---

## Application-Specific Examples

### Slack

**Application ID**: `com.slack.Slack`

```bash
# Backup
tar -czf ~/backup-slack-$(date +%Y%m%d).tar.gz \
    ~/.var/app/com.slack.Slack/config/Slack/

# Restore
flatpak kill com.slack.Slack
tar -xzf ~/backup-slack-20251122.tar.gz -C ~/
```

---

### Signal

**Application ID**: `org.signal.Signal`

```bash
# Backup (includes messages and media)
tar -czf ~/backup-signal-$(date +%Y%m%d).tar.gz \
    ~/.var/app/org.signal.Signal/config/Signal/

# Restore
flatpak kill org.signal.Signal
tar -xzf ~/backup-signal-20251122.tar.gz -C ~/
```

---

### Telegram

**Application ID**: `org.telegram.desktop`

```bash
# Backup
tar -czf ~/backup-telegram-$(date +%Y%m%d).tar.gz \
    ~/.var/app/org.telegram.desktop/data/TelegramDesktop/

# Restore
flatpak kill org.telegram.desktop
tar -xzf ~/backup-telegram-20251122.tar.gz -C ~/
```

---

### Obsidian

**Application ID**: `md.obsidian.Obsidian`

```bash
# Backup (vaults are usually in Documents, backup app settings)
tar -czf ~/backup-obsidian-$(date +%Y%m%d).tar.gz \
    ~/.var/app/md.obsidian.Obsidian/config/obsidian/

# Also backup your vaults if stored in default location
tar -czf ~/backup-obsidian-vaults-$(date +%Y%m%d).tar.gz \
    ~/Documents/Obsidian*/

# Restore
flatpak kill md.obsidian.Obsidian
tar -xzf ~/backup-obsidian-20251122.tar.gz -C ~/
```

---

### GitKraken

**Application ID**: `com.axosoft.GitKraken`

```bash
# Backup
tar -czf ~/backup-gitkraken-$(date +%Y%m%d).tar.gz \
    ~/.var/app/com.axosoft.GitKraken/config/

# Restore
flatpak kill com.axosoft.GitKraken
tar -xzf ~/backup-gitkraken-20251122.tar.gz -C ~/
```

---

### Sublime Text

**Application ID**: `com.sublimetext.three`

```bash
# Backup
tar -czf ~/backup-sublime-$(date +%Y%m%d).tar.gz \
    ~/.var/app/com.sublimetext.three/config/sublime-text-3/

# Restore
flatpak kill com.sublimetext.three
tar -xzf ~/backup-sublime-20251122.tar.gz -C ~/
```

---

### Krita

**Application ID**: `org.kde.krita`

```bash
# Backup settings and resources
tar -czf ~/backup-krita-$(date +%Y%m%d).tar.gz \
    ~/.var/app/org.kde.krita/config/krita/ \
    ~/.var/app/org.kde.krita/data/krita/

# Restore
flatpak kill org.kde.krita
tar -xzf ~/backup-krita-20251122.tar.gz -C ~/
```

---

## Automated Backup Script

Create a script to backup all important Flatpak applications:

```bash
#!/usr/bin/env bash
# flatpak-backup.sh - Automated Flatpak backup script

BACKUP_DIR=~/flatpak-backups
DATE=$(date +%Y%m%d-%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Applications to backup
APPS=(
    "com.vivaldi.Vivaldi"
    "com.google.Chrome"
    "com.slack.Slack"
    "org.signal.Signal"
    "org.telegram.desktop"
    "md.obsidian.Obsidian"
    "com.axosoft.GitKraken"
    "com.sublimetext.three"
    "org.kde.krita"
)

echo "Starting Flatpak backup: $DATE"

for app in "${APPS[@]}"; do
    if [[ -d ~/.var/app/$app ]]; then
        echo "Backing up: $app"
        tar -czf "$BACKUP_DIR/${app}-${DATE}.tar.gz" \
            -C ~/.var/app/ "$app/"
        echo "✓ $app backed up"
    else
        echo "⚠ $app not found, skipping"
    fi
done

# Clean old backups (keep last 5)
for app in "${APPS[@]}"; do
    ls -t "$BACKUP_DIR/${app}"-*.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm
done

echo "Backup complete! Files saved to: $BACKUP_DIR"
```

**Usage:**
```bash
# Make executable
chmod +x flatpak-backup.sh

# Run backup
./flatpak-backup.sh

# Schedule with cron (daily at 2 AM)
crontab -e
# Add: 0 2 * * * /path/to/flatpak-backup.sh
```

---

## Troubleshooting

### Application Won't Start After Restore

```bash
# Reset permissions
flatpak override --user --reset APPLICATION_ID

# Fix ownership
chown -R $USER:$USER ~/.var/app/APPLICATION_ID/

# Clear cache
rm -rf ~/.var/app/APPLICATION_ID/cache/*
```

### Restore Specific Files Only

```bash
# Extract specific files
tar -xzf backup.tar.gz -C /tmp/
cp /tmp/com.vivaldi.Vivaldi/config/vivaldi/Default/Bookmarks \
    ~/.var/app/com.vivaldi.Vivaldi/config/vivaldi/Default/
```

### Migrate to New System

```bash
# On old system
tar -czf ~/flatpak-migration.tar.gz ~/.var/app/

# Transfer to new system
scp ~/flatpak-migration.tar.gz newuser@newhost:~/

# On new system (after installing Flatpak apps)
tar -xzf ~/flatpak-migration.tar.gz -C ~/
```

### View Backup Contents

```bash
# List contents without extracting
tar -tzf backup-vivaldi-20251122.tar.gz | less
```

### Selective Application Restore

```bash
# Restore only browser bookmarks
tar -xzf backup-vivaldi-20251122.tar.gz \
    com.vivaldi.Vivaldi/config/vivaldi/Default/Bookmarks \
    -C ~/.var/app/
```

---

## Best Practices

1. **Regular Backups**: Schedule weekly backups of important applications
2. **Test Restores**: Periodically test your backup restoration process
3. **External Storage**: Store backups on external drives or cloud storage
4. **Before Updates**: Backup before major system or application updates
5. **Selective Backup**: Skip cache directories to save space
6. **Compression**: Use `tar -czf` for compressed backups to save space
7. **Documentation**: Keep notes about what each backup contains

---

## Quick Reference

### Find Application ID
```bash
flatpak list --app --columns=application
```

### List App Data Size
```bash
du -sh ~/.var/app/*
```

### Kill All Flatpak Apps
```bash
flatpak kill --all
```

### Backup Everything (Nuclear Option)
```bash
tar -czf ~/complete-flatpak-backup-$(date +%Y%m%d).tar.gz ~/.var/app/
```

---

## Additional Resources

- [Flatpak Documentation](https://docs.flatpak.org/)
- [Flathub](https://flathub.org/)
- Specific app documentation for data locations and migration guides

---

**Note**: Always close the application before restoring backups to avoid data corruption or conflicts.
