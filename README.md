# MangoWM Arch/CachyOS Setup — Daily Driver

Dotfiles + install scripts for Arch Linux and CachyOS (no DE edition).

**CachyOS:** Pilih `CachyOS-Desktop-Linux` — semua base package sudah include. Script auto-detect CachyOS dan skip step yang tidak perlu.

---

## Struktur

```
arch-mydotfiles/
├── install.sh                # — System, codec, printing, ASUS, WM, shell
├── apps.sh                   # — Aplikasi harian + dev tools
├── gaming.sh                 # — Gaming stack (Arch only, CachyOS auto-skip)
├── dotfiles/                 # Config files (~/.config/)
│   ├── btop/                 # Config btop
│   ├── clean/clean.sh        # System cleanup script (jalan manual)
│   ├── fish/                 # Fish shell config
│   ├── gtk-3.0/, gtk-4.0/   # GTK theme
│   ├── kitty/                # Kitty terminal + scripts + themes
│   ├── mango/                # MangoWM config (autostart, keybinds)
│   ├── noctalia/             # Noctalia shell config + colorschemes + plugins
│   ├── nvim/                 # Neovim config
│   ├── qt5ct/, qt6ct/        # Qt theme
│   ├── telegram-desktop/     # Telegram themes
│   ├── xdg-desktop-portal/   # Portal config
│   ├── yazi/                 # Yazi file manager config
│   ├── zed/                  # Zed editor config
│   └── zen/                  # Zen browser config
├── docker-db/                # Docker compose template untuk database
├── Wallpapers/               # Wallpaper collection
└── README.md
```

### Urutan Install

```bash
chmod +x install.sh apps.sh
./install.sh        # → reboot
./apps.sh           # setelah login desktop
```

CachyOS: `gaming.sh` skip otomatis — gaming packages sudah include via `cachyos-gaming-meta`.

---

## Script Details

### install.sh

Preflight → mirrors/pacman → repos → packages → codecs → NVIDIA → firewalld → printing → ASUS → MangoWM → dotfiles → shell → cleanup.

#### Arch vs CachyOS

| Step | Arch | CachyOS |
|------|------|---------|
| Mirrors | reflector | Skip (optimized) |
| Pacman config | multilib + parallel | Skip |
| AUR helper | Install `paru` | Skip (include) |
| Repos | Chaotic-AUR | Skip (include) |
| NVIDIA | `nvidia` (auto-detect kernel) | Skip (pre-installed) |
| Gaming | `gaming.sh` separate | Skip (cachyos-gaming-meta) |

#### System Packages

| Kategori | Packages |
|----------|----------|
| **Kernel** | linux-firmware, wireless-regdb |
| **Xorg** | xorg-xwayland |
| **Mesa/Vulkan** | mesa, vulkan-icd-loader, vulkan-tools, libglvnd |
| **Audio** | pipewire, pipewire-alsa, pipewire-pulse, pipewire-jack, wireplumber, playerctl, pamixer |
| **Wayland Qt** | qt5-wayland, qt6-wayland |
| **Networking** | networkmanager, wpa_supplicant |
| **Build tools** | cmake, meson, ninja |
| **Filesystem** | exfatprogs, ntfs-3g, btrfs-progs, cifs-utils, dosfstools |
| **System utils** | smartmontools, lsof, pciutils, usbutils, bc, tree, unzip, zip, logrotate, tcpdump, chrony |
| **GVFS** | gvfs-afc, gvfs-afp, gvfs-archive, gvfs-fuse, gvfs-goa, gvfs-gphoto2, gvfs-smb, gvfs-mtp |

#### Core Tools

| Package | Fungsi |
|---------|--------|
| fish | Default shell |
| kitty | Default terminal |
| git, curl, wget, rsync | Tools dasar |
| eza, bat, fzf, zoxide | Shell enhancement |
| fastfetch, btop | System info + monitoring |
| neovim, python, python-pip, pipx | Dev + package management |
| podman, podman-docker, podman-compose | Container (docker-compatible) |

#### Multimedia Codecs

ffmpeg, x264, x265, libdvdcss, gst-libav, gst-plugins-good, gst-plugins-bad, gst-plugins-ugly

#### Fonts

ttf-jetbrains-mono, ttf-jetbrains-mono-nerd, ttf-firacode-nerd, otf-font-awesome, noto-fonts, noto-fonts-emoji

#### Printing Stack

cups, cups-filters, cups-browsed, cups-pk-helper, cups-pdf, ghostscript, gutenprint, gutenprint-cups, hplip, colord, nss-mdns, system-config-printer, system-config-printer-udev, foomatic, foomatic-db-ppds, a2ps, enscript, paps, pnm2ppa, ptouch-driver, splix, samba-client

#### ASUS TUF

- asusctl + asusd (fan profile, battery charge limit)
- rog-control-center (GUI)
- power-profiles-daemon (conflict check: disable tlp/auto-cpufreq/tuned)

#### NVIDIA (Arch only)

- Auto-detect kernel module (nvidia / nvidia-lts / nvidia-zen / nvidia-hardened)
- nvidia-utils, nvidia-settings, egl-wayland, libva-nvidia-driver
- prime-run wrapper di `/usr/local/bin`
- CachyOS: skip — NVIDIA pre-installed

#### Firewall (firewalld)

- Port 53317 TCP+UDP (LocalSend)
- mDNS service (network discovery)

#### MangoWM + Noctalia (dari AUR)

- mangowm-git, noctalia-shell
- Dependencies: qt5ct, qt6ct, grim, slurp, brightnessctl, cliphist, wlsunset, ImageMagick, jq, libinput, libxkbcommon, seatd, xdg-desktop-portal-wlr, xdg-desktop-portal-gtk

#### SDDM

- SDDM (X11, cursor works)
- Wayland=false, X11=true, autologin user
- Cursor: Bibata-Modern-Ice
- Theme: Tela-nord-dark, Bibata-Modern-Ice
- Disable conflicting DMs: gdm, lightdm, lxdm, greetd, plasmalogin
- Default target: graphical.target

#### Dotfiles

Semua config di `dotfiles/` dicopy ke `~/.config/`. Backup otomatis config lama ke `~/.config-backup-{timestamp}/`.

---

### apps.sh

#### Core Apps

| Kategori | Packages |
|----------|----------|
| **File** | nautilus, nautilus-python, yazi, gnome-disk-utility, nautilus-admin-git (AUR) |
| **Media** | mpv, imv, pavucontrol-qt, loupe, tesseract + tesseract-data-eng, ImageMagick |
| **Chat** | telegram-desktop |
| **Editor** | zed |
| **Thumbnailer** | gnome-epub-thumbnailer, totem-video-thumbnailer, glycin-thumbnailer |
| **Browser** | zen-browser-bin (AUR) |
| **Transfer** | localsend-bin (AUR) |
| **Portal** | xdg-desktop-portal-gtk, python-gobject |

#### Dev Tools

| Kategori | Packages |
|----------|----------|
| **Editor/Shell** | tmux |
| **Search** | ripgrep, fd-find |
| **Monitor** | tree, ncdu |
| **Network** | httpie, net-tools, bind-utils, whois, traceroute, mtr, socat, nmap |
| **Compress** | p7zip |
| **Lint** | shellcheck |
| **Debug** | valgrind, strace, ltrace |

#### Nautilus LocalSend

Extension Python — kirim file via LocalSend dari context menu Nautilus. Auto-detect binary `localsend`.

#### Terminal Fix

Desktop entry btop, nvim, yazi dibungkus `kitty -e` agar tidak pake terminal default.

#### Podman

`podman.socket` di-enable — docker-compose compatibility.

---

### gaming.sh (Arch Only)

CachyOS: **auto-skip** (exit 0). Gaming packages sudah include via `cachyos-gaming-meta`.

| Package | Sumber |
|---------|--------|
| gamemode | multilib |
| gamescope | community |
| mangohud | community |
| steam | multilib |
| wine, winetricks | multilib |
| vkbasalt | community |
| goverlay | community |

---

## Dotfiles Config

| Folder | Isi |
|--------|-----|
| `btop/` | Config system monitor |
| `clean/clean.sh` | System cleanup script (jalan manual) |
| `fish/` | Aliases, zoxide, fzf, prompt |
| `gtk-3.0/`, `gtk-4.0/` | GTK dark theme |
| `kitty/` | Config, themes, scripts, sessions |
| `mango/` | Keybinds, autostart, rules, layouts |
| `noctalia/` | Colorschemes, plugins, settings |
| `nvim/` | Neovim config |
| `qt5ct/`, `qt6ct/` | Qt theme |
| `telegram-desktop/` | Telegram theme |
| `xdg-desktop-portal/` | Portal config |
| `yazi/` | File manager config |
| `zed/` | Zed editor config |
| `zen/` | Zen browser config |

---

## Tips

```bash
# Update sistem
sudo pacman -Syu

# Cleanup system
bash ~/.config/clean/clean.sh

# Runtime via mise
mise use --global node@22
mise use --global go@latest
mise use --global rust@stable

# NVIDIA prime-run (Arch only)
prime-run steam

# MangoHud
MANGOHUD=1 prime-run <game>

# ASUS fan profile
asusctl profile -P Quiet
asusctl profile -P Balanced
asusctl profile -P Performance

# Battery charge limit
asusctl -c 80

# ROG Center GUI
rog-control-center
```

## Catatan

1. **Secure Boot** — Disable di BIOS sebelum install di Arch (NVIDIA kernel module). Script cek otomatis via `mokutil`.
2. **Fish shell** — Default shell. Config di `~/.config/fish/config.fish`.
3. **MangoWM + Noctalia** — Dari AUR (mangowm-git, noctalia-shell). Session: `MangoWM`.
4. **BTRFS / Snapper** — CachyOS sudah handle snapshot. Tidak dikonfigurasi ulang.
5. **CachyOS** — Gaming, NVIDIA, mirrors, dan repositori sudah pre-configured. Script skip otomatis.
6. **Tela icon theme** — Install via GitHub release, variant `nord`.
7. **Bibata cursor** — Dari AUR (bibata-cursor-theme-bin).
8. **clean.sh** — Ada di `dotfiles/clean/clean.sh`. Jalankan manual untuk cleanup cache.

## Referensi

- [CachyOS](https://cachyos.org/)
- [MangoWM](https://github.com/DreamMaoMao/mango)
- [Noctalia Shell](https://github.com/ifurther/noctalia-shell)
- [Chaotic-AUR](https://aur.chaotic.cx/)
