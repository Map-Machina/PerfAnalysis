#!/bin/bash
# Post-boot setup script for OCI PerfTest VMs
# Run this via SSH AFTER the instance is accessible
#
# Usage: ./post_boot_setup.sh [target_ip] [session_id]
#   target_ip: Private IP of the target instance
#   session_id: OCI Bastion session ID (optional if using direct SSH)
#
# Example:
#   ./post_boot_setup.sh 10.0.10.151 ocid1.bastionsession.oc1...

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

TARGET_IP="${1:-}"
SESSION_ID="${2:-}"
REGION="${OCI_REGION:-us-phoenix-1}"
SSH_KEY="${SSH_KEY:-~/.ssh/id_ed25519}"
LOCAL_PORT="${LOCAL_PORT:-22222}"

if [ -z "$TARGET_IP" ]; then
    log_error "Usage: $0 <target_ip> [session_id]"
    exit 1
fi

# Function to run command on remote host
remote_exec() {
    if [ -n "$SESSION_ID" ]; then
        # Using bastion tunnel
        ssh -i "$SSH_KEY" -p "$LOCAL_PORT" -o StrictHostKeyChecking=no opc@localhost "$@"
    else
        # Direct SSH
        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no opc@"$TARGET_IP" "$@"
    fi
}

# Setup bastion tunnel if session ID provided
setup_tunnel() {
    if [ -n "$SESSION_ID" ]; then
        log_info "Setting up SSH tunnel through bastion..."

        # Kill any existing tunnel on the port
        pkill -f "ssh.*$LOCAL_PORT.*$SESSION_ID" 2>/dev/null || true
        sleep 1

        # Create tunnel
        ssh -i "$SSH_KEY" -N -L "$LOCAL_PORT:$TARGET_IP:22" \
            -p 22 "$SESSION_ID@host.bastion.$REGION.oci.oraclecloud.com" &
        TUNNEL_PID=$!

        # Wait for tunnel to establish
        sleep 3

        if ! kill -0 $TUNNEL_PID 2>/dev/null; then
            log_error "Failed to establish SSH tunnel"
            exit 1
        fi

        log_info "SSH tunnel established (PID: $TUNNEL_PID)"
        trap "kill $TUNNEL_PID 2>/dev/null" EXIT
    fi
}

# Main setup function
main() {
    log_info "Starting post-boot setup for $TARGET_IP"

    setup_tunnel

    # Step 1: Verify SSH connectivity
    log_info "Step 1: Verifying SSH connectivity..."
    if ! remote_exec "echo 'SSH connection successful'"; then
        log_error "Cannot connect via SSH"
        exit 1
    fi

    # Step 2: Check cloud-init status
    log_info "Step 2: Checking cloud-init status..."
    remote_exec "sudo cloud-init status --wait" || log_warn "Cloud-init may still be running"

    # Step 3: Verify swap space
    log_info "Step 3: Verifying swap space..."
    remote_exec "swapon --show"

    # Step 4: Check available memory
    log_info "Step 4: Checking available memory..."
    remote_exec "free -m"

    # Step 5: Install sysbench
    log_info "Step 5: Installing sysbench..."
    remote_exec "sudo dnf install -y epel-release 2>/dev/null || true"
    remote_exec "sudo dnf install -y sysbench"

    # Step 6: Verify sysbench installation
    log_info "Step 6: Verifying sysbench installation..."
    remote_exec "sysbench --version"

    # Step 7: Verify pcc user setup
    log_info "Step 7: Verifying pcc user setup..."
    remote_exec "id pcc"
    remote_exec "ls -la /home/pcc/"

    # Step 8: Quick sysbench test
    log_info "Step 8: Running quick sysbench test (10 seconds)..."
    remote_exec "sysbench cpu --threads=1 --time=10 run"

    log_info "============================================"
    log_info "Post-boot setup complete for $TARGET_IP"
    log_info "============================================"
    log_info ""
    log_info "Next steps:"
    log_info "1. Optionally install Go and perfcollector2"
    log_info "2. Run full benchmark: sudo -u pcc /home/pcc/run_benchmark.sh"
    log_info ""
}

main "$@"
