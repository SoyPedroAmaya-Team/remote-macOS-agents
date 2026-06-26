#!/bin/bash
# =============================================================================
# Install Homebrew Tools
# =============================================================================
# Installs CLI tools and GUI applications via Homebrew
# Idempotent: safe to run multiple times
# =============================================================================

set -e

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

	local tools=(
		# Core VCS
		git
		gh

		# Shell & Prompt
		starship
		zsh
		zsh-completions

		# Editor
		neovim

		# Runtime managers
		mise
		fvm
		uv

		# JS/Node
		node
		pnpm

		# DB
		supabase
		postgresql@17
		psql

		# Mobile
		cocoapods

		# Utils
		lazygit
		gg
		httpie
		jq
		yq
		tldr
		bat
		exa
		fd
		fzf
		ripgrep
		delta
		ghq

		# Dev tools
		cmake
		go
		rustup
		pyenv

		# Cloud
		awscli
		gcloud
		terraform
		kubectl
		helm

		# Network
		wget
		curl
		nmap
		mosh

		# Image/Media
		imagemagick
		ffmpeg
		gifsicle

		# Misc
		tree
		htop
		watch
		parallel
		shellcheck
		shfmt
		hadolint
		tflint
	)

	# Filter out already installed packages
	local to_install=()
	for tool in "${tools[@]}"; do
		if ! brew list "$tool" &>/dev/null; then
			to_install+=("$tool")
		else
			echo -e "  ${YELLOW}${tool}${NC} already installed, skipping"
		fi
	done

	if [[ ${#to_install[@]} -eq 0 ]]; then
		log_success "All CLI tools already installed"
		return 0
	fi

	echo ""
	log_info "Installing ${#to_install[@]} CLI tools..."
	brew install "${to_install[@]}"

	log_success "CLI tools installed"
}

# =============================================================================
# Install GUI Applications
# =============================================================================

install_gui_apps() {
	log_header "Installing GUI Applications"

	# These are casks - GUI applications
	local apps=(
		# Terminal & Fonts
		"font-fira-code-nerd-font"

		# Password & VPN
		"1password"
		"1password-cli"
		"tailscale"

		# Productivity
		"notion"
		"raycast"
		"setapp"

		# Development
		"cursor"
		"claude"
		"bruno"
		"gitkraken"
		"datagrip"
		"docker"
		"docker-desktop"
		"antigravity"
		"antigravity-ide"

		# BI & Data
		"tableau"
		"superset"

		# Office
		"microsoft-excel"

		# Browser
		"google-chrome"

		# Terminal (cmux manages the actual terminal)
		"cmux"
	)

	# Filter out already installed packages
	local to_install=()
	for app in "${apps[@]}"; do
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
	echo "  (This may take a while for large apps like Docker...)"
	echo ""

	# Install casks one by one to handle failures gracefully
	local failed=()
	for app in "${to_install[@]}"; do
		echo -n "  Installing ${app}... "
		if brew install --cask --quiet "$app" 2>/dev/null; then
			echo -e "${GREEN}OK${NC}"
		else
			echo -e "${RED}FAILED${NC}"
			failed+=("$app")
		fi
	done

	if [[ ${#failed[@]} -gt 0 ]]; then
		echo ""
		log_warning "Some apps failed to install:"
		for app in "${failed[@]}"; do
			echo "  - $app"
		done
		echo ""
		echo "You can try installing them manually with:"
		echo "  brew install --cask ${failed[*]}"
	fi

	log_success "GUI applications processed"
}

# =============================================================================
# Install via Brewfile (alternative method)
# =============================================================================

install_from_brewfile() {
	log_header "Installing from Brewfile"

	local brewfile="$REPO_DIR/Brewfile"

	if [[ ! -f "$brewfile" ]]; then
		log_error "Brewfile not found at $brewfile"
		return 1
	fi

	if [[ ! -f "$brewfile.lock.json" ]]; then
		log_info "Creating Brewfile.lock.json (first run)..."
		brew bundle --file="$brewfile" --describe
	else
		log_info "Installing from Brewfile.lock.json..."
	fi

	brew bundle --file="$brewfile"

	log_success "Brewfile installed"
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
		"git"
		"gh"
		"starship"
		"nvim"
		"mise"
		"pnpm"
		"neovim"
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

	if $all_ok; then
		log_success "All core tools verified"
		return 0
	else
		log_warning "Some tools were not found. You may need to restart your shell."
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

	# Ask for confirmation
	echo ""
	echo "This will install the following:"
	echo "  - Core CLI tools (git, starship, neovim, mise, etc.)"
	echo "  - GUI applications (1password, notion, raycast, cursor, etc.)"
	echo ""
	echo "Already installed packages will be skipped."
	echo ""

	if ! confirm "Continue with installation?"; then
		log_warning "Installation cancelled"
		return 1
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
	echo "  2. Run: ${BOLD}./setup.sh --skip-checks${NC}"
	echo "  3. Select 'Apply dotfiles' to configure your environment"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
