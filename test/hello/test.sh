#!/bin/bash
cd "$(dirname "$0")" || exit 1
source test-utils.sh

# Template specific tests
check "distro" lsb_release -c
# Check that 'hey' appears in greeting file
check "greeting" grep -qF "hey" /usr/local/etc/greeting.txt

# Report result
reportResults
