# Spec: remote-macOS-agents-setup

## Overview

Bash-based setup system for a two-machine macOS remote workflow.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Tailscale VPN                          │
│  ┌──────────────────┐          ┌──────────────────┐        │
│  │  Laptop (client) │◄────────►│  Mac Mini (server)│       │
│  │                  │  SSH/SSH │  Always-on       │        │
│  │  - SSH client    │          │  - SSH server    │        │
│  │  - VSCode Remote │          │  - Web panel     │        │
│  │  - Web browser   │          │  - Background jobs│        │
│  └──────────────────┘          └──────────────────┘        │
│       macmini.tailnet.ts.net ← MagicDNS                    │
└─────────────────────────────────────────────────────────────┘
```

## Requirements

### Shared Requirements (Both Machines)

| Requirement | Version | Command to verify |
|-------------|---------|-------------------|
| macOS | Tahoe 26.5.1+ | `sw_vers` |
| Homebrew | Latest | `brew --version` |
| Git | Latest | `git --version` |
| Tailscale | Latest | `tailscale status` |

### Server Requirements (Mac Mini)

| Requirement | Purpose |
|-------------|---------|
| SSH server enabled | Accept SSH connections |
| Tailscale with MagicDNS | `macmini.tailnet.ts.net` hostname |
| SSH public key in `~/.ssh/authorized_keys` | Key-based auth |
| Web panel port (default: 8080) | Local web interface |

### Client Requirements (Laptop)

| Requirement | Purpose |
|-------------|---------|
| Tailscale authenticated to same tailnet | VPN connection |
| SSH key pair (`~/.ssh/id_ed25519`) | Authenticate to server |
| Public key copied to server | Passwordless SSH |
| VSCode with Remote SSH (optional) | Remote folder access |

## Script Structure

```
remote-macOS-agents/
├── setup.sh                  # Main interactive setup script
├── jobs.sh                   # Background job manager
├── scripts/
│   ├── common/
│   │   ├── check-requirements.sh
│   │   ├── check-tailscale.sh
│   │   ├── colors.sh
│   │   └── network-test.sh
│   ├── server/
│   │   ├── install-tailscale.sh
│   │   ├── enable-ssh.sh
│   │   └── configure-panel.sh
│   └── client/
│       ├── install-tailscale.sh
│       └── setup-ssh.sh
└── configs/
    └── sshd_config           # SSH server configuration
```

## Functional Requirements

### setup.sh

**F1.1** Script detects current role if hostname matches patterns (e.g., "Mac-Mini", "mini")
**F1.2** If role cannot be auto-detected, script asks user to select: `server` or `client`
**F1.3** Script accepts `--role=server` and `--role=client` flags to override detection

**F1.4** After role selection, script lists required tools for that role
**F1.5** Script asks user to confirm each requirement is installed
**F1.6** If user confirms, script verifies each requirement using the check scripts

**F1.7** If all requirements are met, script proceeds to configuration phase
**F1.8** If requirements are not met, script shows installation instructions and exits

**F1.9** Server configuration:

- Enable SSH Remote Login
- Install and configure Tailscale with MagicDNS hostname
- Ask for web panel port
- Run connectivity tests

**F1.10** Client configuration:

- Install and configure Tailscale (authenticate if needed)
- Generate SSH key pair if not exists
- Ask for server hostname
- Copy public key to server
- Run connectivity tests

**F1.11** Script is idempotent: re-running verifies existing configuration and fixes issues

### jobs.sh

**F2.1** `jobs.sh list` — lists all configured jobs with status
**F2.2** `jobs.sh start <job-name>` — starts a background job
**F2.3** `jobs.sh stop <job-name>` — stops a background job
**F2.4** `jobs.sh logs <job-name>` — shows logs for a job
**F2.5** `jobs.sh add <job-name>` — interactive job creation

### Common Scripts

**F3.1** `check-requirements.sh` — verifies all shared requirements
**F3.2** `check-tailscale.sh` — verifies Tailscale is installed and logged in
**F3.3** `network-test.sh` — tests connectivity between client and server

## Configuration Files

### sshd_config

- `PermitRootLogin no`
- `PasswordAuthentication no`
- `PubkeyAuthentication yes`
- `AllowUsers <username>`

### Tailscale

- MagicDNS enabled
- HTTPS certificate disabled (using Tailscale's built-in cert)
- ACLs: allow only client device

## Error Handling

- Each check script returns exit code 0 on success, 1 on failure
- Each configuration script returns exit code 0 on success, 1 on failure with error message
- User can press Ctrl+C to abort at any prompt
- All prompts use `read` for interactivity

## Non-Functional Requirements

- **Shell**: Pure bash (no external dependencies beyond system tools)
- **Compatibility**: macOS 14+ (Sonoma/Sequoia)
- **Permissions**: Most operations require sudo; script prompts for password when needed
- **Output**: Colored output for better readability (green=success, red=error, yellow=warning)
