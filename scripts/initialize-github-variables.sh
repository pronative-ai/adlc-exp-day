#!/usr/bin/env bash
set -euo pipefail

OWNER=""
REPO=""
TOKEN="${PRONATIVE_GH_TOKEN:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"

usage() {
    echo "Usage: $0 [-e <enrollment_id>] [-o <owner>] [-r <repo>] [-t <token>]"
    echo ""
    echo "If -e is not provided, reads ENROLLMENT_ID from .env file."
    exit 1
}

parse_enrollment_number() {
    local enrollment_id="$1"
    local trailing_number
    trailing_number=$(echo "$enrollment_id" | grep -oE '[0-9]+$' || echo "")

    if [ -z "$trailing_number" ]; then
        echo "Error: No trailing number found in enrollment ID: $enrollment_id" >&2
        exit 1
    fi

    if [ "$trailing_number" -lt 1000 ]; then
        echo $((trailing_number + 1000))
    else
        echo "$trailing_number"
    fi
}

while getopts "e:o:r:t:" opt; do
    case $opt in
        e) ENROLLMENT_ID="$OPTARG" ;;
        o) OWNER="$OPTARG" ;;
        r) REPO="$OPTARG" ;;
        t) TOKEN="$OPTARG" ;;
        *) usage ;;
    esac
done

if [ -z "${ENROLLMENT_ID:-}" ]; then
    if [ -f "$ENV_FILE" ]; then
        ENROLLMENT_ID=$(grep -E '^ENROLLMENT_ID=' "$ENV_FILE" | cut -d'=' -f2- | tr -d '[:space:]')
    fi
fi

if [ -z "${ENROLLMENT_ID:-}" ]; then
    echo "Error: Enrollment ID is required. Provide -e or set ENROLLMENT_ID in .env"
    usage
fi

ENROLLMENT_NUMBER=$(parse_enrollment_number "$ENROLLMENT_ID")

if [ -z "$TOKEN" ]; then
    echo "Error: No token. Set PRONATIVE_GH_TOKEN or pass -t."
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

API_BASE="https://api.github.com/repos/$OWNER/$REPO/actions/variables"

declare -A ENROLLMENT_VARS=(
    ["CONTAINERAPP_NAME"]="ca-adlc-exp-$ENROLLMENT_NUMBER"
    ["COSMOSDB_NAME"]="cosmos-adlc-exp-$ENROLLMENT_NUMBER"
    ["RESOURCEGROUP_NAME"]="rg-adlc-exp-2608-$ENROLLMENT_NUMBER"
)

declare -A COMMON_VARS=(
    ["CLIENT_ID"]="429199bf-06e3-438d-8f5c-9bcb95d4249b"
    ["SUBSCRIPTION_ID"]="4969651e-74b0-4e8a-a81d-7fbb61c3fee5"
    ["TENANT_ID"]="eed1d2ca-7ca1-4fe3-8a1c-247a759acf93"
    ["COSMOS_DB_REGION"]="CentralIndia"
)

# Fetch existing variables
declare -A EXISTING
RESP=$(curl -s -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" "$API_BASE")

# Parse JSON using grep and sed (works without jq)
VARIABLES=$(echo "$RESP" | grep -o '"name": *"[^"]*"' | sed 's/"name": *"//;s/"//')
for name in $VARIABLES; do
    value=$(echo "$RESP" | grep -A1 "\"name\": *\"$name\"" | grep -o '"value": *"[^"]*"' | sed 's/"value": *"//;s/"//')
    EXISTING["$name"]="$value"
done

process_var() {
    local name="$1"
    local value="$2"

    if [ -n "${EXISTING[$name]:-}" ]; then
        if [ "${EXISTING[$name]}" = "$value" ]; then
            echo "SKIP (exists, same value): $name"
        else
            curl -s -X PATCH \
                -H "Authorization: Bearer $TOKEN" \
                -H "Accept: application/vnd.github+json" \
                -H "Content-Type: application/json; charset=utf-8" \
                -d "{\"name\":\"$name\",\"value\":\"$value\"}" \
                "$API_BASE/$name" > /dev/null
            echo "UPDATED: $name = $value"
        fi
    else
        curl -s -X POST \
            -H "Authorization: Bearer $TOKEN" \
            -H "Accept: application/vnd.github+json" \
            -H "Content-Type: application/json; charset=utf-8" \
            -d "{\"name\":\"$name\",\"value\":\"$value\"}" \
            "$API_BASE" > /dev/null
        echo "CREATED: $name = $value"
    fi
}

for name in "${!ENROLLMENT_VARS[@]}"; do
    process_var "$name" "${ENROLLMENT_VARS[$name]}"
done

for name in "${!COMMON_VARS[@]}"; do
    process_var "$name" "${COMMON_VARS[$name]}"
done

COUNT=$((${#ENROLLMENT_VARS[@]} + ${#COMMON_VARS[@]}))
echo ""
echo "Done. $COUNT variables processed for enrollment $ENROLLMENT_ID (number: $ENROLLMENT_NUMBER)."
