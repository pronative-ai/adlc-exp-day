
## 1. Context and Business Goal

* Objective: Build a simple single-page web form for marketing managers to submit new sales leads. The React frontend will communicate with a C# .NET minimal API backend that saves leads to Azure Cosmos DB.

* Success Metric: A user submits a valid lead, the backend saves it, and the UI updates dynamically without a page refresh.

## 2. Technical Stack and Environment Alignment

* Target Framework: React (Vite-based frontend using **Node 24.***) and C# (Web API backend using **.NET 10**).

* Azure Infrastructure: Frontend structured and Backend structured for Azure Container App. Database is Azure Cosmos DB.

* Directory Structure: Your root folder must contain a `src` folder, with `src/frontend` and `src/backend` inside it.

## 3. Strict Boundary and Guardrails

* In-Scope Stage 1 (Scaffolding): Create `src/frontend` and `src/backend` directories. Add the base configuration files, a minimal project setup required for running unit tests, and `Dockerfile`for frontend & backend. Create a `.github/workflows/ci.yml` pipeline that focuses exclusively on building the application and running your unit tests. For the backend, frontend the pipeline must verify that the container builds properly without pushing the final image to a registry. Initialize all required configuration targets—specifically repository Variables (like `COSMOS_DB_URI`, `VITE_API_URL` etc.,)—on GitHub with empty strings or placeholder stubs. Commit and push this entire scaffolding directly to the `main`(default branch) branch.

* In-Scope Stage 2 (Implementation): Create and checkout a new branch named `feature/app-implementation`. Implement the React form UI, the C# API endpoint, and the database persistence layers. You must verify that the entire project compiles and passes all checks locally before pushing any code to GitHub. Commit and push the verified changes, then raise a PR back to `main`(default branch) .

* Out-Of-Scope: Do not implement user authentication, file/image uploads, external state management libraries like Redux, or any active cloud service deployment tasks.

## 4. Input / Output Functional Contracts

* Endpoint: POST `/api/leads`
* Input Payload JSON: `{"companyName": "string", "contactEmail": "string", "leadSource": "string", "notes": "string"}`
* Validation: The fields `companyName` and `contactEmail` are required. The `contactEmail` variable must use a valid email format. The `leadSource` variable must strictly match one of the following values: 'Marketing', 'Cold Outreach', or 'Inbound'.
* Output Payload JSON (201 Created): `{"id": "guid-string", "companyName": "string", "contactEmail": "string", "leadSource": "string", "notes": "string", "createdAt": "datetime-string"}`

## 5. Strict Business Rules and Pipeline Secrets

* Rule 1: The frontend must use native browser fetch to call the backend and must read its target API URL dynamically from a Vite environment variable (`VITE_API_URL`) instead of using hardcoded host strings.
* Rule 2: The C# backend must read its database related settings exclusively from runtime environment variables.
* Rule 3: The GitHub Actions CI pipeline must securely pull configurations and secrets from your repository settings and map them as environment variables during the build and container testing phases.
* Rule 4: You must ensure that the backend container's internal build process safely handles the necessary database environment variables without exposing sensitive data in the final image layers.

## 7. Comprehensive Acceptance Criteria

* AC_01 (Scaffolding): Committing the base folders and the verification pipeline to the `main`(default branch)  branch triggers the GitHub Action, which builds both applications, runs unit tests, compiles the backend, frontend container images, and completes successfully.
* AC_02 (Happy Path): Submitting valid form details from the React UI inserts the data into Cosmos DB via the containerized API and appends it to the UI table.
* AC_03 (Validation): Entering an invalid email disables the submit button and shows an error message.
* AC_04 (Local-First Verification): The local build must successfully compile and pass all tests before code is permitted to be pushed to GitHub.
* AC_05 (PR Check & Autonomous Fixes): Raising a PR from the `feature/app-implementation` branch to `main`(default branch)  executes the full verification pipeline. Post PR is raised, poll the Action run of the PR and if any issues or errors arise during the remote run, you must  diagnose the problem, and automatically apply corrective code fixes until the pipeline passes perfectly.