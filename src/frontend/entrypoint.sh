#!/bin/sh
set -eu

API_URL="${VITE_API_URL:-}"

TARGET="/usr/share/nginx/html/index.html"

if [ -f "$TARGET" ]; then
  # Replace the exact placeholder token inside the built index.html.
  # Use | as delimiter to reduce escaping needs for URLs.
  sed -i "s|__VITE_API_URL__|$API_URL|g" "$TARGET"
fi

exec "$@"
