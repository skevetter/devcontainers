#!/bin/bash

PASS_COUNT=0
FAIL_COUNT=0
FAILED=()

echoStderr() {
    echo "$@" 1>&2
}

check() {
    local test_name="$1"
    shift
    echo -e "\n🧪 Testing $test_name"
    if "$@" >/dev/null 2>&1; then
        echo "✅ PASS: $test_name"
        PASS_COUNT=$((PASS_COUNT + 1))
        return 0
    else
        echo "❌ FAIL: $test_name"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED+=("$test_name")
        return 1
    fi
}

# Quiet version for batch testing
check_quiet() {
    local test_name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "✓ PASS: $test_name"
        PASS_COUNT=$((PASS_COUNT + 1))
        return 0
    else
        echo "✗ FAIL: $test_name"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED+=("$test_name")
        return 1
    fi
}

reportResults() {
    echo
    echo "==================== Test Results ===================="
    echo "PASSED: $PASS_COUNT"
    echo "FAILED: $FAIL_COUNT"
    echo "TOTAL:  $((PASS_COUNT + FAIL_COUNT))"

    if [ $FAIL_COUNT -eq 0 ]; then
        echo "🎉 All tests passed!"
        exit 0
    else
        echo "❌ Failed tests: ${FAILED[*]}"
        exit 1
    fi
}

# Common test functions
test_command_exists() {
    local cmd="$1"
    check_quiet "$cmd command exists" command -v "$cmd"
}

test_command_version() {
    local cmd="$1"
    case "$cmd" in
        go)
            check_quiet "$cmd version works" go version
            ;;
        pulumi)
            check_quiet "$cmd version works" pulumi version
            ;;
        *)
            check_quiet "$cmd version works" "$cmd" --version
            ;;
    esac
}

test_environment_var() {
    local var_name="$1"
    check_quiet "$var_name is set" test -n "${!var_name}"
}

test_directory_writable() {
    local dir="$1"
    check_quiet "$dir is writable" test -w "$dir"
}

# Shell history feature tests
test_shell_history_feature() {
    echo "Testing shell history feature"

    # Check shell history directory exists
    check_quiet "shell history directory exists" test -d "/shellhistory"

    # Check history files exist
    check_quiet "bash history file exists" test -f "/shellhistory/.bash_history"
    check_quiet "zsh history file exists" test -f "/shellhistory/.zsh_history"

    # Check HISTFILE environment variable
    test_environment_var "HISTFILE"

    # Test history persistence
    check_quiet "history persistence test" bash -c "
        echo 'test_command_$(date +%s)' >> /shellhistory/.bash_history &&
        test -s /shellhistory/.bash_history
    "

    # Check directory permissions
    check_quiet "shell history directory writable" test -w "/shellhistory"
}

# Pre-commit cache feature tests
test_precommit_cache_feature() {
    echo "Testing pre-commit cache feature"

    # Check pre-commit cache directory exists
    check_quiet "pre-commit cache directory exists" test -d "/pre_commit_cache"

    # Check PRE_COMMIT_HOME environment variable
    test_environment_var "PRE_COMMIT_HOME"

    # Check cache database exists
    check_quiet "pre-commit cache database exists" test -f "/pre_commit_cache/db.db"

    # Check directory permissions
    check_quiet "pre-commit cache directory writable" test -w "/pre_commit_cache"

    # Test cache functionality
    check_quiet "pre-commit cache functional" bash -c "
        cd /tmp &&
        git init test_precommit &&
        cd test_precommit &&
        git config user.email 'test@example.com' &&
        git config user.name 'Test User' &&
        echo 'repos: []' > .pre-commit-config.yaml &&
        pre-commit install > /dev/null 2>&1
    "

    # Cleanup
    rm -rf /tmp/test_precommit 2>/dev/null || true
}
