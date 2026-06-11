#!/usr/bin/env bash
# Focus Clock — one-click run
# Usage: ./run.sh [device]   default: linux desktop

set -e

DEVICE=${1:-linux}

echo "▶ Running Focus Clock on: $DEVICE"
flutter run -d "$DEVICE"
