# Wisper-Alpha - Automated Passive Recon Platform

Wisper-Alpha is organized as **3 connected delivery parts** with a single root workflow for startup, testing, and GitHub handoff.

## High-level structure

1. **Part 1 (Web/API core):** FastAPI backend + React frontend, session and target workflows.
2. **Part 2 (Terminal orchestration):** `wisper.sh` recon automation and evidence/report generation flow.
3. **Part 3 (Data/reporting foundation):** database and dashboard planning assets + final report package.

## Low-level repository map

| Path | Role |
|---|---|
| `parts/part-1-web-app-backend-integration` | Running app (backend/frontend) + backend unit tests |
| `parts/part-2-tools-reports-automation` | Terminal orchestrator script (`wisper.sh`) |
| `parts/part-3-database-dashboard-final-report` | Database/dashboard/report deliverables |
| `docs` | Full project documentation set (01..14) |
| `deliverables/main-project` | GitHub-ready packaged documentation baseline |
| `start.ps1` | Root launcher with **2 modes** (Terminal / Web Monitor) |
| `run-unit-tests.ps1` | Cross-part validation runner |

## Quick start (terminal)

1. Open PowerShell in the repository root.
2. Run `.\start.ps1`.
3. Select:
   - `1` for **Terminal Mode** (runs Part 2 orchestrator in Git Bash).
   - `2` for **Web Monitor Mode** (starts backend + frontend and opens localhost dashboard).

**Terminal mode note (Windows):** tool auto-install in `wisper.sh` uses Linux package managers when available.  
For full automatic dependency install, run Terminal Mode from WSL/Ubuntu. In Git Bash on Windows, non-Linux package steps are skipped safely.

**Dependency workflow update:** `wisper.sh` now performs a dependency pre-check first, reports **correct/problem** status, and only asks to install missing items.

## Run checks for all parts

Run:

```powershell
.\run-unit-tests.ps1
```

This executes the existing checks by part:

- Part 1 backend: `pytest`
- Part 1 frontend: production build
- Part 2: shell syntax validation for `wisper.sh`
- Part 3: required deliverable-file presence validation

## Web mode endpoints

- Frontend monitor UI: `http://localhost:5173`
- Backend API docs: `http://localhost:8000/api/docs`

## Documentation index

1. `docs/01-project-proposal.md`
2. `docs/02-scope-requirements.md`
3. `docs/03-architecture.md`
4. `docs/04-tool-stack.md`
5. `docs/05-data-model.md`
6. `docs/06-implementation-plan.md`
7. `docs/07-reporting-ui-design.md`
8. `docs/08-security-legal-ethics.md`
9. `docs/09-testing-demo-plan.md`
10. `docs/10-risk-register.md`
11. `docs/11-course-discussion-guide.md`
12. `docs/12-references.md`
13. `docs/13-advanced-phase-session-mode.md`
14. `docs/14-github-initial-requirements-and-work-structure.md`

