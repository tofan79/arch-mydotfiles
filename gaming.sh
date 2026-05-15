#!/usr/bin/env bash
# gaming.sh — Install gaming stack for Arch/CachyOS + MangoWM
# Run after install.sh + apps.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/gaming.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}[INFO]${NC}  $*"; }
log_ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_err()  { echo -e "${RED}[ERROR]${NC} $*"; }

exec > >(tee -a "$LOG_FILE") 2>&1
log_info "Logging to: ${LOG_FILE}"
trap 'log_err "Failed at line ${LINENO}: ${BASH_COMMAND}"' ERR

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "${ID:-}" in
            cachyos)
                log_info "CachyOS detected — gaming packages handled by cachyos-welcome. Skipping."
                exit 0
                ;;
            arch|archlinux) return 0 ;;
            *)
                log_err "Unsupported OS. This script is for Arch Linux only."
                exit 1
                ;;
        esac
    else
        log_err "Cannot detect operating system."
        exit 1
    fi
}

pacman_install() { sudo pacman -S --needed --noconfirm "$@"; }

install_gaming_packages() {
    log_info "Installing gaming packages..."

    pacman_install \
        gamemode \
        gamescope \
        mangohud \
        wine winetricks \
        vkbasalt 2>/dev/null || {
        log_warn "Some packages failed — retrying..."
        pacman_install gamemode gamescope mangohud wine winetricks 2>/dev/null || true
    }

    pacman_install goverlay 2>/dev/null || log_warn "goverlay unavailable — skip"

    log_ok "Gaming packages installed."
}

install_steam() {
    log_info "Steam — install from multilib..."
    pacman_install steam 2>/dev/null || log_warn "Steam install failed"
    log_info "  NVIDIA launch options: prime-run %command%"
    log_info "  Gamemode: gamemoderun %command%"
    log_info "  Combined: prime-run gamemoderun %command%"
}

install_mangohud_config() {
    local cfg_dir="${HOME}/.config/MangoHud"
    local cfg_file="${cfg_dir}/MangoHud.conf"

    if [[ -f "$cfg_file" ]]; then
        log_ok "MangoHud config already exists. Skipping."
        return 0
    fi

    log_info "Creating MangoHud config..."
    mkdir -p "$cfg_dir"

    cat > "$cfg_file" << 'MANGOEOF'
legacy_layout=false
horizontal
gpu_stats
gpu_temp
cpu_stats
cpu_temp
ram
fps
frametime=0
hud_no_margin
table_columns=3
font_size=24
MANGOEOF

    log_ok "MangoHud config created."
}

configure_gamemode() {
    if ! pacman -Q gamemode &>/dev/null; then
        log_warn "gamemode not installed. Skipping."
        return 0
    fi

    systemctl --user enable --now gamemoded 2>/dev/null || log_warn "gamemoded user service already running or failed"
    log_ok "gamemode configured."
}

preflight_checks() {
    log_info "Running preflight checks..."
    if [[ "$(id -u)" -eq 0 ]]; then
        log_err "Do not run as root."
        exit 1
    fi
    detect_os
    log_ok "Preflight checks passed."
}

main() {
    preflight_checks
    install_gaming_packages
    install_steam
    install_mangohud_config
    configure_gamemode

    echo ""
    log_ok "========================================"
    log_ok " Gaming setup complete!"
    log_ok "========================================"
    echo ""
    log_info "Log: ${LOG_FILE}"
    echo ""
    log_info "Steam launch for NVIDIA + gamemode:"
    log_info "  prime-run gamemoderun %command%"
    echo ""
}

main "$@"
