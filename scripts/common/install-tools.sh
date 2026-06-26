#!/bin/bash
# =============================================================================
# Install Homebrew Tools
# =============================================================================
# Installs CLI tools and GUI applications via Homebrew
# Idempotent: safe to run multiple times
#
# Usage:
#   ./install-tools.sh              # Interactive mode
#   ./install-tools.sh --yes        # Auto-confirm all prompts
#   FORCE_YES=1 ./install-tools.sh  # Or via environment variable
# =============================================================================

# Parse arguments
FORCE_YES="${FORCE_YES:-0}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --yes|-y)
            FORCE_YES=1
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--yes]"
            echo "  --yes, -y  Auto-confirm all prompts"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${REPO_DIR}/lib/colors.sh"
source "${REPO_DIR}/lib/utils.sh"

# =============================================================================
# Check Requirements
# =============================================================================

check_requirements() {
    log_header "Checking Requirements for Tools Installation"

    if ! command -v brew &>/dev/null; then
        log_error "Homebrew is not installed"
        echo ""
        echo "Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    log_success "Homebrew found"
    return 0
}

# =============================================================================
# Tap Additional Sources
# =============================================================================

setup_taps() {
    log_info "Setting up Homebrew taps..."

    # Core taps
    brew tap homebrew/core 2>/dev/null || true
    brew tap homebrew/cask 2>/dev/null || true
    brew tap homebrew/services 2>/dev/null || true

    # Third-party taps (for specific packages)
    brew tap 1password/tap 2>/dev/null || true
    brew tap supabase/tap 2>/dev/null || true

    log_success "Taps configured"
}

# =============================================================================
# Install CLI Tools
# =============================================================================

install_cli_tools() {
    log_header "Installing CLI Tools"

    # CORE tools - minimal set for remote-macOS-agents project
    # Core VCS
    local core_tools=(
        gh              # GitHub CLI
        ripgrep         # Fast grep (rg)
    )

    # Shell & Prompt
    local shell_tools=(
        starship        # Shell prompt
        chezmoi         # Dotfiles manager
    )

    # Editor
    local editor_tools=(
        neovim          # Text editor
    )

    # Runtime managers
    local runtime_tools=(
        mise            # Runtime version manager
        pnpm            # Node package manager
    )

    # Utils - universally useful
    local utils_tools=(
        jq              # JSON processor
        bat             # cat with colors
        eza             # Modern ls replacement (exa successor)
        fd              # Fast find alternative
        lazygit         # Terminal UI for git
        shellcheck      # Shell script linter
    )

    # Dev tools - optional but commonly needed
    local dev_tools=(
        go              # Go language
    )

    # Media tools
    local media_tools=(
        ffmpeg          # Video/audio conversion
    )

    # Misc utilities
    local misc_tools=(
        tree            # Directory tree view
        watch           # Repeat command
        parallel        # Parallel execution
        hadolint        # Dockerfile linter
    )

    # Combine all tools
    local all_tools=(
        "${core_tools[@]}"
        "${shell_tools[@]}"
        "${editor_tools[@]}"
        "${runtime_tools[@]}"
        "${utils_tools[@]}"
        "${dev_tools[@]}"
        "${media_tools[@]}"
        "${misc_tools[@]}"
    )

    # Filter to install (only tools not already in PATH)
    local to_install=()

    echo ""
    echo "Checking tools..."

    for tool in "${all_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            echo -e "  ${YELLOW}${tool}${NC} already installed, skipping"
        else
            to_install+=("$tool")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        log_success "All tools already installed"
        return 0
    fi

    echo ""
    log_info "Installing ${#to_install[@]} tools..."

    # Use brew install -y to auto-confirm
    if brew install -y "${to_install[@]}" 2>&1; then
        log_success "Tools installed successfully"
    else
        log_warning "Some tools may have failed to install"
        return 1
    fi
}

# =============================================================================
# Install GUI Applications
# =============================================================================

install_gui_apps() {
    log_header "Installing GUI Applications"

    # Essential GUI apps only
    local apps=(
        "1password"
        "1password-cli"
        "tailscale"
    )

    # Development tools (optional)
    local dev_apps=(
        "cursor"
        "docker"
        "docker-desktop"
    )

    # Productivity
    local productivity_apps=(
        "notion"
        "raycast"
    )

    # Combine all apps
    local all_apps=(
        "${apps[@]}"
        "${dev_apps[@]}"
        "${productivity_apps[@]}"
    )

    # Filter out already installed packages
    local to_install=()
    for app in "${all_apps[@]}"; do
        if ! brew list --cask "$app" &>/dev/null; then
            to_install+=("$app")
        else
            echo -e "  ${YELLOW}${app}${NC} already installed, skipping"
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        log_success "All GUI apps already installed"
        return 0
    fi

    echo ""
    log_info "Installing ${#to_install[@]} GUI applications..."

    # Install casks one by one with -y flag
    local failed=()
    for app in "${to_install[@]}"; do
        echo -n "  Installing ${app}... "
        if brew install --cask -y "$app" 2>/dev/null; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}FAILED${NC}"
            failed+=("$app")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        echo ""
        log_warning "Some apps failed to install: ${failed[*]}"
    fi

    log_success "GUI applications processed"
}

# =============================================================================
# Update PATH and Environment
# =============================================================================

update_environment() {
    log_header "Updating Shell Environment"

    # Rehash to update command hash
    rehash 2>/dev/null || true

    log_success "Environment updated"
}

# =============================================================================
# Verify Installation
# =============================================================================

verify_installation() {
    log_header "Verifying Installation"

    local tools=(
        "starship"
        "chezmoi"
        "nvim"
        "mise"
        "pnpm"
        "gh"
        "rg"
        "eza"
        "jq"
        "bat"
        "fd"
        "lazygit"
        "ffmpeg"
        "tree"
    )

    local all_ok=true
    for tool in "${tools[@]}"; do
        # Handle aliases
        case "$tool" in
            nvim) actual="nvim" ;;
            rg) actual="rg" ;;
            *) actual="$tool" ;;
        esac

        if command -v "$actual" &>/dev/null; then
            local version=$("$actual" --version 2>/dev/null | head -1 || "$actual" --help 2>/dev/null | head -1 || echo "installed")
            echo -e "  ${GREEN}✓${NC} ${tool}: ${version}"
        else
            echo -e "  ${RED}✗${NC} ${tool}: NOT FOUND"
            all_ok=false
        fi
    done

    if $all_ok; then
        log_success "All core tools verified"
        return 0
    else
        log_warning "Some tools were not found"
        return 1
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    log_header "Homebrew Tools Installation"
    echo ""

    # Check requirements
    if ! check_requirements; then
        return 1
    fi

    # Setup taps
    setup_taps

    # Ask for confirmation unless FORCE_YES is set
    if [[ "$FORCE_YES" == "1" ]]; then
        echo ""
        echo -e "${BOLD}Auto-confirm mode enabled${NC} (--yes flag)"
        echo "Installing core tools..."
    else
        echo ""
        echo "This will install the following:"
        echo "  - Core CLI tools (starship, chezmoi, neovim, mise, pnpm, eza, gh, etc.)"
        echo "  - GUI applications (1password, tailscale, cursor, docker, etc.)"
        echo ""
        echo "Already installed packages will be skipped."
        echo ""

        if ! confirm "Continue with installation?"; then
            log_warning "Installation cancelled"
            return 1
        fi
    fi

    # Install tools
    echo ""
    install_cli_tools

    echo ""
    install_gui_apps

    echo ""
    update_environment

    echo ""
    verify_installation

    echo ""
    log_success "Tools installation complete!"
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo "  1. Restart your terminal or run: ${BOLD}source ~/.zshrc${NC}"
    echo "  2. Run: ${BOLD}./setup.sh --apply-dotfiles${NC}"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
