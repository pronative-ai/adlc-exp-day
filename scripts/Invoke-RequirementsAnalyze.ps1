[CmdletBinding()]
param(
    [Parameter()]
    [string]$File,

    [Parameter()]
    [string]$String,

    [Parameter()]
    [string]$OutputFile = "Requirement_Analysis_Response.json"
)

$ErrorActionPreference = "Stop"

$Endpoint = "https://ca-adlc-unified-agent.ashyocean-2579666a.westus2.azurecontainerapps.io/api/requirements/analyze"

function Parse-MdToJson {
    param([string]$Content)

    $headingMap = @{
        "business idea"    = "business_idea"
        "target users"     = "target_users"
        "business goal"    = "business_goal"
        "known constraints"= "known_constraints"
        "existing context" = "existing_context"
        "scope level"      = "scope_level"
    }

    $sections = [regex]::Matches($Content, '(?m)^## (.+)$[\s\S]*?(?=\r?\n## |\z)')
    $body = [ordered]@{}

    foreach ($section in $sections) {
        $heading = $section.Groups[1].Value.Trim().ToLower()
        if ($headingMap.Contains($heading)) {
            $field = $headingMap[$heading]
            $value = ($section.Value -split '\r?\n', 2)[1]
            $value = ($value -replace '(?s)\A\s+|\s+\z', '').Trim()
            if ($value) {
                $body[$field] = $value
            }
        }
    }

    if (-not $body.Contains("business_idea")) {
        Write-Error "Markdown must contain a '## Business Idea' section."
        exit 1
    }

    return ($body | ConvertTo-Json -Depth 10)
}

function Parse-StringToJson {
    param([string]$Text)

    $body = @{ business_idea = $Text }
    return ($body | ConvertTo-Json -Depth 10)
}

if (-not $File -and -not $String) {
    Write-Error "Provide -File <path> or -String <text>."
    exit 1
}

if ($File -and -not (Test-Path $File)) {
    Write-Error "File not found: $File"
    exit 1
}

if ($File) {
    $content = Get-Content -Raw -Path $File
    $extension = [System.IO.Path]::GetExtension($File).TrimStart('.')

    switch ($extension) {
        "json"     { $payload = $content }
        { $_ -in "md", "markdown" } { $payload = Parse-MdToJson -Content $content }
        default {
            Write-Error "Unsupported file extension '.$extension'. Use .json or .md."
            exit 1
        }
    }
} else {
    $payload = Parse-StringToJson -Text $String
}

$baseName = [System.IO.Path]::GetFileNameWithoutExtension($OutputFile)
$extension = [System.IO.Path]::GetExtension($OutputFile)
$directory = [System.IO.Path]::GetDirectoryName($OutputFile)
if (-not $directory) { $directory = "." }

$finalFile = $OutputFile
$counter = 1
while (Test-Path $finalFile) {
    $finalFile = Join-Path $directory "${baseName}_${counter}${extension}"
    $counter++
}

Write-Host "Sending request to $Endpoint ..."
Write-Host "Payload: $payload"

try {
    $response = Invoke-RestMethod -Uri $Endpoint -Method Post -ContentType "application/json" -Body $payload
    $response | ConvertTo-Json -Depth 20 | Set-Content -Path $finalFile -Encoding UTF8
    Write-Host "Response saved to $finalFile"
} catch {
    Write-Error "Request failed: $($_.Exception.Message)"
    exit 1
}
