#!/bin/bash
set -e

# --- Configuration ---
GPS_BINARY="${PWD}/target/release/gps"
TEST_ROOT_DIR="/tmp/git-ps-isolate-config-test"
REPO_DIR="${TEST_ROOT_DIR}/repo"
ORIGIN_REMOTE_DIR="${TEST_ROOT_DIR}/origin.git"

USER_NAME="Test User"
USER_EMAIL="test@example.com"

# --- Helper Functions ---
cleanup() {
    echo "Cleaning up test directory..."
    rm -rf "${TEST_ROOT_DIR}"
}

# Sets up a repository with one patch, ready for 'gps isolate 0'
setup_repo() {
    cleanup
    echo "Setting up repositories..."
    mkdir -p "${ORIGIN_REMOTE_DIR}"
    git -C "${ORIGIN_REMOTE_DIR}" init --bare
    
    mkdir -p "${REPO_DIR}"
    cd "${REPO_DIR}"

    git init -b main
    git config user.email "${USER_EMAIL}"
    git config user.name "${USER_NAME}"
    
    git remote add origin "${ORIGIN_REMOTE_DIR}"

    # Create a base commit and push it to establish the remote tracking branch
    git commit --allow-empty -m "Initial commit"
    git push origin main
    git config branch.main.remote origin
    git config branch.main.merge refs/heads/main

    # Create a patch
    git commit --allow-empty -m "feat: A new feature"
}

# --- Test Functions ---

test_defaults() {
    echo
    echo "--- Testing Default Behavior (no config) ---"
    setup_repo
    
    echo "Creating an untracked file..."
    echo "untracked content" > untracked.txt
    
    echo "Running 'gps isolate 0'..."
    # The default is include_untracked = false, so this should succeed
    if "${GPS_BINARY}" isolate 0; then
        echo "SUCCESS: 'gps isolate' succeeded with an untracked file, as expected by default."
    else
        echo "FAILURE: 'gps isolate' failed unexpectedly."
        exit 1
    fi
    cleanup
}

test_configured() {
    echo
    echo "--- Testing Configured Behavior (with config.toml) ---"
    setup_repo

    echo "Creating .git-ps/config.toml to include untracked files..."
    mkdir -p .git-ps
    cat > .git-ps/config.toml << EOL
[isolate]
include_untracked = true
EOL

    echo "Creating an untracked file..."
    echo "untracked content" > untracked.txt

    echo "Running 'gps isolate 0'..."
    # We expect this to fail because include_untracked = true
    # We redirect stderr to stdout to grep for the error message
    if ! "${GPS_BINARY}" isolate 0 2>&1 | grep -q "yours is dirty"; then
        echo "FAILURE: 'gps isolate' did not fail with the expected 'dirty' message."
        exit 1
    else
        echo "SUCCESS: 'gps isolate' failed as expected when configured to include untracked files."
    fi
    cleanup
}

# --- Main Execution ---
echo "Building 'gps' executable..."
cargo build --release

test_defaults
test_configured

echo
echo "All isolate config tests passed successfully."
