# Instructions and Guidelines

## Prerequisites

* Repository: Fork this GitHub repository to get started.

* PronativeAI Environment Doctor: Install PronativeAI environemnt doctor (follow instructions from [https://www.npmjs.com/package/@pronative.ai/doctor](https://www.npmjs.com/package/@pronative.ai/doctor)).

* GitHub Auth token (Classic PAT): Generate a GitHub Personal Access Token (PAT) with 'repo', 'workflow', 'write:packages','delete:packages', 'project' scopes enabled. Copy & keep the token handy.

* Official Instructions to Generate a Classic PAT:
[https://docs.github.com/en/enterprise-server@3.18/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic](https://docs.github.com/en/enterprise-server@3.18/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic)

## User Setup Commands for GitHub Repo and Auth token

### Step 1: Configure your GitHub authentication token as a system environment variable:

**Linux / macOS:**

```bash
# For Zsh (Default on macOS)
echo 'export PRONATIVE_GH_TOKEN="your_personal_access_token_here"' >> ~/.zshrc

# For Bash
echo 'export PRONATIVE_GH_TOKEN="your_personal_access_token_here"' >> ~/.bashrc

```

**Windows PowerShell:**

```powershell
[Environment]::SetEnvironmentVariable("PRONATIVE_GH_TOKEN", "your_personal_access_token_here", "User")

```

### Step 2: Secrets (GitHub Actions > Secrets)

These must be added manually:

| Secret | Description |
|--------|-------------|
| `CLIENT_SECRET` | Service principal secret (for Azure auth will be shared by Presenter) |
| `GHCR_PAT` | GitHub classic PAT generated earlier|


### Step 3: Clone the forked repo locally and open it in VS Code:

```bash
git clone https://github.com/<your-github-username>/adlc-exp-day-step2.git
cd adlc-exp-day-step2
code .

```


## Triggering the AI Agent

### Step 1: Review or Customize the Requirements

If you want to modify the application business requirements for your lab, you can open `BUSINESS_SPEC.md` and customize certain sections. However, you must follow these strict guidelines:

* **What you CAN customize:** You are free to modify **Business Idea, Business Goal,Target Users** to change the app idea, or  your custom data requirements.
* **What you MUST leave AS IS:** Do **not** modify **Known Constraints, Existing Context**. The agent requires these exact rules to develop cosmos services, utilzie environment variables and safely push your scaffolding/Pull Requests to GitHub.

### Step 2: Invoke the pronative.ai ADLC Spec Agent

Open your OpenCode agent chat panel from VS Code Terminal, enter /agent and paste below prompt to kick off the autonomous workflow:

```text
Act as an expert Requirment Analyst and process the spec from 'BUSINESS_SPEC.md' file. Perfoem a mandatory pre-flight verification check as mentioned in 'Pre-flight_Verification.md' file.

```
