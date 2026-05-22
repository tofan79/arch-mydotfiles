# Source CachyOS default config
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
~/.local/bin/mise activate fish | source
