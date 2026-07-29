# Instructions and Guidelines

## Prerequisites

* Repository: Fork this GitHub repository to get started.

* PronativeAI Environment Doctor: Install PronativeAI environemnt doctor (follow instructions from [https://www.npmjs.com/package/@pronative.ai/doctor](https://www.npmjs.com/package/@pronative.ai/doctor)).

* GitHub Auth token (Classic PAT): Generate a GitHub Personal Access Token (PAT) and keep the token handy. Steps are given below.

Steps: click Profile `Picture` -> Select `Settings` -> Select `Developer settings` in the left side blade at the bottom -> select `Personal Access Token` in the left side blade -> select `Tokens (clasic)`  -> Click the `Generate new token` ->  select `Generate new token (clasic)`  -> provide the token name (your wish) -> Select Expiration date -> Select the following scopes (given below) -> finally click the `Generate Token` button located below. 

Required Scopes: 'repo', 'workflow', 'write:packages','delete:packages'

* Official Instructions to Generate a Classic PAT:
[https://docs.github.com/en/enterprise-server@3.18/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic](https://docs.github.com/en/enterprise-server@3.18/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic)

## User Setup Commands for GitHub Repo and Auth token

### Step 1: Clone the forked repo locally and open it in VS Code:

```bash
git clone https://github.com/<your-github-username>/adlc-exp-day-step2.git
cd adlc-exp-day-step2
code .

```

Get the Azure Foundry Token from MS Teams and put it in `.opencode\opencode.json` at `provider.azure.options.apiKey`.


### Step 2: Configure your GitHub authentication token as a system environment variable:

**Windows PowerShell:**

```powershell
[Environment]::SetEnvironmentVariable("PRONATIVE_GH_TOKEN", "your_personal_access_token_here", "User")

```

### Step 3: Secrets (GitHub Actions > Secrets)

These must be added manually:

| Secret | Description |
|--------|-------------|
| `CLIENT_SECRET` | Service principal secret (for Azure auth will be shared by Presenter) |
| `GHCR_PAT` | GitHub classic PAT generated earlier|

(or)

```sh
gh secret set  GHCR_PAT --body <generated-earlier>
gh secret set CLIENT_SECRET --body <client-secret>
```


### Step 3: Run make file to setup configuration required to collect Agent metrics:

* Open the `make` file in root folder
* Update placeholder for participant with your enrollment id  (e.g. replace <ENROLLMENT_ID> with ST-2608-adlc101) and save the file
* run the command `make run` from VS Code terminal
* Note: Remember to run above command each time when VS code is reopned/restarted

### Step 4: Run script to create variables required for outerloop:

* Rename the `env.example` file to `.env` file 
* Follow instructions env.example in root folder to save .env
* Navigate to `scripts` folder from VS Code terminal
* Run `Initialize-GitHubVariables.ps1` in powershell as follows. 

```sh
.\Initialize-GitHubVariables.ps1 -EnrollmentId "<your-enrolement-id>"
```

## Triggering the AI Agent

### Step 1: Review or Customize the Requirements

If you want to modify the business requirements for your lab, you can open the `input-spec-agent.md` file located in `intent` folder and customize certain sections. However, you must follow these strict guidelines:

* **What you CAN customize:** You are free to modify **Business Intent Title, Business Idea, Persona, User Need** to change the app idea, or  your custom data requirements.
* **What you MUST leave AS IS:** Do **not** modify **Known Constraints**. The agent requires these exact rules to develop cosmos services, utilzie environment variables and safely push your scaffolding/Pull Requests to GitHub.

## Step 2: Invoke the pronative.ai ADLC Spec Agent

* Open your OpenCode agent chat panel from the VS Code Terminal. ( Run `make run` command to open the OpenCode)
* Type `/models` in the chat panel.
* Enter `pronative` in the search box.
* Scroll through the agent list to select `pronative.ai GPT`.
* Press enter to confirm your selection.
* Paste the below prompt below to kick off the spec agent (a markdown file appears under the `spec` folder once processing is complete).

```text
Process `intent\input-spec-agent.md` file.

```

## Step 3: Invoke the pronative.ai ADLC Coding Agent

* After step 1 is finished, then type `/models`.
* Enter `pronative` in the search box.
* Scroll through the agent list to select `pronative.ai GPT Nano`.
* Press enter to confirm your selection.
* Paste the below prompt below to kick off the coding agent.

```text
Implement `spec` folder.

```
