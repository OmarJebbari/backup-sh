#!/bin/bash

# =============================================================================
#  backup.sh — Advanced Automated Backup Script
#  Author   : Omar Jebbari
#  Version  : 2.0.0
# =============================================================================
#
#  USAGE:
#    ./backup.sh <target_directory> <destination_directory>
#
#  DESCRIPTION:
#    Scans <target_directory> for files modified in the last 24 hours,
#    compresses them into a timestamped .tar.gz archive, moves the archive
#    to <destination_directory>, and logs every step of the process.
#
#  FEATURES:
#    - Color-coded terminal output
#    - Rotating log file (keeps last 1000 lines)
#    - Email alert on failure (configure below)
#    - Config file support (~/.backup.conf)
#    - Dry-run mode (--dry-run flag)
#    - Summary report at the end
# =============================================================================

# ─────────────────────────────────────────────
#  CONFIGURATION — Override via ~/.backup.conf
# ─────────────────────────────────────────────
LOG_DIR="${HOME}/.backup_logs"
LOG_FILE="${LOG_DIR}/backup.log"
MAX_LOG_LINES=1000
EMAIL_ALERTS=false          # Set to true to enable email alerts
ALERT_EMAIL=""              # Set your email: "you@example.com"
DRY_RUN=false               # Overridden by --dry-run flag

# Load user config if it exists
CONFIG_FILE="${HOME}/.backup.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

# ─────────────────────────────────────────────
#  COLORS
# ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ─────────────────────────────────────────────
#  FLAGS
# ─────────────────────────────────────────────
for arg in "$@"; do
    if [[ "$arg" == "--dry-run" ]]; then
        DRY_RUN=true
    fi
done

# ─────────────────────────────────────────────
#  LOGGING
# ─────────────────────────────────────────────
mkdir -p "$LOG_DIR"

log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local log_entry="[$timestamp] [$level] $message"

    # Write to log file
    echo "$log_entry" >> "$LOG_FILE"

    # Print to terminal with color
    case "$level" in
        INFO)    echo -e "${CYAN}${log_entry}${RESET}" ;;
        SUCCESS) echo -e "${GREEN}${log_entry}${RESET}" ;;
        WARNING) echo -e "${YELLOW}${log_entry}${RESET}" ;;
        ERROR)   echo -e "${RED}${log_entry}${RESET}" ;;
        DRY)     echo -e "${BLUE}[DRY-RUN] ${log_entry}${RESET}" ;;
    esac

    # Rotate log — keep only last MAX_LOG_LINES lines
    if [[ $(wc -l < "$LOG_FILE") -gt $MAX_LOG_LINES ]]; then
        tail -n "$MAX_LOG_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp"
        mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
}

# ─────────────────────────────────────────────
#  EMAIL ALERT ON FAILURE
# ─────────────────────────────────────────────
send_alert() {
    local subject="$1"
    local body="$2"

    if [[ "$EMAIL_ALERTS" == true && -n "$ALERT_EMAIL" ]]; then
        if command -v mail &> /dev/null; then
            echo "$body" | mail -s "$subject" "$ALERT_EMAIL"
            log "INFO" "Alert email sent to $ALERT_EMAIL"
        else
            log "WARNING" "Email alerts enabled but 'mail' command not found"
        fi
    fi
}

# ─────────────────────────────────────────────
#  ERROR HANDLER
# ─────────────────────────────────────────────
handle_error() {
    local message="$1"
    log "ERROR" "$message"
    send_alert "[backup.sh] FAILED on $(hostname)" "$message"
    exit 1
}

# ─────────────────────────────────────────────
#  BANNER
# ─────────────────────────────────────────────
print_banner() {
    echo -e "${BOLD}${BLUE}"
    echo "============================================="
    echo "   backup.sh — Advanced Backup Script v2.0  "
    echo "=============================================${RESET}"
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}  *** DRY-RUN MODE — No files will be moved ***${RESET}"
        echo ""
    fi
}

# ─────────────────────────────────────────────
#  ARGUMENT VALIDATION
# ─────────────────────────────────────────────
validate_args() {
    # Strip --dry-run from argument count check
    local real_args=()
    for arg in "$@"; do
        [[ "$arg" != "--dry-run" ]] && real_args+=("$arg")
    done

    if [[ ${#real_args[@]} != 2 ]]; then
        echo -e "${RED}Usage: backup.sh <target_directory> <destination_directory> [--dry-run]${RESET}"
        handle_error "Incorrect number of arguments: expected 2, got ${#real_args[@]}"
    fi

    if [[ ! -d "${real_args[0]}" ]]; then
        handle_error "Target directory does not exist: '${real_args[0]}'"
    fi

    if [[ ! -d "${real_args[1]}" ]]; then
        handle_error "Destination directory does not exist: '${real_args[1]}'"
    fi
}

# =============================================================================
#  MAIN
# =============================================================================
main() {
    print_banner
    validate_args "$@"

    # ── [TASK 1] Set variables ──────────────────
    targetDirectory=$1
    destinationDirectory=$2

    # ── [TASK 2] Display values ─────────────────
    log "INFO" "Target Directory      : $targetDirectory"
    log "INFO" "Destination Directory : $destinationDirectory"
    log "INFO" "Log File              : $LOG_FILE"
    log "INFO" "Dry-Run Mode          : $DRY_RUN"

    # ── [TASK 3] Current timestamp ──────────────
    currentTS=$(date +%s)

    # ── [TASK 4] Backup filename ─────────────────
    backupFileName="backup-${currentTS}.tar.gz"
    log "INFO" "Backup archive name   : $backupFileName"

    # ── [TASK 5] Save original path ─────────────
    origAbsPath=$(pwd)

    # ── [TASK 6] Get destination absolute path ──
    cd "$destinationDirectory" || handle_error "Cannot cd into destination: $destinationDirectory"
    destAbsPath=$(pwd)
    log "INFO" "Destination Abs Path  : $destAbsPath"

    # ── [TASK 7] Go to target directory ─────────
    cd "$origAbsPath" || handle_error "Cannot return to original path: $origAbsPath"
    cd "$targetDirectory" || handle_error "Cannot cd into target: $targetDirectory"
    log "INFO" "Scanning files in     : $(pwd)"

    # ── [TASK 8] Calculate 24h ago timestamp ────
    yesterdayTS=$(( currentTS - 24 * 60 * 60 ))
    log "INFO" "Looking for files modified after: $(date -d @"$yesterdayTS" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -r "$yesterdayTS" "+%Y-%m-%d %H:%M:%S")"

    # ── [TASK 9-11] Find recently modified files ─
    declare -a toBackup

    for file in *; do                                           # [TASK 9]
        [[ -f "$file" ]] || continue                            # skip directories
        fileTS=$(date -r "$file" +%s 2>/dev/null) || continue   # skip unreadable
        if [[ $fileTS -gt $yesterdayTS ]]; then                 # [TASK 10]
            toBackup+=("$file")                                 # [TASK 11]
            log "INFO" "  + Queued for backup: $file (modified: $(date -r "$file" "+%Y-%m-%d %H:%M:%S"))"
        fi
    done

    # ── Summary check ────────────────────────────
    local file_count=${#toBackup[@]}
    log "INFO" "Files found for backup: $file_count"

    if [[ $file_count -eq 0 ]]; then
        log "WARNING" "No files were modified in the last 24 hours. Nothing to back up."
        exit 0
    fi

    # ── [TASK 12] Create archive ──────────────────
    if [[ "$DRY_RUN" == true ]]; then
        log "DRY" "Would create archive: $backupFileName"
        log "DRY" "Would include files : ${toBackup[*]}"
    else
        log "INFO" "Creating archive: $backupFileName ..."
        tar -czvf "$backupFileName" "${toBackup[@]}" >> "$LOG_FILE" 2>&1 \
            || handle_error "tar command failed while creating $backupFileName"
        log "SUCCESS" "Archive created successfully: $backupFileName"
    fi

    # ── [TASK 13] Move archive to destination ─────
    if [[ "$DRY_RUN" == true ]]; then
        log "DRY" "Would move $backupFileName → $destAbsPath/"
    else
        mv "$backupFileName" "$destAbsPath/" \
            || handle_error "Failed to move $backupFileName to $destAbsPath"
        log "SUCCESS" "Archive moved to: $destAbsPath/$backupFileName"
    fi

    # ── Final summary ─────────────────────────────
    echo ""
    echo -e "${BOLD}${GREEN}============================================="
    echo "   BACKUP COMPLETE"
    echo "=============================================${RESET}"
    echo -e "  ${BOLD}Files backed up :${RESET} $file_count"
    echo -e "  ${BOLD}Archive         :${RESET} $destAbsPath/$backupFileName"
    echo -e "  ${BOLD}Log file        :${RESET} $LOG_FILE"
    echo -e "  ${BOLD}Timestamp       :${RESET} $(date "+%Y-%m-%d %H:%M:%S")"
    echo ""
}

main "$@"
