# =============================================================================
# Zsh Configuration
# Managed by chezmoi - edits go to source, then apply
# =============================================================================

# Initialize starship prompt
eval "$(starship init zsh)"

# =============================================================================
# PATH Configuration
# =============================================================================

# Extend PATH (avoid duplicates)
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/bin"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# Postgres (managed via Homebrew)
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

# Antigravity IDE (if installed)
if [[ -d "$HOME/.antigravity-ide/antigravity-ide/bin" ]]; then
    export PATH="$HOME/.antigravity-ide/antigravity-ide/bin:$PATH"
fi

# =============================================================================
# Completions
# =============================================================================

# Dart CLI completion
[[ -f $HOME/.dart-cli-completion/zsh-config.zsh ]] && . $HOME/.dart-cli-completion/zsh-config.zsh || true

# =============================================================================
# Aliases
# =============================================================================

# SSH shortcuts
alias vps='ssh -i $HOME/Tech/seguridad/ssh/pedro root@158.220.116.111'
alias andrew='ssh andrew@100.64.26.17'

# Meta CLI
alias meta="$HOME/.local/meta-ads-env/bin/meta"

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
