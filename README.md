# Automated Passive Reconnaissance Platform (Course Project)

This repository now contains a full documentation package for building a **fully automated passive reconnaissance platform** for web application penetration testing.

The goal is to collect, normalize, correlate, and present external attack-surface intelligence in a local web app, with a clean path to later online deployment.

## Documentation Index

1. `docs/01-project-proposal.md` - project charter, objectives, outcomes
2. `docs/02-scope-requirements.md` - detailed scope, requirements, constraints
3. `docs/03-architecture.md` - architecture, workflows, and diagrams
4. `docs/04-tool-stack.md` - core + advanced tool selection and integration strategy
5. `docs/05-data-model.md` - data model, schema, evidence normalization, and session isolation
6. `docs/06-implementation-plan.md` - phased implementation plan and deliverables
7. `docs/07-reporting-ui-design.md` - web app UX, reports, dashboards, and session UX
8. `docs/08-security-legal-ethics.md` - legal boundary, ethics, data handling
9. `docs/09-testing-demo-plan.md` - testing, QA, and course demo strategy
10. `docs/10-risk-register.md` - risks, impacts, and mitigation plan
11. `docs/11-course-discussion-guide.md` - phase-by-phase discussion points
12. `docs/12-references.md` - curated technical references and standards
13. `docs/13-advanced-phase-session-mode.md` - pro reconnaissance phase and multi-website session mode
14. `docs/14-github-initial-requirements-and-work-structure.md` - GitHub-ready project structure, milestones, and detailed tasks in 3 main parts

## Project Direction

- **Primary mode:** passive reconnaissance only (no exploitation, no intrusive scanning in core pipeline)
- **Advanced mode:** deeper collection profiles for slower but higher-value outcomes
- **Session mode:** isolate runs and evidence for different websites in separate workspaces
- **Core output:** professional report portal with evidence traceability
- **Engineering focus:** reproducible data collection, quality scoring, and explainable findings

## 3 Main Delivery Parts (Execution Structure)

1. **Web app and backend integration** - UI, API, session flow, and end-to-end user operations.
2. **Main tools usage, reporting, and automation** - tool adapters, orchestration, scoring, reports, and scheduled automation.
3. **Database creation to dashboard reporting** - schema, migrations, session-isolated data pipeline, dashboard queries, and final report data assembly.

