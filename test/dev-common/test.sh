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

# Docker tools
test_command_exists docker
test_command_version docker
check_quiet "docker daemon accessible" docker info

#------------------------------------------------------------------------------
# Programming Languages
#------------------------------------------------------------------------------

echo "Testing programming languages"

# Python
test_command_exists python3
test_command_exists pip3
test_command_version python3
test_command_version pip3

# Go
test_command_exists go
test_command_version go

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
# DevOps Tools
#------------------------------------------------------------------------------

echo "Testing DevOps tools"

# AWS CLI
test_command_exists aws
test_command_version aws

# Terraform
test_command_exists terraform
test_command_version terraform

# Act (GitHub Actions)
test_command_exists act
test_command_version act

# DevContainer CLI
test_command_exists devcontainer
test_command_version devcontainer

# Task runner
test_command_exists task
test_command_version task

# Mise (runtime manager)
test_command_exists mise
test_command_version mise

# UV (Python package manager)
test_command_exists uv
test_command_version uv

# Ruff (Python linter)
test_command_exists ruff
test_command_version ruff

# Wrangler (Cloudflare)
test_command_exists wrangler
test_command_version wrangler

# Pulumi
test_command_exists pulumi
test_command_version pulumi

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

# Docker permissions
check_quiet "docker permissions" docker ps

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
