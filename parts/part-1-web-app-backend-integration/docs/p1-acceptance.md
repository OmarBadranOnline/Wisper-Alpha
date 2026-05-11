# Part 1 Acceptance Package

## Delivery Status: COMPLETE

All P1-T01 through P1-T10 tasks are delivered.

---

## Task Checklist

| ID | Task | Status | Artifact |
|----|------|--------|----------|
| P1-T01 | Platform skeleton | ✅ | `backend/`, `frontend/`, `shared/`, `docker-compose.yml` |
| P1-T02 | Backend service bootstrap | ✅ | `backend/app/main.py`, health endpoint at `/api/v1/health` |
| P1-T03 | Session and target APIs | ✅ | `/api/v1/targets`, `/api/v1/sessions` with lock-scope |
| P1-T04 | Recon run control APIs | ✅ | `/api/v1/runs` with start/status/logs/cancel |
| P1-T05 | Frontend shell and navigation | ✅ | React app with sidebar nav, 5 routes |
| P1-T06 | API client integration | ✅ | `frontend/src/services/` typed client layer |
| P1-T07 | Run console UX | ✅ | `RunConsolePage` with live polling, stage progress, terminal log |
| P1-T08 | Access control baseline | ✅ | `ProtectedRoute` guard, auth placeholder |
| P1-T09 | Integration hardening | ✅ | Loading states, error alerts, retry-ready client, correlation IDs |
| P1-T10 | Acceptance package | ✅ | This document + `docs/api/endpoints.md` |

---

## Acceptance Criteria Verification

1. **User can create and edit targets/sessions from UI and persist them through API.**
   - TargetsPage: create modal, inline delete
   - SessionsPage: create modal, target filter, start run button
   - SessionDetailPage: lock scope, view run history

2. **User can trigger a run and observe current run status in the run console.**
   - RunConsolePage: stage progress bar, live log polling every 2s, cancel button
   - Run simulation progresses through 6 stages with realistic log messages

3. **API failures produce consistent error payloads; UI displays clear error state.**
   - All errors use `{ success: false, error: { code, message } }` envelope
   - Frontend ErrorAlert component shown on all API failures
   - Correlation IDs in every request/response

4. **Part 1 artifacts are documented and reusable by Part 2/Part 3 teams.**
   - `shared/contracts/` TypeScript contracts for all entities
   - `docs/api/endpoints.md` full API reference
   - `Makefile` for consistent dev commands
   - `.env.example` for configuration

---

## Running the Platform

### Local Development

```bash
# Install dependencies
make install

# Terminal 1: backend
make backend

# Terminal 2: frontend
make frontend
```

Open http://localhost:5173

### Docker

```bash
make docker-up
```

Open http://localhost:3000

---

## Integration Notes for Part 2

- Backend `/api/v1/runs` creates stub runs; Part 2 replaces `_simulate_run()` in `run_service.py` with real tool adapter calls.
- Session `profile` field (`core`/`advanced`) already flows through to runs — Part 2 reads this to select tool set.
- All entities carry `session_id` and `target_id` — Part 2 data writes must include these for session isolation.
- `shared/contracts/` define the stable API surface — do not break these shapes.

---

## Integration Notes for Part 3

- SQLAlchemy models in `backend/app/models.py` are the migration baseline.
- Add `findings`, `subdomains`, `dns_records`, etc. as new model files and Alembic migrations.
- Dashboard widgets in `DashboardPage.tsx` have placeholder stat cards ready for real data queries.
