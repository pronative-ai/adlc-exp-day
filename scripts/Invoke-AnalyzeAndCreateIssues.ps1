[CmdletBinding()]
param(
    [Parameter()]
    [string]$File,

    [Parameter()]
    [string]$String,

    [Parameter()]
    [string]$OutputDir = ".",

    [Parameter()]
    [string]$Owner,

    [Parameter()]
    [string]$Repo,

    [Parameter()]
    [string]$Token = $env:PRONATIVE_GH_TOKEN
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Endpoint = "https://ca-adlc-unified-agent.ashyocean-2579666a.westus2.azurecontainerapps.io/api/requirements/analyze"

# --- Helper Functions ---

function Parse-MdToJson {
    param([string]$Content)

    $headingMap = @{
        "business idea"     = "business_idea"
        "target users"      = "target_users"
        "business goal"     = "business_goal"
        "known constraints" = "known_constraints"
        "existing context"  = "existing_context"
        "scope level"       = "scope_level"
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

function Resolve-RequirementText {
    param(
        [string]$ReqId,
        [array]$FunctionalReqs,
        [array]$NonFunctionalReqs
    )

    foreach ($req in $FunctionalReqs) {
        if ($req.id -eq $ReqId) {
            return "**$ReqId** - $($req.title)`n$($req.description)`nPriority: $($req.priority)"
        }
    }
    foreach ($req in $NonFunctionalReqs) {
        if ($req.id -eq $ReqId) {
            return "**$ReqId** - $($req.title)`n$($req.description)`nPriority: $($req.priority)"
        }
    }
    return "**$ReqId**`n(Reference not found in response)"
}

function Build-IssueBody {
    param(
        [psobject]$Candidate,
        [array]$FunctionalReqs,
        [array]$NonFunctionalReqs
    )

    $body = "## Description`n`n$($Candidate.description)`n`n"
    $body += "## Priority`n`n$($Candidate.priority)`n`n"
    $body += "## Related Requirements`n`n"

    foreach ($reqId in $Candidate.related_requirements) {
        $body += (Resolve-RequirementText -ReqId $reqId -FunctionalReqs $FunctionalReqs -NonFunctionalReqs $NonFunctionalReqs)
        $body += "`n`n---`n`n"
    }

    return $body
}

# --- Input Validation ---

if (-not $File -and -not $String) {
    Write-Error "Provide -File <path> or -String <text>."
    exit 1
}

if ($File -and -not (Test-Path $File)) {
    Write-Error "File not found: $File"
    exit 1
}

if (-not $Token) {
    Write-Error "No token. Set PRONATIVE_GH_TOKEN or pass -Token."
    exit 1
}

# --- Build Payload ---

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

# --- Step 1: Requirements Analysis ---

Write-Host "`n=== Step 1: Requirements Analysis ==="
Write-Host "Endpoint: $Endpoint"

try {
    $analysisResponse = Invoke-RestMethod -Uri $Endpoint -Method Post -ContentType "application/json" -Body $payload
} catch {
    Write-Error "Requirements analysis failed: $($_.Exception.Message)"
    exit 1
}

# --- Save Analysis Response ---

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$analysisFile = Join-Path $OutputDir "Requirement_Analysis_Response.json"
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($analysisFile)
$ext = [System.IO.Path]::GetExtension($analysisFile)
$dir = [System.IO.Path]::GetDirectoryName($analysisFile)
if (-not $dir) { $dir = "." }
$counter = 1
while (Test-Path $analysisFile) {
    $analysisFile = Join-Path $dir "${baseName}_${counter}${ext}"
    $counter++
}
$analysisResponse | ConvertTo-Json -Depth 20 | Set-Content -Path $analysisFile -Encoding UTF8
Write-Host "Analysis response saved to $analysisFile"

# --- Extract Data ---

$issueCandidates = @($analysisResponse.issue_candidates)
$functionalReqs = @($analysisResponse.functional_requirements)
$nonFunctionalReqs = @($analysisResponse.non_functional_requirements)

if ($issueCandidates.Count -eq 0) {
    Write-Warning "No issue candidates in the analysis response. Nothing to create."
    exit 0
}

Write-Host "`nFound $($issueCandidates.Count) issue candidate(s):"
foreach ($c in $issueCandidates) {
    Write-Host "  - $($c.title) [Priority: $($c.priority)]"
}

# --- Step 2: Create GitHub Issues via New-GitHubIssue.ps1 ---

Write-Host "`n=== Step 2: Creating GitHub Issues ==="

$issueScript = Join-Path $ScriptDir "New-GitHubIssue.ps1"
if (-not (Test-Path $issueScript)) {
    Write-Error "Issue creation script not found: $issueScript"
    exit 1
}

$createdCount = 0

foreach ($candidate in $issueCandidates) {
    $issueBody = Build-IssueBody -Candidate $candidate -FunctionalReqs $functionalReqs -NonFunctionalReqs $nonFunctionalReqs

    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        [System.IO.File]::WriteAllText($tempFile, $issueBody, [System.Text.Encoding]::UTF8)

        $scriptArgs = @{
            Title = $candidate.title
            FilePath = $tempFile
            Token = $Token
        }
        if ($Owner) { $scriptArgs.Owner = $Owner }
        if ($Repo)  { $scriptArgs.Repo = $Repo }

        Write-Host "`nCreating: $($candidate.title)"

        & $issueScript @scriptArgs
        $createdCount++
    } catch {
        Write-Warning "Failed to create issue '$($candidate.title)': $($_.Exception.Message)"
    } finally {
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n=== Done ==="
Write-Host "Analysis response: $analysisFile"
Write-Host "Issues created: $createdCount"
