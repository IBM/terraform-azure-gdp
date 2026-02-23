#!/bin/bash

#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/central_manager/run_guardium_phase2.sh
# Wrapper script for Guardium Phase 2 configuration

set -euo pipefail

# Check arguments
if [ $# -ne 3 ]; then
    echo "Usage: $0 <IP> <final_password> <shared_secret>"
    echo "Example: $0 192.168.1.100 'MyCliSecurePassword123!' MySharedSecret123"
    echo "Note: Put single quotes around the password if it has special characters."
    exit 1
fi

IP="$1"
FINAL_PASSWORD="$2"
SHARED_SECRET="$3"

echo "=========================================="
echo "GUARDIUM PHASE 2 CONFIGURATION"
echo "IP: $IP"
echo "Time: $(date)"
echo "=========================================="

# Check if expect script exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPECT_SCRIPT="$SCRIPT_DIR/wait_for_guardium_phase2.expect"

if [ ! -f "$EXPECT_SCRIPT" ]; then
    echo "Error: Expect script not found at $EXPECT_SCRIPT"
    exit 1
fi

# Make sure expect script is executable
chmod +x "$EXPECT_SCRIPT"

# Test connectivity first
echo "Testing connectivity to $IP:22..."
if ! nc -z -w10 "$IP" 22 >/dev/null 2>&1; then
    echo "Error: Cannot reach $IP on port 22"
    exit 1
fi

echo "Connection test passed. Starting Phase 2 configuration..."
echo "Note: Phase 2 may take up to about 5 minutes. Please do not interrupt..."

# Measure runtime
start_ts=$(date +%s)

# Run the expect script
"$EXPECT_SCRIPT" "$IP" "$FINAL_PASSWORD" "$SHARED_SECRET"
rc=$?

end_ts=$(date +%s)
duration=$(( end_ts - start_ts ))
mins=$(( duration / 60 ))
secs=$(( duration % 60 ))

echo "=========================================="
echo "Phase 2 runtime: ${mins}m ${secs}s (total ${duration}s)"
echo "=========================================="

if [ $rc -eq 0 ]; then
    echo "Phase 2 configuration completed successfully!"
    echo "Guardium Central Manager is now fully configured."
    echo "=========================================="
    exit 0
else
    echo "Phase 2 configuration failed!"
    echo "Please check the logs and try again."
    echo "=========================================="
    exit 1
fi
