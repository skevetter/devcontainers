#!/bin/bash

set -e

cd "$(dirname "$0")" || exit 1
source test-utils.sh

#------------------------------------------------------------------------------
# Environment
#------------------------------------------------------------------------------

echo "==================== Test Environment ===================="
env | grep -E "(NODE|NPM|DOCKER|GH|RUST|CARGO|PATH|HIST|PRE_COMMIT)" || true
echo "==========================================================="

#------------------------------------------------------------------------------
# Feature Tests
#------------------------------------------------------------------------------

test_shell_history_feature
test_precommit_cache_feature

#------------------------------------------------------------------------------
# Core Tools Installation
#------------------------------------------------------------------------------

echo "Testing core development tools"

# Basic system tools
check "distro" lsb_release -cs
test_command_exists git
test_command_version git

# Docker tools
test_command_exists docker
test_command_version docker
check_quiet "docker daemon accessible" docker info

# GitHub CLI
test_command_exists gh
test_command_version gh

# Node.js ecosystem (if available)
if command -v node >/dev/null 2>&1; then
    test_command_exists node
    test_command_exists npm
    test_command_version node
    test_command_version npm
fi

# Rust
test_command_exists rustc
test_command_exists cargo
test_command_version rustc
test_command_version cargo

# Rust package download test
echo "Testing Rust package download and permissions"
check_quiet "cargo registry access" bash -c 'cargo search serde --limit 1 > /dev/null'
check_quiet "install rust package" cargo install ripgrep --version 14.1.0
check_quiet "installed package works" rg --version
check_quiet "uninstall rust package" cargo uninstall ripgrep

#------------------------------------------------------------------------------
# DevContainer Tools
#------------------------------------------------------------------------------

echo "Testing devcontainer tools"

test_command_exists devcontainer
test_command_version devcontainer

# Act (GitHub Actions runner)
test_command_exists act
test_command_version act

#------------------------------------------------------------------------------
# Development Environment
#------------------------------------------------------------------------------

echo "Testing development environment setup"

# Pre-commit
test_command_exists pre-commit
test_command_version pre-commit

# Biome
test_command_exists biome
test_command_version biome

# FZF
test_command_exists fzf
test_command_version fzf

# Lazygit
test_command_exists lazygit
test_command_version lazygit

# Neovim
test_command_exists nvim
test_command_version nvim

# Shfmt
test_command_exists shfmt
test_command_version shfmt

# Protoc
test_command_exists protoc
test_command_version protoc

# Ginkgo (Go testing framework)
test_command_exists ginkgo
test_command_version ginkgo

# Goimports (Go imports formatter)
test_command_exists goimports
check_quiet "goimports can run" goimports /dev/null

#------------------------------------------------------------------------------
# Permissions and Environment
#------------------------------------------------------------------------------

echo "Testing permissions and environment"

# Docker permissions
check_quiet "docker permissions" docker ps

# Git configuration
check_quiet "git config accessible" git config --list

# Home directory writable
test_directory_writable "$HOME"

# Workspace directory accessible
check_quiet "workspace accessible" test -d "/workspaces"

#------------------------------------------------------------------------------
# Feature Integration Tests
#------------------------------------------------------------------------------

echo "Testing feature integrations"

# Test pre-commit functionality
TEMP_REPO="/tmp/test_repo_$$"
check_quiet "create test git repo" bash -c "
    mkdir -p '$TEMP_REPO' &&
    cd '$TEMP_REPO' &&
    git init &&
    git config user.email 'test@example.com' &&
    git config user.name 'Test User'
"

# Test biome can process files (exit code doesn't matter for this test)
check_quiet "biome format test" bash -c "
    cd '$TEMP_REPO' &&
    echo 'const x=1;' > test.js &&
    biome format test.js || true
"

# Cleanup
rm -rf "$TEMP_REPO"

#------------------------------------------------------------------------------
# Report Results
#------------------------------------------------------------------------------

echo "Tests completed!"
reportResults
