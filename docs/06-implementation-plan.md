# 06. Implementation Plan

## 1) Execution Strategy

Build in vertical slices so each phase is demonstrable:

1. Scope intake
2. Data collection
3. Correlation and scoring
4. Reporting UI
5. Session isolation and multi-website control
6. Advanced recon depth
7. Hardening and presentation

## 2) Phase Plan

## Phase 1 - Foundation

- Define repository structure and coding standards
- Bootstrap backend, worker, frontend, and database
- Configure environment management and secrets strategy

**Deliverable:** runnable local stack with health checks.

## Phase 2 - Passive Collection Engine

- Implement adapters for Subfinder, Amass(passive), theHarvester, WHOIS, dig/nslookup, DNSRecon(passive), waybackurls
- Build job orchestration and retry logic
- Store raw and parsed outputs

**Deliverable:** one-click passive recon run with raw data capture.

## Phase 3 - Normalization and Correlation

- Canonicalize hostnames/URLs
- Merge duplicates across sources
- Build entity relationship links
- Implement first confidence scoring rules

**Deliverable:** clean, correlated target view with confidence labels.

## Phase 4 - Findings and Reporting

- Implement finding generation logic
- Build report templates (executive + technical)
- Add export endpoints (JSON/CSV/PDF)

**Deliverable:** report output suitable for academic and stakeholder review.

## Phase 5 - Web Application UX

- Dashboard (asset counts, trends, source coverage)
- Entity drill-down pages
- Run history and diff between runs

**Deliverable:** complete local web app interface.

## Phase 6 - Session Mode for Different Websites

- Implement session manager with immutable scope lock
- Add per-session recon profile selection (core vs advanced)
- Add website/session switcher in UI
- Add session-level compare (core result vs advanced result)

**Deliverable:** isolated sessions with clean multi-website workflow.

## Phase 7 - Advanced Pro Reconnaissance Layer

- Integrate advanced adapters (`Recon-ng`, `Shodan`, `Censys`, `SpiderFoot`, `Wappalyzer`, `WhatWeb`, advanced `theHarvester` profiles)
- Track stage runtime and quality gain metrics
- Add advanced-outcome highlighting in dashboard and report templates

**Deliverable:** deeper, slower, higher-confidence intelligence pipeline.

## Phase 8 - Hardening and Demonstration Readiness

- Access control and audit logs
- Error observability and run diagnostics
- Demo scripts, seeded datasets, and backup presentation flow

**Deliverable:** stable demo package for course evaluation.

## 3) Work Breakdown (Practical)

| Stream | Key Work Items |
|---|---|
| Backend | API, orchestration, adapter contracts, report APIs |
| Data | schema, migration, dedupe, confidence rules, session partitioning |
| Frontend | dashboards, tables, filters, session switcher, exports, run status |
| DevOps | compose stack, env profiles, backup/restore, logging |
| Documentation | architecture, legal scope, test evidence, discussion pack |

## 4) Definition of Done

- Feature implemented with error paths handled.
- Evidence traceable to source/provider.
- UI and API behavior documented.
- Test cases and demo flow updated.

## 5) Priority Improvement Backlog

1. Scheduled recurring reconnaissance + delta alerts.
2. Team collaboration (review workflow, comments, tagging).
3. Source health monitoring and adaptive fallback.
4. Multi-target benchmarking dashboards.
5. Hosted deployment profile with managed services.
6. Auto profile recommendation (choose core vs advanced by target complexity).

