# 00. Consolidated Planning (No Implementation Details)

This file consolidates planning details from the documentation set into one planning-only source.

**Excluded intentionally:** implementation instructions, execution steps, and command-level integration details.

## 1) Project Vision and Rationale

### Problem
Manual reconnaissance is slow, inconsistent, and difficult to reproduce, which reduces reporting quality and decision confidence.

### Planned Solution
A local-first reconnaissance platform that:
- collects external attack-surface intelligence,
- correlates multi-source evidence,
- scores confidence and relevance,
- presents results in a professional web app,
- supports deeper advanced profiling and isolated session-based workflows.

### Objectives
- End-to-end automated reconnaissance workflow (defensive, authorized usage).
- Better signal quality through normalization and deduplication.
- Strong evidence traceability for each finding.
- Course-grade structure for explanation, review, and presentation.

### Success Conditions
- Repeatable evidence-backed outputs.
- Clear dashboards and report-ready artifacts.
- Measurable quality gain in advanced profile versus baseline profile.
- No cross-website data contamination between sessions.

## 2) Scope, Boundaries, and Modes

### In Scope
- Passive asset intelligence (domains, subdomains, DNS, certificates, URLs, ASN context).
- Correlation, scoring, reporting, and historical comparison.
- Session isolation for different websites/scopes.

### Out of Scope (Core Policy)
- Exploitation or payload activity.
- Intrusive aggressive scanning by default.
- Credential attacks and denial-of-service behavior.

### Operating Modes
- **Core mode:** passive-first baseline (faster).
- **Advanced mode:** deeper enrichment and higher confidence (slower).
- **Session mode:** dedicated isolated workspace per website/scope.

## 3) Requirement Baseline

### Functional Planning Requirements
- Target profile management.
- Recon run control from UI/API.
- Multi-source tool/provider integration.
- Output normalization and evidence merging.
- Confidence/relevance scoring.
- Dashboard, deep-dive views, and report exports.
- Historical snapshots and comparisons.
- Advanced profile support and advanced-outcome highlighting.
- Session-based website isolation and session switching.

### Non-Functional Planning Requirements
- Reliability under source/API variability.
- Scalable queued processing for long-running profiles.
- Traceability from findings to raw evidence.
- Security controls for secrets and report access.
- Maintainability via adapter-based architecture.
- Isolation guarantees by session and target scope.

## 4) Architecture Plan

### Core Components
- Web UI
- Backend API
- Session Manager
- Recon Orchestrator
- Tool Adapter Layer (core + advanced)
- Correlation/Scoring Engine
- Reporting Engine
- Data Stores (raw evidence + normalized model)

### Flow Model
- Intake target/scope.
- Execute profile-based collection (core or advanced).
- Normalize and deduplicate entities.
- Correlate evidence and compute confidence.
- Produce findings and report views.

### Deployment Direction
- Local-first deployment model for course context.
- Clean portability to hosted environments later.

## 5) Tooling Strategy Plan

### Core Tooling (Baseline)
- subfinder
- amass (passive mode)
- theHarvester
- whois
- dig / nslookup
- DNSRecon (passive profile)
- waybackurls
- Wappalyzer
- WhatWeb

### Advanced Tooling (Deep Profile)
- Recon-ng (domain intelligence enrichment)
- Shodan (public exposure intelligence)
- Censys (public exposure and certificate intelligence)
- SpiderFoot (metadata and email enrichment)
- Advanced theHarvester profiles

### Planning Principle
Use profile-based depth control to balance runtime cost against intelligence quality.

## 6) Data and Session Planning

### Data Layers
- Raw evidence layer (immutable provenance records)
- Normalized entity layer (deduplicated assets/relationships)
- Analytics layer (findings, scoring, trends, report aggregates)

### Core Planned Entities
- targets, recon_sessions, recon_runs, sources, evidence_records
- domains, subdomains, dns_records, certificates, ip_addresses, asns, web_endpoints, findings

### Session Isolation Rules
- Every run-derived record is session-scoped.
- Scope lock per session to prevent cross-website leakage.
- Cross-session comparisons only through explicit compare logic.

### Confidence Model Direction
Confidence is planned as a function of source diversity, consistency, and recency, with contradiction penalties.

## 7) UI and Reporting Planning

### Planned UX Surfaces
- Targets view
- Session manager
- Run console
- Dashboard
- Assets explorer
- Findings view
- Report builder

### Reporting Structure
- Executive summary
- Scope and methodology
- Session/profile summary
- Key findings
- Evidence appendix
- Recommendations

### Advanced Highlighting
- Advanced-only discovered assets
- Confidence uplift versus baseline
- Runtime versus quality-gain visibility

## 8) Security, Legal, and Ethics Planning

- Authorization and scope validation are mandatory.
- Core policy remains passive-first.
- Advanced actions must be explicitly declared per session.
- Provider terms/rate limits must be respected.
- Evidence storage must preserve confidentiality and access control.
- Reporting must separate observed facts from interpretation.

## 9) Quality and Evaluation Planning

### Planned Quality Focus
- Parser and normalization correctness
- Evidence-link integrity
- Session isolation integrity
- Profile branching correctness
- Export/report completeness

### Course Demo Planning Focus
- Demonstrate core vs advanced comparison.
- Demonstrate multi-website session isolation.
- Demonstrate traceable evidence-to-finding chain.

## 10) Risk Planning Priorities

Top risk themes:
- API/rate-limit bottlenecks,
- source blind spots and noisy outputs,
- legal scope errors,
- session data leakage risk,
- advanced runtime and API budget pressure.

Mitigation direction includes throttling, multi-source corroboration, strict scope locks, and profile controls.

## 11) Course Discussion Structure

Planned discussion sequence:
1. project need and value,
2. scope and ethics,
3. architecture rationale,
4. tooling rationale,
5. data/scoring rationale,
6. reporting rationale,
7. quality/risk rationale,
8. future evolution.

## 12) Standards and Reference Baseline

- OWASP WSTG (Information Gathering)
- PTES Technical Guidelines
- NIST SP 800-115
- Core and advanced tool documentation set used by this project

## 13) Planning Status Summary

The project planning baseline now supports:
- baseline and advanced reconnaissance strategy,
- measurable quality-vs-runtime framing,
- strict multi-website session isolation model,
- course-ready architecture and discussion structure,
- single-file planning view without implementation instructions.

