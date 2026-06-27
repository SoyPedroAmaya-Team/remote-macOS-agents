#!/bin/bash
# =============================================================================
# Apply Dotfiles with Chezmoi
# =============================================================================
# Configures the user's environment using chezmoi
# Idempotent: safe to run multiple times
#
# Usage:
#   ./apply-dotfiles.sh             # Interactive mode
#   ./apply-dotfiles.sh --yes       # Auto-confirm all prompts
#   AUTO_YES=1 ./apply-dotfiles.sh  # Via environment variable
# =============================================================================

# Parse arguments
AUTO_YES="${AUTO_YES:-0}"
while [[ $# -gt 0 ]]; do
	case "$1" in
	--yes | -y)
		AUTO_YES=1
		shift
		;;
	--help | -h)
		echo "Usage: $0 [--yes]"
		exit 0
		;;
	*)
		shift
		;;
	esac
done

# Don't use set -e, we'll handle errors explicitly
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${REPO_DIR}/lib/colors.sh"
source "${REPO_DIR}/lib/utils.sh"

# =============================================================================
# Auto-confirm wrapper for confirm function
# =============================================================================

if [[ "$AUTO_YES" == "1" ]]; then
	confirm() { return 0; } # Always return true
fi

# =============================================================================
# Check Requirements
# =============================================================================

check_requirements() {
	log_header "Checking Requirements for Dotfiles"

	local failed=0

	# Check chezmoi
	if ! command -v chezmoi &>/dev/null; then
		log_error "chezmoi is not installed"
		echo ""
		echo "Please install chezmoi first:"
		echo "  brew install chezmoi"
		failed=1
	else
		local version=$(chezmoi --version | head -1)
		log_success "chezmoi found: $version"
	fi

	# Check git
	if ! command -v git &>/dev/null; then
		log_error "git is not installed"
		failed=1
	else
		log_success "git found"
	fi

	# Check if dotfiles source exists
	local dotfiles_dir="$REPO_DIR/dotfiles"
	if [[ ! -d "$dotfiles_dir" ]]; then
		log_error "Dotfiles source directory not found at $dotfiles_dir"
		failed=1
	else
		log_success "Dotfiles source found at $dotfiles_dir"
	fi

	if [[ $failed -eq 1 ]]; then
		return 1
	fi

	return 0
}

# =============================================================================
# Configure Machine-Specific Values
# =============================================================================

configure_machine() {
	log_header "Configuring Machine-Specific Values"

	local hostname=$(hostname -s 2>/dev/null || scutil --get LocalHostName 2>/dev/null || echo "unknown")
	local git_email="soypedroamaya@gmail.com"
	local git_name="Pedro Amaya"

	# In auto mode, don't ask questions
	if [[ "$AUTO_YES" != "1" ]]; then
		echo ""
		echo -e "  ${BOLD}Detected hostname:${NC} ${hostname}"
		echo -e "  ${BOLD}Git user name:${NC} ${git_name}"
		echo -e "  ${BOLD}Git user email:${NC} ${git_email}"
		echo ""
		read -p "Git email [$git_email]: " input_email
		if [[ -n "$input_email" ]]; then
			git_email="$input_email"
		fi
	else
		echo "  hostname: $hostname"
		echo "  git_email: $git_email (auto mode)"
	fi

	# Create/update machine config for chezmoi
	mkdir -p ~/.config/chezmoi

	cat >~/.config/chezmoi/chezmoi.toml <<EOF
# Machine-specific chezmoi configuration
[data]
    hostname = "$hostname"
    gitEmail = "$git_email"
EOF

	log_success "Machine config saved to ~/.config/chezmoi/chezmoi.toml"
}

# =============================================================================
# Initialize chezmoi with the repo
# =============================================================================

init_chezmoi() {
	log_header "Initializing Chezmoi"

	local dotfiles_dir="$REPO_DIR/dotfiles"
	local chezmoi_source_dir="$HOME/.local/share/chezmoi"

	# Check if already initialized
	if [[ -d "$chezmoi_source_dir" ]]; then
		# Always update in auto mode, otherwise ask
		if [[ "$AUTO_YES" == "1" ]]; then
			log_info "Updating chezmoi source from $dotfiles_dir (auto mode)"
			rm -rf "$chezmoi_source_dir"
		elif [[ -L "$chezmoi_source_dir" ]]; then
			local current_link=$(readlink "$chezmoi_source_dir")
			if [[ "$current_link" != "$dotfiles_dir" ]]; then
				echo ""
				if confirm "chezmoi source points to different location. Update to $dotfiles_dir?"; then
					rm -rf "$chezmoi_source_dir"
				else
					log_info "Keeping existing chezmoi source"
					return 0
				fi
			fi
		fi
	else
		log_info "Initializing chezmoi"
	fi

	# Link the dotfiles repo as chezmoi source
	log_info "Linking $dotfiles_dir as chezmoi source"

	mkdir -p "$(dirname "$chezmoi_source_dir")"
	ln -sfn "$dotfiles_dir" "$chezmoi_source_dir"

	log_success "Chezmoi source linked to $chezmoi_source_dir"
}

# =============================================================================
# Apply Dotfiles
# =============================================================================

apply_dotfiles() {
	log_header "Applying Dotfiles"

	echo ""
	log_info "This will apply the following configurations:"
	echo "  - ~/.zshrc"
	echo "  - ~/.gitconfig"
	echo "  - ~/.config/git/ignore"
	echo ""

	if ! confirm "Apply dotfiles?"; then
		log_warning "Dotfiles application cancelled"
		return 1
	fi

	echo ""

	# In auto mode, apply directly without showing diff
	if [[ "$AUTO_YES" == "1" ]]; then
		log_info "Applying dotfiles (auto mode)..."
		chezmoi apply --force 2>/dev/null || chezmoi apply
	else
		# Show what will change
		log_info "Changes to be applied:"
		chezmoi diff || true
		echo ""

		if confirm "Proceed with these changes?"; then
			chezmoi apply
			log_success "Dotfiles applied successfully!"
		else
			log_warning "Changes not applied"
			return 1
		fi
	fi

	log_success "Dotfiles applied successfully!"
}

# =============================================================================
# Verify Configuration
# =============================================================================

verify_configuration() {
	log_header "Verifying Configuration"

	echo ""
	echo -e "  ${BOLD}Checking configuration files...${NC}"
	echo ""

	local files=(
		"~/.zshrc"
		"~/.gitconfig"
		"~/.config/git/ignore"
	)

	local all_ok=true
	for file in "${files[@]}"; do
		local expanded="${file/#\~/$HOME}"

		if [[ -f "$expanded" ]] || [[ -d "$expanded" ]]; then
			echo -e "  ${GREEN}✓${NC} ${file} exists"
		else
			echo -e "  ${RED}✗${NC} ${file} NOT FOUND"
			all_ok=false
		fi
	done

	echo ""

	# Check starship
	if command -v starship &>/dev/null; then
		echo -e "  ${GREEN}✓${NC} starship installed"
	else
		echo -e "  ${RED}✗${NC} starship NOT FOUND"
		all_ok=false
	fi

	# Check neovim
	if command -v nvim &>/dev/null; then
		echo -e "  ${GREEN}✓${NC} neovim installed"
	else
		echo -e "  ${RED}✗${NC} neovim NOT FOUND"
		all_ok=false
	fi

	echo ""

	if $all_ok; then
		log_success "All configurations verified"
		return 0
	else
		log_warning "Some configurations are missing"
		return 1
	fi
}

# =============================================================================
# Main
# =============================================================================

main() {
	echo ""
	log_header "Dotfiles Configuration"
	echo ""

	if [[ "$AUTO_YES" == "1" ]]; then
		log_info "Auto mode enabled - no prompts"
	fi

	# Check requirements
	if ! check_requirements; then
		return 1
	fi

	# Configure machine-specific values
	echo ""
	configure_machine

	# Initialize chezmoi
	echo ""
	init_chezmoi

	# Apply dotfiles
	echo ""
	apply_dotfiles

	# Verify
	echo ""
	verify_configuration

	echo ""
	log_success "Dotfiles configuration complete!"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
