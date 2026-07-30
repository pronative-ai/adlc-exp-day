# 🛠️ INSTALLATION, CONFIGURATION and VERIFICATION

> [!NOTE]
> When you have issues with Installation, configuration or verification, you can refer to [FAQ](https://github.com/pronative-ai/adlc-exp-day/blob/main/1.EnvironmentSetup/Troubleshooting/FAQ.md#-faq---verification-check).
---

## 🏃 Step 1: pronative.ai Environment Doctor

* **Install Environment Doctor:** Run the below command from **POWERSHELL** in `ADMIN` mode. 
* **Additional details:** Refer to the [@pronative.ai/doctor npm package](https://www.npmjs.com/package/@pronative.ai/doctor).

```powershell
irm https://api.doctor.pronative.ai/win | iex
```

---

## 🔑 Step 2: Generate a GitHub Personal Access Token (PAT)

* **GitHub Auth token:** Generate a GitHub Personal Access Token (Classic PAT) by following these UI steps:

1. **Open Settings:** In the upper-right corner of any page on GitHub, click your **profile picture**, then click <kbd>Settings</kbd>.
2. **Access Developer Settings:** In the left sidebar, click <kbd>Developer settings</kbd>.
3. **Select Token Type:** In the left sidebar, under **Personal access tokens**, click <kbd>Tokens (Classic)</kbd>.
4. **Create Token:** Click the <kbd>Generate new token (Classic)</kbd> button.
5. **Name Your Token:** Under **Token name**, enter a memorable name for the token.
6. **Enable Scopes:** Check the boxes to enable the following **SCOPES**:
   * `repo`
   * `workflow`
   * `write:packages`
   * `delete:packages`
7. **Finalize Generation:** Scroll down to the end of the page and click the <kbd>Generate Token</kbd> button.

> [!IMPORTANT]
> Copy & keep the `TOKEN` handy for **next step 3**. You will not be able to see it again.

![](../images/GitHub-PAT.png)

---

## 💻 Step 3: Configure your GitHub authentication token as a system environment variable

**Windows PowerShell:**

```powershell
[Environment]::SetEnvironmentVariable("PRONATIVE_GH_TOKEN", "your_personal_access_token_here", "User")
```

---

## 🤖 Step 4: Setup custom models in your Local OpenCode

> [!IMPORTANT]
> ### 📁 Required Configuration File
> The custom `opencode.jsonc` file will be shared directly by the instructor through your **MS Teams** session chat. Make sure to download it locally before proceeding to the steps below.


### Update opencode pronative.ai Models configuration

* **Navigate to path:** Go to `C:\Users\<your_login_accountname>\.config\opencode`
* **Backup existing config:** Rename the existing `opencode.jsonc` file to `opencode.jsonc.bkp`
* **Download new config:** Download the updated `opencode.jsonc` file shared in your MS Teams session.
* **Deploy new config:** Move the freshly downloaded `opencode.jsonc` file into `C:\Users\<your_login_accountname>\.config\opencode`

> [!TIP]
> **Post-session cleanup:** You can safely revert back to your original configuration later by restoring the `opencode.jsonc.bkp` file.

---

# ✅ VERIFICATION 

> [!NOTE]
> If any verification step fails, please refer to the [FAQ](https://github.com/pronative-ai/adlc-exp-day/blob/main/1.EnvironmentSetup/Troubleshooting/FAQ.md#-faq---verification-check). section for step-by-step troubleshooting.

### 🔍 Environment Presence Check
* **Verify Variable:** Confirm that `PRONATIVE_GH_TOKEN` is visible and correctly saved in your system's **ENVIRONMENT VARIABLES**.

### 🌐 GitHub Connectivity & Scope Validation Test
* **Run Validation Test:** Open **Windows PowerShell** (do not use the standard Command Prompt) and execute the following command:

```powershell
curl.exe -sI -H "Authorization: token $env:PRONATIVE_GH_TOKEN" https://api.github.com/user
```
