# Scripts

Helper scripts for GitHub repo variable management and issue creation.

## Prerequisites

- **Git** installed (brings Git Bash on Windows)
- System Environment variable `PRONATIVE_GH_TOKEN` set with a GitHub PAT

## Files

| File | Description |
|------|-------------|
| `initialize-github-variables.sh` | Create/update GitHub Actions variables for a given enrollment |
| `new-github-issue.sh` | Create a GitHub issue from text or markdown file |
| `Initialize-GitHubVariables.ps1` | PowerShell version of variable initializer |
| `New-GitHubIssue.ps1` | PowerShell version of issue creator |

## Setup

Set `PRONATIVE_GH_TOKEN` as a **system environment variable** (user level) so it persists across sessions:

```powershell
# Windows PowerShell
[System.Environment]::SetEnvironmentVariable("PRONATIVE_GH_TOKEN", "ghp_xxxxxxxxxxxx", "User")
```

```bash
# Linux/macOS (add to ~/.bashrc or ~/.zshrc)
export PRONATIVE_GH_TOKEN="ghp_xxxxxxxxxxxx"
```

Verify it is set:

```powershell
[System.Environment]::GetEnvironmentVariable("PRONATIVE_GH_TOKEN", "User")
```

## Initialize GitHub Variables

Creates/updates 7 GitHub Actions variables for a given enrollment.

The script parses the enrollment ID from the `.env` file (or `-e` parameter) and extracts the trailing number. If the number is less than 1000, it adds 1000 to make it a 4-digit number.

**3 enrollment-specific:**
- `CONTAINERAPP_NAME` = `ca-adlc-exp-{enrollment}`
- `COSMOSDB_NAME` = `cosmos-adlc-exp-{enrollment}`
- `RESOURCEGROUP_NAME` = `rg-adlc-exp-2608-{enrollment}`

**4 common (same for all enrollments):**
- `AZURE_MANAGED_IDENTITY_CLIENT_ID`
- `CLIENT_ID`
- `SUBSCRIPTION_ID`
- `TENANT_ID`

### Usage

```bash
# Read from .env file (default)
./scripts/initialize-github-variables.sh

# Pass enrollment ID directly
./scripts/initialize-github-variables.sh -e ST-2608-adlc1

# Windows PowerShell (reads from .env)
.\scripts\Initialize-GitHubVariables.ps1

# Pass enrollment ID directly (PowerShell)
.\scripts\Initialize-GitHubVariables.ps1 -EnrollmentId ST-2608-adlc1

# Override owner/repo (auto-detected from git remote by default)
./scripts/initialize-github-variables.sh -e ST-2608-adlc1 -o other-owner -r other-repo
```

### Enrollment ID Parsing

| Input Enrollment ID | Extracted Number | Result |
|---------------------|------------------|--------|
| `ST-2608-adlc1` | `1` | `1001` (1 + 1000) |
| `ST-2608-adlc21` | `21` | `1021` (21 + 1000) |
| `ST-2608-021` | `21` | `1021` (21 + 1000) |
| `ST-2608-1021` | `1021` | `1021` (used as-is) |
| `1021` | `1021` | `1021` (used as-is) |

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-e` / `-EnrollmentId` | No | Enrollment ID (reads from `.env` if not provided) |
| `-o` / `-Owner` | No | GitHub owner (auto-detected) |
| `-r` / `-Repo` | No | GitHub repo (auto-detected) |
| `-t` / `-Token` | No | GitHub PAT (uses `PRONATIVE_GH_TOKEN` env var) |

### Idempotent

Running the same command twice skips variables with matching values. If a variable exists with a different value, it is updated.

## Create GitHub Issue

### Usage

```bash
# macOS/Linux
./scripts/new-github-issue.sh -T "Bug title" -b "Description here"

# From markdown file
./scripts/new-github-issue.sh -T "Bug title" -f issue.md

# Windows PowerShell
.\scripts\New-GitHubIssue.ps1 -Title "Bug title" -Body "Description here"

# From markdown file (PowerShell)
.\scripts\New-GitHubIssue.ps1 -Title "Bug title" -FilePath .\issue.md
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-T` / `-Title` | Yes | Issue title |
| `-b` / `-Body` | Yes* | Issue body (text) |
| `-f` / `-FilePath` | Yes* | Path to markdown file for body |
| `-o` / `-Owner` | No | GitHub owner (auto-detected) |
| `-r` / `-Repo` | No | GitHub repo (auto-detected) |
| `-t` / `-Token` | No | GitHub PAT (uses `PRONATIVE_GH_TOKEN` env var) |

*Either `-b` or `-f` is required, but not both.

## VS Code Integration

### Windows

If VS Code terminal is **PowerShell**, use the `.ps1` scripts directly.
If VS Code terminal is **Git Bash**, use the `.sh` scripts directly.

To run `.sh` from PowerShell:

```powershell
& "C:\Program Files\Git\bin\bash.exe" -c "./scripts/initialize-github-variables.sh"
```

### macOS / Linux

Run `.sh` scripts directly in terminal. Use `.ps1` only if PowerShell Core (`pwsh`) is installed.
