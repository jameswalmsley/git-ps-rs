#!/bin/bash
set -e

# --- Configuration ---
GPS_BINARY="${PWD}/target/release/gps"
TEST_ROOT_DIR="/tmp/git-ps-test-pr"
LOCAL_CLONE_DIR="${TEST_ROOT_DIR}/local-clone"
ORIGIN_REMOTE_DIR="${TEST_ROOT_DIR}/origin.git"

USER_NAME="Test User"
USER_EMAIL="test@example.com"

# --- Functions ---
cleanup() {
    echo "Cleaning up test directories..."
    rm -rf "${TEST_ROOT_DIR}"
}

setup_remotes() {
    echo "Setting up remote repository in ${TEST_ROOT_DIR}..."
    mkdir -p "${ORIGIN_REMOTE_DIR}"
    git -C "${ORIGIN_REMOTE_DIR}" init --bare
}

setup_local_repo() {
    echo "Cloning origin to create local repository in ${LOCAL_CLONE_DIR}..."
    cd "${TEST_ROOT_DIR}"
    git clone "${ORIGIN_REMOTE_DIR}" "${LOCAL_CLONE_DIR}"
    cd "${LOCAL_CLONE_DIR}"

    git config user.email "${USER_EMAIL}"
    git config user.name "${USER_NAME}"

    # Ensure main branch is created and pushed to origin
    git checkout -b main
    git commit --allow-empty -m "Initial commit"
    git push origin main

    # Explicitly set upstream tracking information
    git config branch.main.remote origin
    git config branch.main.merge refs/heads/main
}

create_test_scenario() {
    echo "Creating test scenario..."
    # Create an unrelated branch
    git checkout --orphan unrelated-branch
    echo "unrelated content" > unrelated.txt
    git add .
    git commit -m "Commit on unrelated branch"

    # Create a patch on main branch
    git checkout main
    echo "patch content" > patch.txt
    git add .
    git commit -m "feat: A new feature for review"
}

run_test() {
    echo "--- Running 'gps rr 0' test ---"
    echo "Executing: ${GPS_BINARY} rr 0 from ${LOCAL_CLONE_DIR}"
    cd "${LOCAL_CLONE_DIR}"
    # We expect this to pass with the fix
    "${GPS_BINARY}" rr 0
}

verify_results() {
    echo "--- Verifying Results ---"
    EXPECTED_BRANCH_NAME="ps/rr/feat__a_new_feature_for_review"
    echo "Checking branches on 'origin' remote (${ORIGIN_REMOTE_DIR}) for branch: ${EXPECTED_BRANCH_NAME}"
    if git -C "${ORIGIN_REMOTE_DIR}" branch | grep -q "${EXPECTED_BRANCH_NAME}"; then
        echo "SUCCESS: Review branch '${EXPECTED_BRANCH_NAME}' found on origin remote."
    else
        echo "FAILURE: Review branch '${EXPECTED_BRANCH_NAME}' NOT found on origin remote."
        exit 1
    fi
}

# --- Main execution ---
# Build gps before running the test
echo "Building 'gps' executable..."
cargo build --release

cleanup
setup_remotes
setup_local_repo
create_test_scenario
run_test
verify_results

echo "Test script finished successfully."
cleanup # Clean up again after successful run
