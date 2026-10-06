alias aconf 'nano ~/.config/fish/aliases.fish'
alias ff 'fzf --preview \'bat {}\''
alias la 'eza --long --header --icons --git --no-user'
alias ls 'eza --icons'
alias rmd 'rm  --recursive --force --verbose'
alias refish 'exec fish'
alias pwrd 'systemctl poweroff'
alias pwrc 'systemctl reboot'

function cp --description 'cp -i; auto -r when a source is a directory (cp existing_dir new_dir works)'
    set -l opts -i
    for a in $argv
        if test -d $a
            set -a opts -r
            break
        end
    end
    command cp $opts $argv
end
alias mv 'mv -i'
alias ps 'ps auxf'
alias ping 'ping -c 10'
alias cls clear


alias home 'cd ~'
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias ..... 'cd ../../../..'


alias udc 'udisksctl'

alias edit 'neovide'

#### MISC ####
alias weather 'curl wttr.in'


#### FUNCTIONS ####
# (Machine-private VM helpers — win11, comfy — plus skillspector are autoloaded
#  from ~/.config/fish-local/functions when the private layer is present; see
#  the fish_function_path hook in config.fish.)

# mount
function mnt
	udisksctl mount -b /dev/$argv
end
# unmount
function umnt
	udisksctl unmount -b /dev/$argv
end

# mkdir and move 
function md
    mkdir $argv && cd $argv
end


# Run a nix app inside a bubblewrap sandbox: throwaway HOME/tmp, GUI still works.
# __play <extra-bwrap-args...> -- <pkg[:binary]> <pkg-args...>
# Use pkg:binary when the executable's name differs from the package attr,
# e.g. nodejs:node, ripgrep:rg, imagemagick:convert.
# If the spec is a path ending in .AppImage it's run through appimage-run
# instead (supplies the FHS loader NixOS lacks); the file is bound read-only
# and X11 is exposed, since linuxdeploy AppImages force GDK_BACKEND=x11.
#   play ~/Downloads/foo.AppImage        # with network
#   play-offline ~/Downloads/foo.AppImage  # no network
function __play
    set -l sep (contains -i -- -- $argv)
    set -l extra
    test $sep -gt 1; and set extra $argv[1..(math $sep - 1)]
    set -l spec $argv[(math $sep + 1)]
    set -l rest
    test (math $sep + 2) -le (count $argv); and set rest $argv[(math $sep + 2)..-1]
    set -l pkg
    set -l bin
    if string match -qir '\.appimage$' -- $spec
        set -l file (path resolve -- $spec)
        if not test -f "$file"
            echo "play: no such AppImage: $spec" >&2
            return 1
        end
        set pkg appimage-run
        set bin appimage-run
        set rest $file $rest
        set extra --ro-bind $file $file \
            --ro-bind-try /tmp/.X11-unix /tmp/.X11-unix --setenv DISPLAY "$DISPLAY" \
            $extra
    else
        set -l parts (string split -m1 : -- $spec)
        set pkg $parts[1]
        set bin $parts[2]
        test -z "$bin"; and set bin $pkg
    end
    set -l rt "/run/user/"(id -u)
    # NOTE: no --new-session on purpose. It setsid()s away the controlling
    # terminal, which breaks TUI apps (amfora, htop, …). Its only real benefit
    # is blocking TIOCSTI keystroke injection into the parent shell — already
    # disabled kernel-wide here (dev.tty.legacy_tiocsti = 0), so it's redundant.
    # Escape the caller-supplied tokens so paths with spaces/parens (common in
    # AppImage names) survive the bwrap command string.
    set -l tail (string escape -- $extra $bin $rest)
    nix-shell -p $pkg bubblewrap --run "bwrap \
        --unshare-all --die-with-parent \
        --ro-bind /nix /nix \
        --ro-bind /etc /etc \
        --ro-bind /run/current-system /run/current-system \
        --proc /proc --dev /dev --dev-bind /dev/dri /dev/dri \
        --ro-bind /sys /sys \
        --ro-bind /run/opengl-driver /run/opengl-driver \
        --ro-bind-try /run/opengl-driver-32 /run/opengl-driver-32 \
        --tmpfs /tmp \
        --tmpfs $HOME --setenv HOME $HOME \
        --tmpfs $rt --setenv XDG_RUNTIME_DIR $rt \
        --ro-bind $rt/$WAYLAND_DISPLAY $rt/$WAYLAND_DISPLAY \
        --ro-bind-try $rt/pipewire-0 $rt/pipewire-0 \
        $tail"
end

# Sandboxed + networked (default)
function play
    __play --share-net -- $argv
end

# Sandboxed, no network
function play-offline
    __play -- $argv
end

# Sandboxed + networked + NVIDIA (PRIME offload) for GPU apps.
# Pass --sdl as the first arg for SDL games: forces the Wayland/EGL backend so
# they skip GLX (which mismatches visuals under XWayland+PRIME) and actually
# land on the dGPU. e.g.  play-gpu --sdl neverball
function play-gpu
    set -l sdl
    if test "$argv[1]" = --sdl
        set sdl --setenv SDL_VIDEODRIVER wayland
        set argv $argv[2..-1]
    end
    __play --share-net \
        --dev-bind-try /dev/nvidia0 /dev/nvidia0 \
        --dev-bind-try /dev/nvidiactl /dev/nvidiactl \
        --dev-bind-try /dev/nvidia-modeset /dev/nvidia-modeset \
        --dev-bind-try /dev/nvidia-uvm /dev/nvidia-uvm \
        --dev-bind-try /dev/nvidia-uvm-tools /dev/nvidia-uvm-tools \
        --setenv __NV_PRIME_RENDER_OFFLOAD 1 \
        --setenv __GLX_VENDOR_LIBRARY_NAME nvidia \
        $sdl \
        -- $argv
end


# send filetype to destination
function to
    if test (count $argv) -ne 2
        echo "Usage: to <destination> <filetype>"
        return 1
    end

    set dest $argv[1]
    set type $argv[2]

    # Check if destination exists and is a directory
    if not test -d $dest
        echo "Error: Destination '$dest' is not a directory"
        return 1
    end

    # Check if any files of the specified type exist
    if not count *.{$type} >/dev/null
        echo "No files with extension .$type found"
        return 1
    end

    # Move all files of specified type to destination
    mv *.{$type} $dest/
    echo "Moved all .$type files to $dest"
end

# bat command output
alias alist 'alias | bat'
# read a file with bat, e.g. `r file.md`
alias r 'bat'
function o
	$argv | bat
end


# rename folder to folder.bak
function bak
    mv $argv{,.bak}
end


# kill all pids matching name
function ka
    for pid in (pidof $argv)
        kill $pid
    end
end


# shred then delete file
function wipe
    shred --verbose $argv && rm $argv
    echo "File '$argv' destroyed!"
end


# ---------------------------------------------------------------------------
# graft: move lines from one file into another
#   prepend [first N | last N] <source> <dest>   put at top of dest
#   append  [first N | last N] <source> <dest>   put at bottom of dest
#   replace [first N | last N] <source> <dest>   overwrite dest's content
# Omit the selector to use the whole source file.
# A blank line separates grafted text from dest's existing content
#   (after for prepend, before for append); pass -t/--tight to disable.
# replace keeps dest's inode & permissions (writes in place, doesn't cp over).
# ---------------------------------------------------------------------------
function __graft --description 'core for prepend/append/replace'
    set -l mode $argv[1]
    set -e argv[1]

    argparse h/help t/tight -- $argv
    or return 1

    if set -q _flag_help
        set -l where
        switch $mode
            case prepend; set where "the TOP of"
            case append;  set where "the BOTTOM of"
            case replace; set where "(overwrites)"
        end
        echo "$mode — graft lines from <source> onto $where <dest>"
        echo
        echo "Usage: $mode [first N | last N] [-t|--tight] <source> <dest>"
        echo
        echo "  first N / last N   take the first/last N lines of source"
        echo "                     (omit to use the whole source file)"
        echo "  -t, --tight        no blank-line separator between grafted"
        echo "                     and existing content (default: separate)"
        echo "  -h, --help         show this help"
        echo
        switch $mode
            case prepend
                echo "Examples:"
                echo "  $mode first 5 header.txt body.txt   # first 5 lines to the top"
                echo "  $mode intro.md article.md           # whole file to the top"
            case append
                echo "Examples:"
                echo "  $mode last 20 app.log archive.log   # last 20 lines to the end"
                echo "  $mode footer.txt page.html          # whole file to the end"
            case replace
                echo "replace keeps dest's inode & permissions (writes in place)."
                echo "Examples:"
                echo "  $mode first 100 new.csv data.csv    # dest becomes first 100 lines"
                echo "  $mode new.conf app.conf             # full overwrite"
        end
        return 0
    end

    # optional leading selector: `first N` | `last N`  (default: whole file)
    set -l selector all
    set -l count 0
    if test (count $argv) -ge 2; and contains -- $argv[1] first last
        set selector $argv[1]
        set count $argv[2]
        set -e argv[1..2]
        if not string match -qr '^[0-9]+$' -- $count
            echo "$mode: line count must be a non-negative integer, got '$count'" >&2
            return 1
        end
    end

    if test (count $argv) -ne 2
        echo "$mode: usage: $mode [first N | last N] <source> <dest>" >&2
        return 1
    end
    set -l src $argv[1]
    set -l dest $argv[2]

    if not test -f "$src"
        echo "$mode: source '$src' not found" >&2
        return 1
    end

    # Slice into a temp file first: decouples from src so source==dest is safe.
    set -l slice (mktemp)
    switch $selector
        case first
            head -n $count -- "$src" >$slice
        case last
            tail -n $count -- "$src" >$slice
        case '*'
            command cp -- "$src" $slice
    end

    set -l tmp (mktemp)
    switch $mode
        case prepend
            cat $slice >$tmp
            if not set -q _flag_tight; and test -s "$dest"
                echo "" >>$tmp
            end
            test -f "$dest"; and cat "$dest" >>$tmp
            cat $tmp >"$dest"
        case append
            if test -f "$dest"
                cat "$dest" >$tmp
                if not set -q _flag_tight; and test -s "$dest"
                    echo "" >>$tmp
                end
            end
            cat $slice >>$tmp
            cat $tmp >"$dest"
        case replace
            cat $slice >"$dest"   # `>` keeps dest's inode & permissions
    end

    rm -f $slice $tmp
end

function prepend --description 'graft source lines onto the top of dest'
    __graft prepend $argv
end
function append --description 'graft source lines onto the bottom of dest'
    __graft append $argv
end
function replace --description "overwrite dest's content with source (keeps dest's name/perms)"
    __graft replace $argv
end
