#!/bin/bash
# clean.sh — System cleanup for Arch/CachyOS

echo "========================================="
echo "        ARCH/CACHYOS SYSTEM CLEANUP"
echo "========================================="

echo -e "\n[1/9] Pacman cache (keep latest 2 versions)..."
sudo paccache -rk2 2>/dev/null && echo "  ✔ Cache cleaned" || echo "  ⚠ paccache not found (install pacman-contrib)"

echo -e "\n[2/9] Orphan packages..."
sudo pacman -Rns "$(pacman -Qtdq 2>/dev/null)" --noconfirm 2>/dev/null && echo "  ✔ Orphans removed" || echo "  ✔ No orphans"

echo -e "\n[3/9] mise cache..."
rm -rf ~/.local/share/mise/http-tarballs/* 2>/dev/null && echo "  ✔ mise tarballs cleaned"
mise cache clear 2>/dev/null && echo "  ✔ mise cache cleared"

echo -e "\n[4/9] JetBrains Toolbox cache..."
rm -rf ~/.local/share/JetBrains/Toolbox/cache/* 2>/dev/null && echo "  ✔ Toolbox cache cleaned"
rm -rf ~/.cache/JetBrains/* 2>/dev/null && echo "  ✔ JetBrains cache cleaned"

echo -e "\n[5/9] System temp..."
sudo rm -rf /tmp/* 2>/dev/null
sudo rm -rf /var/tmp/* 2>/dev/null
sudo journalctl --vacuum-time=3d 2>/dev/null && echo "  ✔ Old journal logs cleaned"

echo -e "\n[6/9] Trash..."
rm -rf ~/.local/share/Trash/* 2>/dev/null && echo "  ✔ Trash cleaned"

echo -e "\n[7/9] Browser cache..."
rm -rf ~/.cache/zen-browser/* 2>/dev/null && echo "  ✔ Zen Browser cache cleaned"

echo -e "\n[8/9] History + ZSH cache + npm..."
> ~/.bash_history 2>/dev/null && echo "  ✔ bash history cleared"
rm -f ~/.zcompdump* 2>/dev/null && echo "  ✔ ZSH compdump cache cleared"
rm -rf ~/.npm/* 2>/dev/null && echo "  ✔ npm cache cleared"
rm -rf ~/.cache/thumbnails/* 2>/dev/null && echo "  ✔ Thumbnail cache cleaned"
paru -Scc --noconfirm 2>/dev/null && echo "  ✔ AUR helper cache cleaned"

echo -e "\n========================================="
echo "           CLEANUP COMPLETE"
echo "========================================="
