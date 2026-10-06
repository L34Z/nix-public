if status is-interactive
    # Fresh top-level kitty window: jump straight into an interactive
    # zoxide picker. Esc leaves you at a normal prompt.
    if set -q KITTY_WINDOW_ID; and test "$SHLVL" -eq 1
        zi
    end
end



set -U fish_greeting

# Route SSH (and ssh-add, git, etc.) to the 1Password SSH agent
set -gx SSH_AUTH_SOCK $HOME/.1password/agent.sock

oh-my-posh init fish --config ~/.config/fish/tokyonight_storm.omp.json | source
source ~/.config/fish/aliases.fish
zoxide init fish | source
direnv hook fish | source

# Machine-private functions (win11, comfy, skillspector, …) live in a separate
# managed dir the private layer populates. Autoload them by name when present;
# absent on a public-only box, this is a no-op. The dir is a SIBLING of the
# fish config symlink so home-manager can manage it independently.
if test -d $HOME/.config/fish-local/functions
    set -gp fish_function_path $HOME/.config/fish-local/functions
end

# (tty autostart removed: greetd/tuigreet on tty1 now launches the session —
# Hyprland via uwsm or niri via niri-session; see modules/greeter.nix)
export PATH="$HOME/.local/bin:$PATH"
