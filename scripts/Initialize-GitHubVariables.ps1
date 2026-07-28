[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$EnrollmentNumber,

    [Parameter()]
    [string]$Owner = $env:OWNER,

    [Parameter()]
    [string]$Repo = $env:REPO,

    [Parameter()]
    [string]$Token = $env:PRONATIVE_GH_TOKEN
)

$ErrorActionPreference = "Stop"

if (-not $Token) {
    Write-Error "No token. Set PRONATIVE_GH_TOKEN or pass -Token."
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

$headers = @{
    Authorization = "Bearer $Token"
    Accept        = "application/vnd.github+json"
}

$apiBase = "https://api.github.com/repos/$Owner/$Repo/actions/variables"

# Variables with enrollment number in value
$enrollmentVars = @{
    "CONTAINERAPP_NAME"  = "ca-adlc-exp-$EnrollmentNumber"
    "COSMOSDB_NAME"      = "cosmos-adlc-exp-$EnrollmentNumber"
    "RESOURCEGROUP_NAME" = "rg-adlc-exp-2608-$EnrollmentNumber"
}

# Common variables (same for all enrollment numbers)
$commonVars = @{
    "CLIENT_ID"       = "429199bf-06e3-438d-8f5c-9bcb95d4249b"
    "SUBSCRIPTION_ID" = "4969651e-74b0-4e8a-a81d-7fbb61c3fee5"
    "TENANT_ID"       = "eed1d2ca-7ca1-4fe3-8a1c-247a759acf93"
    "COSMOS_DB_REGION" = "CentralIndia"
}

$allVars = $enrollmentVars + $commonVars

# Fetch existing variables
$existing = @{}
try {
    $resp = Invoke-RestMethod -Uri $apiBase -Headers $headers -Method Get
    foreach ($v in $resp.variables) {
        $existing[$v.name] = $v.value
    }
} catch {
    Write-Error "Failed to list variables: $($_.Exception.Message)"
    exit 1
}

foreach ($kv in $allVars.GetEnumerator()) {
    $name  = $kv.Key
    $value = $kv.Value

    if ($existing.ContainsKey($name)) {
        if ($existing[$name] -eq $value) {
            Write-Host "SKIP (exists, same value): $name"
        } else {
            # Update existing variable
            $patchBody = @{ name = $name; value = $value } | ConvertTo-Json
            Invoke-RestMethod -Uri "$apiBase/$name" -Headers $headers -Method Patch -Body $patchBody -ContentType "application/json; charset=utf-8" | Out-Null
            Write-Host "UPDATED: $name = $value"
        }
    } else {
        # Create new variable
        $postBody = @{ name = $name; value = $value } | ConvertTo-Json
        Invoke-RestMethod -Uri $apiBase -Headers $headers -Method Post -Body $postBody -ContentType "application/json; charset=utf-8" | Out-Null
        Write-Host "CREATED: $name = $value"
    }
}

Write-Host "`nDone. $(($allVars.Count)) variables processed for enrollment $EnrollmentNumber."


