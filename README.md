# MangoWM Arch/CachyOS Setup

Dotfiles + install scripts for Arch Linux and CachyOS (no DE edition).

## Phase 1 — System + GUI

```bash
cd arch-mydotfiles
chmod +x *.sh
./install.sh
```

Reboot, login to MangoWM (session pilih di SDDM).

## Phase 2 — Applications

```bash
./apps.sh
```

## Phase 3 — Gaming (Arch only)

```bash
./gaming.sh
```

CachyOS: skip, pake `cachyos-welcome` yang udah include.

## Arch vs CachyOS

| Step | Arch | CachyOS |
|------|------|---------|
| Mirrors | reflector | Skip |
| Pacman config | multilib + parallel | Skip |
| AUR helper | Install `paru` | Skip (include) |
| Repos | Chaotic-AUR | Skip |
| Snapper | Setup limits | Set limits only |
| NVIDIA | `nvidia` (auto-detect kernel) | Skip (pre-installed) |

## What's Included

- **WM**: MangoWM + Noctalia (AUR)
- **DM**: SDDM (X11, cursor works)
- **Shell**: Fish + zoxide + mise
- **Terminal**: Kitty (default)
- **Editor**: Neovim, Zed
- **Browser**: Zen Browser
- **File**: Nautilus + LocalSend extension
- **Multimedia**: FFmpeg, x264/x265, PipeWire, codecs (gst-libav, gst-plugins-*)
- **Tools**: Fastfetch, Eza, Bat, FZF, Yazi, Btop, Podman, Snapper, Git, Python/Pipx
- **Utils**: Grim (screenshot), Slurp (region), Brightnessctl, Cliphist, Wlsunset, Imagemagick, JQ
- **Fonts**: JetBrains Mono + Nerd Font, Font Awesome, Noto
- **GPU**: Mesa, Vulkan (ICD loader + tools), libva-utils, vdpauinfo
- **NVIDIA** (Arch): auto-detect kernel module (nvidia/nvidia-lts/etc) + utils
- **AUR**: Zen Browser, LocalSend, WebApp Manager
- **Gaming** (Arch): Steam, Gamemode, Gamescope, MangoHud, Wine
