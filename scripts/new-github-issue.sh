#!/usr/bin/env bash
set -euo pipefail

OWNER=""
REPO=""
TITLE=""
BODY=""
FILE_PATH=""
TOKEN="${PRONATIVE_GH_TOKEN:-}"

usage() {
    echo "Usage: $0 -T <title> [-b <body>] [-f <file_path>] [-o <owner>] [-r <repo>] [-t <token>]"
    exit 1
}

while getopts "T:b:f:o:r:t:" opt; do
    case $opt in
        T) TITLE="$OPTARG" ;;
        b) BODY="$OPTARG" ;;
        f) FILE_PATH="$OPTARG" ;;
        o) OWNER="$OPTARG" ;;
        r) REPO="$OPTARG" ;;
        t) TOKEN="$OPTARG" ;;
        *) usage ;;
    esac
done

if [ -z "$TOKEN" ]; then
    echo "Error: No token. Set PRONATIVE_GH_TOKEN or pass -t."
    exit 1
fi

if [ -n "$FILE_PATH" ] && [ -n "$BODY" ]; then
    echo "Error: Provide -f or -b, not both."
    exit 1
fi

if [ -n "$FILE_PATH" ]; then
    if [ ! -f "$FILE_PATH" ]; then
        echo "Error: File not found: $FILE_PATH"
        exit 1
    fi
    BODY=$(cat "$FILE_PATH")
fi

if [ -z "$BODY" ]; then
    echo "Error: Issue body is required via -b or -f."
    exit 1
fi

if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
    REMOTE=$(git remote get-url origin 2>/dev/null || true)
    if echo "$REMOTE" | grep -qE "github\.com[:/]"; then
        REMOTE_CLEAN=$(echo "$REMOTE" | sed 's/\.git$//')
        OWNER=$(echo "$REMOTE_CLEAN" | sed -E 's#.*github\.com[:/]([^/]+)/([^/]+)#\1#')
        REPO=$(echo "$REMOTE_CLEAN" | sed -E 's#.*github\.com[:/]([^/]+)/([^/]+)#\2#')
    else
        echo "Error: Could not detect repo from git remote. Provide -o and -r."
        exit 1
    fi
fi

# Escape body for JSON (replace \ with \\, " with \", newlines with \n)
ESCAPED_BODY=$(printf '%s' "$BODY" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "{\"title\":\"$TITLE\",\"body\":\"$ESCAPED_BODY\"}" \
    "https://api.github.com/repos/$OWNER/$REPO/issues")

ISSUE_NUMBER=$(echo "$RESPONSE" | grep -o '"number": *[0-9]*' | head -1 | sed 's/"number": *//')
ISSUE_URL=$(echo "$RESPONSE" | grep -o '"html_url": *"[^"]*"' | head -1 | sed 's/"html_url": *"//;s/"$//')

if [ -n "$ISSUE_NUMBER" ]; then
    echo "Created issue #$ISSUE_NUMBER: $ISSUE_URL"
else
    echo "Failed to create issue."
    echo "$RESPONSE"
    exit 1
fi
