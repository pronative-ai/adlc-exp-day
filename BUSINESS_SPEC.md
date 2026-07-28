## Business Idea

A lightweight lead capture system featuring a single-page web form for marketing managers to submit new sales leads.

## Target Users

Marketing managers and sales operations teams who need to quickly input and track new prospects.

## Business Goal

Enable instant, dynamic lead submission and storage without page refreshes, ensuring a seamless user experience for data entry.

## Known Constraints

- Frontend must read `VITE_API_URL` dynamically at container runtime using a generic entrypoint script placeholder replacement to allow native browser fetch.
- Backend must read database configurations exclusively from runtime environment variables.
- CI/CD pipeline must inject placeholders safely at deployment time without exposing sensitive data in container layers.
- Restricted to specific stack versions: React (Vite/Node 24.*) and C# (.NET 10).
- Must adhere to a strict folder layout (`src/frontend` and `src/backend`).
- Deploy as a single Azure Container App using the sidecar pattern to host both frontend and backend.
- Authenticate to Cosmos DB using the pre-assigned User-Assigned Managed Identity via `Azure.Identity`.
- Utilize `Microsoft.Azure.Cosmos` and `Azure.Identity` packages for secure, token-based database interactions.
- Include `Azure.ResourceManager` and `Azure.ResourceManager.CosmosDB` packages to handle programmatic database and container provisioning (Required RBAC roles are in place).


## Existing Context

The organization requires a dual-stage execution model, starting with an initial configuration/scaffolding push straight to the default branch, followed by a formal feature branch and pull request workflow for the actual implementation. Refer to `CICD_INSTRUCTIONS.md`

## Scope Level

Minimum Viable Product (MVP) focusing strictly on basic text/email validation and local database persistence. It explicitly excludes user authentication, file uploads, external state management libraries, and active cloud deployment tasks.
