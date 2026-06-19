# Tasks: remote-macOS-agents-setup

## Implementation Tasks

### Phase 1: Foundation

- [ ] **T1.1** Create `lib/colors.sh` — color variables and logging functions
- [ ] **T1.2** Create `lib/utils.sh` — common utility functions (prompt_yes_no, confirm, etc.)
- [ ] **T1.3** Create `lib/config.sh` — configuration management (load, save, defaults)

### Phase 2: Common Scripts

- [ ] **T2.1** Create `scripts/common/check-macos.sh` — verify macOS version
- [ ] **T2.2** Create `scripts/common/check-homebrew.sh` — verify Homebrew installation
- [ ] **T2.3** Create `scripts/common/check-git.sh` — verify Git installation
- [ ] **T2.4** Create `scripts/common/check-tailscale.sh` — verify Tailscale installation and login
- [ ] **T2.5** Create `scripts/common/check-ssh.sh` — verify SSH key pair exists
- [ ] **T2.6** Create `scripts/common/network-test.sh` — test connectivity between client/server

### Phase 3: Server Scripts

- [ ] **T3.1** Create `scripts/server/enable-ssh.sh` — enable SSH Remote Login on Mac Mini
- [ ] **T3.2** Create `scripts/server/install-tailscale.sh` — install and configure Tailscale on server
- [ ] **T3.3** Create `scripts/server/configure-panel.sh` — configure web panel settings

### Phase 4: Client Scripts

- [ ] **T4.1** Create `scripts/client/install-tailscale.sh` — install and configure Tailscale on laptop
- [ ] **T4.2** Create `scripts/client/setup-ssh.sh` — generate SSH keys and copy to server

### Phase 5: Main Scripts

- [ ] **T5.1** Create `setup.sh` — main interactive setup script with role detection
- [ ] **T5.2** Create `jobs.sh` — background job manager (list, start, stop, logs)

### Phase 6: Configuration

- [ ] **T6.1** Create `configs/sshd_config` — SSH server configuration template
- [ ] **T6.2** Create `jobs/example-job.sh` — example job template

### Phase 7: Documentation

- [ ] **T7.1** Update `AGENTS.md` — ensure documentation matches implementation
- [ ] **T7.2** Create `README.md` — quick start guide

### Phase 8: Testing

- [ ] **T8.1** Test `setup.sh` on client role (laptop)
- [ ] **T8.2** Test `setup.sh` on server role (Mac Mini)
- [ ] **T8.3** Test `jobs.sh` commands
- [ ] **T8.4** Verify SSH connection from client to server
- [ ] **T8.5** Verify Tailscale MagicDNS resolution

## Task Details

### T1.1: lib/colors.sh

```bash
# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Functions
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_warning() { echo -e "${YELLOW}!${NC} $1"; }
log_info() { echo -e "${BLUE}→${NC} $1"; }
log_header() { echo -e "\n${CYAN}═══ $1 ═══${NC}"; }
```

### T2.1: scripts/common/check-macos.sh

Check minimum macOS version (Sonoma 14.0):

```bash
#!/bin/bash
MIN_VERSION="14.0"
CURRENT_VERSION=$(sw_vers -productVersion)
# Compare versions...
```

### T3.1: scripts/server/enable-ssh.sh

Enable SSH Remote Login:

```bash
#!/bin/bash
sudo systemsetup -f setremotelogin on
```

### T5.1: setup.sh (main flow)

```
1. Load lib functions
2. Detect role (auto or prompt)
3. Show requirements for role
4. Ask user to confirm requirements
5. Verify requirements with check scripts
6. If verified:
   a. Server: run server setup scripts
   b. Client: run client setup scripts
7. Run connectivity tests
8. Show success message
```

## Verification Commands

After implementation, verify:

```bash
# Server verification
./scripts/server/enable-ssh.sh && echo "SSH OK"
tailscale status | grep "macmini" && echo "Tailscale OK"
curl localhost:8080 && echo "Panel OK"

# Client verification
ssh -o ConnectTimeout=5 user@macmini.tailnet.ts.net "echo OK" && echo "SSH OK"
tailscale ping macmini && echo "Tailscale VPN OK"
```

## Dependencies

```
Homebrew → Tailscale
         → Git
macOS built-in → SSH Remote Login
              → sw_vers
```
