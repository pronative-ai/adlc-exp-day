#!/usr/bin/env bash
set -euo pipefail

ENDPOINT="https://ca-adlc-unified-agent.ashyocean-2579666a.westus2.azurecontainerapps.io/api/requirements/analyze"
OUTPUT_FILE="Requirement_Analysis_Response.json"

usage() {
    echo "Usage: $0 <-f <file.md|file.json> | -s <string>>"
    echo ""
    echo "Options:"
    echo "  -f <file>    Path to a .md or .json file containing the business intent"
    echo "  -s <string>  Raw business idea string"
    echo "  -o <file>    Output file name (default: Requirement_Analysis_Response.json)"
    echo "  -h           Show this help message"
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
            local heading=$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]' | xargs)
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

INPUT_FILE=""
INPUT_STRING=""

while getopts "f:s:o:h" opt; do
    case $opt in
        f) INPUT_FILE="$OPTARG" ;;
        s) INPUT_STRING="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
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

BASENAME="${OUTPUT_FILE%.*}"
EXTENSION="${OUTPUT_FILE##*.}"
DIRECTORY="$(dirname "$OUTPUT_FILE")"
[ "$DIRECTORY" = "." ] && DIRECTORY="$(pwd)"

FINAL_FILE="$OUTPUT_FILE"
COUNTER=1
while [ -f "$FINAL_FILE" ]; do
    FINAL_FILE="${DIRECTORY}/${BASENAME}_${COUNTER}.${EXTENSION}"
    COUNTER=$((COUNTER + 1))
done

echo "Sending request to $ENDPOINT ..."
echo "Payload: $PAYLOAD"

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$ENDPOINT")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_STATUS" -lt 200 ] || [ "$HTTP_STATUS" -ge 300 ]; then
    echo "Error: HTTP $HTTP_STATUS"
    echo "$HTTP_BODY"
    exit 1
fi

echo "$HTTP_BODY" | jq '.' > "$FINAL_FILE"
echo "Response saved to $FINAL_FILE (HTTP $HTTP_STATUS)"
