#!/bin/sh
# Setup git hooks to automatically build and sync AVR releases on commit

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "Setting core.hooksPath to .githooks..."
git config core.hooksPath .githooks
chmod +x .githooks/*

echo "Git hooks successfully installed!"
echo "Now, any commit modifying firmware/src/avr/ will automatically rebuild"
echo "and stage updated firmware binaries in firmware/releases/."
