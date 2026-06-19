#!/bin/bash
# =============================================================================
# Utility Functions
# =============================================================================

# Confirm with user
confirm() {
    local question="$1"
    local default="${2:-n}"
    local response
    
    while true; do
        read -p "$(echo -e "${question} [${default}] ")" response
        response="${response:-$default}"
        case "$response" in
            y|Y|yep|yes|si|s) return 0 ;;
            n|N|nope|no) return 1 ;;
            *) echo "Please answer yes or no" ;;
        esac
    done
}

# Prompt for input with validation
prompt_input() {
    local question="$1"
    local var_name="$2"
    local default="${3:-}"
    local validation="${4:-}"  # Optional: regex pattern
    local response
    
    while true; do
        if [[ -n "$default" ]]; then
            read -p "$(echo -e "${question} [${default}]: ")" response
            response="${response:-$default}"
        else
            read -p "$(echo -e "${question}: ")" response
        fi
        
        if [[ -z "$validation" ]]; then
            break
        elif [[ "$response" =~ $validation ]]; then
            break
        else
            log_warning "Invalid input. Please try again."
        fi
    done
    
    eval "$var_name='$response'"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Get current user
get_current_user() {
    whoami
}

# Get hostname
get_hostname() {
    hostname
}

# Check if service is running (macOS)
service_is_running() {
    local service_name="$1"
    launchctl list | grep -q "$service_name"
}

# Run with sudo if needed
run_with_sudo() {
    if is_root; then
        "$@"
    else
        sudo "$@"
    fi
}

# Retry a command with exponential backoff
retry() {
    local max_attempts="$1"
    local delay="$2"
    local command="$3"
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if eval "$command"; then
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            log_warning "Attempt $attempt failed. Retrying in ${delay}s..."
            sleep "$delay"
            delay=$((delay * 2))
        fi
        
        attempt=$((attempt + 1))
    done
    
    log_error "Command failed after $max_attempts attempts"
    return 1
}

# Version comparison (simple)
version_gte() {
    local v1="$1"
    local v2="$2"
    [[ "$v1" == "$v2" ]] || [[ "$v1" > "$v2" ]]
}
