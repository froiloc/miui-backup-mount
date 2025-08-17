#!/bin/bash
#
# MIUI Backup Mount Utility
# Version: 1.0
VERSION="1.0"
# Description: Mounts MIUI .bak files as virtual filesystems
# Usage: ./miui_mount.sh [mount|unmount] file.bak [mountpoint]
#
# Author: Alexander Reintzsch, <firstname>.<lastname>(at)gmail.com
# License: GPLv3
# Dependencies: archivemount (optional), coreutils
#
# Examples:
#   ./miui-backup-mount.sh mount backup.bak
#   ./miui-backup-mount.sh unmount backup.bak

set -Eeuo pipefail  # Safer script execution
shopt -s inherit_errexit 2>/dev/null || true

# Configurable defaults
: "${PREMAGIC_SIZE:=257}"
: "${MAX_SEARCH:=1024}"
: "${DEBUG:=0}"

# Get the syntax for the colored output
COLOR_BLUE=$((tput bold; tput setaf 4) 2>/dev/null || tput setaf 4 2>/dev/null || echo '')
COLOR_RED=$((tput bold; tput setaf 1) 2>/dev/null || tput setaf 1 2>/dev/null || echo '')
COLOR_RESET=$(tput sgr0 2>/dev/null || echo '')

# How to use this script
function usage() {
    cat <<EOF
Usage: $0 [mount|unmount] <filename.bak> [mountpoint]

Options:
  mount     - Mount the MIUI backup as virtual filesystem
  unmount   - Unmount and clean up resources
  version   - Display the version

Environment VARIABLES:
  PREMAGIC_SIZE - Offset adjustment (default: 257)
  MAX_SEARCH    - Bytes to search for header (default: 1024)
  NO_COLOR      - Disable colored output (any value)
EOF
    exit 1
}

function show_version()
{
    echo "$(basename "$0") v$VERSION"
    exit 0
}

function _color_supported()
{
    # Check for:
    # 1. NO_COLOR env variable (standard: https://no-color.org/)
    # 2. Non-interactive terminal
    # 3. Terminal color capability
    [[ -z "${NO_COLOR:-}" ]] && [[ -t 1 ]] && command -v tput >/dev/null && tput colors >/dev/null 2>&1
}

function _color_print_if_possible()
{
    if _color_supported
    then
        echo -e "$*"
    else
        echo -e "$(echo "$*" | sed -E 's#\\(033|[Xx]1[Bb])\[[0-9;]+[mGK]##g')"
    fi
}

function log()
{
    _color_print_if_possible "$COLOR_BLUE[$(date '+%Y-%m-%d %H:%M:%S')]$COLOR_RESET $*"
}

function err()
{
    if [ "$1" == 'noexit' ]
    then
        shift
        _color_print_if_possible "$COLOR_RED[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:$COLOR_RESET $*" >&2
    else
        _color_print_if_possible "$COLOR_RED[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:$COLOR_RESET $*" >&2
        exit 1
    fi
}

function debug()
{
    (( DEBUG )) && log "DEBUG: $*" >&2
}

# Setup cleanup traps
function cleanup()
{
    echo "Performing cleanup..."
    
    # Unmount if mounted
    if mountpoint -q "$MOUNTPOINT"
    then
        fusermount -u "$MOUNTPOINT" 2>/dev/null || true
    fi
    
    # Remove mountpoint directory if empty
    [ -d "$MOUNTPOINT" ] && rmdir "$MOUNTPOINT" 2>/dev/null || true
    
    # Detach loop device if attached
    loopdev=$(losetup -j "$FILENAME" 2>/dev/null | awk -F: '{print $1}')
    if [ -n "$loopdev" ]
    then
        sudo losetup -d "$loopdev" 2>/dev/null || true
    fi
}

# find the magic number string "ustar"
function find_tar_offset()
{
    local filename=$1
    local max_search=${MAX_SEARCH:-1024}
    local magic="ustar"
    local premagicsize=${PREMAGIC_SIZE:-257}
    local magic_length=5  # Explicit length for binary safety
    
    if [ ! -r "$filename" ]
    then
        err "File '$filename' not found or not readable."
    fi
    
    # Use hexdump for binary-safe search
    local hex_pattern=$(echo -n "$magic" | xxd -p)
    local hexdump=$(hexdump -n $max_search -ve '1/1 "%.2x"' "$filename")
    
    # Find pattern position (each byte is 2 hex chars)
    local pos=$(echo "$hexdump" | grep -ob "$hex_pattern" | head -1 | cut -d: -f1)
    
    if [ -n "$pos" ]
    then
        echo $((pos/2 - premagicsize))  # Convert from hex char position to byte offset
        return 0
    else
        err "'$magic' magic string not found in first $max_search bytes."
    fi
}

# Check if it is a MIUI Backup file and display header
function display_backup_header()
{
    local filename="$1"
    local tar_offset=$(find_tar_offset "$filename")
    header="$(head -c $tar_offset "$filename")"
    if [ "$(head -n 1 <<<"$header")" == "MIUI BACKUP" ]
    then
        log "This is a MIUI Backup file." \
          "\nHeader:" \
          "\n  Type:    $(sed -n '2p' <<<"$header")" \
          "\n  App:     $(sed -n '3p' <<<"$header")" \
          "\n  Version: $(sed -n '6p;7p;8p' <<<"$header" | tr $'\n' ' ')"
    else
        err "This is NOT a MIUI Backup file."
    fi
}

function mount_backup()
{
    display_backup_header "$FILENAME"
    mkdir -p "$MOUNTPOINT"
    offset=$(find_tar_offset "$FILENAME" || (err "This file does not contain a tar header."))
    size=$(stat -c%s "$FILENAME")
    size=$(echo "$size - $offset" | bc -l)
    if (( $(echo "$size <= 0" | bc -l) ))
    then
        err "Invalid calculated size ($size) after offset adjustment"
    fi
    if mountpoint -q "$MOUNTPOINT"
    then
        err "$MOUNTPOINT is already a mountpoint. Abort!"
    else
        # Create virtual loop device
        loopdev=$(sudo losetup --find --show --offset $offset --sizelimit $size --read-only "$FILENAME" | awk -F: '{print $1}')
        [ -b "$loopdev" ] || err "Failed to create valid loop device"
        echo "Created loop-device: $loopdev"
        if command -v archivemount >/dev/null
        then
            if ! archivemount "$loopdev" "$MOUNTPOINT"
            then
                err noexit "Failed to mount tar archive at $MOUNTPOINT."
                if ! rmdir "$MOUNTPOINT"
                then
                    err "Failed to delete directory '$MOUNTPOINT'."
                fi
                exit 1
            fi
            # Remove traps after successful mount to prevent cleanup during normal unmount operations
            trap - TERM INT HUP
        else
            log "WARNING: The command 'archivemount' does not exist. Please install it." \
              "\nYou can work with the 'tar' command directly, though." \
              "\nList the tar's content with:" \
              "\n  tar -tf $loopdev"
        fi
    fi
}

function unmount_backup()
{
    if ( [ -e "$MOUNTPOINT" ] && mountpoint -q "$MOUNTPOINT" )
    then
        if fusermount -u "$MOUNTPOINT"
        then
            if ! rmdir "$MOUNTPOINT"
            then
                err "Failed to delete directory '$MOUNTPOINT'."
            fi
        else
            err "Failed to unmount $MOUNTPOINT."
        fi
    fi
    loopdev="$(losetup -j "$FILENAME" | awk -F: '{print $1}')"
    if [ -n "$loopdev" ]
    then
        # Remove the virtual loop device
        if ! sudo losetup -d "${loopdev}"
        then
            err "Failed to detach loop device ${loopdev}." \
              "\n       You may need to manually clean up with: sudo losetup -d ${loopdev}"
        fi
    else
        err "Loop device not found."
    fi
 }

function main()
{
    case $ACTION in
        mount)   mount_backup ;;
        unmount) unmount_backup ;;
        version) show_version ;;
        *)       usage ;;
    esac
}

# Register the cleanup function to run on these signals
trap cleanup TERM INT HUP

# Requires fuse2fs or similar FUSE tools
if [ $# -lt 2 ] && [ "$1" != "version" ]
then
    usage
    exit 1
fi

ACTION=$1
FILENAME=$2
MOUNTPOINT="${3:-"./${FILENAME%.*}.virtual.tar"}"

# At script start
REQUIRED_CMDS=(losetup awk grep stat bc fusermount mountpoint hexdump dd rmdir mkdir bash date sed tr xxd sudo head cut cat)
OPTIONAL_CMDS=(archivemount tput)
for cmd in "${REQUIRED_CMDS[@]}"
do
    command -v "$cmd" >/dev/null || err "Required command '$cmd' not found."
done

for cmd in "${OPTIONAL_CMDS[@]}"
do
    command -v "$cmd" >/dev/null || log "INFO: command '$cmd' not found. (optional for better mounting)"
done

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    main "$@"
fi
