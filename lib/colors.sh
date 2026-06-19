#!/bin/bash
# =============================================================================
# Colors and Logging Functions
# =============================================================================

# Color codes
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export NC='\033[0m' # No Color
export BOLD='\033[1m'

# Emoji shortcuts
export CHECK="${GREEN}✓${NC}"
export CROSS="${RED}✗${NC}"
export WARN="${YELLOW}!${NC}"
export ARROW="${BLUE}→${NC}"
export BULLET="${MAGENTA}•${NC}"

# Logging functions
log_success() {
    echo -e "${CHECK} $1"
}

log_error() {
    echo -e "${CROSS} $1" >&2
}

log_warning() {
    echo -e "${WARN} $1"
}

log_info() {
    echo -e "${ARROW} $1"
}

log_header() {
    echo -e "\n${CYAN}${BOLD}═══ $1 ═══${NC}"
}

log_step() {
    echo -e "\n${BULLET} ${BOLD}$1${NC}"
}

log_text() {
    echo -e "  $1"
}

# Section separator
separator() {
    echo -e "${BLUE}─────────────────────────────────────────────${NC}"
}
