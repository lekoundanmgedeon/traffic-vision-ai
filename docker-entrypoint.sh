#!/bin/sh
set -e

# Create runtime directories
mkdir -p /app/models /app/uploads /app/outputs /app/outputs/logs

# If no model (.pt) exists in /app/models, try to download from MODEL_URL
if ! ls /app/models/*.pt 1> /dev/null 2>&1; then
  if [ -n "$MODEL_URL" ]; then
    echo "No model found in /app/models. Downloading from MODEL_URL..."
    if command -v curl >/dev/null 2>&1; then
      curl -L "$MODEL_URL" -o /app/models/best.pt
    elif command -v wget >/dev/null 2>&1; then
      wget -O /app/models/best.pt "$MODEL_URL"
    else
      echo "Neither curl nor wget available to download model. Skipping download."
    fi
  else
    echo "Warning: No .pt model found in /app/models and MODEL_URL not provided."
    echo "Place your model file (example: yolo11s.pt or best.pt) under /app/models."
  fi
else
  echo "Model file found in /app/models. Using existing model(s)."
fi

# If the first argument looks like an option (starts with -), prepend the default CMD
if [ "${1#-}" != "$1" ]; then
  set -- gunicorn --workers 2 --threads 2 --bind 0.0.0.0:${PORT:-5000} run:app
fi

# If any of the arguments contain unexpanded shell-style variables (like ${PORT}),
# join them into a single command string and eval it so environment variables
# are expanded before exec. This avoids passing literal `${PORT:-5000}` to gunicorn
# when Docker provided CMD as a JSON array (which doesn't expand shell vars).
cmd="$*"
if echo "$cmd" | grep -q '\${'; then
  eval "exec $cmd"
else
  exec "$@"
fi
