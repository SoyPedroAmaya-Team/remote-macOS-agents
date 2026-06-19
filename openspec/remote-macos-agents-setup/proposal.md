# Proposal: remote-macOS-agents-setup

## What

Create a repository with bash scripts to configure and maintain a two-machine macOS workflow:

- **Mac Mini** (server): Always-on machine that runs background jobs (AI agents, scripts, web panel)
- **Laptop** (client): Mobile workstation that connects remotely via Tailscale VPN

## Why

The user needs a reliable remote development setup where:

- The Mac Mini is always working on scheduled tasks
- The laptop can access the Mac Mini from anywhere via SSH, VSCode Remote, and a local web panel
- Configuration is reproducible and can be improved over time

## Scope

**In scope:**

- Interactive `setup.sh` script that detects role (server/client) and guides through configuration
- Requirements verification for each role
- Tailscale installation and MagicDNS configuration
- SSH key-based authentication setup
- Connectivity tests after configuration
- Server-side scripts for enabling SSH, configuring Tailscale
- Client-side scripts for SSH access and VSCode Remote
- `AGENTS.md` documentation
- `jobs.sh` script for managing background jobs on the server

**Out of scope:**

- Installing specific AI agents (user will define later)
- Specific web panel implementation (user will define later)
- Tailscale ACL configuration (network-level security)
- Automated backup strategy
- CI/CD pipelines

## Risks

1. **SSH lockout**: If SSH keys are misconfigured, the user might lock themselves out → mitigated by requiring manual verification steps
2. **Tailscale auth**: Needs user interaction to authenticate → handled by interactive prompts with QR code or auth key
3. **macOS Security**: Remote Login must be enabled manually on first run → script checks and prompts

## Success Criteria

- [ ] `setup.sh` runs interactively and guides through role selection
- [ ] Server setup enables SSH, configures Tailscale with MagicDNS, and passes connectivity tests
- [ ] Client setup copies SSH key to server and passes connectivity tests
- [ ] `jobs.sh` can list, start, stop, and view logs for background jobs
- [ ] Documentation in `AGENTS.md` is complete and accurate
