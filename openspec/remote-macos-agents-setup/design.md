# Design: remote-macOS-agents-setup

## Script Architecture

```
setup.sh (main)
├── functions/load-config.sh      # Load configuration or create defaults
├── functions/detect-role.sh     # Auto-detect role based on hostname
├── functions/prompt-role.sh     # Ask user to select role
├── functions/check-all.sh       # Verify all requirements
│   ├── scripts/common/check-macos.sh
│   ├── scripts/common/check-homebrew.sh
│   ├── scripts/common/check-git.sh
│   ├── scripts/common/check-tailscale.sh
│   └── scripts/common/check-ssh.sh
├── setup-server.sh              # Server-specific setup
│   ├── scripts/server/enable-ssh.sh
│   ├── scripts/server/install-tailscale.sh
│   └── scripts/server/configure-panel.sh
├── setup-client.sh              # Client-specific setup
│   ├── scripts/client/install-tailscale.sh
│   └── scripts/client/setup-ssh.sh
└── tests/network-test.sh        # Connectivity tests
```

## Directory Structure

```
remote-macOS-agents/
├── setup.sh                  # Main entry point
├── jobs.sh                   # Job manager
├── lib/
│   ├── colors.sh             # Color variables and functions
│   ├── utils.sh              # Common utility functions
│   └── config.sh             # Config management
├── scripts/
│   ├── common/
│   │   ├── check-macos.sh
│   │   ├── check-homebrew.sh
│   │   ├── check-git.sh
│   │   ├── check-tailscale.sh
│   │   ├── check-ssh.sh
│   │   └── network-test.sh
│   ├── server/
│   │   ├── enable-ssh.sh
│   │   ├── install-tailscale.sh
│   │   └── configure-panel.sh
│   └── client/
│       ├── install-tailscale.sh
│       └── setup-ssh.sh
├── configs/
│   └── sshd_config
├── jobs/
│   └── example-job.sh        # Example job template
└── README.md
```

## Key Design Decisions

### 1. Role Detection

The script auto-detects the role based on hostname patterns:

```bash
detect_role() {
    local hostname=$(hostname)
    case "$hostname" in
        *mini*|*Mac-Mini*|*macmini*)
            echo "server"
            ;;
        *MacBook*|*Laptop*|*macbook*)
            echo "client"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}
```

### 2. Interactive Prompts

All user interactions use `read` with clear prompts:

```bash
prompt_yes_no() {
    local question="$1"
    local response
    while true; do
        read -p "$question [y/n]: " response
        case "$response" in
            y|Y) return 0 ;;
            n|N) return 1 ;;
            *) echo "Please answer y or n" ;;
        esac
    done
}
```

### 3. Color Output

Using a simple color system:

```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_warning() { echo -e "${YELLOW}!${NC} $1"; }
log_info() { echo -e "${BLUE}→${NC} $1"; }
```

### 4. SSH Key Management

**Server side:**

```bash
setup_server_ssh() {
    # Ensure .ssh directory exists with correct permissions
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Enable Remote Login via System Preferences
    sudo systemsetup -f setremotelogin on
    
    # Verify SSH is enabled
    if sudo systemsetup -getremotelogin | grep -q "On"; then
        log_success "SSH Remote Login enabled"
    fi
}
```

**Client side:**

```bash
setup_client_ssh() {
    # Generate SSH key if not exists
    if [[ ! -f ~/.ssh/id_ed25519 ]]; then
        ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f ~/.ssh/id_ed25519 -N ""
    fi
    
    # Copy public key to server
    SERVER_HOST="$1"
    ssh-copy-id -i ~/.ssh/id_ed25519.pub "$SERVER_USER@$SERVER_HOST"
}
```

### 5. Tailscale Configuration

**Installation:**

```bash
install_tailscale() {
    if ! command -v tailscale &> /dev/null; then
        log_info "Installing Tailscale..."
        brew install --cask tailscale
    fi
    
    # Start Tailscale
    sudo tailscaled install
    tailscale up --accept-routes
}
```

**MagicDNS setup:**

```bash
setup_magicdns() {
    local hostname="$1"
    tailscale set --hostname "$hostname"
    log_info "MagicDNS: https://${hostname}.tailnet.ts.net"
}
```

### 6. Connectivity Tests

```bash
test_connectivity() {
    local server_host="$1"
    local port="${2:-8080}"
    
    log_info "Testing SSH connection..."
    if ssh -o ConnectTimeout=5 "$server_host" "echo 'SSH OK'" &>/dev/null; then
        log_success "SSH connection successful"
    else
        log_error "SSH connection failed"
        return 1
    fi
    
    log_info "Testing web panel..."
    if curl -s --connect-timeout 5 "http://${server_host}:${port}" &>/dev/null; then
        log_success "Web panel reachable"
    else
        log_warning "Web panel not reachable (may not be running)"
    fi
}
```

### 7. Job Management

Jobs are managed as launchd agents or simple background processes:

```bash
# jobs.sh list
list_jobs() {
    echo "Configured jobs:"
    for job in jobs/*.sh; do
        [[ -f "$job" ]] || continue
        local name=$(basename "$job" .sh)
        local pid=$(pgrep -f "$job" 2>/dev/null)
        if [[ -n "$pid" ]]; then
            echo "  $name [running, PID: $pid]"
        else
            echo "  $name [stopped]"
        fi
    done
}
```

## Configuration Persistence

Configuration is stored in `~/.config/remote-macOS-agents/config`:

```bash
# ~/.config/remote-macOS-agents/config
ROLE=server
SERVER_HOSTNAME=macmini.tailnet.ts.net
SERVER_USER=pedro
PANEL_PORT=8080
```

## Error Handling Strategy

1. **Pre-flight checks**: Verify prerequisites before any destructive operation
2. **Non-destructive**: Script never overwrites user data; it only adds configs
3. **Rollback awareness**: Document manual steps to undo changes if needed
4. **Idempotent**: Safe to re-run; it will skip already-completed steps

## Security Considerations

1. **SSH keys only**: No password authentication
2. **Sudo elevation**: Only when necessary, with clear prompts
3. **Tailscale ACLs**: User should configure Tailscale ACLs to restrict access
4. **No secrets in repo**: All secrets (auth keys, etc.) stored in user home or keychain
