#!/bin/sh
set -e

# Chạy migration trước khi khởi động API.
python -m app.db.migrate

exec "$@"
