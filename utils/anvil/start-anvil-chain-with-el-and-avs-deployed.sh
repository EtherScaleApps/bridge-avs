#!/bin/bash

RPC_URL=http://localhost:8545

# Ensure PATH includes the directory where cast is installed
export PATH="$HOME/.foundry/bin:$PATH"

# Source profile files to ensure environment variables are loaded
if [ -f "$HOME/.profile" ]; then
    source "$HOME/.profile"
fi
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi

# Verify cast command availability
echo "Verifying cast command availability..."
echo "Current PATH: $PATH"
which cast
cast --version

# cd to the directory of this script so that this can be run from anywhere
parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)
cd "$parent_path"

set -a
source ./utils.sh
set +a

cleanup() {
    echo "Executing cleanup function..."
    set +e
    docker rm -f anvil
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        echo "Script exited due to set -e on line $1 with command '$2'. Exit status: $exit_status"
    fi
}
trap 'cleanup $LINENO "$BASH_COMMAND"' EXIT

# Start an anvil instance in the background that has eigenlayer contracts deployed
# We start anvil in the background so that we can run the below script
# anvil --load-state avs-and-eigenlayer-deployed-anvil-state.json &
# FIXME: bug in latest foundry version, so we use this pinned version instead of latest
start_anvil_docker $parent_path/avs-and-eigenlayer-deployed-anvil-state.json ""

cd ../../contracts

# Advancing the chain manually
echo "Advancing the chain..."
cast rpc anvil_mine 100 --rpc-url $RPC_URL
echo "Advancing chain... current block-number:" $(cast block-number)

# Bring Anvil back to the foreground
docker attach anvil
