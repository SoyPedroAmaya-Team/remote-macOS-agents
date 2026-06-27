# =============================================================================
# Zsh Configuration
# Managed by chezmoi - edits go to source, then apply
# =============================================================================

# Initialize starship prompt
eval "$(starship init zsh)"

# =============================================================================
# PATH Configuration
# =============================================================================

# Homebrew paths FIRST (have priority)
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

# User bin directories
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# pnpm (Homebrew version - not ~/.local/pnpm)
# Remove any old pnpm installations that might conflict
if [[ -d "$HOME/Library/pnpm" ]] && [[ -d "/opt/homebrew/bin" ]]; then
    # Only use Homebrew pnpm, ignore local installation
    unset PNPM_HOME
fi

# =============================================================================
# Shell Options
# =============================================================================

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Options
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
