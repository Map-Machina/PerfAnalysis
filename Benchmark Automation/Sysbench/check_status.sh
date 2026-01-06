#!/bin/bash

# Quick status check script for benchmark progress

VM1_IP="4.155.247.78"
VM1_USER="azureuser"
VM1_NAME="pcc-test-01"

VM2_IP="4.155.213.76"
VM2_USER="testuser"
VM2_NAME="pcc-e2e-test"

echo "============================================"
echo "BENCHMARK STATUS - $(date)"
echo "============================================"
echo ""

for VM in "1" "2"; do
    eval "IP=\$VM${VM}_IP"
    eval "USER=\$VM${VM}_USER"
    eval "NAME=\$VM${VM}_NAME"

    echo "=== ${NAME} (${IP}) ==="
    ssh -o ConnectTimeout=10 ${USER}@${IP} "
        echo 'Processes:'
        pgrep -x pcc > /dev/null && echo '  ✓ pcc running' || echo '  ✗ pcc completed/stopped'
        pgrep -x sysbench > /dev/null && echo '  ✓ sysbench running' || echo '  ✗ sysbench completed/stopped'

        echo 'Files:'
        ls -lh ~/benchmark_results/*.json 2>/dev/null | awk '{print \"  \" \$9 \" (\" \$5 \")\"}' || echo '  No JSON files yet'
        ls -lh ~/benchmark_results/*.txt 2>/dev/null | awk '{print \"  \" \$9 \" (\" \$5 \")\"}' || echo '  No benchmark results yet'
    " 2>/dev/null || echo "  Could not connect to ${NAME}"
    echo ""
done

echo "============================================"
