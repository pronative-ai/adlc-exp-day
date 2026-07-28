# Workshop Reference: Multi-Container Azure Container App

This repository is a reference implementation for deploying a **React/Vite frontend** + **.NET backend** as a multi-container Azure Container App with CI/CD via GitHub Actions.

Use this as a template — copy themissing relevant files into your project and follow the instructions below to customize.

---

## Repository Structure

```
your-repo/
├── .azure/
│   └── container-app.tmpl.yaml    # <-- COPY this file as-is
├── .github/
│   └── workflows/
│       ├── ci-cd.yml             # <-- COPY this file, customize variables
├── scripts/
│   ├── initialize-github-variables.sh   # <-- COPY this file as-is
│   └── Initialize-GitHubVariables.ps1   # <-- COPY this file as-is
├── src/
│   ├── frontend/
│   │   ├── Dockerfile            # <-- COPY and customize
│   │   ├── nginx.conf            # <-- COPY and customize proxy port
│   │   └── ...
│   └── backend/
│       ├── Dockerfile            # <-- COPY and customize
│       └── ...
```

---

## Step 1: Files to Copy Into Your Project

Copy these files into your repository if missing:

| File | Purpose |
|------|---------|
| `.azure/container-app.tmpl.yaml` | Container App template with envsubst tokens |
| `.github/workflows/ci-cd.yml` | CI/CD pipeline |
| `scripts/initialize-github-variables.sh` | Bash script to set up GitHub repo variables |
| `scripts/Initialize-GitHubVariables.ps1` | PowerShell version of the same |

---

## Step 2: Customize Dockerfiles

### Frontend Dockerfile (`src/frontend/Dockerfile`)

```dockerfile
FROM node:<VERSION>-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:stable-alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**What to customize:**
- `node:<VERSION>` — Change to match your Node.js version (e.g., `20-alpine`, `22-alpine`)
- If your build output is not `dist/` (e.g., `build/`), update the `COPY --from=build` line
- If you don't use Vite, the build command and output directory may differ

### Backend Dockerfile (`src/backend/Dockerfile`)

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:<VERSION> AS build
WORKDIR /src

COPY <ProjectName>/<ProjectName>.csproj <ProjectName>/
RUN dotnet restore <ProjectName>/<ProjectName>.csproj

COPY <ProjectName>/ <ProjectName>/
RUN dotnet publish <ProjectName>/<ProjectName>.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:<VERSION> AS runtime
WORKDIR /app
COPY --from=build /app/publish .

EXPOSE 3000
ENTRYPOINT ["dotnet", "<ProjectName>.dll"]
```

**What to customize:**
- `<VERSION>` — Change to match your .NET version (e.g., `8.0`, `9.0`, `10.0`)
- `<ProjectName>` — Replace with your .csproj name (e.g., `MyApi`, `WeatherService`)
  - There are **4 occurrences** to replace: 2x `COPY`, 1x `RUN dotnet restore`, 1x `RUN dotnet publish`, 1x `ENTRYPOINT`
- `EXPOSE 3000` — Change if your backend listens on a different port
- The `ENTRYPOINT` DLL name must match your project name (e.g., `MyApi.dll`)

---

## Step 3: Customize nginx.conf (`src/frontend/nginx.conf`)

```nginx
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location /api/ {
        proxy_pass http://localhost:3000;
        ...
    }

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|svg|ico|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

**What to customize:**
- `proxy_pass http://localhost:3000` — Change `3000` to match your backend container's port
- `location /api/` — Change if your API uses a different base path (e.g., `/v1/`)
- If your SPA uses hash routing (`/#/`), the `try_files` fallback may not be needed

> **How the multi-container proxy works:** In Azure Container App, all containers in the same revision share `localhost`. Nginx forwards `/api/*` to the backend container on `localhost:3000`. No service discovery needed.

---

## Step 4: Customize container-app.tmpl.yaml (`.azure/container-app.tmpl.yaml`)

```yaml
properties:
  template:
    containers:
      - name: frontend
        image: ${FRONTEND_IMAGE}
        resources:
          cpu: 0.5
          memory: 1Gi
        ports:
          - port: 80
            protocol: TCP
        env:
          - name: VITE_API_URL
            value: ""

      - name: backend
        image: ${BACKEND_IMAGE}
        resources:
          cpu: 0.5
          memory: 1Gi
        ports:
          - port: 3000
            protocol: TCP
        env:
          - name: ASPNETCORE_ENVIRONMENT
            value: "Production"
          - name: ASPNETCORE_URLS
            value: "http://+:3000"
          - name: COSMOS_DB_URI
            value: "${COSMOS_DB_URI}"
          ...
    ingress:
      external: true
      targetPort: 80
      transport: http
```

**What to customize:**
- **Container names** (`frontend`, `backend`) — Change to match your app's container names
- **Ports** — Update to match your Dockerfiles (`EXPOSE` values)
- **Backend env vars** — Add/remove environment variables your backend needs
- **`COSMOS_DB_DATABASE`** and **`COSMOS_DB_CONTAINER`** — Change the default database (`leads-db`) and container (`leads`) names to suit your data model, project design
- **`VITE_API_URL`** — For Vite apps, keep as `""` since Nginx proxies on the same origin. For other frameworks, set the API base URL
- **Non-.NET backends** — Replace `ASPNETCORE_*` env vars with what your runtime needs (e.g., `PORT`, `NODE_ENV`)
- **`ingress.targetPort`** — Must match your **frontend** container's port (the one that serves the UI)
- **Resources** — Adjust `cpu` and `memory` based on your app's needs

### Adding environment variables

To add a new env var (e.g., a database connection string), add it in two places:

1. **container-app.tmpl.yaml** — Add under the relevant container's `env:` section:
   ```yaml
   env:
     - name: MY_DB_CONNECTION
       value: "${MY_DB_CONNECTION}"
   ```

2. **ci-cd.yml** — Add the export in the `Substitute template tokens` step:
   ```yaml
   export MY_DB_CONNECTION="${{ vars.MY_DB_CONNECTION }}"
   ```

---

## Step 5: Customize ci-cd.yml (`.github/workflows/ci-cd.yml`)

The pipeline is mostly generic. Key areas to customize:

### Registry auth

If you're using a different container registry (not GHCR), update:
- The `Log in to GitHub Container Registry` step
- The `Ensure Container App registry auth` step
- Image tags in `Build and push` steps

---

## Step 6: GitHub Repository Setup

### Variables (GitHub Actions > Variables)

Run the initialization script to create all required variables:

```bash
# From the repo root
./scripts/initialize-github-variables.sh -e <YOUR_ENROLLMENT_NUMBER>
# e.g., ./scripts/initialize-github-variables.sh -e 1001
```

This creates these **Actions variables**:

| Variable | Example Value | Description |
|----------|--------------|-------------|
| `CONTAINERAPP_NAME` | `ca-adlc-exp-1001` | Azure Container App name |
| `COSMOSDB_NAME` | `cosmos-adlc-exp-1001` | Cosmos DB account name |
| `RESOURCEGROUP_NAME` | `rg-adlc-exp-2608-1001` | Azure resource group |
| `CLIENT_ID` | `<GUID>` | Service principal client ID (for Azure login) |
| `SUBSCRIPTION_ID` | `<GUID>` | Azure subscription ID |
| `TENANT_ID` | `<GUID>` | Azure AD tenant ID |
| `COSMOS_DB_REGION` | `CentralIndia` | Azure region for Cosmos DB provisioning (e.g., `CentralIndia`, `EastUS`, `WestEurope`) |

### Secrets (GitHub Actions > Secrets)

These must be added manually (cannot be created via API without encryption):

| Secret | Description |
|--------|-------------|
| `CLIENT_SECRET` | Service principal secret (for Azure auth will be shared by Presenter) |
| `GHCR_PAT` | GitHub PAT with `read:packages` scope (for Container App to pull images from GHCR) |

### Azure Resources Required

Before first deploy, ensure these exist in Azure:

1. **Resource Group**
2. **Container App Environment**
3. **Container App** (can be empty initially)
4. **Cosmos DB Account** (SQL API)
5. **User-Assigned Managed Identity** named `id-<ContainerAppName>`

---

## Step 7: First Deploy

1. Commit all files reated to CI CD to the `main` branch
2. The deploy pipeline triggers automatically on changes to `src/frontend/**` or `src/backend/**`
3. Or trigger manually: **Actions > Deploy Multi-Container App > Run workflow**

---

## Architecture Diagram

```
                    ┌─────────────────────────────────────────┐
                    │         Azure Container App             │
                    │                                         │
  Internet ──────►  │  Ingress (port 80)                      │
                    │    │                                    │
                    │    ├──► frontend (nginx:80)             │
                    │    │     │                              │
                    │    │     ├── /           → index.html   │
                    │    │     └── /api/*      → proxy_pass   │
                    │    │              │                      │
                    │    └──► backend (.NET:3000)             │
                    │              │                          │
                    │              └──► Cosmos DB             │
                    └─────────────────────────────────────────┘
```


