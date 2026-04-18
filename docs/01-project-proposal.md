# 01. Project Proposal

## 1) Problem Statement

Manual reconnaissance is slow, inconsistent, and hard to reproduce across targets. Teams often lose context between tools and cannot quickly produce defensible, well-structured reports for stakeholders.

## 2) Proposed Solution

Build a **local-first, fully automated passive reconnaissance platform** that:

1. Accepts target scope (domains/org names).
2. Runs passive collectors from multiple OSINT sources.
3. Normalizes and correlates findings into a unified asset graph.
4. Scores evidence confidence and finding relevance.
5. Presents results in a professional web app with exportable reports.
6. Supports **advanced recon profile(s)** for deeper, slower intelligence.
7. Uses **session mode** to isolate different websites/scopes cleanly.

## 3) Project Objectives

- Automate passive attack-surface discovery end-to-end.
- Improve signal quality via deduplication and confidence scoring.
- Provide evidence-backed findings with source traceability.
- Produce course-grade documentation, architecture, and implementation depth.

## 4) Expected Deliverables

- Passive recon orchestration engine
- Tool-adapter layer for multi-source enrichment
- Structured database (assets, evidence, history)
- Web UI for target management, findings, and reporting
- Export templates (PDF/JSON/CSV)
- Full documentation set (this repository)

## 5) Success Criteria

- Single-command or API-triggered recon workflow.
- Repeatable results with source provenance.
- Dashboard with clear summaries, drill-down views, and trends.
- Report quality suitable for academic presentation and security review.
- Session isolation ensures no cross-website data contamination.
- Advanced profile demonstrates measurable quality gain over baseline mode.

## 6) In-Scope vs Out-of-Scope

### In Scope

- Passive subdomain and asset intelligence
- DNS, certificate, historical URL, ASN, and web metadata collection
- Correlation and evidence-based reporting

### Out of Scope (Core Version)

- Exploitation and payload delivery
- Intrusive active scanning in default mode
- Credential attacks or denial-of-service behavior

## 7) Value Proposition

- Faster recon cycle
- Better reporting quality
- Better discussion readiness for each project phase
- Clean migration path from local deployment to hosted deployment

