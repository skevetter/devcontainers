#!/bin/bash

set -e

cd "$(dirname "$0")" || exit 1
source test-utils.sh

#------------------------------------------------------------------------------
# Environment
#------------------------------------------------------------------------------

echo "==================== Test Environment ===================="
env | grep -E "(RUST|CARGO|PATH|HIST|PRE_COMMIT)" || true
echo "==========================================================="

#------------------------------------------------------------------------------
# Feature Tests
#------------------------------------------------------------------------------

test_shell_history_feature
test_precommit_cache_feature

#------------------------------------------------------------------------------
# Rust Installation Checks
#------------------------------------------------------------------------------

echo "Testing Rust installation and permissions"

test_command_exists rustc
test_command_exists cargo
test_command_version rustc
test_command_version cargo

#------------------------------------------------------------------------------
# Permission Tests
#------------------------------------------------------------------------------

echo "Testing user permissions for Rust development"

check_quiet "cargo install permissions" bash -c 'cargo install --list > /dev/null 2>&1'

# Test creating a temporary Rust project
TEMP_PROJECT="/tmp/test_rust_project_$$"
check_quiet "create test rust project" cargo new "$TEMP_PROJECT" --bin
check_quiet "build test project" bash -c "cd '$TEMP_PROJECT' && cargo build"
check_quiet "run test project" bash -c "cd '$TEMP_PROJECT' && cargo run"

# Test adding a dependency
check_quiet "add dependency" bash -c "cd '$TEMP_PROJECT' && cargo add serde --no-default-features"
check_quiet "build with dependency" bash -c "cd '$TEMP_PROJECT' && cargo build"

# Cleanup
rm -rf "$TEMP_PROJECT"

#------------------------------------------------------------------------------
# Cargo Registry Access
#------------------------------------------------------------------------------

echo "Testing cargo registry access"

check_quiet "cargo search works" bash -c 'cargo search serde --limit 1 > /dev/null'

#------------------------------------------------------------------------------
# Environment Setup Validation
#------------------------------------------------------------------------------

echo "Testing environment setup"

check_quiet "CARGO_HOME exists" test -d "${CARGO_HOME:-$HOME/.cargo}"
test_directory_writable "${CARGO_HOME:-$HOME/.cargo}"
check_quiet "cargo bin in PATH" bash -c "echo \"\$PATH\" | grep -q \"\${CARGO_HOME:-\$HOME/.cargo}/bin\""

# Verify user can install global crates
check_quiet "install global crate" cargo install --force cargo-tree
check_quiet "global crate works" cargo tree --version
check_quiet "uninstall global crate" cargo uninstall cargo-tree

#------------------------------------------------------------------------------
# Report Results
#------------------------------------------------------------------------------

echo "Tests completed!"
reportResults
