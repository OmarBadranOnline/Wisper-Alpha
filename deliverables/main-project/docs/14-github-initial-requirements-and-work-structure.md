# 14. GitHub Initial Requirements and 3-Part Work Structure

This document defines the initial GitHub setup requirements and a detailed, maintainable task structure for execution.

## 1) Initial GitHub Repository Requirements

## Branching and Protection

- Default branch: `main`
- Protect `main`:
  - Require pull request before merge
  - Require at least 1 approval
  - Require status checks to pass before merge
  - Block force push and branch deletion

## Branch Naming

- `feature/P1-Txx-short-name`
- `feature/P2-Txx-short-name`
- `feature/P3-Txx-short-name`
- `fix/short-name`
- `docs/short-name`

## Labels

- `part:web-backend`
- `part:tools-reports-automation`
- `part:database-dashboard`
- `priority:high`
- `priority:medium`
- `priority:low`
- `status:blocked`
- `type:feature`
- `type:bug`
- `type:docs`

## Milestones

1. `M1 - Web App + Backend Integration`
2. `M2 - Tools, Reports, and Automation`
3. `M3 - Database to Dashboard and Final Reporting`

## Project Board Columns

1. `Backlog`
2. `Ready`
3. `In Progress`
4. `Review`
5. `Done`

## Definition of Done (All Tasks)

- Acceptance criteria are met.
- Data and evidence traceability is preserved.
- Documentation is updated if behavior changes.
- Task is linked to PR and milestone.

## 2) Part 1 - Web App and Backend Integration

**Goal:** deliver a usable web application connected to backend APIs for target/session/recon workflows.

| ID | Task | Detailed Scope | Deliverable | Depends On | Priority |
|---|---|---|---|---|---|
| P1-T01 | Platform skeleton | Create base folder structure for frontend, backend, shared contracts, and config management. | Runnable starter structure with clear module boundaries. | None | High |
| P1-T02 | Backend service bootstrap | Set up backend app startup, health endpoint, environment loading, and base middleware. | Backend service with health check and standard error response format. | P1-T01 | High |
| P1-T03 | Session and target APIs | Implement CRUD endpoints for targets and sessions, including session scope lock metadata. | Versioned APIs for targets/sessions with validation. | P1-T02 | High |
| P1-T04 | Recon run control APIs | Add endpoints to start runs, read run status, and fetch run logs/summary. | API surface for orchestration trigger and progress reporting. | P1-T03 | High |
| P1-T05 | Frontend shell and navigation | Build base UI shell, route layout, and top-level navigation for main pages. | Stable frontend frame with route-level page placeholders. | P1-T01 | High |
| P1-T06 | API client integration | Connect frontend to backend APIs using typed request/response models. | Working data flow from UI to backend endpoints. | P1-T03, P1-T05 | High |
| P1-T07 | Run console UX | Build a run console view showing current stage, status, and failure messages. | Real-time or poll-based run monitoring page. | P1-T04, P1-T06 | Medium |
| P1-T08 | Access control baseline | Add basic auth/session guard placeholders and route protection strategy. | Protected routes with consistent unauthorized handling. | P1-T06 | Medium |
| P1-T09 | Integration hardening | Standardize error payloads, loading states, retries for transient API calls. | Reliable UX for request failures and partial outages. | P1-T07 | Medium |
| P1-T10 | Part 1 acceptance package | Document API contracts and complete end-to-end integration walkthrough. | Signed-off integration baseline for milestone M1. | P1-T09 | High |

## 3) Part 2 - Main Tools Usage, Reports, and Automation

**Goal:** integrate recon tools, automate execution, and produce high-quality, evidence-linked reports.

| ID | Task | Detailed Scope | Deliverable | Depends On | Priority |
|---|---|---|---|---|---|
| P2-T01 | Adapter contract | Define a common adapter interface for all recon sources and outputs. | Standard adapter spec with normalized output schema contract. | P1-T04 | High |
| P2-T02 | Core tool adapters | Implement adapters for core passive tools and source metadata mapping. | Core collection pipeline returning normalized records. | P2-T01 | High |
| P2-T03 | Advanced adapters | Add advanced profile adapters with profile-based enable/disable controls. | Advanced pipeline mode with explicit profile selection. | P2-T01 | Medium |
| P2-T04 | Orchestration engine | Build stage execution flow, retries, backoff, timeout control, and partial-failure handling. | Deterministic orchestration behavior and run state transitions. | P2-T02 | High |
| P2-T05 | Correlation and scoring | Merge duplicate entities, link evidence, compute confidence/relevance scores. | Correlated asset graph and scoring outputs. | P2-T02, P3-T03 | High |
| P2-T06 | Findings generator | Translate correlated results into finding objects with evidence references. | Structured findings ready for dashboard and report views. | P2-T05 | High |
| P2-T07 | Report templates | Implement executive and technical report templates with methodology and evidence appendix sections. | Report templates that can render session outputs consistently. | P2-T06 | High |
| P2-T08 | Export pipeline | Support report export formats (PDF/JSON/CSV) and metadata packaging. | Downloadable report artifacts with reproducible content. | P2-T07 | Medium |
| P2-T09 | Scheduled automation | Add scheduled run capability and delta comparison trigger between runs. | Automated recon cycles with change tracking outputs. | P2-T04, P3-T05 | Medium |
| P2-T10 | Tool health and audit | Track adapter execution metrics, failures, and source coverage quality. | Operational visibility and audit-ready run diagnostics. | P2-T04 | Medium |

## 4) Part 3 - Database Creation to Dashboard and Final Reporting

**Goal:** create a session-safe data layer that powers dashboard analytics and final report generation.

| ID | Task | Detailed Scope | Deliverable | Depends On | Priority |
|---|---|---|---|---|---|
| P3-T01 | Schema design v1 | Define core relational schema for targets, sessions, runs, evidence, assets, findings. | Reviewed schema and entity relationship map. | P1-T01 | High |
| P3-T02 | Migrations and seed strategy | Implement migration files, seed data for local demo, and versioned schema change flow. | Repeatable DB bootstrap and migration process. | P3-T01 | High |
| P3-T03 | Session isolation controls | Enforce session IDs and scope boundaries across all evidence and derived entities. | Isolation-safe data model with no cross-session leakage. | P3-T02 | High |
| P3-T04 | Raw evidence store | Persist immutable raw tool outputs and provenance metadata. | Auditable raw evidence layer. | P3-T02 | High |
| P3-T05 | Snapshot and compare model | Support run snapshots and diff logic for new/changed/removed assets. | Historical comparison tables and query logic. | P3-T03 | Medium |
| P3-T06 | Dashboard read models | Create query models/materialized views for fast dashboard cards and trend data. | Dashboard-ready read models and summary endpoints. | P3-T05 | High |
| P3-T07 | Findings/report read APIs | Build APIs that assemble findings, evidence links, and report sections from DB. | Endpoints for final report and UI findings pages. | P2-T06, P3-T06 | High |
| P3-T08 | Data quality and integrity rules | Add constraints, indexes, and validation rules for consistency and performance. | Stable query performance and referential integrity controls. | P3-T06 | Medium |
| P3-T09 | Retention and archival policy | Define retention windows for raw evidence and archived runs with policy controls. | Controlled storage growth with policy-based cleanup rules. | P3-T04 | Low |
| P3-T10 | Recovery readiness | Define backup/restore procedures for sessions and report-critical data. | Recoverable dataset for dashboard/report continuity. | P3-T08 | Medium |

## 5) Cross-Part Dependency Map

1. Part 1 establishes API and UI foundations required by Parts 2 and 3.
2. Part 3 session isolation (`P3-T03`) must be ready before final scoring/report consistency in Part 2.
3. Part 2 findings and report logic depends on Part 3 read models and query paths.
4. Final dashboard/report acceptance requires completion of `P1-T10`, `P2-T08`, and `P3-T07`.

## 6) Recommended GitHub Issue Format

Use this naming style for Issues:

- `[P1-T03] Session and target APIs`
- `[P2-T04] Orchestration engine`
- `[P3-T06] Dashboard read models`

Each issue should include:

1. Problem statement and why this task exists.
2. Scope in/out boundaries.
3. Acceptance criteria.
4. Dependencies from this document.
5. Linked PR and test/demo evidence.
