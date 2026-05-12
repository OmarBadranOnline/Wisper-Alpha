# 04. Contract Plan (Part 2)

## Adapter Contract Draft

Adapter input:

- `runId`
- `sessionId`
- `targetScope`
- `profile` (`core` | `advanced`)
- `timeoutPolicy`
- `rateLimitPolicy`

Adapter output:

- `source`
- `rawRecords[]`
- `normalizedRecords[]`
- `warnings[]`
- `errors[]`
- `executionMeta` (duration, retries, version)

## Orchestration Contract Draft

Stage event fields:

- `runId`
- `stageName`
- `status`
- `startedAt`
- `endedAt`
- `attempt`
- `errorCode`
- `errorMessage`

Run summary fields:

- `runId`
- `status`
- `completedStages[]`
- `failedStages[]`
- `partialStages[]`
- `qualityMetrics`

## Findings Contract Draft

Finding fields:

- `id`
- `sessionId`
- `title`
- `category`
- `severityOrRelevance`
- `confidenceScore`
- `evidenceRefs[]`
- `recommendation`
- `createdAt`

## Reporting and Export Contract Draft

Report payload sections:

1. Executive summary
2. Scope and methodology
3. Session/profile summary
4. Key findings
5. Evidence appendix
6. Recommendations

Export metadata:

- `reportId`
- `format` (`pdf` | `json` | `csv`)
- `generatedAt`
- `sourceRunIds[]`
- `profile`
