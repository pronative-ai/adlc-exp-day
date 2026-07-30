# Instructions and Guidelines

## Prerequisites

* Install PronativeAI Environment Doctor: Run below command from powershell in Admin mode (Refer [https://www.npmjs.com/package/@pronative.ai/doctor](https://www.npmjs.com/package/@pronative.ai/doctor) for additional details.).

```powershell
irm https://api.doctor.pronative.ai/win | iex

```


* GitHub Auth token (Classic PAT): Generate a GitHub Personal Access Token (PAT) with 'repo', 'workflow', 'write:packages','delete:packages' scopes enabled. Copy & keep the token handy.

* Official Instructions to Generate a Classic PAT:
[https://docs.github.com/en/enterprise-server@3.18/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic](https://docs.github.com/en/enterprise-server@3.18/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic)

## User Setup Commands for GitHub Repo and Auth token

### Step 1: Configure your GitHub authentication token as a system environment variable:

**Windows PowerShell:**

```powershell
[Environment]::SetEnvironmentVariable("PRONATIVE_GH_TOKEN", "your_personal_access_token_here", "User")

```