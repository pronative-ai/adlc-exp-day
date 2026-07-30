**📝 Business Intent Title:** Real-Time Currency Conversion & Audit Trail

**💡 Business Idea:** Treasury operations teams at our enterprise customers
currently convert currency using manual lookups against a third-party
portal — slow, and it leaves no record for compliance. We need instant,
self-serve conversion inside our own app, and because these are regulated
transactions, every conversion must be reconstructable for an auditor on
demand, not pieced together afterward from emails or spreadsheets.

**👤 Persona:** Treasury operations analysts at enterprise customers, who
process multiple cross-border settlements a day and are personally
accountable if a conversion can't be justified during an audit.

**💚 User Need:** See a trustworthy converted amount the moment I enter it
— and be able to pull up any past conversion, with its rate and timestamp,
the moment an auditor asks for it.

Notice what's *not* here: no mention of caching, no mention of circuit
breakers, no mention of `IHttpClientFactory`. Those come from the Spec
Agent's technical elaboration, not from this layer.

---

**🔒 Known Constraints** *(fixed — carry through unchanged, do not reinterpret)*

- Frontend must read `VITE_API_URL` dynamically at container runtime using
  a generic entrypoint script placeholder replacement to allow native
  browser fetch.
- Backend must read database configurations exclusively from runtime
  environment variables.
- CI/CD pipeline must inject placeholders safely at deployment time without
  exposing sensitive data in container layers.
- Restricted to specific stack versions: React (Vite/Node 24.*) and C#
  (.NET 10).
- Must adhere to a strict folder layout (`src/frontend` and `src/backend`).
- Deploy as a single Azure Container App using the sidecar pattern to host
  both frontend and backend.
- Authenticate to Cosmos DB using the pre-assigned User-Assigned Managed
  Identity via `Azure.Identity`.
- Utilize `Microsoft.Azure.Cosmos` and `Azure.Identity` packages for
  secure, token-based database interactions.
- Include `Azure.ResourceManager` and `Azure.ResourceManager.CosmosDB`
  packages to handle programmatic database and container provisioning
  (Required RBAC roles are already in place).
- Reference and apply the environment variables defined in `docs\CONTAINER_ENVIRONMENT_VARIABLES.md` as required throughout the development and configuration of the services.
