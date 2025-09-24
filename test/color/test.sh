#!/bin/bash
cd "$(dirname "$0")" || exit 1
source test-utils.sh

# Template specific tests
check "distro" lsb_release -c
# Check that 'red' appears in /tmp/color.txt
check "color" grep -qF "red" /tmp/color.txt

# Report result
reportResults
