# INSTALLATION, CONFIGURATION and VERIFICATION

## Step 1: pronative.ai Environment Doctor

* Install **pronative.ai Environment Doctor**: Run below command from **POWERSHELL** in `ADMIN` mode (Refer [https://www.npmjs.com/package/@pronative.ai/doctor](https://www.npmjs.com/package/@pronative.ai/doctor) for additional details.).

```powershell
irm https://api.doctor.pronative.ai/win | iex

```
### Step 2: Generate a GitHub Personal Access Token (PAT):

* GitHub Auth token (Classic PAT): Generate a GitHub Personal Access Token (PAT).

In the upper-right corner of any page on GitHub, click your **profile** picture, then click  **Settings**.

In the left sidebar, click  **Developer settings**.

In the left sidebar, under  **Personal access tokens**, click **Fine-grained tokens**.

Click **Generate new token**.

Under Token name, enter a name for the token.

Enable the following **SCOPES** - 'repo', 'workflow', 'write:packages','delete:packages'.

Finally, scroll down to the end and click **Generate Token** button

**NOTE:**  Copy & keep the `TOKEN` handy

GitHub-PAT.png

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




