#!/bin/bash
# =============================================================================
# Install Homebrew Tools
# =============================================================================
# Installs CLI tools and GUI applications via Homebrew
# Idempotent: safe to run multiple times
# =============================================================================

# Don't exit on error - we handle errors gracefully
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${REPO_DIR}/lib/colors.sh"
source "${REPO_DIR}/lib/utils.sh"

# =============================================================================
# Parse Arguments
# =============================================================================

AUTO_YES=false

while [[ $# -gt 0 ]]; do
	case "$1" in
	--yes | -y)
		AUTO_YES=true
		;;
	-h | --help)
		echo "Usage: $0 [--yes]"
		echo "  --yes, -y  Auto-confirm all prompts"
		exit 0
		;;
	*)
		;;
	esac
	shift
done

# =============================================================================
# Configuration
# =============================================================================

# Tools to install (CLI)
CLI_TOOLS=(
	# Core VCS
	git
	gh

	# Shell & Prompt
	starship
	chezmoi

	# Editor
	neovim

	# Runtime managers
	mise
	fvm
	pnpm

	# DB
	supabase
	postgresql@17

	# Mobile
	cocoapods

	# Utils
	lazygit
	jq
	yq
	tldr
	bat
	eza
	fd
	ripgrep

	# Dev tools
	go

	# Image/Media
	imagemagick
	ffmpeg

	# System Utilities
	tree
	htop
	watch
	parallel
	shellcheck
	shfmt
	hadolint
)

# GUI Apps to install
GUI_APPS=(
	# Terminal & Fonts
	font-fira-code-nerd-font
	cmux

	# Password Manager & VPN
	1password
	1password-cli
	tailscale

	# Productivity
	notion
	raycast
	setapp

	# Development
	cursor
	claude
	bruno
	gitkraken
	datagrip
	docker
	docker-desktop
	antigravity
	antigravity-ide

	# BI & Data
	tableau
	superset

	# Office
	microsoft-excel

	# Browser
	google-chrome
)

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
	log_header "Setting up Homebrew taps..."

	# Core taps
	brew tap homebrew/core 2>/dev/null || true
	brew tap homebrew/cask 2>/dev/null || true
	brew tap homebrew/services 2>/dev/null || true

	# Third-party taps
	brew tap 1password/tap 2>/dev/null || true
	brew tap supabase/tap 2>/dev/null || true

	log_success "Taps configured"
}

# =============================================================================
# Install CLI Tools
# =============================================================================

install_cli_tools() {
	log_header "Installing CLI Tools"

	local failed=()
	local installed=0
	local skipped=0

	echo ""

	for tool in "${CLI_TOOLS[@]}"; do
		if brew list "$tool" &>/dev/null; then
			echo -e "  ${YELLOW}${tool}${NC} already installed, skipping"
			((skipped++))
		else
			echo -n "  Installing ${tool}... "
			if brew install "$tool" 2>/dev/null; then
				echo -e "${GREEN}OK${NC}"
				((installed++))
			else
				echo -e "${RED}FAILED${NC}"
				failed+=("$tool")
				((skipped++))
			fi
		fi
	done

	echo ""

	if [[ ${#failed[@]} -gt 0 ]]; then
		log_warning "Failed to install: ${failed[*]}"
		log_info "You can try manually: brew install ${failed[*]}"
	fi

	log_success "CLI tools: $installed installed, $skipped already installed"
	return 0
}

# =============================================================================
# Install GUI Applications
# =============================================================================

install_gui_apps() {
	log_header "Installing GUI Applications"

	local failed=()
	local installed=0
	local skipped=0

	echo ""

	for app in "${GUI_APPS[@]}"; do
		if brew list --cask "$app" &>/dev/null; then
			echo -e "  ${YELLOW}${app}${NC} already installed, skipping"
			((skipped++))
		else
			echo -n "  Installing ${app}... "
			# Try with --no-quarantine first
			if brew install --cask --no-quarantine "$app" 2>/dev/null; then
				echo -e "${GREEN}OK${NC}"
				((installed++))
			elif brew install --cask "$app" 2>/dev/null; then
				echo -e "${GREEN}OK${NC}"
				((installed++))
			else
				echo -e "${RED}FAILED${NC}"
				failed+=("$app")
				((skipped++))
			fi
		fi
	done

	echo ""

	if [[ ${#failed[@]} -gt 0 ]]; then
		log_warning "Failed to install: ${failed[*]}"
		log_info "You can try manually: brew install --cask ${failed[*]}"
	fi

	log_success "GUI apps: $installed installed, $skipped already installed"
	return 0
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
		git
		gh
		starship
		nvim
		mise
		pnpm
		chezmoi
	)

	local all_ok=true
	for tool in "${tools[@]}"; do
		if command -v "$tool" &>/dev/null; then
			local version=$("$tool" --version 2>/dev/null | head -1 || echo "installed")
			echo -e "  ${GREEN}✓${NC} ${tool}: ${version}"
		else
			echo -e "  ${RED}✗${NC} ${tool}: NOT FOUND"
			all_ok=false
		fi
	done

	echo ""

	if $all_ok; then
		log_success "All core tools verified"
		return 0
	else
		log_warning "Some tools were not found. Restart your terminal."
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

	# Auto-confirm for automated runs
	if [[ "${AUTO_YES:-false}" == "true" ]] || [[ "${CI:-false}" == "true" ]]; then
		log_info "Auto-confirm mode enabled"
	else
		echo ""
		echo "This will install:"
		echo "  - CLI tools: ${#CLI_TOOLS[@]} packages"
		echo "  - GUI apps: ${#GUI_APPS[@]} applications"
		echo ""
		echo "Already installed packages will be skipped."
		echo ""

		if ! confirm "Continue with installation?" "y"; then
			log_warning "Installation cancelled"
			return 1
		fi
	fi

	# Install tools
	echo ""
	log_info "Installing core tools..."
	install_cli_tools

	# Install GUI apps
	echo ""
	log_info "Installing GUI applications..."
	install_gui_apps

	# Update environment
	echo ""
	update_environment

	# Verify
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
