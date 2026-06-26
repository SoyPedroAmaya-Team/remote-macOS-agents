#!/bin/bash
# =============================================================================
# Apply Dotfiles with Chezmoi
# =============================================================================
# Configures the user's environment using chezmoi
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
	local git_email="{{ .gitEmail }}"
	local git_name="Pedro Amaya"

	echo ""
	echo -e "  ${BOLD}Detected hostname:${NC} ${hostname}"
	echo -e "  ${BOLD}Git user name:${NC} ${git_name}"
	echo -e "  ${BOLD}Git user email:${NC} ${git_email}"
	echo ""

	# Allow customization
	read -p "Git email [$git_email]: " input_email
	if [[ -n "$input_email" ]]; then
		git_email="$input_email"
	fi

	echo ""
	log_info "Machine configuration saved"
	echo "  hostname: $hostname"
	echo "  git_email: $git_email"

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
		echo ""
		if confirm "chezmoi is already initialized. Update from repo?"; then
			log_info "Updating chezmoi source from $dotfiles_dir"
			rm -rf "$chezmoi_source_dir"
		else
			log_info "Keeping existing chezmoi source"
			return 0
		fi
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
# Help for manual commands
# =============================================================================

show_help() {
	cat <<EOF
${BOLD}Dotfiles Management Commands${NC}

After setup, you can use these commands:

  chezmoi diff         Show changes without applying
  chezmoi apply        Apply changes
  chezmoi edit ~/.zshrc  Edit a file and apply on save
  chezmoi update       Update from repo
  chezmoi cd           Go to source directory

${BOLD}Workflow:${NC}
  1. Edit files directly: chezmoi edit ~/.zshrc
  2. Preview changes: chezmoi diff
  3. Apply changes: chezmoi apply
  4. Commit to repo: cd ~/.local/share/chezmoi && git commit -m "..."
  5. Push: git push
  6. On other machine: chezmoi update

EOF
}

# =============================================================================
# Main
# =============================================================================

main() {
	echo ""
	log_header "Dotfiles Configuration"
	echo ""

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
	echo ""

	show_help
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
