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
- **Editor**: Neovim
- **Tools**: Fastfetch, Eza, Bat, FZF, Yazi, Podman
- **Multimedia**: FFmpeg, PipeWire, codecs
- **Gaming** (Arch): Steam, Gamemode, Gamescope, MangoHud, Wine
- **Browser**: Zen Browser
- **File**: Nautilus + LocalSend extension
