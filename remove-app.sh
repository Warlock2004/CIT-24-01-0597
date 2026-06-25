#!/usr/bin/env bash

echo "Removing app ..."

# Stop and remove containers
for container in todo-frontend todo-backend; do
  if docker inspect "$container" >/dev/null 2>&1; then
    echo "  Removing container $container ..."
    docker rm -f "$container"
  fi
done

# Remove images
for image in todo-frontend:latest todo-backend:latest; do
  if docker image inspect "$image" >/dev/null 2>&1; then
    echo "  Removing image $image ..."
    docker rmi "$image"
  fi
done

# Remove network
if docker network inspect todo-net >/dev/null 2>&1; then
  echo "  Removing network todo-net ..."
  docker network rm todo-net
fi

# Remove named volume (WARNING: this deletes all persisted todo data)
if docker volume inspect todo-data >/dev/null 2>&1; then
  echo "  Removing volume todo-data (all persisted data will be lost) ..."
  docker volume rm todo-data
fi

echo ""
echo "Removed app."
