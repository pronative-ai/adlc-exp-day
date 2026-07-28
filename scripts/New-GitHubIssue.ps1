[CmdletBinding()]
param(
    [Parameter()]
    [string]$Owner,

    [Parameter()]
    [string]$Repo,

    [Parameter(Mandatory)]
    [string]$Title,

    [Parameter()]
    [string]$Body,

    [Parameter()]
    [string]$FilePath,

    [Parameter()]
    [string]$Token = $env:PRONATIVE_GH_TOKEN
)

if (-not $Token) {
    Write-Error "No token. Set PRONATIVE_GH_TOKEN or pass -Token."
    exit 1
}

if ($FilePath -and $Body) {
    Write-Error "Provide -FilePath or -Body, not both."
    exit 1
}

if ($FilePath) {
    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        exit 1
    }
    $Body = Get-Content -Path $FilePath -Raw
}

if (-not $Body) {
    Write-Error "Issue body is required via -Body or -FilePath."
    exit 1
}

if (-not $Owner -or -not $Repo) {
    $remote = git remote get-url origin
    if ($remote -match "github\.com[:/](.+?)/(.+?)(\.git)?$") {
        $Owner = $Matches[1]
        $Repo  = $Matches[2]
    } else {
        Write-Error "Could not detect repo from git remote. Provide -Owner and -Repo."
        exit 1
    }
}

$uri = "https://api.github.com/repos/$Owner/$Repo/issues"
$headers = @{
    Authorization = "Bearer $Token"
    Accept        = "application/vnd.github+json"
}

$payload = @{
    title = $Title
    body  = $Body
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-WebRequest `
        -Uri $uri `
        -Method Post `
        -Headers $headers `
        -Body $payload `
        -ContentType "application/json; charset=utf-8" `
        -UseBasicParsing

    $issue = $response.Content | ConvertFrom-Json
    Write-Host "Created issue #$($issue.number): $($issue.html_url)"
} catch {
    Write-Error "Failed to create issue: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        Write-Error $reader.ReadToEnd()
    }
    exit 1
}
