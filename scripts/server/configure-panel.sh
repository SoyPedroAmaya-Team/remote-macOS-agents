#!/bin/bash
# =============================================================================
# Configure Web Panel Settings
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/colors.sh"
source "${SCRIPT_DIR}/../../lib/config.sh"
source "${SCRIPT_DIR}/../../lib/utils.sh"

load_config

configure_panel() {
    log_header "Web Panel Configuration"
    
    # Ask for port
    prompt_input "Enter web panel port" NEW_PORT "${PANEL_PORT}" "^[0-9]+$"
    
    if [[ $NEW_PORT -lt 1024 || $NEW_PORT -gt 65535 ]]; then
        log_error "Port must be between 1024 and 65535"
        return 1
    fi
    
    PANEL_PORT="$NEW_PORT"
    update_config "PANEL_PORT" "$PANEL_PORT"
    
    log_success "Panel port set to: ${PANEL_PORT}"
    
    # Get Tailscale hostname
    local magicdns_hostname
    magicdns_hostname="$(get_magicdns_hostname)"
    
    echo ""
    log_info "Web panel will be accessible at:"
    echo -e "  ${BOLD}http://${magicdns_hostname}:${PANEL_PORT}${NC}"
    echo ""
    log_warning "Note: The web panel must be running for this to work."
    log_info "You'll need to configure your web panel application separately."
}

show_panel_info() {
    log_header "Web Panel Access Info"
    
    load_config
    
    local magicdns_hostname
    magicdns_hostname="$(get_magicdns_hostname)"
    
    echo -e "  MagicDNS:  ${BOLD}${magicdns_hostname}${NC}"
    echo -e "  Port:      ${BOLD}${PANEL_PORT}${NC}"
    echo -e "  URL:       ${BOLD}http://${magicdns_hostname}:${PANEL_PORT}${NC}"
    echo ""
    
    # Check if something is listening
    if lsof -i ":${PANEL_PORT}" &>/dev/null; then
        log_success "Something is listening on port ${PANEL_PORT}"
    else
        log_warning "Nothing listening on port ${PANEL_PORT}"
        echo -e "  ${YELLOW}Start your web panel before accessing it${NC}"
    fi
}

# Main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-configure}" in
        configure)
            configure_panel
            ;;
        info)
            show_panel_info
            ;;
        *)
            echo "Usage: $0 {configure|info}"
            exit 1
            ;;
    esac
fi
