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

Creates/updates 7 GitHub Actions variables for a given enrollment number.

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
# macOS/Linux (from repo root)
./scripts/initialize-github-variables.sh -e 1021

# Windows Git Bash / WSL
bash scripts/initialize-github-variables.sh -e 1021

# Windows PowerShell
.\scripts\Initialize-GitHubVariables.ps1 -EnrollmentNumber 1021

# Override owner/repo (auto-detected from git remote by default)
./scripts/initialize-github-variables.sh -e 1021 -o other-owner -r other-repo
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-e` / `-EnrollmentNumber` | Yes | Enrollment number (e.g., 1021) |
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
& "C:\Program Files\Git\bin\bash.exe" -c "./scripts/initialize-github-variables.sh -e 1021"
```

### macOS / Linux

Run `.sh` scripts directly in terminal. Use `.ps1` only if PowerShell Core (`pwsh`) is installed.
