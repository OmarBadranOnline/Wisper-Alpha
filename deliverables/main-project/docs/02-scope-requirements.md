# 02. Scope and Requirements

## 1) Scope Definition

The platform performs **authorized reconnaissance** against web application targets using:

- **Core mode**: passive-first collection (faster baseline)
- **Advanced mode**: deeper, slower collection for richer intelligence and stronger correlation

## 2) Functional Requirements

| ID | Requirement | Priority |
|---|---|---|
| FR-01 | Create and manage target profiles (domain, org, tags, owner) | High |
| FR-02 | Run passive recon jobs from the UI/API | High |
| FR-03 | Integrate multiple passive tools/providers | High |
| FR-04 | Normalize raw outputs into unified schema | High |
| FR-05 | Deduplicate entities and merge evidence | High |
| FR-06 | Score confidence and severity/relevance | Medium |
| FR-07 | Provide dashboard and deep-dive pages | High |
| FR-08 | Export reports (PDF/JSON/CSV) | Medium |
| FR-09 | Keep historical snapshots for comparison | Medium |
| FR-10 | Enforce passive-only policy in core mode | High |
| FR-11 | Support advanced recon profile with longer runtime and deeper enrichment | High |
| FR-12 | Provide session mode to isolate work per website/scope | High |
| FR-13 | Allow multi-website session switching from one UI | Medium |
| FR-14 | Highlight advanced-mode outcomes separately from baseline findings | High |

## 3) Non-Functional Requirements

| ID | Requirement | Target |
|---|---|---|
| NFR-01 | Reliability | Retry transient failures, no silent drops |
| NFR-02 | Performance | Handle large target sets with queued workers |
| NFR-03 | Traceability | Every finding linked to source evidence |
| NFR-04 | Security | RBAC-ready auth, encrypted secrets at rest |
| NFR-05 | Usability | Clear dashboard + report-ready outputs |
| NFR-06 | Maintainability | Adapter-based architecture for new tools |
| NFR-07 | Portability | Local Docker deployment first, cloud-ready later |
| NFR-08 | Isolation | No evidence leakage between website sessions |
| NFR-09 | Scalability | Concurrent long-running advanced sessions with queues |

## 4) Data Requirements

- Raw evidence retention (immutable source records)
- Normalized asset tables (domain, subdomain, endpoint, cert, IP, ASN)
- Run metadata (tool versions, run config, timestamps)
- Confidence scoring metadata (rule version, score inputs)
- Session metadata (session profile, scope lock, stage durations, quality metrics)

## 5) Constraints

- Core workflow must remain passive.
- Advanced profile may include controlled low-noise metadata probes only when explicitly enabled.
- Collection must respect provider TOS and API limits.
- Use only authorized targets with documented permission.

## 6) Assumptions

- The project team has API keys for premium/passive sources where needed.
- Local environment can run containerized services.
- Course evaluation values architecture clarity and traceable evidence.

## 7) Acceptance Criteria

1. User starts recon for a target and receives complete correlated results.
2. UI shows discovered assets, evidence source, and confidence score.
3. Report export includes methodology and verifiable supporting artifacts.
4. Passive-only mode is enforced by configuration and command policy.
5. User can create separate sessions for different websites without data mixing.
6. Advanced-mode report clearly highlights added findings, added confidence, and extra runtime cost.

