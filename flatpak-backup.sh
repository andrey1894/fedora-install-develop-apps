#!/usr/bin/env bash
#
# Flatpak Backup Script
# Creates backups of all installed Flatpak applications
#
# Usage: ./flatpak-backup.sh [backup_directory]
# Example: ./flatpak-backup.sh ~/backups/flatpak

set -euo pipefail

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

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

# Get backup directory from argument or use default
BACKUP_BASE_DIR="${1:-$HOME/flatpak-backups}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_BASE_DIR/$TIMESTAMP"

# Option: Skip cache to save space (set to "true" to enable)
SKIP_CACHE=true

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}           Flatpak Application Backup Tool             ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
log_info "Backup location: $BACKUP_DIR"
if [[ "$SKIP_CACHE" == "true" ]]; then
    log_info "Cache folders will be excluded (saves space)"
fi
echo ""

# List of applications to backup (add/remove as needed)
PRIORITY_APPS=(
    "com.vivaldi.Vivaldi"
    # "com.google.Chrome"
    # "io.github.ungoogled_software.ungoogled_chromium"
    # "com.opera.Opera"
    # "com.slack.Slack"
    # "org.signal.Signal"
    # "org.telegram.desktop"
    # "md.obsidian.Obsidian"
    # "com.axosoft.GitKraken"
    # "com.sublimetext.three"
    # "org.kde.krita"
)

# Counter for statistics
BACKED_UP=0
SKIPPED=0
FAILED=0

# Function to backup a single app
backup_app() {
    local app_id=$1
    local app_path="$HOME/.var/app/$app_id"
    
    if [[ ! -d "$app_path" ]]; then
        log_warning "$app_id: Not installed, skipping"
        ((SKIPPED++))
        return
    fi
    
    log_info "Backing up: $app_id"
    
    local backup_file="$BACKUP_DIR/${app_id}.tar.gz"
    
    # Build tar exclude options for cache
    local exclude_opts=""
    if [[ "$SKIP_CACHE" == "true" ]]; then
        exclude_opts="--exclude=${app_id}/cache --exclude=${app_id}/.cache --exclude=${app_id}/*/Cache --exclude=${app_id}/*/GPUCache"
    fi
    
    # Create backup (show errors if they occur)
    local tar_output
    tar_output=$(tar -czf "$backup_file" $exclude_opts -C "$HOME/.var/app" "$app_id" 2>&1)
    local tar_status=$?
    
    # Filter out harmless warnings
    local filtered_output=$(echo "$tar_output" | grep -v "socket ignored" | grep -v "file changed as we read it" | grep -v "^$")
    
    # Show actual errors if any
    if [[ -n "$filtered_output" ]]; then
        echo "$filtered_output" | while IFS= read -r line; do
            log_warning "$line"
        done
    fi
    
    # Check if backup was successful (tar returns 0 or 1 for some non-critical warnings)
    if [[ $tar_status -eq 0 || $tar_status -eq 1 ]] && [[ -f "$backup_file" ]]; then
        # Verify the archive was created successfully
        if gzip -t "$backup_file" 2>/dev/null; then
            local size=$(du -h "$backup_file" | cut -f1)
            log_success "$app_id backed up ($size)"
            ((BACKED_UP++))
        else
            log_error "$app_id: Archive verification failed"
            ((FAILED++))
            rm -f "$backup_file"
        fi
    else
        log_error "$app_id: Backup failed (tar exit code: $tar_status)"
        ((FAILED++))
        rm -f "$backup_file"
    fi
}

# Backup priority apps
log_info "Backing up priority applications..."
echo ""

for app in "${PRIORITY_APPS[@]}"; do
    backup_app "$app"
done

echo ""
log_info "Checking for other installed Flatpak applications..."
echo ""

# Backup any other installed apps not in priority list
if command -v flatpak &> /dev/null; then
    while IFS= read -r app_id; do
        # Skip if already backed up
        if [[ " ${PRIORITY_APPS[@]} " =~ " ${app_id} " ]]; then
            continue
        fi
        backup_app "$app_id"
    done < <(flatpak list --app --columns=application 2>/dev/null)
fi

# Create backup manifest
MANIFEST_FILE="$BACKUP_DIR/backup-manifest.txt"
cat > "$MANIFEST_FILE" << EOF
Flatpak Backup Manifest
=======================
Date: $(date)
Hostname: $(hostname)
User: $USER
Backup Directory: $BACKUP_DIR

Backed Up Applications:
EOF

# List backed up apps
for backup_file in "$BACKUP_DIR"/*.tar.gz; do
    if [[ -f "$backup_file" ]]; then
        basename "$backup_file" .tar.gz >> "$MANIFEST_FILE"
    fi
done

echo "" >> "$MANIFEST_FILE"
echo "Total backed up: $BACKED_UP" >> "$MANIFEST_FILE"
echo "Skipped: $SKIPPED" >> "$MANIFEST_FILE"
echo "Failed: $FAILED" >> "$MANIFEST_FILE"

# Create a single archive for easy transfer
log_info "Creating combined archive for transfer..."
COMBINED_ARCHIVE="$BACKUP_BASE_DIR/flatpak-backup-${TIMESTAMP}.tar.gz"

if tar -czf "$COMBINED_ARCHIVE" -C "$BACKUP_BASE_DIR" "$TIMESTAMP" 2>&1 | grep -v "socket ignored"; then
    # Verify the combined archive
    if tar -tzf "$COMBINED_ARCHIVE" >/dev/null 2>&1; then
        ARCHIVE_SIZE=$(du -h "$COMBINED_ARCHIVE" | cut -f1)
        log_success "Combined archive created successfully"
    else
        log_error "Combined archive verification failed"
        rm -f "$COMBINED_ARCHIVE"
        COMBINED_ARCHIVE=""
    fi
else
    log_error "Failed to create combined archive"
    COMBINED_ARCHIVE=""
fi

# Summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}                Backup Complete                         ${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✓${NC} Applications backed up: $BACKED_UP"
echo -e "${YELLOW}⊘${NC} Skipped (not installed): $SKIPPED"
if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}✗${NC} Failed: $FAILED"
fi
echo ""
echo -e "${BLUE}Backup Details:${NC}"
echo "  Individual backups: $BACKUP_DIR"
if [[ -n "$COMBINED_ARCHIVE" ]]; then
    echo "  Combined archive: $COMBINED_ARCHIVE ($ARCHIVE_SIZE)"
fi
echo "  Manifest: $MANIFEST_FILE"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
if [[ -n "$COMBINED_ARCHIVE" ]]; then
    echo "  1. Copy the combined archive to your new system:"
    echo "     ${BLUE}$COMBINED_ARCHIVE${NC}"
    echo ""
    echo "  2. On the new system, run:"
    echo "     ${BLUE}./flatpak-restore.sh $COMBINED_ARCHIVE${NC}"
else
    echo "  Use individual backups from: $BACKUP_DIR"
fi
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"