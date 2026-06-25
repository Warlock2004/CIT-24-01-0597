#!/usr/bin/env bash
set -e

echo "Running app ..."

# ── Backend ────────────────────────────────────────────────────────────────────
echo "  [1/2] Starting backend container ..."
docker run -d \
  --name todo-backend \
  --restart on-failure \
  --network todo-net \
  --volume todo-data:/data \
  --env DB_PATH=/data/todos.db \
  --health-cmd "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:5000/api/health')\"" \
  --health-interval 15s \
  --health-timeout 5s \
  --health-retries 3 \
  --health-start-period 10s \
  todo-backend:latest

# Wait for backend to become healthy before starting frontend
echo "  Waiting for backend to become healthy ..."
for i in $(seq 1 20); do
  STATUS=$(docker inspect --format='{{.State.Health.Status}}' todo-backend 2>/dev/null || echo "starting")
  if [ "$STATUS" = "healthy" ]; then
    echo "  Backend is healthy."
    break
  fi
  if [ "$i" -eq 20 ]; then
    echo "  WARNING: Backend health check timed out. Starting frontend anyway ..."
  fi
  sleep 2
done

# ── Frontend ───────────────────────────────────────────────────────────────────
echo "  [2/2] Starting frontend container ..."
docker run -d \
  --name todo-frontend \
  --restart on-failure \
  --network todo-net \
  --publish 8080:80 \
  todo-frontend:latest

echo ""
echo "The app is available at http://localhost:8080"
