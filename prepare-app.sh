#!/usr/bin/env bash
set -e

echo "Preparing app ..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Build backend image
echo "  [1/4] Building backend image ..."
docker build -t todo-backend:latest "$SCRIPT_DIR/backend"

# Build frontend image
echo "  [2/4] Building frontend image ..."
docker build -t todo-frontend:latest "$SCRIPT_DIR/frontend"

# Create Docker network (skip if already exists)
echo "  [3/4] Creating network 'todo-net' ..."
docker network inspect todo-net >/dev/null 2>&1 || \
  docker network create --driver bridge todo-net

# Create named volume for persistent data (skip if already exists)
echo "  [4/4] Creating volume 'todo-data' ..."
docker volume inspect todo-data >/dev/null 2>&1 || \
  docker volume create todo-data

echo ""
echo "Preparation complete. Run ./start-app.sh to start the application."
