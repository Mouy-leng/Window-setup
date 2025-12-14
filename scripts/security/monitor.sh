#!/bin/bash
# Security Monitor for Agent and User Protection (Linux)
# Monitors system activities and enforces security policies

LOCAL_MODE=true
BROWSER_MODE=false
MONITOR_INTERVAL=60
LOG_PATH="/tmp/security-monitor.log"

log_security() {
    local message="$1"
    local level="${2:-INFO}"
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$timestamp [$level] - $message" | tee -a "$LOG_PATH"
}

test_process_security() {
    log_security "Checking running processes for security threats..."
    
    # List of suspicious process names
    suspicious_procs=("mimikatz" "nc" "netcat" "psexec" "procdump")
    
    for proc in "${suspicious_procs[@]}"; do
        if pgrep -x "$proc" > /dev/null; then
            log_security "WARNING: Suspicious process detected: $proc" "WARNING"
            return 1
        fi
    done
    
    log_security "No suspicious processes detected" "SUCCESS"
    return 0
}

test_network_connections() {
    log_security "Monitoring network connections..."
    
    # Check for established connections (excluding localhost)
    if command -v ss &> /dev/null; then
        connections=$(ss -tunp state established 2>/dev/null | grep -v "127.0.0.1\|::1")
        if [ -n "$connections" ]; then
            log_security "Active network connections detected"
            echo "$connections" | head -5 >> "$LOG_PATH"
        fi
    elif command -v netstat &> /dev/null; then
        connections=$(netstat -tunp 2>/dev/null | grep ESTABLISHED | grep -v "127.0.0.1\|::1")
        if [ -n "$connections" ]; then
            log_security "Active network connections detected"
            echo "$connections" | head -5 >> "$LOG_PATH"
        fi
    fi
    
    return 0
}

test_file_integrity() {
    log_security "Checking file integrity in critical directories..."
    
    # Define critical paths to monitor
    critical_paths=(
        "$HOME/.agent-secure"
        "$HOME/.wine-mql5"
    )
    
    for path in "${critical_paths[@]}"; do
        if [ -d "$path" ]; then
            file_count=$(find "$path" -type f 2>/dev/null | wc -l)
            log_security "Monitoring $file_count files in $path"
            
            # Check for recently modified files (last 5 minutes)
            recent_files=$(find "$path" -type f -mmin -5 2>/dev/null | wc -l)
            if [ "$recent_files" -gt 0 ]; then
                log_security "Recently modified files in $path: $recent_files" "WARNING"
            fi
        fi
    done
    
    return 0
}

test_browser_security() {
    log_security "Checking browser security settings..."
    
    # Check if browser processes are running
    browser_procs=("chrome" "firefox" "chromium" "brave")
    
    for browser in "${browser_procs[@]}"; do
        if pgrep -x "$browser" > /dev/null; then
            log_security "Active browser detected: $browser"
        fi
    done
    
    return 0
}

test_agent_activity() {
    log_security "Monitoring agent activity..."
    
    agent_path="$HOME/.agent-secure"
    if [ -d "$agent_path" ]; then
        # Check agent log files
        log_files=$(find "$agent_path" -name "*.log" 2>/dev/null)
        
        for log_file in $log_files; do
            if [ -f "$log_file" ]; then
                size_mb=$(du -m "$log_file" 2>/dev/null | cut -f1)
                if [ "$size_mb" -gt 100 ]; then
                    log_security "Large agent log detected: $(basename $log_file) - ${size_mb}MB" "WARNING"
                fi
            fi
        done
        
        log_security "Agent directory monitored successfully" "SUCCESS"
    else
        log_security "Agent secure directory not found" "WARNING"
    fi
    
    return 0
}

start_security_monitoring() {
    log_security "=== Security Monitoring Started ===" "SUCCESS"
    log_security "Mode: $(if [ "$LOCAL_MODE" = true ]; then echo 'Local'; else echo 'Remote'; fi), Browser Mode: $BROWSER_MODE"
    log_security "Monitor Interval: $MONITOR_INTERVAL seconds"
    
    iteration=0
    while true; do
        iteration=$((iteration + 1))
        log_security ""
        log_security "--- Security Check Iteration $iteration ---"
        
        # Run security checks
        test_process_security
        test_network_connections
        test_file_integrity
        test_agent_activity
        
        if [ "$BROWSER_MODE" = true ]; then
            test_browser_security
        fi
        
        log_security "Sleeping for $MONITOR_INTERVAL seconds..."
        sleep "$MONITOR_INTERVAL"
    done
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --browser-mode)
            BROWSER_MODE=true
            shift
            ;;
        --interval)
            MONITOR_INTERVAL="$2"
            shift 2
            ;;
        --log-path)
            LOG_PATH="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Main execution
log_security "Initializing Security Monitor..." "SUCCESS"
log_security "Log Path: $LOG_PATH"

# Create secure directory if it doesn't exist
secure_path="$HOME/.agent-secure"
if [ ! -d "$secure_path" ]; then
    mkdir -p "$secure_path"
    chmod 700 "$secure_path"
    log_security "Created secure directory: $secure_path" "SUCCESS"
fi

# Start monitoring
start_security_monitoring
