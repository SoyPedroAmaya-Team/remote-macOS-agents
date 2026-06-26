# =============================================================================
# Zsh Configuration
# Managed by chezmoi - edits go to source, then apply
# =============================================================================

# Initialize starship prompt
eval "$(starship init zsh)"

# Extend PATH
export PATH="$PATH:$HOME/.local/bin"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# User bin
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Postgres (managed separately via Homebrew)
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f $HOME/.dart-cli-completion/zsh-config.zsh ]] && . $HOME/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

# =============================================================================
# Aliases
# =============================================================================

# SSH shortcuts
alias vps='ssh -i $HOME/Tech/seguridad/ssh/pedro root@158.220.116.111'
alias andrew='ssh andrew@100.64.26.17'

# Meta CLI
alias meta="$HOME/.local/meta-ads-env/bin/meta"

# =============================================================================
# Machine-specific configuration (chezmoi template)
# =============================================================================

# Hostname-aware aliases (uncomment and customize if needed)
# if [[ "{{ .chezmoi.hostname }}" == "macmini" ]]; then
#     alias serv='ssh pedro@macmini.local'
# fi

# =============================================================================
# Environment variables
# =============================================================================

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Options
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
