#!/usr/bin/env bash
#
# Flatpak Restore Script
# Restores Flatpak applications from backup archive
#
# Usage: ./flatpak-restore.sh <backup_archive>
# Example: ./flatpak-restore.sh ~/flatpak-backup-20251122-143022.tar.gz

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

# Check if backup source provided
if [[ $# -eq 0 ]]; then
    log_error "No backup source specified!"
    echo ""
    echo "Usage: $0 <backup_archive_or_directory>"
    echo "Example: $0 ~/flatpak-backup-20251122-143022.tar.gz"
    echo "      or $0 ~/flatpak-backups/20251122-143022"
    exit 1
fi

BACKUP_SOURCE="$1"
BACKUP_DIR=""
TEMP_DIR=""

# Check if input is a directory or an archive
if [[ -d "$BACKUP_SOURCE" ]]; then
    # Direct directory - no extraction needed
    BACKUP_DIR="$BACKUP_SOURCE"
    log_info "Using backup directory: $BACKUP_DIR"
elif [[ -f "$BACKUP_SOURCE" ]]; then
    # Archive file - need to extract
    log_info "Verifying archive integrity..."
    if ! tar -tzf "$BACKUP_SOURCE" >/dev/null 2>&1; then
        log_error "Archive is corrupted or invalid"
        log_error "The file may have been interrupted during creation or transfer"
        exit 1
    fi
    log_success "Archive integrity verified"
    
    # Create temporary directory for extraction
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    
    log_info "Extracting backup archive..."
    tar -xzf "$BACKUP_SOURCE" -C "$TEMP_DIR"
    
    # Find the backup directory (should be only one)
    BACKUP_DIR=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -1)
    
    if [[ -z "$BACKUP_DIR" || ! -d "$BACKUP_DIR" ]]; then
        log_error "Invalid backup archive structure"
        exit 1
    fi
else
    log_error "Backup source not found: $BACKUP_SOURCE"
    log_error "Please provide either a .tar.gz archive or a backup directory"
    exit 1
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}          Flatpak Application Restore Tool             ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
log_info "Backup source: $BACKUP_SOURCE"
echo ""

# Check for manifest
MANIFEST_FILE="$BACKUP_DIR/backup-manifest.txt"
if [[ -f "$MANIFEST_FILE" ]]; then
    echo ""
    echo -e "${BLUE}Backup Manifest:${NC}"
    head -10 "$MANIFEST_FILE" | while IFS= read -r line; do
        echo "  $line"
    done
    echo ""
else
    log_info "No manifest file found (older backup format)"
fi

# Counter for statistics
RESTORED=0
SKIPPED=0
FAILED=0

# Function to restore a single app
restore_app() {
    local app_backup=$1
    local app_id=$(basename "$app_backup" .tar.gz)
    local app_path="$HOME/.var/app/$app_id"
    
    log_info "Restoring: $app_id"
    
    # Check if app already exists
    if [[ -d "$app_path" ]]; then
        read -p "  $app_id already exists. Overwrite? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_warning "$app_id: Skipped by user"
            ((SKIPPED++))
            return
        fi
        
        # Kill the app if running
        if command -v flatpak &> /dev/null; then
            flatpak kill "$app_id" 2>/dev/null || true
        fi
        
        # Backup existing data (just in case)
        local backup_old="$HOME/.flatpak-restore-backup-$(date +%s)"
        mv "$app_path" "$backup_old"
        log_info "$app_id: Existing data moved to $backup_old"
    fi
    
    # Extract the app backup
    if tar -xzf "$app_backup" -C "$HOME/.var/app" 2>&1 | grep -v "socket ignored"; then
        # Verify extraction was successful
        if [[ -d "$app_path" ]]; then
            # Fix permissions
            chown -R "$USER:$USER" "$app_path" 2>/dev/null || true
            
            log_success "$app_id restored"
            ((RESTORED++))
        else
            log_error "$app_id: Extraction completed but directory not found"
            ((FAILED++))
        fi
    else
        log_error "$app_id: Restore failed"
        ((FAILED++))
    fi
}

# Restore all apps
log_info "Starting restore process..."
echo ""

# Ensure target directory exists
mkdir -p "$HOME/.var/app"

# Restore each app
for app_backup in "$BACKUP_DIR"/*.tar.gz; do
    if [[ -f "$app_backup" ]]; then
        restore_app "$app_backup"
    fi
done

# Summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}                Restore Complete                        ${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✓${NC} Applications restored: $RESTORED"
echo -e "${YELLOW}⊘${NC} Skipped: $SKIPPED"
if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}✗${NC} Failed: $FAILED"
fi
echo ""

if [[ $RESTORED -gt 0 ]]; then
    echo -e "${YELLOW}Important:${NC}"
    echo "  • Launch the applications to verify everything works"
    echo "  • Your tabs, settings, and data should be restored"
    echo "  • If an app doesn't work, try:"
    echo "    ${BLUE}flatpak repair${NC}"
    echo "    ${BLUE}flatpak override --user --reset APP_ID${NC}"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
