from flask import Flask, request, jsonify
from flask_cors import CORS
import sqlite3
import os

app = Flask(__name__)
CORS(app)

DB_PATH = os.environ.get("DB_PATH", "/data/todos.db")

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = get_db()
    conn.execute("""
        CREATE TABLE IF NOT EXISTS todos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            done INTEGER NOT NULL DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.commit()
    conn.close()

@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})

@app.route("/api/todos", methods=["GET"])
def get_todos():
    conn = get_db()
    todos = conn.execute("SELECT * FROM todos ORDER BY created_at DESC").fetchall()
    conn.close()
    return jsonify([dict(t) for t in todos])

@app.route("/api/todos", methods=["POST"])
def create_todo():
    data = request.get_json()
    title = data.get("title", "").strip()
    if not title:
        return jsonify({"error": "Title is required"}), 400
    conn = get_db()
    cur = conn.execute("INSERT INTO todos (title) VALUES (?)", (title,))
    conn.commit()
    todo = conn.execute("SELECT * FROM todos WHERE id = ?", (cur.lastrowid,)).fetchone()
    conn.close()
    return jsonify(dict(todo)), 201

@app.route("/api/todos/<int:todo_id>", methods=["PUT"])
def update_todo(todo_id):
    data = request.get_json()
    conn = get_db()
    todo = conn.execute("SELECT * FROM todos WHERE id = ?", (todo_id,)).fetchone()
    if not todo:
        conn.close()
        return jsonify({"error": "Not found"}), 404
    title = data.get("title", todo["title"])
    done = int(data.get("done", todo["done"]))
    conn.execute("UPDATE todos SET title = ?, done = ? WHERE id = ?", (title, done, todo_id))
    conn.commit()
    updated = conn.execute("SELECT * FROM todos WHERE id = ?", (todo_id,)).fetchone()
    conn.close()
    return jsonify(dict(updated))

@app.route("/api/todos/<int:todo_id>", methods=["DELETE"])
def delete_todo(todo_id):
    conn = get_db()
    conn.execute("DELETE FROM todos WHERE id = ?", (todo_id,))
    conn.commit()
    conn.close()
    return jsonify({"deleted": todo_id})

init_db()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
