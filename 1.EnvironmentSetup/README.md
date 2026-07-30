# INSTALLATION, CONFIGURATION and VERIFICATION

## Step 1: pronative.ai Environment Doctor

* Install **pronative.ai Environment Doctor**: Run below command from **POWERSHELL** in `ADMIN` mode (Refer [https://www.npmjs.com/package/@pronative.ai/doctor](https://www.npmjs.com/package/@pronative.ai/doctor) for additional details.).

```powershell
irm https://api.doctor.pronative.ai/win | iex

```
### Step 2: Generate a GitHub Personal Access Token (PAT):

* GitHub Auth token (Classic PAT): Generate a GitHub Personal Access Token (PAT) with 'repo', 'workflow', 'write:packages','delete:packages' scopes enabled. Copy & keep the token handy.

* Official Instructions to Generate a Classic PAT:
[https://docs.github.com/en/enterprise-server@3.18/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic](https://docs.github.com/en/enterprise-server@3.18/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic)


### Step 3: Configure your GitHub authentication token as a system environment variable:

**Windows PowerShell:**

```powershell
[Environment]::SetEnvironmentVariable("PRONATIVE_GH_TOKEN", "your_personal_access_token_here", "User")

```

## Step 4: Setup custom models in your Local OpenCode

### Update opencode pronative.ai Models configuration

* GO TO `C:\Users\`<your_login_accountname>`\.config\opencode`
* RENAME the exisitng `opencode.jsonc` to `opencode.jsonc.bkp`
* DOWNLOAD the `opencode.jsonc` file shared in MS TEAMS session
* MOVE the `opencode.jsonc` downloaded file to this path `C:\Users\`<your_login_accountname>`\.config\opencode`

**NOTE:** Post session you can revert back to the original file ( `opencode.jsonc.bkp`)

# VERIFICATION (Refer to FAQ for troubleshooting) 

### Environment Presence Check
* Verify **PRONATIVE_GH_TOKEN** in ENVIRONMENT VARIABLES


### GitHub Connectivity & Scope Validation Test
* GitHub Connectivity & Scope Validation Test
```bash
curl -sI -H "Authorization: token $PRONATIVE_GH_TOKEN" https://api.github.com/user
```




