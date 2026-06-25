#!/usr/bin/env bash

echo "Stopping app ..."

# Stop containers (do NOT remove them — persistent data is preserved in the volume)
for container in todo-frontend todo-backend; do
  if docker inspect "$container" >/dev/null 2>&1; then
    echo "  Stopping $container ..."
    docker stop "$container"
    docker rm "$container"
  else
    echo "  $container is not running, skipping."
  fi
done

echo ""
echo "App stopped. Persistent data is preserved in the 'todo-data' volume."
echo "Run ./start-app.sh to restart the application."
