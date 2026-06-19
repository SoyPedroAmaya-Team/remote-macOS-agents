# Remote macOS Agents

## Overview

This repository contains setup scripts and configuration for a two-machine macOS workflow:

- **Laptop** (client): Mobile workstation, may be offline or sleeping
- **Mac Mini** (server): Always-on office machine, runs background jobs and serves local interfaces

The goal is to have the Mac Mini always working on scheduled tasks (AI agents, scripts, services) while being accessible from anywhere via Tailscale VPN — SSH, VSCode Remote, and a local web panel.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Tailscale VPN                          │
│  ┌──────────────────┐          ┌──────────────────┐        │
│  │  Laptop (client) │◄────────►│  Mac Mini (server)│       │
│  │                  │  SSH/SSHFS│  Always-on      │        │
│  │  - Pi coding agent│         │  - Web panel     │        │
│  │  - VSCode Remote │          │  - Background jobs│        │
│  │  - Manual work   │          │  - AI agents     │        │
│  └──────────────────┘          └──────────────────┘        │
│       macmini.tailnet.ts.net ← MagicDNS                    │
└─────────────────────────────────────────────────────────────┘
```

## Device Roles

### Server (Mac Mini)

The Mac Mini acts as the always-on agent host.

**Responsibilities:**

- Runs Tailscale as an exit node or relay (optional)
- Serves a local web panel on a configurable port
- Runs scheduled jobs (AI agents, scripts, monitoring)
- Accepts SSH connections from the client
- Serves repositories via SSHFS or VSCode Remote

**Requirements:**

- [ ] macOS Tahoe 26.5.1 (or equivalent)
- [ ] Homebrew installed
- [ ] Git installed
- [ ] Tailscale installed and configured with MagicDNS (`macmini.tailnet.ts.net`)
- [ ] SSH server enabled (`sudo systemsetup -f setremotelogin on`)
- [ ] SSH public key added to `~/.ssh/authorized_keys`
- [ ] A configured web panel (application-specific)

**Network access:**

- Web panel: `http://macmini.tailnet.ts.net:<PORT>`
- SSH: `ssh user@macmini.tailnet.ts.net`

### Client (Laptop)

The Laptop is the mobile workstation used when away from the office.

**Responsibilities:**

- Connect to Tailscale VPN
- Access Mac Mini via SSH
- Open remote folders with VSCode Remote
- View the Mac Mini's web panel
- Run manual development work

**Requirements:**

- [ ] macOS Tahoe 26.5.1 (or equivalent)
- [ ] Homebrew installed
- [ ] Git installed
- [ ] Tailscale installed and authenticated to the same tailnet
- [ ] SSH key pair generated (`ssh-keygen`)
- [ ] Public key added to Mac Mini's `~/.ssh/authorized_keys`
- [ ] VSCode with Remote SSH extension (optional, for folder access)

## Setup Script

The setup is driven by `setup.sh`, an interactive script that guides you through configuration.

### Usage

```bash
git clone <repo-url>
cd remote-macOS-agents
./setup.sh
```

### Script Flow

1. **Role Detection** — The script asks which device you're setting up:
   - `server` → Mac Mini configuration
   - `client` → Laptop configuration

2. **Requirements Check** — For each role, the script verifies:
   - Tailscale is installed and logged in
   - SSH keys exist (client) or SSH server is enabled (server)
   - Required tools are present

3. **Configuration** — When requirements are met, the script:
   - Configures Tailscale with MagicDNS
   - Sets up SSH keys and copies public keys
   - Enables SSH server (server only)
   - Runs connectivity tests

4. **Connectivity Tests** — After setup:
   - Client pings server via Tailscale IP
   - Client tests SSH connection
   - Client tests web panel reachability (if panel port is provided)

### Interactive Prompts

The script is fully interactive. You will be asked:

**For both roles:**

- Confirmation that prerequisites are installed
- Tailscale auth key or QR code login
- Desired hostname for MagicDNS

**For server only:**

- Username for SSH access
- Port for the web panel (default: 8080)
- Web panel startup command (optional)

**For client only:**

- Server hostname to connect to (default: `macmini.tailnet.ts.net`)
- Username (must match server's username)

## Project Structure

```
remote-macOS-agents/
├── AGENTS.md              # This file
├── setup.sh               # Main interactive setup script
├── scripts/
│   ├── common/            # Shared functions and checks
│   │   ├── check-tailscale.sh
│   │   ├── check-ssh-keys.sh
│   │   └── network-test.sh
│   ├── server/            # Server-specific setup
│   │   ├── install-tailscale.sh
│   │   ├── enable-ssh.sh
│   │   └── configure-web-panel.sh
│   └── client/            # Client-specific setup
│       ├── install-tailscale.sh
│       ├── setup-ssh-access.sh
│       └── vscode-remote.sh
├── configs/
│   ├── sshd_config        # SSH server configuration (server only)
│   └── tailscale.conf     # Tailscale configuration example
└── docs/
    ├── troubleshooting.md
    └── web-panel-guide.md
```

## Security Considerations

- **Single user**: This setup assumes only one user (`pedro`) accesses the system
- **SSH**: Public key authentication only (no password authentication)
- **Tailscale**: ACLs should be configured to allow only your devices
- **No internet-facing services**: All services are accessed via Tailscale VPN

## Background Jobs (Mac Mini)

The Mac Mini runs scheduled work via launchd agents or cronjobs.

### Configuration

Jobs are defined in `~/Library/LaunchAgents/` or managed by the project's job runner.

Example job types:

- AI agent sessions (pi, gentle-pi, or other)
- Scripts with scheduled runs
- Web panel service

### Managing Jobs

```bash
# List active agents/jobs
./jobs.sh list

# Start a job
./jobs.sh start <job-name>

# Stop a job
./jobs.sh stop <job-name>

# View job logs
./jobs.sh logs <job-name>
```

## Common Tasks

### First-time Setup (Server)

```bash
# On the Mac Mini
./setup.sh
# Select "server" when prompted
# Follow interactive prompts
# Verify with: tailscale status
```

### First-time Setup (Client)

```bash
# On the Laptop
./setup.sh
# Select "client" when prompted
# Enter server hostname (macmini.tailnet.ts.net)
# Verify SSH access: ssh user@macmini.tailnet.ts.net
```

### Connect to Mac Mini via SSH

```bash
ssh user@macmini.tailnet.ts.net
```

### Open a Remote Folder in VSCode

```bash
# From VSCode
# Cmd+Shift+P → "Remote-SSH: Connect to Host"
# Enter: user@macmini.tailnet.ts.net

# Or from terminal
code --remote ssh-remote+user@macmini.tailnet.ts.net /path/to/folder
```

### Access the Web Panel

Open in browser:

```
http://macmini.tailnet.ts.net:<PORT>
```

### Re-run Setup

The setup script is idempotent. Re-running it will:

- Verify existing configuration
- Fix any misconfigurations
- Re-run connectivity tests

## Requirements Summary

### Server (Mac Mini)

| Requirement | Command to verify |
|-------------|-------------------|
| macOS Tahoe 26.5.1 | `sw_vers` |
| Homebrew | `brew --version` |
| Git | `git --version` |
| Tailscale | `tailscale status` |
| SSH enabled | `sudo systemsetup -getremotelogin` |
| Web panel | `curl localhost:<PORT>` |

### Client (Laptop)

| Requirement | Command to verify |
|-------------|-------------------|
| macOS Tahoe 26.5.1 | `sw_vers` |
| Homebrew | `brew --version` |
| Git | `git --version` |
| Tailscale | `tailscale status` |
| SSH keys | `ls ~/.ssh/id_ed25519` |
| VSCode (optional) | `code --version` |

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) for common issues and solutions.

## TODO

- [ ] Define specific AI agents to run on Mac Mini
- [ ] Create web panel application or service
- [ ] Set up job runner for scheduled tasks
- [ ] Configure Tailscale ACLs for security
- [ ] Add automated backup strategy
