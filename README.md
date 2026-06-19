# Remote macOS Agents

Setup and manage a two-machine macOS remote workflow: **Mac Mini** (server) always-on in your office, **Laptop** (client) for mobile work — connected via Tailscale VPN.

## Overview

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

## Features

- **Interactive setup** — `setup.sh` guides through role selection and configuration
- **Role detection** — auto-detects server (Mac Mini) vs client (Laptop) by hostname
- **Requirements verification** — checks macOS, Homebrew, Git, Tailscale
- **SSH key management** — generates keys and copies to server
- **Tailscale MagicDNS** — access server via `macmini.tailnet.ts.net`
- **Job manager** — `jobs.sh` for managing background tasks on the server
- **Idempotent** — safe to re-run; verifies existing configuration

## Prerequisites

- macOS 14+ (Sonoma/Sequoia)
- Homebrew installed
- Git installed
- Tailscale account (free tier works)

## Quick Start

### 1. Clone the repo on both machines

```bash
git clone <repo-url>
cd remote-macOS-agents
```

### 2. Run setup

**On Mac Mini (server):**

```bash
./setup.sh
# Select "server" role
# Enable SSH, configure Tailscale, set panel port
```

**On Laptop (client):**

```bash
./setup.sh
# Select "client" role
# Configure SSH keys and server connection
```

### 3. Connect from client

```bash
# SSH to server
ssh user@macmini.tailnet.ts.net

# Open VSCode remote
code --remote ssh-remote+user@macmini.tailnet.ts.net

# Access web panel
open http://macmini.tailnet.ts.net:8080
```

## Scripts

| Script | Description |
|--------|-------------|
| `setup.sh` | Main interactive setup |
| `jobs.sh` | Manage background jobs |

### setup.sh Options

```bash
./setup.sh                  # Interactive mode
./setup.sh --role=server    # Force server role
./setup.sh --role=client    # Force client role
./setup.sh --skip-tests     # Skip connectivity tests
```

### jobs.sh Commands

```bash
./jobs.sh list              # List all jobs
./jobs.sh start <name>      # Start a job
./jobs.sh stop <name>       # Stop a job
./jobs.sh logs <name>       # View job logs
./jobs.sh add <name>        # Create new job
./jobs.sh remove <name>     # Remove job
```

## Project Structure

```
remote-macOS-agents/
├── setup.sh                  # Main setup script
├── jobs.sh                   # Job manager
├── lib/                      # Shared library
│   ├── colors.sh             # Color output
│   ├── utils.sh              # Utilities
│   └── config.sh             # Config management
├── scripts/
│   ├── common/               # Shared checks
│   │   ├── check-*.sh        # Requirement checks
│   │   └── network-test.sh   # Connectivity tests
│   ├── server/               # Server setup
│   │   ├── enable-ssh.sh
│   │   ├── install-tailscale.sh
│   │   └── configure-panel.sh
│   └── client/               # Client setup
│       ├── install-tailscale.sh
│       └── setup-ssh.sh
├── configs/
│   └── sshd_config           # SSH server template
└── openspec/                 # SDD artifacts
```

## Documentation

- [AGENTS.md](AGENTS.md) — Full project documentation

## Troubleshooting

### SSH connection fails

1. Check Tailscale is connected on both machines
2. Verify SSH is enabled on server: `sudo systemsetup -getremotelogin`
3. Check public key is in server's `~/.ssh/authorized_keys`

### Tailscale MagicDNS not working

1. Ensure Tailscale is logged in on both machines
2. Check hostname: `tailscale status`
3. Update MagicDNS hostname if needed

### Web panel not accessible

1. Verify the web panel is running on the server
2. Check port: `lsof -i :8080`
3. Ensure Tailscale is connected

## Security

- SSH uses public key authentication only
- Tailscale end-to-end encryption
- Single user (you) access only
- No internet-facing services

## Contributing

This is a personal setup repository. Feel free to adapt for your own workflow.
