# 04. Data Contract Plan (Part 3)

## Core Entity Contract Draft

### Target

- `id`
- `name`
- `primaryDomain`
- `owner`
- `tags[]`
- `createdAt`
- `updatedAt`

### Session

- `id`
- `targetId`
- `profile`
- `scopeDefinition`
- `scopeLocked`
- `createdAt`
- `updatedAt`

### Run

- `id`
- `sessionId`
- `status`
- `startedAt`
- `completedAt`
- `runtimeMs`

### Evidence Record

- `id`
- `sessionId`
- `runId`
- `source`
- `rawPayloadRef`
- `normalizedHash`
- `capturedAt`
- `provenance`

### Finding

- `id`
- `sessionId`
- `runId`
- `title`
- `category`
- `confidenceScore`
- `severityOrRelevance`
- `evidenceRefs[]`

## Dashboard Read Model Contract Draft

Summary payload:

- `sessionId`
- `runId`
- `totalAssets`
- `newAssets`
- `confidenceDistribution`
- `topSources`
- `highPriorityFindings`

Trend payload:

- `sessionId`
- `timeline[]` (run timestamp + metric snapshots)
- `deltaSummary`

## Report Data Contract Draft

Report assembly payload:

1. Scope/methodology block
2. Session/profile block
3. Findings block (with evidence links)
4. Appendix block (source traceability)
5. Recommendation block

## Isolation and Integrity Rules

1. Every read/write query is scoped by `sessionId`.
2. Findings cannot reference evidence outside the same session.
3. Deletion/archive policies cannot remove linked report-critical artifacts without retention checks.
