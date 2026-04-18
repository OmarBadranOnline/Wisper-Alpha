# 01. Scope and Deliverables (Part 3)

## Goal

Deliver the data platform from schema creation to dashboard/report data delivery with strict session isolation and traceable evidence.

## In Scope

1. Schema design for targets, sessions, runs, evidence, assets, and findings.
2. Migration and seed strategy for reproducible setup.
3. Session isolation controls across all records.
4. Immutable raw evidence storage with provenance metadata.
5. Snapshot/compare model for historical run deltas.
6. Dashboard read models for fast summary/trend queries.
7. Findings and report-read APIs assembled from normalized data.
8. Integrity/performance controls (constraints, indexes, validations).
9. Retention and archival strategy definition.
10. Backup/restore readiness for report-critical continuity.

## Out of Scope

1. Full multi-region/high-availability database deployment.
2. Enterprise-scale warehouse integrations.
3. Non-project analytics not tied to dashboard/report requirements.

## Primary Deliverables

1. Versioned schema + migrations + seed baseline.
2. Session-isolated evidence and derived entity model.
3. Dashboard and report read models with stable API consumption.
4. Data integrity and recovery controls documented and ready.

## Acceptance Criteria

1. All run data is session-bound with no cross-session leakage.
2. Dashboard endpoints can read summary/trend metrics from read models.
3. Report APIs assemble findings with linked evidence references.
4. Historical comparison can identify new/changed/removed assets between runs.
5. Backup/restore procedure can preserve report-critical data continuity.
