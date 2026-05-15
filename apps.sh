#!/usr/bin/env bash
# apps.sh — Install applications for Arch/CachyOS + MangoWM
# Run after install.sh + desktop login
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/apps.log"

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
            arch|archlinux|cachyos) return 0 ;;
            *)
                log_err "Unsupported OS: ${ID:-unknown}. This script is for Arch Linux and CachyOS only."
                exit 1
                ;;
        esac
    else
        log_err "Cannot detect operating system."
        exit 1
    fi
}

pacman_install() { sudo pacman -S --needed --noconfirm "$@"; }

detect_aur_helper() {
    if command -v paru &>/dev/null; then
        echo "paru"
    elif command -v yay &>/dev/null; then
        echo "yay"
    else
        echo ""
    fi
}

install_apps() {
    log_info "Installing applications..."

    pacman_install \
        nautilus nautilus-python yazi mpv imv \
        gnome-disk-utility \
        pavucontrol \
        tesseract tesseract-data-eng \
        imagemagick ffmpeg \
        libmtp gvfs-mtp \
        xdg-desktop-portal-gtk \
        python-gobject \
        telegram-desktop zed 2>/dev/null || true

    local aur_helper
    aur_helper=$(detect_aur_helper)
    if [[ -n "$aur_helper" ]]; then
        "$aur_helper" -S --needed --noconfirm zen-browser-bin localsend-bin webapp-manager-git 2>/dev/null || log_warn "AUR packages failed — try manual: paru -S zen-browser-bin localsend-bin webapp-manager-git"
    else
        log_warn "No AUR helper. Install manually: paru -S zen-browser-bin localsend-bin webapp-manager-git"
    fi

    log_ok "Core apps installed."
}

install_nautilus_localsend() {
    local ext_dir="${HOME}/.local/share/nautilus-python/extensions"
    local ext_file="${ext_dir}/localsend.py"

    if [[ -f "$ext_file" ]]; then
        log_ok "Nautilus LocalSend extension already exists."
        return 0
    fi

    log_info "Installing Nautilus LocalSend extension..."
    mkdir -p "$ext_dir"

    cat > "$ext_file" << 'NAUTEXTEOF'
import os
import shutil

from gi import require_version

require_version("Nautilus", "4.1")

from gi.repository import GObject, Gio, Nautilus


class SendViaLocalSendAction(GObject.GObject, Nautilus.MenuProvider):
    def _launch_localsend(self, paths):
        command = self._resolve_command()
        if not command:
            return

        if command[-1] == "@@":
            command = command + paths + ["@@"]
        else:
            command = command + paths

        Gio.Subprocess.new(command, Gio.SubprocessFlags.NONE)

    def _resolve_command(self):
        localsend = shutil.which("localsend")
        if localsend:
            return [localsend, "--headless", "send"]

        flatpak = shutil.which("flatpak")
        if flatpak and self._has_flatpak_app(flatpak, "org.localsend.localsend_app"):
            return [
                flatpak,
                "run",
                "--file-forwarding",
                "org.localsend.localsend_app",
                "@@",
            ]

        return None

    def _has_flatpak_app(self, flatpak, app_id):
        process = Gio.Subprocess.new(
            [flatpak, "info", app_id],
            Gio.SubprocessFlags.STDOUT_SILENCE | Gio.SubprocessFlags.STDERR_SILENCE,
        )
        return process.wait_check()

    def _selected_paths(self, files):
        paths = []
        for file in files:
            location = file.get_location()
            if not location:
                continue
            path = location.get_path()
            if path and path not in paths:
                paths.append(path)
        return paths

    def _make_item(self, paths):
        label = "Send via LocalSend" if len(paths) == 1 else "Send selected via LocalSend"
        item = Nautilus.MenuItem(
            name="LocalSendNautilus::send_via_localsend",
            label=label,
            icon="localsend",
        )
        item.connect("activate", self._on_activate, paths)
        return item

    def _on_activate(self, _menu, paths):
        self._launch_localsend(paths)

    def get_file_items(self, *args):
        files = args[0] if len(args) == 1 else args[1]
        paths = self._selected_paths(files)
        if not paths or not self._resolve_command():
            return []
        return [self._make_item(paths)]
NAUTEXTEOF

    chmod +x "$ext_file"
    log_ok "Nautilus LocalSend extension installed."
}

fix_terminal_desktop() {
    local apps=(btop nvim yazi)
    mkdir -p ~/.local/share/applications
    for app in "${apps[@]}"; do
        local src="/usr/share/applications/${app}.desktop"
        local dst="$HOME/.local/share/applications/${app}.desktop"
        if [[ -f "$src" ]] && ! grep -q "kitty" "$dst" 2>/dev/null; then
            cp "$src" "$dst"
            sed -i 's|^Exec=\(.*\)$|Exec=kitty -e \1|' "$dst"
            sed -i 's/^Terminal=true/Terminal=false/' "$dst"
            log_ok "Fixed desktop: ${app} (kitty)"
        fi
    done
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
    install_apps
    install_nautilus_localsend
    fix_terminal_desktop

    echo ""
    log_ok "========================================"
    log_ok " Apps installation complete!"
    log_ok "========================================"
    echo ""
    log_info "Log: ${LOG_FILE}"
    echo ""
}

main "$@"
