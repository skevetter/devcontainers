#!/bin/bash

set -e

cd "$(dirname "$0")" || exit 1
source test-utils.sh

#------------------------------------------------------------------------------
# Environment
#------------------------------------------------------------------------------

echo "==================== Test Environment ===================="
env | grep -E "(GO|PYTHON|RUST|AWS|DOCKER|PATH|HIST|PRE_COMMIT)" || true
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

check "distro" lsb_release -cs
test_command_exists git
test_command_version git

#------------------------------------------------------------------------------
# Programming Languages
#------------------------------------------------------------------------------

echo "Testing programming languages"

# Python
test_command_exists python3
test_command_exists pip3
test_command_version python3
test_command_version pip3

#------------------------------------------------------------------------------
# DevOps Tools
#------------------------------------------------------------------------------

echo "Testing DevOps tools"

# Act (GitHub Actions)
test_command_exists act
test_command_version act

# Github CLI
test_command_exists gh
test_command_version gh

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

#------------------------------------------------------------------------------
# Permissions and Environment
#------------------------------------------------------------------------------

echo "Testing permissions and environment"

# Git configuration
check_quiet "git config accessible" git config --list

# Home directory writable
test_directory_writable "$HOME"

# Workspace directory accessible
check_quiet "workspace accessible" test -d "/workspaces"

#------------------------------------------------------------------------------
# Report Results
#------------------------------------------------------------------------------

echo "Tests completed!"
reportResults
