#!/bin/sh
# Legacy launcher kept for backwards compatibility with old deploy scripts.
echo "[start.sh] preparing runtime for ${APP_NAME:-webapp}..."
mkdir -p /tmp/app
python /app/app.py
