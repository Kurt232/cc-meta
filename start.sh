#!/bin/bash
# Entry point: launch Claude Code for this project
# Each invocation creates a git worktree for isolation. Run multiple times for multiple workers.
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

# --- Path A: Inside container ---
if [ "${CC_IN_CONTAINER:-}" = "1" ]; then
    git config --global --add safe.directory /workspace
    git config --global user.name "${GIT_USER_NAME:-cc-worker}"
    git config --global user.email "${GIT_USER_EMAIL:-cc-worker@noreply}"

    CLAUDE_ARGS=(--dangerously-skip-permissions)
    [ -n "${MODEL:-}" ]  && CLAUDE_ARGS+=(--model "$MODEL")
    [ -n "${EFFORT:-}" ] && CLAUDE_ARGS+=(--effort "$EFFORT")

    if [ -n "$1" ]; then
        TIMEOUT=${TIMEOUT:-300}
        timeout "$TIMEOUT" claude "${CLAUDE_ARGS[@]}" -p "$1"
    else
        claude "${CLAUDE_ARGS[@]}"
    fi
    exit 0
fi

# --- Path B: Docker mode (host) ---
AUTH_DIR="$PROJECT_DIR/.docker-claude"
mkdir -p "$AUTH_DIR/config"
[ ! -f "$AUTH_DIR/claude.json" ] && echo '{}' > "$AUTH_DIR/claude.json"

# Create worktree for isolation
WORKER_ID="$(date +%s)-$$"
BRANCH="worker-${PROJECT_NAME}-${WORKER_ID}"
WORKER_DIR="$PROJECT_DIR/.worktrees/worker-${WORKER_ID}"

git worktree add -b "$BRANCH" "$WORKER_DIR" HEAD
echo "Worktree: $WORKER_DIR (branch: $BRANCH)"

# Auto-rebuild if Dockerfile or compose.yml changed
BUILD_FLAG=()
BUILD_HASH_FILE="$AUTH_DIR/.build-hash"
CURRENT_HASH="$(cat "$PROJECT_DIR/Dockerfile" "$PROJECT_DIR/compose.yml" 2>/dev/null | shasum -a 256 | cut -d' ' -f1)"
if [ ! -f "$BUILD_HASH_FILE" ] || [ "$(cat "$BUILD_HASH_FILE")" != "$CURRENT_HASH" ]; then
    echo "Dockerfile or compose.yml changed, rebuilding image..."
    BUILD_FLAG=(--build)
    echo "$CURRENT_HASH" > "$BUILD_HASH_FILE"
fi

# Run container with worktree mounted
export PROJECT_NAME
export GIT_USER_NAME="${GIT_USER_NAME:-$(git config user.name 2>/dev/null || echo cc-worker)}"
export GIT_USER_EMAIL="${GIT_USER_EMAIL:-$(git config user.email 2>/dev/null || echo cc-worker@noreply)}"
COMPOSE_PROJECT_DIR="$PROJECT_DIR" docker compose \
    -f "$PROJECT_DIR/compose.yml" \
    run --rm "${BUILD_FLAG[@]}" \
    -v "$(cd "$WORKER_DIR" && pwd):/workspace" \
    worker "$@"
