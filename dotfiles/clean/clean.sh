#!/bin/bash
# clean.sh — System cleanup for Arch/CachyOS

echo "========================================="
echo "        ARCH/CACHYOS SYSTEM CLEANUP"
echo "========================================="

echo -e "\n[1/9] Pacman cache (keep latest 2 versions)..."
sudo paccache -rk2 2>/dev/null && echo "  ✔ Cache cleaned" || echo "  ⚠ paccache not found (install pacman-contrib)"

echo -e "\n[2/9] Orphan packages..."
sudo pacman -Rns "$(pacman -Qtdq 2>/dev/null)" --noconfirm 2>/dev/null && echo "  ✔ Orphans removed" || echo "  ✔ No orphans"

echo -e "\n[3/9] AUR + dev caches..."
[[ -d ~/.cache/yay ]] && rm -rf ~/.cache/yay/* && echo "  ✔ yay cache cleaned"
[[ -d ~/.cache/paru ]] && rm -rf ~/.cache/paru/* && echo "  ✔ paru cache cleaned"
paru -Scc --noconfirm 2>/dev/null && echo "  ✔ paru AUR cache cleaned"
[[ -d ~/.cache/go-build ]] && rm -rf ~/.cache/go-build/* && echo "  ✔ Go build cache cleaned"
[[ -d ~/.cache/pip ]] && rm -rf ~/.cache/pip && echo "  ✔ pip cache cleaned"
[[ -d ~/.cache/npm ]] && rm -rf ~/.cache/npm/* && echo "  ✔ npm cache cleared"

echo -e "\n[4/9] mise cache..."
rm -rf ~/.local/share/mise/http-tarballs/* 2>/dev/null && echo "  ✔ mise tarballs cleaned"
mise cache clear 2>/dev/null && echo "  ✔ mise cache cleared"

echo -e "\n[5/9] JetBrains Toolbox cache..."
rm -rf ~/.local/share/JetBrains/Toolbox/cache/* 2>/dev/null && echo "  ✔ Toolbox cache cleaned"
rm -rf ~/.cache/JetBrains/* 2>/dev/null && echo "  ✔ JetBrains cache cleaned"

echo -e "\n[6/9] System temp..."
sudo rm -rf /tmp/* 2>/dev/null
sudo rm -rf /var/tmp/* 2>/dev/null
sudo journalctl --vacuum-time=3d 2>/dev/null && echo "  ✔ Old journal logs cleaned"

echo -e "\n[7/9] Trash..."
rm -rf ~/.local/share/Trash/* 2>/dev/null && echo "  ✔ Trash cleaned"

echo -e "\n[8/9] Browser cache..."
[[ -d ~/.cache/brave-browser ]] && rm -rf ~/.cache/brave-browser/* && echo "  ✔ Brave cache cleaned"
[[ -d ~/.cache/zen ]] && rm -rf ~/.cache/zen/* && echo "  ✔ Zen cache cleaned"
[[ -d ~/.cache/chromium ]] && rm -rf ~/.cache/chromium/* && echo "  ✔ Chromium cache cleaned"

echo -e "\n[9/9] History + thumbnails..."
[[ -f ~/.bash_history ]] && > ~/.bash_history && echo "  ✔ bash history cleared"
[[ -f ~/.local/share/fish/fish_history ]] && > ~/.local/share/fish/fish_history && echo "  ✔ fish history cleared"
rm -rf ~/.cache/thumbnails/* 2>/dev/null && echo "  ✔ Thumbnail cache cleaned"

echo -e "\n========================================="
echo "           CLEANUP COMPLETE"
echo "========================================="
