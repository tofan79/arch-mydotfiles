#!/usr/bin/env bash
# MangoWM Arch/CachyOS Installation Script
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}/dotfiles"
WALLPAPERS_DIR="${SCRIPT_DIR}/Wallpapers"
LOG_FILE="${SCRIPT_DIR}/install.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}[INFO]${NC}  $*"; }
log_ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_err()  { echo -e "${RED}[ERROR]${NC} $*"; }

if [[ -f "$LOG_FILE" ]]; then
    mv "$LOG_FILE" "${LOG_FILE}.old.$(date +%Y%m%d%H%M%S)"
fi

exec > >(tee -a "$LOG_FILE") 2>&1
log_info "Logging to: ${LOG_FILE}"
trap 'log_err "Failed at line ${LINENO}: ${BASH_COMMAND}"' ERR

OS_ID=""
OS_NAME=""
IS_CACHYOS=false
IS_ARCH=false
AUR_HELPER=""

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="${ID:-unknown}"
        OS_NAME="${NAME:-unknown}"
        case "${ID:-}" in
            arch|archlinux)
                IS_ARCH=true
                ;;
            cachyos)
                IS_CACHYOS=true
                IS_ARCH=true
                ;;
            *)
                log_err "Unsupported OS: ${ID:-unknown}. This script is for Arch Linux and CachyOS only."
                exit 1
                ;;
        esac
        log_ok "Detected: ${OS_NAME} (${OS_ID})"
    else
        log_err "Cannot detect operating system."
        exit 1
    fi
}

detect_aur_helper() {
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    else
        AUR_HELPER=""
    fi
}

install_aur_helper() {
    if [[ -n "$AUR_HELPER" ]]; then
        log_ok "AUR helper already installed: ${AUR_HELPER}"
        return 0
    fi

    log_info "Installing paru (AUR helper)..."
    sudo pacman -S --needed --noconfirm base-devel git
    local temp_dir="/tmp/paru-build"
    rm -rf "$temp_dir"
    git clone --depth 1 https://aur.archlinux.org/paru.git "$temp_dir"
    (cd "$temp_dir" && makepkg -si --noconfirm)
    rm -rf "$temp_dir"
    AUR_HELPER="paru"
    log_ok "paru installed."
}

pacman_install() {
    local pkgs=()
    for pkg in "$@"; do
        if pacman -Si "$pkg" &>/dev/null || pacman -Qg "$pkg" &>/dev/null; then
            pkgs+=("$pkg")
        else
            log_warn "Package '$pkg' not found in any repository. Skipping."
        fi
    done
    if [[ ${#pkgs[@]} -gt 0 ]]; then
        sudo pacman -S --needed --noconfirm --ask 4 "${pkgs[@]}"
    fi
}

aur_install() {
    if [[ -n "$AUR_HELPER" ]]; then
        "$AUR_HELPER" -S --needed --noconfirm "$@"
    else
        log_err "No AUR helper found. Cannot install: $*"
        return 1
    fi
}

is_pkg_installed() {
    pacman -Q "$1" &>/dev/null
}

setup_mirrors() {
    if [[ "$IS_CACHYOS" == "true" ]]; then
        log_ok "CachyOS: mirrors already optimized. Skipping."
        return 0
    fi

    log_info "Setting up mirrors with reflector..."
    if ! command -v reflector &>/dev/null; then
        pacman_install reflector
    fi

    sudo reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || {
        log_warn "Reflector failed. Using default mirrors."
    }
    log_ok "Mirrors configured."
}

configure_pacman() {
    if [[ "$IS_CACHYOS" == "true" ]]; then
        log_ok "CachyOS: pacman already optimized. Skipping."
        return 0
    fi

    log_info "Configuring pacman..."
    local conf="/etc/pacman.conf"
    local needs_update=false

    if ! grep -q "^Color" "$conf" 2>/dev/null; then
        sudo sed -i 's/^#Color/Color/' "$conf"
        needs_update=true
    fi

    if ! grep -q "^ParallelDownloads" "$conf" 2>/dev/null; then
        sudo sed -i '/^#ParallelDownloads/a ParallelDownloads = 10' "$conf"
        needs_update=true
    fi

    if ! grep -q "^VerbosePkgLists" "$conf" 2>/dev/null; then
        sudo sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' "$conf"
        needs_update=true
    fi

    if ! grep -q "^\[multilib\]" "$conf" 2>/dev/null; then
        sudo sed -i '/^#\[multilib\]/s/^#//' "$conf"
        sudo sed -i '/^#Include = \/etc\/pacman.d\/mirrorlist/s/^#//' "$conf"
        needs_update=true
    fi

    if [[ "$needs_update" == "true" ]]; then
        sudo pacman -Sy --noconfirm 2>/dev/null || true
        log_ok "Pacman configured."
    else
        log_ok "Pacman already configured."
    fi
}

add_repositories() {
    if [[ "$IS_CACHYOS" == "true" ]]; then
        log_ok "CachyOS: repositories already configured (CachyOS + Chaotic-AUR)."
        return 0
    fi

    log_info "Adding Chaotic-AUR repository..."
    if [[ -f /etc/pacman.conf ]] && grep -q "\[chaotic-aur\]" /etc/pacman.conf 2>/dev/null; then
        log_ok "Chaotic-AUR already configured."
    else
        sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com 2>/dev/null || true
        sudo pacman-key --lsign-key 3056513887B78AEB 2>/dev/null || true

        if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf 2>/dev/null; then
            sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 2>/dev/null || true
            sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' 2>/dev/null || true

            local chaotic_conf="
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
"
            echo "$chaotic_conf" | sudo tee -a /etc/pacman.conf > /dev/null
        fi

        sudo pacman -Sy --noconfirm 2>/dev/null || true
        log_ok "Chaotic-AUR added."
    fi
}

preflight_checks() {
    log_info "Running preflight checks..."
    detect_os

    if [[ "$(id -u)" -eq 0 ]]; then
        log_err "Do not run this script as root. Run as a regular user with sudo access."
        exit 1
    fi

    if ! sudo -n true 2>/dev/null; then
        log_warn "This script requires sudo privileges."
        sudo -v
    else
        log_ok "Sudo privileges available."
    fi

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_err "Dotfiles directory not found at ${DOTFILES_DIR}"
        exit 1
    fi

    detect_aur_helper
    if [[ -z "$AUR_HELPER" ]]; then
        install_aur_helper
    fi

    if mokutil --sb-state 2>/dev/null | grep -qi "enabled"; then
        log_warn "============================================"
        log_warn " SECURE BOOT IS ENABLED!"
        log_warn " NVIDIA kernel modules may FAIL to load."
        log_warn " Disable Secure Boot in BIOS/UEFI first."
        log_warn "============================================"
        read -rp "Continue anyway? [y/N]: " sb_response
        case "$sb_response" in
            [Yy]*) log_warn "Proceeding with Secure Boot enabled." ;;
            *)     log_err "Install cancelled. Disable Secure Boot first."; exit 1 ;;
        esac
    else
        log_ok "Secure Boot: disabled"
    fi

    local conflict_found=0
    for svc in tlp auto-cpufreq tuned; do
        if systemctl is-enabled "${svc}.service" &>/dev/null 2>&1; then
            log_warn "Detected: ${svc} — may conflict with power-profiles-daemon."
            conflict_found=1
        fi
    done
    if [[ "$conflict_found" -eq 1 ]]; then
        log_warn "Consider disabling conflicting services before install."
        read -rp "Continue anyway? [Y/n]: " conflict_response
        case "$conflict_response" in
            [Nn]*) log_err "Install cancelled."; exit 1 ;;
        esac
    fi

    log_ok "Preflight checks passed."
}

install_packages() {
    log_info "Installing system packages..."

    local core_pkgs=(
        base-devel git curl wget rsync
        linux-firmware
        networkmanager wpa_supplicant wireless-regdb
        mesa vulkan-icd-loader vulkan-tools
        libglvnd
        pipewire pipewire-alsa pipewire-pulse pipewire-jack
        wireplumber playerctl pamixer
        libva-utils vdpauinfo
        qt5-wayland qt6-wayland
        xorg-xwayland
        eza python python-pip python-pipx fastfetch
        kitty
        neovim bat fzf snapper zoxide
        btop podman podman-docker podman-compose
        acpid
        grim slurp brightnessctl cliphist wlsunset
        imagemagick jq
        libinput libxkbcommon seatd
        noto-fonts-emoji gtk4
    )

    if [[ "$IS_CACHYOS" == "true" ]]; then
        log_info "CachyOS: detecting kernel..."
        local kernel=""
        if pacman -Q linux-cachyos &>/dev/null 2>&1; then
            kernel="linux-cachyos"
        elif pacman -Q linux-cachyos-lts &>/dev/null 2>&1; then
            kernel="linux-cachyos-lts"
        elif pacman -Q linux &>/dev/null 2>&1; then
            kernel="linux"
        fi

        if [[ -n "$kernel" ]]; then
            core_pkgs+=("${kernel}-headers")
        fi
    else
        core_pkgs+=(linux-headers)
    fi

    if is_pkg_installed jack; then
        log_info "Replacing jack with pipewire-jack..."
        sudo pacman -Rdd --noconfirm jack 2>/dev/null || true
    fi

    pacman_install "${core_pkgs[@]}"

    if [[ "$IS_CACHYOS" == "true" ]]; then
        pacman_install cachyos-settings 2>/dev/null || true
    fi

    local font_pkgs=(
        ttf-jetbrains-mono ttf-jetbrains-mono-nerd
        otf-font-awesome noto-fonts
    )
    pacman_install "${font_pkgs[@]}" 2>/dev/null || true

    pacman_install adw-gtk-theme 2>/dev/null || true

    pacman_install power-profiles-daemon

    log_ok "All packages installed."
}

install_multimedia() {
    log_info "Installing multimedia codecs..."

    local multimedia_pkgs=(
        ffmpeg x264 x265
        libdvdcss
        gst-libav gst-plugins-good gst-plugins-bad gst-plugins-ugly
    )
    pacman_install "${multimedia_pkgs[@]}"

    log_ok "Multimedia codecs installed."
}

install_nvidia() {
    if [[ "$IS_CACHYOS" == "true" ]]; then
        log_ok "CachyOS: NVIDIA pre-installed. Skipping."
        return 0
    fi

    if is_pkg_installed nvidia-dkms || is_pkg_installed nvidia; then
        log_ok "NVIDIA already installed. Skipping."
        modinfo nvidia &>/dev/null 2>&1 && log_ok "Module loaded" || \
            log_warn "Module not loaded — reboot required"
        setup_prime_run
        return 0
    fi

    read -rp "Install NVIDIA drivers? [Y/n]: " response
    case "$response" in
        [Nn]*) log_warn "Skipping NVIDIA."; return 0 ;;
    esac

    log_info "Installing NVIDIA drivers..."

    local kernel=""
    if pacman -Q linux &>/dev/null 2>&1; then
        kernel="linux"
    elif pacman -Q linux-lts &>/dev/null 2>&1; then
        kernel="linux-lts"
    elif pacman -Q linux-zen &>/dev/null 2>&1; then
        kernel="linux-zen"
    elif pacman -Q linux-hardened &>/dev/null 2>&1; then
        kernel="linux-hardened"
    fi
    local nvidia_pkg="${kernel:+"nvidia-${kernel#linux-}"}"
    nvidia_pkg="${nvidia_pkg:-nvidia}"

    pacman_install "$nvidia_pkg" nvidia-utils nvidia-settings
    pacman_install egl-wayland 2>/dev/null || true
    pacman_install libva-nvidia-driver 2>/dev/null || true

    log_info "Rebuilding initramfs..."
    sudo mkinitcpio -P 2>/dev/null || true
    log_ok "initramfs rebuilt."

    log_info "Verifying NVIDIA..."
    if nvidia-smi &>/dev/null 2>&1; then
        log_ok "NVIDIA loaded: $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo OK)"
    elif modinfo -F version nvidia &>/dev/null 2>&1; then
        log_warn "Module exists but not loaded (normal before reboot)"
    else
        log_warn "Module not found — check after reboot"
    fi

    setup_prime_run
}

setup_prime_run() {
    if command -v prime-run &>/dev/null; then
        log_ok "prime-run already available."
        return 0
    fi

    log_warn "prime-run not found. Creating wrapper..."
    sudo tee /usr/local/bin/prime-run > /dev/null << 'PRIMEEOF'
#!/bin/bash
__NV_PRIME_RENDER_OFFLOAD=1 \
__NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0 \
__GLX_VENDOR_LIBRARY_NAME=nvidia \
__VK_LAYER_NV_optimus=NVIDIA_only \
"$@"
PRIMEEOF
    sudo chmod +x /usr/local/bin/prime-run
    log_ok "prime-run wrapper created."
}

configure_firewalld() {
    log_info "Configuring firewalld..."

    if ! command -v firewall-cmd &>/dev/null; then
        pacman_install firewalld
    fi

    if ! systemctl is-active firewalld &>/dev/null; then
        sudo systemctl enable --now firewalld 2>/dev/null || true
        log_ok "firewalld enabled and started."
    else
        log_ok "firewalld already running."
    fi

    if firewall-cmd --list-ports 2>/dev/null | grep -q "53317"; then
        log_ok "Firewall: port 53317 already open."
    else
        sudo firewall-cmd --permanent --add-port=53317/tcp 2>/dev/null || true
        sudo firewall-cmd --permanent --add-port=53317/udp 2>/dev/null || true
        sudo firewall-cmd --reload 2>/dev/null || true
        log_ok "Firewall: port 53317 opened (LocalSend)."
    fi

    if firewall-cmd --list-services 2>/dev/null | grep -q "mdns"; then
        log_ok "Firewall: mDNS already allowed."
    else
        sudo firewall-cmd --permanent --add-service=mdns 2>/dev/null || true
        sudo firewall-cmd --reload 2>/dev/null || true
        log_ok "Firewall: mDNS service added."
    fi
}

install_snapper() {
    if ! findmnt -n -o FSTYPE / | grep -q btrfs; then
        log_warn "Root filesystem is not BTRFS. Skipping snapper."
        return 0
    fi

    if ! command -v snapper &>/dev/null; then
        log_warn "Snapper not installed. Skipping."
        return 0
    fi

    if snapper list-configs 2>/dev/null | grep -q "^root"; then
        log_ok "Snapper config 'root' already exists."
    else
        sudo snapper -c root create-config / 2>/dev/null || \
            log_warn "Snapper config might already exist."
        log_ok "Snapper root config created."
    fi

    log_info "Setting snapper limits (max 10 total)..."
    sudo snapper -c root set-config \
        NUMBER_LIMIT=10 \
        NUMBER_LIMIT_IMPORTANT=5 \
        TIMELINE_CREATE=yes \
        TIMELINE_CLEANUP=yes \
        TIMELINE_LIMIT_HOURLY=3 \
        TIMELINE_LIMIT_DAILY=7 \
        TIMELINE_LIMIT_WEEKLY=0 \
        TIMELINE_LIMIT_MONTHLY=0 \
        TIMELINE_LIMIT_YEARLY=0

    sudo systemctl enable --now snapper-timeline.timer
    sudo systemctl enable --now snapper-cleanup.timer

    log_ok "Snapper configured. Max 10 snapshots."
}

install_mangowm() {
    log_info "Installing MangoWM and Noctalia..."

    if is_pkg_installed mangowm-git || is_pkg_installed mangowm; then
        log_ok "MangoWM already installed. Skipping."
        install_sddm
        return 0
    fi

    read -rp "Install MangoWM + Noctalia? [Y/n]: " response
    case "$response" in
        [Nn]*)
            log_warn "Skipping MangoWM/Noctalia."
            install_sddm
            return 0
            ;;
    esac

    aur_install mangowm-git noctalia-shell 2>/dev/null || {
        log_warn "MangoWM/Noctalia not found in AUR. Installing from source..."
        log_info "Please check https://github.com/mangowm/mangowm for manual install."
        install_sddm
        return 0
    }

    pacman_install \
        qt5ct qt6ct \
        xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
        libdisplay-info 2>/dev/null || true

    pacman_install \
        sddm qt6-declarative qt6-svg

    log_ok "MangoWM + Noctalia installed."

    install_sddm
}

install_sddm() {
    log_info "Configuring SDDM..."

    if ! is_pkg_installed sddm; then
        pacman_install sddm qt6-declarative qt6-svg || {
            log_warn "SDDM installation failed."
            return 0
        }
    fi

    sudo mkdir -p /etc/sddm.conf.d

    local current_user="${USER:-$(whoami)}"

    if [[ -f /etc/sddm.conf.d/10-mango.conf ]]; then
        log_ok "SDDM already configured. Skipping."
    else
        sudo tee /etc/sddm.conf.d/10-mango.conf > /dev/null << SDDMEOF
[General]
InputMethod=none
Numlock=on
DefaultUser=$current_user

[Theme]
Current=

[Wayland]
Enable=false

[X11]
Enable=true
SDDMEOF
        log_ok "SDDM configured — username: $current_user"
    fi

    if systemctl is-enabled sddm.service &>/dev/null 2>&1; then
        log_ok "SDDM service already enabled."
    else
        sudo systemctl enable sddm --force
        log_ok "SDDM enabled."
    fi

    sudo systemctl set-default graphical.target
    log_ok "Default target: graphical.target"

    for dm in gdm lightdm lxdm greetd plasmalogin; do
        if systemctl is-enabled "${dm}.service" &>/dev/null 2>&1; then
            log_info "Disabling conflicting display manager: ${dm}"
            sudo systemctl disable "${dm}.service" || true
        fi
    done

    log_ok "SDDM complete."
}

install_tela_icon_theme() {
    log_info "Checking for Tela icon theme..."

    if ls ~/.local/share/icons/Tela* &>/dev/null 2>&1 || \
       ls /usr/share/icons/Tela* &>/dev/null 2>&1; then
        log_ok "Tela icon theme already installed. Skipping."
        return 0
    fi

    if ! command -v git &>/dev/null; then
        log_warn "git not installed. Skipping Tela."
        return 0
    fi

    local temp_dir="/tmp/tela-icon-theme"
    rm -rf "$temp_dir"
    if git clone --depth 1 https://github.com/vinceliuice/Tela-icon-theme.git "$temp_dir" 2>/dev/null; then
        (cd "$temp_dir" && ./install.sh -a) 2>/dev/null || log_warn "Tela install failed"
        rm -rf "$temp_dir"
        log_ok "Tela icon theme installed."
    else
        log_warn "Failed to clone Tela. Skipping."
    fi
}

copy_dotfiles() {
    log_info "Copying dotfiles to ~/.config/..."
    mkdir -p ~/.config

    local dirs=(
        gtk-3.0 gtk-4.0 kitty mango
        nvim qt5ct qt6ct yazi zed clean
        btop xdg-desktop-portal
    )

    local backup_dir=""
    local has_existing=false
    for dir in "${dirs[@]}"; do
        if [[ -d "${HOME}/.config/${dir}" ]]; then
            has_existing=true
            break
        fi
    done
    if [[ "$has_existing" == "true" ]]; then
        backup_dir="${HOME}/.config-backup-$(date +%Y%m%d%H%M%S)"
        mkdir -p "$backup_dir"
    fi

    for dir in "${dirs[@]}"; do
        local src="${DOTFILES_DIR}/${dir}"
        local dst="${HOME}/.config/${dir}"

        if [[ -d "$src" ]]; then
            if [[ -d "$dst" ]] && [[ -n "$backup_dir" ]]; then
                mv "$dst" "${backup_dir}/${dir}"
                log_info "Backed up ${dir}"
            fi
            cp -r "$src" "$dst"
            log_ok "Copied ${dir}"
        else
            log_warn "Source not found: ${src} (skip)"
        fi
    done

    if [[ -d "$backup_dir" ]]; then
        log_ok "Old configs backed up to: ${backup_dir}"
    fi
    log_ok "Dotfiles copied."
}

copy_wallpapers() {
    if [[ ! -d "$WALLPAPERS_DIR" ]]; then
        log_warn "Wallpapers directory not found. Skipping."
        return 0
    fi

    local dst="${HOME}/Pictures/Wallpapers"
    mkdir -p "$dst"
    cp -r "${WALLPAPERS_DIR}"/* "$dst/"
    log_ok "Wallpapers copied to ${dst}"
}

copy_user_dirs() {
    if [[ -f "${DOTFILES_DIR}/user-dirs.dirs" ]]; then
        cp "${DOTFILES_DIR}/user-dirs.dirs" ~/.config/user-dirs.dirs
        log_ok "user-dirs.dirs copied."
    fi
}

setup_shell() {
    if [[ "$IS_CACHYOS" == "true" ]]; then
        if ! command -v fish &>/dev/null; then
            log_warn "Fish not found on CachyOS. Installing..."
            pacman_install fish
        else
            log_ok "Fish already installed (CachyOS default)."
        fi
    else
        pacman_install fish
    fi

    if ! command -v fish &>/dev/null; then
        log_warn "Fish not installed. Skipping shell setup."
        return 0
    fi

    log_info "Configuring Fish..."

    mkdir -p ~/.config/fish

    if [[ -f ~/.config/fish/config.fish ]]; then
        cp ~/.config/fish/config.fish ~/.config/fish/config.fish.bak.$(date +%Y%m%d) 2>/dev/null || true
    fi

    cat > ~/.config/fish/config.fish << FISHEOF
# Source CachyOS default config if present
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

if status is-interactive
    # Eza
    alias ls='eza --icons'
    alias ll='eza -lah --icons'
    alias la='eza -a --icons'
    alias lt='eza --tree --icons'

    # Bat
    alias cat='bat --style=plain'

    # Apps
    alias op='opencode'
    alias cc='claude'
    alias y='yazi'
    alias nv='nvim'

    # Docker
    alias d='docker'
    alias dc='docker compose'
    alias dps='docker ps'
    alias dpa='docker ps -a'
    alias di='docker images'
    alias dex='docker exec -it'
    alias dlog='docker logs -f'

    # System
    alias update='sudo pacman -Syu'
    alias clean='sudo pacman -Rns (pacman -Qtdq) 2>/dev/null; sudo pacman -Scc --noconfirm'
    alias cleanfd='~/.config/clean/clean.sh'

    # FZF
    set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'
    set -gx FZF_CTRL_R_OPTS '--height 40% --layout=reverse --border'
    set -gx FZF_CTRL_T_OPTS '--height 40% --layout=reverse --border'

    # Zoxide
    if command -v zoxide &>/dev/null
        zoxide init fish | source
    end

end
FISHEOF

    log_ok "Fish configured."

    local fish_path
    fish_path=$(command -v fish)
    if [[ "$SHELL" != "$fish_path" ]]; then
        sudo chsh -s "$fish_path" "$USER" || log_warn "chsh failed — manual: chsh -s $fish_path"
        log_ok "Fish set as default shell."
    else
        log_ok "Fish already default shell."
    fi
}

setup_mise() {
    log_info "Installing mise..."
    if command -v mise &>/dev/null; then
        log_ok "mise already installed."
        return 0
    fi

    curl https://mise.run | sh 2>/dev/null || {
        log_warn "mise install failed"
        return 0
    }
    log_ok "mise installed."

    local mise_line='~/.local/bin/mise activate fish | source'
    if grep -q "mise activate fish" ~/.config/fish/config.fish 2>/dev/null; then
        log_ok "mise already in fish config."
    else
        echo "$mise_line" >> ~/.config/fish/config.fish
        log_ok "mise added to fish config."
    fi
}

set_kitty_default() {
    log_info "Setting Kitty as default terminal..."

    if ! command -v kitty &>/dev/null; then
        log_warn "Kitty not installed. Skipping."
        return 0
    fi

    sudo ln -sf /usr/bin/kitty /usr/local/bin/x-terminal-emulator 2>/dev/null || true

    local kde_desktop_file="/usr/share/applications/org.kde.konsole.desktop"
    if [[ -f "$kde_desktop_file" ]]; then
        sudo mv "$kde_desktop_file" "${kde_desktop_file}.disabled" 2>/dev/null || true
    fi

    local gnome_desktop_file="/usr/share/applications/org.gnome.Terminal.desktop"
    if [[ -f "$gnome_desktop_file" ]]; then
        sudo mv "$gnome_desktop_file" "${gnome_desktop_file}.disabled" 2>/dev/null || true
    fi

    log_ok "Kitty set as default terminal."
}

create_user_folders() {
    log_info "Creating standard user folders..."

    local folders=(
        "$HOME/Downloads"
        "$HOME/Documents"
        "$HOME/Pictures"
        "$HOME/Music"
        "$HOME/Videos"
        "$HOME/Desktop"
    )

    for folder in "${folders[@]}"; do
        if [[ ! -d "$folder" ]]; then
            mkdir -p "$folder"
            log_ok "Created: $folder"
        fi
    done

    log_ok "User folders created."
}

cleanup() {
    log_info "Cleaning up..."
    if command -v paru &>/dev/null; then
        paru -Scc --noconfirm 2>/dev/null || true
    fi
    sudo pacman -Rns "$(pacman -Qtdq 2>/dev/null)" --noconfirm 2>/dev/null || true
    log_ok "Cleanup complete."
}

main() {
    preflight_checks
    setup_mirrors
    configure_pacman
    add_repositories
    install_packages
    install_multimedia
    install_nvidia
    configure_firewalld
    install_snapper
    install_mangowm
    install_tela_icon_theme
    aur_install bibata-cursor-theme-bin 2>/dev/null || log_warn "Bibata cursor not installed."
    copy_dotfiles
    copy_wallpapers
    copy_user_dirs
    setup_shell
    setup_mise
    set_kitty_default
    create_user_folders
    cleanup

    echo ""
    log_ok "========================================"
    log_ok " Installation complete!"
    log_ok "========================================"
    echo ""
    log_info "Log: ${LOG_FILE}"
    echo ""
    log_info "After reboot:"
    log_info "  - SDDM login screen (not TTY)"
    log_info "  - Select session: MangoWM"
    echo ""
    log_info "NVIDIA (AMD iGPU default, NVIDIA on-demand):"
    log_info "  Verifikasi   : nvidia-smi"
    log_info "  Jalankan app : prime-run <app>"
    echo ""
    if [[ "$IS_CACHYOS" == "false" ]]; then
        log_info "BTRFS Snapshots (snapper):"
        log_info "  Lihat        : snapper list"
        log_info "  Rollback     : snapper undochange <pre>..<post>"
        echo ""
    fi
    log_info "Reboot: sudo reboot"
    echo ""
}

main "$@"
