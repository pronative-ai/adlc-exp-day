#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENDPOINT="https://ca-adlc-unified-agent.ashyocean-2579666a.westus2.azurecontainerapps.io/api/requirements/analyze"
OUTPUT_DIR="."

OWNER=""
REPO=""
TOKEN="${PRONATIVE_GH_TOKEN:-}"

usage() {
    echo "Usage: $0 <-f <file.md|file.json> | -s <string>> [-o <output_dir>] [-O <owner>] [-r <repo>] [-t <token>]"
    echo ""
    echo "Options:"
    echo "  -f <file>      Path to a .md or .json file containing the business intent"
    echo "  -s <string>    Raw business idea string"
    echo "  -o <dir>       Output directory (default: .)"
    echo "  -O <owner>     GitHub repo owner (auto-detected from git remote)"
    echo "  -r <repo>      GitHub repo name (auto-detected from git remote)"
    echo "  -t <token>     GitHub PAT (or set PRONATIVE_GH_TOKEN)"
    echo "  -h             Show this help message"
    exit 1
}

parse_md_to_json() {
    local content="$1"
    declare -A HEADING_MAP=(
        ["business idea"]="business_idea"
        ["target users"]="target_users"
        ["business goal"]="business_goal"
        ["known constraints"]="known_constraints"
        ["existing context"]="existing_context"
        ["scope level"]="scope_level"
    )

    local json="{"
    local first=true
    local current_field=""
    local current_body=""

    flush_section() {
        if [ -n "$current_field" ] && [ -n "$current_body" ]; then
            current_body=$(echo "$current_body" | sed '/^\s*$/d' | sed ':a;N;$!ba;s/\n/\\n/g')
            if [ "$first" = true ]; then
                first=false
            else
                json+=","
            fi
            json+="\"$current_field\":\"$current_body\""
        fi
    }

    while IFS= read -r line; do
        if [[ "$line" =~ ^##\ (.+)$ ]]; then
            flush_section
            current_field=""
            current_body=""
            local heading
            heading=$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]' | xargs)
            if [[ -v "HEADING_MAP[$heading]" ]]; then
                current_field="${HEADING_MAP[$heading]}"
            fi
        elif [ -n "$current_field" ]; then
            if [ -n "$current_body" ]; then
                current_body+=$'\n'"$line"
            else
                current_body="$line"
            fi
        fi
    done <<< "$content"

    flush_section
    json+="}"

    if ! echo "$json" | jq -e '.business_idea' > /dev/null 2>&1; then
        echo "Error: Content must contain a '## Business Idea' section." >&2
        exit 1
    fi

    echo "$json" | jq '.'
}

resolve_requirement_text() {
    local req_id="$1"
    local json="$2"

    local result
    result=$(echo "$json" | jq -r --arg id "$req_id" '
        (.functional_requirements // [])[] | select(.id == $id) |
        "**\(.id)** - \(.title)\n\(.description)\nPriority: \(.priority)"
    ' 2>/dev/null)

    if [ -z "$result" ]; then
        result=$(echo "$json" | jq -r --arg id "$req_id" '
            (.non_functional_requirements // [])[] | select(.id == $id) |
            "**\(.id)** - \(.title)\n\(.description)\nPriority: \(.priority)"
        ' 2>/dev/null)
    fi

    if [ -z "$result" ]; then
        result="**$req_id**\n(Reference not found in response)"
    fi

    echo "$result"
}

build_issue_body() {
    local candidate_json="$1"
    local full_json="$2"

    local title desc priority related
    title=$(echo "$candidate_json" | jq -r '.title')
    desc=$(echo "$candidate_json" | jq -r '.description')
    priority=$(echo "$candidate_json" | jq -r '.priority')
    related=$(echo "$candidate_json" | jq -r '.related_requirements[]')

    local body="## Description\n\n$desc\n\n"
    body+="## Priority\n\n$priority\n\n"
    body+="## Related Requirements\n\n"

    for req_id in $related; do
        body+="$(resolve_requirement_text "$req_id" "$full_json")"
        body+="\n\n---\n\n"
    done

    echo -e "$body"
}

# --- Parse Arguments ---

INPUT_FILE=""
INPUT_STRING=""

while getopts "f:s:o:O:r:t:h" opt; do
    case $opt in
        f) INPUT_FILE="$OPTARG" ;;
        s) INPUT_STRING="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        O) OWNER="$OPTARG" ;;
        r) REPO="$OPTARG" ;;
        t) TOKEN="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

if [ -z "$INPUT_FILE" ] && [ -z "$INPUT_STRING" ]; then
    echo "Error: Provide -f <file> or -s <string>."
    usage
fi

if [ -n "$INPUT_FILE" ] && [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File not found: $INPUT_FILE"
    exit 1
fi

if [ -z "$TOKEN" ]; then
    echo "Error: No token. Set PRONATIVE_GH_TOKEN or pass -t."
    exit 1
fi

# --- Build Payload ---

if [ -n "$INPUT_FILE" ]; then
    CONTENT=$(cat "$INPUT_FILE")
    EXTENSION="${INPUT_FILE##*.}"

    if [ "$EXTENSION" = "json" ]; then
        PAYLOAD="$CONTENT"
    elif [ "$EXTENSION" = "md" ] || [ "$EXTENSION" = "markdown" ]; then
        PAYLOAD=$(parse_md_to_json "$CONTENT")
    else
        echo "Error: Unsupported file extension '.$EXTENSION'. Use .json or .md."
        exit 1
    fi
else
    PAYLOAD=$(jq -n --arg idea "$INPUT_STRING" '{business_idea: $idea}')
fi

# --- Step 1: Requirements Analysis ---

echo ""
echo "=== Step 1: Requirements Analysis ==="
echo "Endpoint: $ENDPOINT"

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$ENDPOINT")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_STATUS" -lt 200 ] || [ "$HTTP_STATUS" -ge 300 ]; then
    echo "Error: Requirements analysis failed (HTTP $HTTP_STATUS)"
    echo "$HTTP_BODY"
    exit 1
fi

# --- Save Analysis Response ---

mkdir -p "$OUTPUT_DIR"

ANALYSIS_FILE="$OUTPUT_DIR/Requirement_Analysis_Response.json"
COUNTER=1
while [ -f "$ANALYSIS_FILE" ]; do
    ANALYSIS_FILE="$OUTPUT_DIR/Requirement_Analysis_Response_${COUNTER}.json"
    COUNTER=$((COUNTER + 1))
done

echo "$HTTP_BODY" | jq '.' > "$ANALYSIS_FILE"
echo "Analysis response saved to $ANALYSIS_FILE"

# --- Extract Data ---

ISSUE_COUNT=$(echo "$HTTP_BODY" | jq '.issue_candidates | length')
if [ "$ISSUE_COUNT" -eq 0 ]; then
    echo "No issue candidates in the analysis response. Nothing to create."
    exit 0
fi

echo ""
echo "Found $ISSUE_COUNT issue candidate(s):"
echo "$HTTP_BODY" | jq -r '.issue_candidates[] | "  - \(.title) [Priority: \(.priority)]"'

# --- Step 2: Create GitHub Issues ---

echo ""
echo "=== Step 2: Creating GitHub Issues ==="

ISSUE_SCRIPT="$SCRIPT_DIR/new-github-issue.sh"
if [ ! -f "$ISSUE_SCRIPT" ]; then
    echo "Error: Issue creation script not found: $ISSUE_SCRIPT"
    exit 1
fi

CREATED_COUNT=0
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

for i in $(seq 0 $((ISSUE_COUNT - 1))); do
    CANDIDATE=$(echo "$HTTP_BODY" | jq ".issue_candidates[$i]")
    TITLE=$(echo "$CANDIDATE" | jq -r '.title')

    ISSUE_BODY=$(build_issue_body "$CANDIDATE" "$HTTP_BODY")
    BODY_FILE="$TEMP_DIR/issue_${i}.md"
    echo -e "$ISSUE_BODY" > "$BODY_FILE"

    echo ""
    echo "Creating: $TITLE"

    ISSUE_ARGS=(-T "$TITLE" -f "$BODY_FILE")
    [ -n "$OWNER" ] && ISSUE_ARGS+=(-o "$OWNER")
    [ -n "$REPO" ]  && ISSUE_ARGS+=(-r "$REPO")

    if bash "$ISSUE_SCRIPT" "${ISSUE_ARGS[@]}"; then
        CREATED_COUNT=$((CREATED_COUNT + 1))
    else
        echo "  Failed to create issue: $TITLE"
    fi
done

echo ""
echo "=== Done ==="
echo "Analysis response: $ANALYSIS_FILE"
echo "Issues created: $CREATED_COUNT"
