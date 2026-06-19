#!/bin/bash
# =============================================================================
# Remote macOS Agents - Job Manager
# =============================================================================
# Manage background jobs running on the server (Mac Mini).
# Jobs are stored as shell scripts in ~/.config/remote-macOS-agents/jobs/
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/colors.sh"
source "${SCRIPT_DIR}/lib/config.sh"

JOB_DIR="${HOME}/.config/remote-macOS-agents/jobs"
mkdir -p "$JOB_DIR"

# =============================================================================
# Help
# =============================================================================

show_help() {
	cat <<EOF
${BOLD}Remote macOS Agents - Job Manager${NC}

${BOLD}Usage:${NC}
    $0 <command> [arguments]

${BOLD}Commands:${NC}
    list                List all configured jobs
    start <name>        Start a job
    stop <name>         Stop a running job
    restart <name>      Restart a job
    logs <name>         Show recent logs for a job
    add <name>          Create a new job interactively
    remove <name>       Remove a job
    status <name>       Check if a job is running

${BOLD}Examples:${NC}
    $0 list
    $0 start my-agent
    $0 logs my-agent
    $0 add new-job

EOF
}

# =============================================================================
# List Jobs
# =============================================================================

list_jobs() {
	log_header "Configured Jobs"

	if [[ -z "$(ls -A "$JOB_DIR" 2>/dev/null)" ]]; then
		echo "  No jobs configured."
		echo ""
		echo -e "  Create a job with: ${BOLD}$0 add <name>${NC}"
		return 0
	fi

	echo ""

	for job_file in "$JOB_DIR"/*.sh; do
		[[ -f "$job_file" ]] || continue

		local name=$(basename "$job_file" .sh)
		local pid_file="${JOB_DIR}/${name}.pid"

		echo -e "  ${BOLD}${name}${NC}"

		if [[ -f "$pid_file" ]]; then
			local pid=$(cat "$pid_file")
			if kill -0 "$pid" 2>/dev/null; then
				echo -e "    ${GREEN}● running${NC} (PID: $pid)"
			else
				echo -e "    ${YELLOW}○ stopped${NC} (stale PID file)"
				rm -f "$pid_file"
			fi
		else
			echo -e "    ${YELLOW}○ stopped${NC}"
		fi

		# Show description if available
		if head -5 "$job_file" | grep -q "DESCRIPTION:"; then
			local desc=$(grep "DESCRIPTION:" "$job_file" | cut -d: -f2- | xargs)
			echo -e "    ${desc}"
		fi

		echo ""
	done
}

# =============================================================================
# Job Status
# =============================================================================

job_status() {
	local name="$1"

	if [[ ! -f "${JOB_DIR}/${name}.sh" ]]; then
		log_error "Job not found: $name"
		return 1
	fi

	local pid_file="${JOB_DIR}/${name}.pid"

	if [[ -f "$pid_file" ]]; then
		local pid=$(cat "$pid_file")
		if kill -0 "$pid" 2>/dev/null; then
			echo -e "${GREEN}Running${NC} (PID: $pid)"
			return 0
		fi
	fi

	echo -e "${YELLOW}Stopped${NC}"
	return 1
}

# =============================================================================
# Start Job
# =============================================================================

start_job() {
	local name="$1"
	local job_file="${JOB_DIR}/${name}.sh"
	local pid_file="${JOB_DIR}/${name}.pid"
	local log_file="${JOB_DIR}/${name}.log"

	if [[ ! -f "$job_file" ]]; then
		log_error "Job not found: $name"
		echo -e "  Create it with: ${BOLD}$0 add $name${NC}"
		return 1
	fi

	# Check if already running
	if job_status "$name" &>/dev/null; then
		log_warning "Job '$name' is already running"
		return 1
	fi

	log_info "Starting job: $name"

	# Make job executable
	chmod +x "$job_file"

	# Start job in background
	nohup bash "$job_file" >>"$log_file" 2>&1 &
	local pid=$!

	# Save PID
	echo "$pid" >"$pid_file"

	# Wait a moment and verify
	sleep 1

	if kill -0 "$pid" 2>/dev/null; then
		log_success "Job started (PID: $pid)"
		return 0
	else
		log_error "Job failed to start"
		rm -f "$pid_file"
		return 1
	fi
}

# =============================================================================
# Stop Job
# =============================================================================

stop_job() {
	local name="$1"
	local pid_file="${JOB_DIR}/${name}.pid"

	if [[ ! -f "$pid_file" ]]; then
		log_error "No PID file for job: $name"
		log_info "Job may not be running"
		return 1
	fi

	local pid=$(cat "$pid_file")

	if ! kill -0 "$pid" 2>/dev/null; then
		log_warning "Job '$name' is not running"
		rm -f "$pid_file"
		return 0
	fi

	log_info "Stopping job: $name (PID: $pid)"

	# Try graceful shutdown first
	kill "$pid" 2>/dev/null

	# Wait up to 5 seconds
	local count=0
	while kill -0 "$pid" 2>/dev/null && [[ $count -lt 5 ]]; do
		sleep 1
		count=$((count + 1))
	done

	# Force kill if still running
	if kill -0 "$pid" 2>/dev/null; then
		log_warning "Graceful shutdown failed, forcing..."
		kill -9 "$pid" 2>/dev/null
		sleep 1
	fi

	if kill -0 "$pid" 2>/dev/null; then
		log_error "Failed to stop job"
		return 1
	fi

	rm -f "$pid_file"
	log_success "Job stopped"
	return 0
}

# =============================================================================
# Restart Job
# =============================================================================

restart_job() {
	local name="$1"

	log_info "Restarting job: $name"

	if [[ -f "${JOB_DIR}/${name}.pid" ]]; then
		stop_job "$name"
	fi

	start_job "$name"
}

# =============================================================================
# View Logs
# =============================================================================

view_logs() {
	local name="$1"
	local lines="${2:-50}"
	local log_file="${JOB_DIR}/${name}.log"

	if [[ ! -f "$log_file" ]]; then
		log_error "No logs found for: $name"
		return 1
	fi

	log_header "Logs: $name (last $lines lines)"
	echo ""

	if command -v tail &>/dev/null; then
		tail -n "$lines" "$log_file"
	else
		cat "$log_file"
	fi
}

# =============================================================================
# Add Job
# =============================================================================

add_job() {
	local name="$1"

	if [[ -z "$name" ]]; then
		read -p "Enter job name: " name
	fi

	if [[ -f "${JOB_DIR}/${name}.sh" ]]; then
		log_error "Job already exists: $name"
		return 1
	fi

	if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
		log_error "Invalid job name. Use letters, numbers, hyphens, and underscores only."
		return 1
	fi

	local job_file="${JOB_DIR}/${name}.sh"

	log_info "Creating job: $name"
	echo ""

	# Get description
	echo "Enter a description for this job (optional):"
	read -p "> " description
	description="${description:-No description}"

	# Get command/script
	echo ""
	echo "Enter the command or script to run:"
	echo "(Press Ctrl+D when done, or enter '.' for inline script)"
	read -p "> " -r command

	# Create job file
	cat >"$job_file" <<EOF
#!/bin/bash
# =============================================================================
# Job: $name
# DESCRIPTION: $description
# Created: $(date)
# =============================================================================

# Job configuration
JOB_NAME="$name"
LOG_DIR="${JOB_DIR}"

# Job command
$command

EOF

	chmod +x "$job_file"
	log_success "Job created: ${job_file}"
	log_info "Run '$0 start $name' to start it"
}

# =============================================================================
# Remove Job
# =============================================================================

remove_job() {
	local name="$1"
	local job_file="${JOB_DIR}/${name}.sh"

	if [[ ! -f "$job_file" ]]; then
		log_error "Job not found: $name"
		return 1
	fi

	# Stop if running
	if job_status "$name" &>/dev/null; then
		log_warning "Job is running. Stopping first..."
		stop_job "$name"
	fi

	log_warning "About to remove job: $name"

	if confirm "Are you sure?"; then
		rm -f "$job_file" "${JOB_DIR}/${name}.pid" "${JOB_DIR}/${name}.log"
		log_success "Job removed"
	else
		log_info "Cancelled"
	fi
}

# =============================================================================
# Main
# =============================================================================

main() {
	if [[ $# -eq 0 ]]; then
		show_help
		exit 0
	fi

	local command="$1"
	shift

	case "$command" in
	list)
		list_jobs
		;;
	start)
		[[ -n "$1" ]] || {
			log_error "Usage: $0 start <name>"
			exit 1
		}
		start_job "$1"
		;;
	stop)
		[[ -n "$1" ]] || {
			log_error "Usage: $0 stop <name>"
			exit 1
		}
		stop_job "$1"
		;;
	restart)
		[[ -n "$1" ]] || {
			log_error "Usage: $0 restart <name>"
			exit 1
		}
		restart_job "$1"
		;;
	logs)
		[[ -n "$1" ]] || {
			log_error "Usage: $0 logs <name> [lines]"
			exit 1
		}
		view_logs "$1" "${2:-50}"
		;;
	status)
		[[ -n "$1" ]] || {
			log_error "Usage: $0 status <name>"
			exit 1
		}
		job_status "$1"
		;;
	add)
		add_job "$1"
		;;
	remove | delete)
		[[ -n "$1" ]] || {
			log_error "Usage: $0 remove <name>"
			exit 1
		}
		remove_job "$1"
		;;
	-h | --help | help)
		show_help
		;;
	*)
		log_error "Unknown command: $command"
		show_help
		exit 1
		;;
	esac
}

main "$@"
