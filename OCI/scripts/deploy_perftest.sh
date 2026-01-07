#!/bin/bash
# OCI PerfTest Deployment Script
# Complete deployment workflow with validation at each step
#
# Prerequisites:
# - OCI CLI configured (~/.oci/config)
# - Terraform installed
# - SSH key pair available
#
# Usage: ./deploy_perftest.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "\n${BLUE}========== $1 ==========${NC}\n"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform/environments/perftest"
REGION="${OCI_REGION:-us-phoenix-1}"
SSH_KEY="${SSH_KEY:-~/.ssh/id_ed25519}"
LOCAL_PORT_BASE=22220

cd "$TERRAFORM_DIR"

# Function to wait for user confirmation
confirm() {
    echo -e "${YELLOW}"
    read -p "$1 [y/N] " response
    echo -e "${NC}"
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

log_step "Phase 1: Pre-flight Checks"

# Check OCI CLI
log_info "Checking OCI CLI..."
if ! command -v oci &> /dev/null; then
    log_error "OCI CLI not found. Please install: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm"
    exit 1
fi
oci --version

# Check Terraform
log_info "Checking Terraform..."
if ! command -v terraform &> /dev/null; then
    log_error "Terraform not found. Please install: https://www.terraform.io/downloads"
    exit 1
fi
terraform version

# Check SSH key
log_info "Checking SSH key..."
if [ ! -f "$SSH_KEY" ]; then
    log_error "SSH key not found at $SSH_KEY"
    exit 1
fi
log_info "SSH key: $SSH_KEY"

log_step "Phase 2: Terraform Validation"

log_info "Initializing Terraform..."
terraform init

log_info "Validating Terraform configuration..."
terraform validate

log_info "Planning infrastructure..."
terraform plan -out=tfplan

log_warn "Review the plan above."
if ! confirm "Do you want to apply this plan?"; then
    log_info "Deployment cancelled."
    exit 0
fi

log_step "Phase 3: Infrastructure Deployment"

log_info "Applying Terraform plan..."
terraform apply tfplan

log_info "Getting instance details..."
INSTANCE_IDS=$(terraform output -json instance_ids 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")
PRIVATE_IPS=$(terraform output -json private_ips 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")
BASTION_ID=$(terraform output -raw bastion_id 2>/dev/null || echo "")

if [ -z "$INSTANCE_IDS" ]; then
    log_error "Could not get instance IDs from Terraform output"
    exit 1
fi

log_info "Instance IDs: $INSTANCE_IDS"
log_info "Private IPs: $PRIVATE_IPS"
log_info "Bastion ID: $BASTION_ID"

log_step "Phase 4: Wait for Instances"

for INSTANCE_ID in $INSTANCE_IDS; do
    log_info "Waiting for instance $INSTANCE_ID to be RUNNING..."
    oci compute instance get \
        --instance-id "$INSTANCE_ID" \
        --query 'data."lifecycle-state"' \
        --raw-output

    # Wait up to 5 minutes
    TIMEOUT=300
    ELAPSED=0
    while [ $ELAPSED -lt $TIMEOUT ]; do
        STATE=$(oci compute instance get --instance-id "$INSTANCE_ID" --query 'data."lifecycle-state"' --raw-output)
        if [ "$STATE" = "RUNNING" ]; then
            log_info "Instance $INSTANCE_ID is RUNNING"
            break
        fi
        log_info "State: $STATE, waiting..."
        sleep 10
        ELAPSED=$((ELAPSED + 10))
    done

    if [ "$STATE" != "RUNNING" ]; then
        log_error "Instance $INSTANCE_ID did not reach RUNNING state within timeout"
        exit 1
    fi
done

log_step "Phase 5: Wait for Bastion"

if [ -n "$BASTION_ID" ]; then
    log_info "Waiting for Bastion $BASTION_ID to be ACTIVE..."

    TIMEOUT=300
    ELAPSED=0
    while [ $ELAPSED -lt $TIMEOUT ]; do
        STATE=$(oci bastion bastion get --bastion-id "$BASTION_ID" --query 'data."lifecycle-state"' --raw-output)
        if [ "$STATE" = "ACTIVE" ]; then
            log_info "Bastion is ACTIVE"
            break
        fi
        log_info "Bastion state: $STATE, waiting..."
        sleep 15
        ELAPSED=$((ELAPSED + 15))
    done

    if [ "$STATE" != "ACTIVE" ]; then
        log_error "Bastion did not reach ACTIVE state within timeout"
        exit 1
    fi
fi

log_step "Phase 6: Create Bastion Sessions and Test SSH"

PORT_INDEX=0
for IP in $PRIVATE_IPS; do
    LOCAL_PORT=$((LOCAL_PORT_BASE + PORT_INDEX))
    log_info "Creating bastion session for $IP..."

    # Create session
    SESSION_OUTPUT=$(oci bastion session create-port-forwarding \
        --bastion-id "$BASTION_ID" \
        --target-private-ip "$IP" \
        --target-port 22 \
        --ssh-public-key-file "${SSH_KEY}.pub" \
        --session-ttl 10800 \
        --wait-for-state SUCCEEDED \
        --wait-for-state FAILED \
        2>&1) || true

    SESSION_ID=$(echo "$SESSION_OUTPUT" | jq -r '.data.id // empty' 2>/dev/null || echo "")

    if [ -z "$SESSION_ID" ]; then
        log_warn "Could not create session for $IP - may already exist"
        # Try to find existing session
        SESSION_ID=$(oci bastion session list \
            --bastion-id "$BASTION_ID" \
            --session-lifecycle-state ACTIVE \
            --query "data[?\"target-resource-details\".\"target-resource-private-ip-address\"=='$IP'] | [0].id" \
            --raw-output 2>/dev/null || echo "")
    fi

    if [ -n "$SESSION_ID" ] && [ "$SESSION_ID" != "null" ]; then
        log_info "Session ID: $SESSION_ID"
        log_info "SSH tunnel command:"
        echo "  ssh -i $SSH_KEY -N -L $LOCAL_PORT:$IP:22 -p 22 $SESSION_ID@host.bastion.$REGION.oci.oraclecloud.com &"
        echo "  ssh -i $SSH_KEY -p $LOCAL_PORT opc@localhost"
    else
        log_warn "No session available for $IP"
    fi

    PORT_INDEX=$((PORT_INDEX + 1))
done

log_step "Phase 7: Summary"

log_info "============================================"
log_info "Deployment Complete!"
log_info "============================================"
log_info ""
log_info "Instances deployed: $(echo $PRIVATE_IPS | wc -w | tr -d ' ')"
log_info "Private IPs: $PRIVATE_IPS"
log_info ""
log_info "Next steps:"
log_info "1. Establish SSH tunnel using the commands above"
log_info "2. SSH to each instance and run: sudo dnf install -y sysbench"
log_info "3. Or use the post_boot_setup.sh script:"
log_info "   $SCRIPT_DIR/post_boot_setup.sh <target_ip> <session_id>"
log_info ""
log_info "4. Run benchmark: sudo -u pcc /home/pcc/run_benchmark.sh"
log_info ""
