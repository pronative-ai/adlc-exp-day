# Business Intent — Step 2

**Ships in the starter pack at `intent/business-intent.md`.** Participants
do not write this — they review it, then paste it as input to the Spec
Agent. Because there's no facilitator narrating this one live, the document
has to teach on its own. That means showing the difference between a weak
and a strong version, the same way Step 1 showed ADHOC next to PRACTISING —
not just handing over a good example and asserting it's good.

---

## What makes a strong Business Intent

Four things, and only the last one is genuinely new — the first three echo
what "Optimize Your Inputs" already taught for technical intents, applied
one layer up:

1. **The problem is specific, not generic.** Say what's actually happening
   today and why it's a problem — not just "we need X."
2. **The persona is concrete, not a placeholder.** A real role, a real
   frequency of use, a real stake in the outcome — not "users" or
   "customers."
3. **The "why now" is explicit.** What business risk, cost, or missed
   opportunity makes this worth building today, specifically.
4. **It describes the outcome, not the solution.** Say what needs to be
   true, not how to build it. Caching, circuit breakers, database
   choices — all of that belongs in the technical layer the Spec Agent
   adds, not here. If your Business Idea already names an implementation
   pattern, you've written a spec, not an intent.

That fourth point is the one most engineers get wrong by default — it's
natural to jump straight to "we need a cache" instead of "we can't afford
repeated load on the external provider." Both describe the same problem;
only one leaves room for the technical layer to actually decide how.

---

## Weak version — what this looks like without the four principles

*(Shown for contrast only — do not use this one.)*

> **Title:** Currency Converter
> **Business Idea:** We need a currency converter for our app.
> **Persona:** Users.
> **User Need:** Users want to convert currency and see their history.

Every field here is technically true and tells the Spec Agent almost
nothing. There's no problem, no real persona, no reason this matters now,
and nothing to build against.

---

## Strong version — use this one

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

**🔒 Known Constraints** *(fixed — carry through unchanged, do not
reinterpret)*

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
  (Required RBAC roles are in place).

Notice Known Constraints is a different *kind* of thing than the four
fields above it — it's not a business need, it's a fixed technical fact.
That's why it's visually separate and marked "do not reinterpret" rather
than judged against the four principles above.

---

## Why this is the same scope as Step 0, on purpose

Step 0 was this idea, unguided. Step 1 was this idea, hand-structured two
ways. This is that same idea again, at the business layer specifically —
now with the weak/strong contrast that shows *why* the strong version
works, not just that it does. What's new in Step 2 is that a participant
reviews this, rather than writing it, and hands it to an agent, which adds
the remaining technical layer on top.

## What a participant actually does with this

1. Open `intent/business-intent.md` in the starter pack. Read the rubric
   and the weak/strong contrast first — that's the actual lesson.
2. Copy the **Strong version** section plus **Known Constraints**.
3. Tab to the Spec Agent in OpenCode, paste it, hit enter.
4. The Spec Agent carries the business fields and Known Constraints through
   unchanged, adds the technical layer, and writes the result to
   `spec/<slug>.md`.
