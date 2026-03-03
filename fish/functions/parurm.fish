mkdir -p ~/.config/fish/functions
cat > ~/.config/fish/functions/parurm.fish << 'EOF'
function parurm --description 'Remove package with paru and interactively clean user config files with fzf (trash-cli safe version)'
    if test (count $argv) -eq 0
        echo "Usage: parurm <package-name> [package2 ...]"
        echo "Example: parurm neovim hyprland foot"
        return 1
    end

    echo "🚀 Executing removal: paru -Rsn $argv"
    paru -Rsn $argv; or return $status

    printf '\n🧹 Starting interactive fuzzy search for configuration files across entire ~ directory...\n\n'

    for pkg in $argv
        set_color bryellow
        echo "━━ Processing package: $pkg ━━"
        set_color normal

        # Generate package name variants (supports -git / -bin etc.)
        set -l names $pkg
        set -l base (string replace -r '-(git|bin|git-bin)$' '' $pkg)
        if test "$base" != "$pkg"
            set -a names $base
        end
        set -a names (string lower $pkg) (string replace -a '-' '_' $pkg)

        # Search entire home directory (no exclusions at all)
        set -l candidates
        for name in $names
            set -l found (fd -H -t f -t d --max-depth 8 "$name" ~ 2>/dev/null)
            set -a candidates $found
        end

        set candidates (printf '%s\n' $candidates | sort -u)

        if test (count $candidates) -eq 0
            echo (set_color green)"✅ No configuration files found for $pkg."(set_color normal)
            continue
        end

        # Interactive selection with fzf
        printf '%s\n' $candidates | fzf --multi \
            --height 78% --border rounded --reverse \
            --prompt "Select files to move to trash for $pkg > " \
            --header "Tab: multi-select | Ctrl+A: select all | Enter: confirm | Esc: skip" \
            --bind 'ctrl-a:select-all' \
            --preview 'echo "📏 Size: $(du -sh {} 2>/dev/null | cut -f1)";
                       if [ -d "{}" ]; then
                         echo "📁 Directory preview:";
                         ls -la "{}" | head -15;
                       else
                         echo "📄 File preview:";
                         head -n 30 "{}" 2>/dev/null;
                       end' \
            --preview-window 'right:50%:wrap' \
        | xargs -r trash-put -v
    end

    set_color green
    printf '\n🎉 Cleanup completed! All selected files have been safely moved to the trash bin.\n'
    set_color normal
    echo "💡 Trash commands:"
    echo "   trash-list      →  List trashed files"
    echo "   trash-restore   →  Restore files"
    echo "   trash-empty     →  Empty trash"
end
