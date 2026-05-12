# 01. Scope and Deliverables (Part 1)

## Goal

Build the application foundation where frontend and backend are integrated and operational for core workflows.

## In Scope

1. Platform skeleton for backend, frontend, and shared contracts.
2. Backend bootstrap with health check and standardized error shape.
3. CRUD APIs for targets and sessions (with session scope lock metadata).
4. Recon run control APIs (start run, status, logs/summary retrieval).
5. Frontend shell (routes and navigation) connected to backend.
6. Run console page for progress and failure visibility.
7. Basic access-control placeholders and protected route flow.
8. Integration hardening for loading, retry, and error states.
9. Part-1 acceptance documentation for handoff to Part 2.

## Out of Scope

1. Full recon adapter implementation (Part 2).
2. Final scoring and reporting pipeline (Part 2).
3. Deep database optimization, snapshots, and advanced read models (Part 3).
4. Production-grade auth/SSO and complete RBAC policy.

## Primary Deliverables

1. Running backend service with stable baseline endpoints.
2. Running frontend application with connected API client.
3. End-to-end flow: create target/session -> start run -> monitor status.
4. Documented API/UI behavior and integration contract.

## Acceptance Criteria

1. User can create and edit targets/sessions from UI and persist them through API.
2. User can trigger a run and observe current run status in the run console.
3. API failures produce consistent error payloads; UI displays clear error state.
4. Part 1 artifacts are documented and reusable by Part 2/Part 3 teams.
