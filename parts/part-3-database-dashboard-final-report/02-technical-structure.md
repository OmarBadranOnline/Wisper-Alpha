# 02. Technical Structure (Part 3)

## Proposed Folder Structure

```text
part-3-database-dashboard-final-report/
  schema/
    migrations/
    seeds/
    constraints/
    indexes/
  data-layer/
    repositories/
    transactions/
    isolation/
  read-models/
    dashboard/
    findings/
    report/
    compare/
  retention/
    archival/
    cleanup/
  recovery/
    backup/
    restore/
  docs/
    schema/
    query-spec/
    recovery-runbook/
```

## Data Layer Model

1. **Raw Evidence Layer** - immutable source artifacts and provenance.
2. **Normalized Entity Layer** - deduplicated assets and relationships.
3. **Read Model Layer** - optimized projections for dashboard/report consumption.

## End-to-End Data Flow

1. Ingest raw tool outputs with session scope metadata.
2. Normalize and link evidence into entity graph.
3. Build snapshot deltas for run comparisons.
4. Project dashboard/report read models.
5. Serve findings/report payloads through stable read APIs.

## Core Engineering Rules

1. Every persisted record includes `sessionId` and origin metadata.
2. Immutable evidence records are never updated in-place.
3. Read models are rebuilt or incrementally updated deterministically.
4. Constraints and indexes are added as part of migration history.
