#!/bin/bash
# entrypoint.sh

set -e

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to generate config file
generate_config() {
    local config_file="/seadrive/config/seadrive.conf"
    
    if [ ! -f "$config_file" ]; then
        log "Generating SeaDrive configuration..."
        
        # Check required environment variables
        if [ -z "$SEAFILE_SERVER" ] || [ -z "$SEAFILE_USERNAME" ]; then
            log "ERROR: SEAFILE_SERVER and SEAFILE_USERNAME are required"
            log "Please set the following environment variables:"
            log "  - SEAFILE_SERVER: Your Seafile server URL (e.g., https://seafile.example.com)"
            log "  - SEAFILE_USERNAME: Your Seafile username/email"
            log "  - SEAFILE_PASSWORD: Your password (for initial token generation)"
            log "  - SEAFILE_TOKEN: Your auth token (alternative to password)"
            exit 1
        fi
        
        # Generate token if password provided and token not set
        if [ -n "$SEAFILE_PASSWORD" ] && [ -z "$SEAFILE_TOKEN" ]; then
            log "Generating authentication token..."
            SEAFILE_TOKEN=$(curl -s -d "username=$SEAFILE_USERNAME&password=$SEAFILE_PASSWORD" "$SEAFILE_SERVER/api2/auth-token/" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
            if [ -n "$SEAFILE_TOKEN" ] && [ "$SEAFILE_TOKEN" != "null" ]; then
                log "Authentication token generated successfully"
                export SEAFILE_TOKEN
            else
                log "ERROR: Failed to generate authentication token"
                log "Please check your credentials and server URL"
                exit 1
            fi
        fi
        
        # Create config from template
        envsubst < /seadrive/config/seadrive.conf.template > "$config_file"
        log "Configuration file created at $config_file"
    else
        log "Using existing configuration file"
    fi
}

# Function to check FUSE availability
check_fuse() {
    if [ ! -c /dev/fuse ]; then
        log "ERROR: /dev/fuse not available"
        log "Please run the container with: --device /dev/fuse --cap-add SYS_ADMIN"
        exit 1
    fi
    
    log "FUSE device available"
}

# Function to start SeaDrive
start_seadrive() {
    local config_file="/seadrive/config/seadrive.conf"
    local mount_point="$MOUNT_POINT"
    local data_dir="$DATA_DIR"
    
    log "Starting SeaDrive..."
    log "Mount point: $mount_point"
    log "Data directory: $data_dir"
    log "Configuration: $config_file"
    
    # Ensure mount point exists
    mkdir -p "$mount_point"
    
    # Check if already mounted
    if mountpoint -q "$mount_point"; then
        log "Unmounting existing mount at $mount_point"
        fusermount -u "$mount_point" || true
    fi
    
    # Start SeaDrive in background and save PID
    log "Starting SeaDrive daemon..."
    seadrive-cli \
        -c "$config_file" \
        -d "$data_dir" \
        -l "/seadrive/logs/seadrive.log" \
        -f \
        "$mount_point" &
    SEADRIVE_PID=$!
    
    # Wait for SeaDrive to mount
    log "Waiting for SeaDrive mount to be ready..."
    timeout=30
    while [ $timeout -gt 0 ] && ! mountpoint -q "$mount_point"; do
        sleep 1
        timeout=$((timeout - 1))
    done
    
    if mountpoint -q "$mount_point"; then
        log "SeaDrive mounted successfully at $mount_point"
        log "SeaDrive is ready! Files available at $mount_point"
        
        # Keep the container running by waiting for the SeaDrive process
        log "Keeping container running... (PID: $SEADRIVE_PID)"
        wait $SEADRIVE_PID
        log "SeaDrive process exited, shutting down container"
    else
        log "ERROR: SeaDrive failed to mount within timeout"
        exit 1
    fi
}

# Function to handle shutdown
cleanup() {
    log "Received shutdown signal, cleaning up..."
    
    # Kill SeaDrive process if it's running
    if [ -n "$SEADRIVE_PID" ] && kill -0 "$SEADRIVE_PID" 2>/dev/null; then
        log "Stopping SeaDrive process (PID: $SEADRIVE_PID)"
        kill "$SEADRIVE_PID" || true
    fi
    
    # Clean up FUSE mount
    if mountpoint -q "$MOUNT_POINT"; then
        log "Unmounting $MOUNT_POINT"
        fusermount -u "$MOUNT_POINT" || true
    fi
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Main execution
case "${1:-seadrive}" in
    seadrive)
        log "Starting SeaDrive Docker container..."
        check_fuse
        generate_config
        start_seadrive
        ;;
    bash|sh)
        log "Starting interactive shell..."
        exec "$@"
        ;;
    *)
        log "Running custom command: $*"
        exec "$@"
        ;;
esac