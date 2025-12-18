#!/bin/bash
cd "$(dirname "$0")" || exit 1
source test-utils.sh

# Template specific tests
check "distro" lsb_release -cs

# Report result
reportResults
