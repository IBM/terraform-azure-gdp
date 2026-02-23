#!/bin/bash

#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/central_manager/run_wait_for_guardium.sh

set -euo pipefail


PRIVATE_IP="${1:?Missing private IP argument}"
FINAL_PW="${2:?Missing final password argument}"
SUBNET_MASK="${3:?Missing subnet mask argument}"
GATEWAY="${4:?Missing default gateway argument}"
RESOLVER1="${5:?Missing primary resolver argument}"
RESOLVER2="${6:-}"
HOSTNAME="${7:?Missing hostname argument}"
DOMAIN="${8:?Missing domain argument}"
TIMEZONE="${9:-America/New_York}"
LICENSE_KEY="${10:?Missing license key argument}"
SHARED_SECRET="${11:-}"
CENTRAL_MANAGER_IP="${12:-}"

# Guardium v12 default CLI password
DEFAULT_PW="guardium"

function to_dotted_mask() {
  local mask="$1"
  if [[ "$mask" == /* ]]; then
    local cidr="${mask#/}"
    case "$cidr" in
      16) echo "255.255.0.0" ;;
      20) echo "255.255.240.0" ;;
      23) echo "255.255.254.0" ;;
      24) echo "255.255.255.0" ;;
      25) echo "255.255.255.128" ;;
      27) echo "255.255.255.224" ;;
      *)
        echo "Unsupported CIDR mask: $mask" >&2
        return 1
        ;;
    esac
  else
    echo "$mask"
  fi
}

DOTTED_MASK="$(to_dotted_mask "$SUBNET_MASK")"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPECT_SCRIPT="$SCRIPT_DIR/wait_for_guardium.expect"

if [ ! -f "$EXPECT_SCRIPT" ]; then
  echo "[ERROR] wait_for_guardium.expect not found in $SCRIPT_DIR"
  exit 1
fi

chmod +x "$EXPECT_SCRIPT"

MAX_RETRIES=3
for ((i=1; i<=MAX_RETRIES; i++)); do
  echo "[$(date '+%H:%M:%S')] Attempt $i for Guardium CLI on $PRIVATE_IP"

  if expect "$EXPECT_SCRIPT" \
      "$PRIVATE_IP" \
      "$DEFAULT_PW" \
      "$FINAL_PW" \
      "$PRIVATE_IP" \
      "$DOTTED_MASK" \
      "$GATEWAY" \
      "$RESOLVER1" \
      "$RESOLVER2" \
      "$HOSTNAME" \
      "$DOMAIN" \
      "$TIMEZONE" \
      "$LICENSE_KEY" \
      "$SHARED_SECRET" \
      "$CENTRAL_MANAGER_IP"; then
    echo "Guardium CLI configuration passed"
    exit 0
  fi

  echo "Attempt $i failed, retrying in 10 seconds..."
  sleep 10
done

echo "[ERROR] Guardium CLI configuration failed after $MAX_RETRIES attempts"
exit 1
