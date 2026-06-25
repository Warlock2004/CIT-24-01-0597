# Todo App — Docker Deployment

A simple full-stack **Todo** web application deployed with Docker. It consists of two services communicating over a private Docker network, with todo data persisted in a named Docker volume.

---

## Deployment Requirements

| Software | Minimum Version | Purpose |
|---|---|---|
| Docker Engine | 24.x | Container runtime |
| Docker Compose *(optional)* | v2.x | Compose-based deployment |
| Bash | 3.x | Running the shell scripts |

> Docker Compose is only required for the optional `docker-compose.yaml` workflow. All four shell scripts work with plain Docker.

---

## Application Description

A **full-stack todo manager** that lets users:

- Add, complete, and delete tasks.
- Filter tasks by status (All / Active / Done).
- Persist tasks across container restarts using a named Docker volume.

### Architecture

```
Browser
  │  HTTP :8080
  ▼
┌─────────────────────┐
│  todo-frontend      │  Nginx (port 80 inside, 8080 outside)
│  Serves static SPA  │
│  Proxies /api/ ──►  │
└────────┬────────────┘
         │  HTTP :5000  (todo-net)
         ▼
┌─────────────────────┐
│  todo-backend       │  Python / Flask / Gunicorn (port 5000)
│  REST API           │
│  SQLite DB ──────►  │── todo-data volume (/data/todos.db)
└─────────────────────┘
```

---

## Network and Volume Details

### Network — `todo-net`

| Property | Value |
|---|---|
| Name | `todo-net` |
| Driver | `bridge` |
| Purpose | Private network for inter-container communication. The backend is **not** exposed externally; only the frontend publishes a port to the host. |

### Volume — `todo-data`

| Property | Value |
|---|---|
| Name | `todo-data` |
| Mounted in | `todo-backend` at `/data` |
| Contents | `todos.db` — SQLite database file |
| Purpose | Persists all todo records across container restarts and re-deployments. |

---

## Container Configuration

### `todo-backend`

| Setting | Value |
|---|---|
| Image | `todo-backend:latest` (custom build from `backend/Dockerfile`) |
| Base image | `python:3.12-slim` |
| Internal port | `5000` |
| Network | `todo-net` |
| Volume mount | `todo-data:/data` |
| Environment | `DB_PATH=/data/todos.db` |
| Restart policy | `on-failure` |
| Health check | `GET http://localhost:5000/api/health` every 15 s |
| Runtime | Gunicorn (2 workers) |

### `todo-frontend`

| Setting | Value |
|---|---|
| Image | `todo-frontend:latest` (custom build from `frontend/Dockerfile`) |
| Base image | `nginx:1.27-alpine` |
| Host port → container port | `8080 → 80` |
| Network | `todo-net` |
| Restart policy | `on-failure` |
| Depends on | `todo-backend` (healthy) |

---

## Container List

| Container Name | Role |
|---|---|
| `todo-backend` | REST API built with Flask. Manages todo CRUD operations; stores data in SQLite on the persistent volume. |
| `todo-frontend` | Nginx web server. Serves the static single-page application and reverse-proxies `/api/` requests to the backend. |

---

## Instructions

### Prepare (build images + create resources)

```bash
./prepare-app.sh
```

This builds both Docker images, creates the `todo-net` network, and creates the `todo-data` volume. Safe to run multiple times — existing resources are skipped.

### Start

```bash
./start-app.sh
```

Starts both containers. The backend is started first and the script waits for its health check to pass before starting the frontend.

### Access

Open a browser and navigate to:

```
http://localhost:8080
```

### Stop (preserves data)

```bash
./stop-app.sh
```

Stops and removes the containers. The `todo-data` volume is **not** deleted, so all todos are preserved for the next start.

### Remove (deletes everything)

```bash
./remove-app.sh
```

Removes containers, images, the network, and the volume. **All persisted data will be lost.**

---

## Optional: Docker Compose Workflow

If Docker Compose is installed you can use it instead of the shell scripts:

```bash
# Build images
docker compose build

# Start all services
docker compose up -d

# Stop (preserves volume)
docker compose down

# Stop and remove everything including the volume
docker compose down --volumes --rmi all
```

---

## Example Workflow

```bash
# 1. Create all application resources
./prepare-app.sh
# Preparing app ...
# ...
# Preparation complete. Run ./start-app.sh to start the application.

# 2. Run the application
./start-app.sh
# Running app ...
# ...
# The app is available at http://localhost:8080

# 3. Open a web browser and interact with the application
#    → Add some todos, check them off, delete them

# 4. Pause the application (data is preserved)
./stop-app.sh
# Stopping app ...
# App stopped. Persistent data is preserved in the 'todo-data' volume.

# 5. Restart — todos reappear exactly as left
./start-app.sh
# Running app ...
# The app is available at http://localhost:8080

# 6. Delete all application resources
./remove-app.sh
# Removing app ...
# Removed app.
```

---

## API Reference

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/health` | Health check |
| GET | `/api/todos` | List all todos |
| POST | `/api/todos` | Create a todo `{"title": "..."}` |
| PUT | `/api/todos/<id>` | Update a todo `{"done": 1}` |
| DELETE | `/api/todos/<id>` | Delete a todo |

---

## File Structure

```
.
├── backend/
│   ├── app.py              # Flask REST API
│   ├── requirements.txt    # Python dependencies
│   └── Dockerfile
├── frontend/
│   ├── html/
│   │   └── index.html      # Single-page application
│   ├── nginx.conf          # Nginx reverse-proxy config
│   └── Dockerfile
├── prepare-app.sh          # Build images; create network & volume
├── start-app.sh            # Start containers
├── stop-app.sh             # Stop containers (data preserved)
├── remove-app.sh           # Remove all resources
├── docker-compose.yaml     # Optional Compose config
└── README.md
```
