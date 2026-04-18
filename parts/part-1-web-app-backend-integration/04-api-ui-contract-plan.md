# 04. API and UI Contract Plan (Part 1)

## Initial API Contract Draft

## Targets

1. `GET /api/v1/targets` - list targets
2. `POST /api/v1/targets` - create target
3. `GET /api/v1/targets/{targetId}` - get target details
4. `PATCH /api/v1/targets/{targetId}` - update target
5. `DELETE /api/v1/targets/{targetId}` - archive/delete target

Target draft fields:
- `id`
- `name`
- `primaryDomain`
- `tags[]`
- `owner`
- `createdAt`
- `updatedAt`

## Sessions

1. `GET /api/v1/sessions` - list sessions
2. `POST /api/v1/sessions` - create session
3. `GET /api/v1/sessions/{sessionId}` - get session details
4. `PATCH /api/v1/sessions/{sessionId}` - update session metadata
5. `POST /api/v1/sessions/{sessionId}/lock-scope` - lock scope

Session draft fields:
- `id`
- `targetId`
- `profile` (`core` | `advanced`)
- `scopeDefinition`
- `scopeLocked`
- `status`
- `createdAt`
- `updatedAt`

## Runs

1. `POST /api/v1/runs` - start recon run
2. `GET /api/v1/runs/{runId}` - run status summary
3. `GET /api/v1/runs/{runId}/logs` - run logs/events
4. `POST /api/v1/runs/{runId}/cancel` - cancel run

Run draft fields:
- `id`
- `sessionId`
- `stage`
- `status`
- `startedAt`
- `completedAt`
- `error`

## UI Route Mapping

| UI Route | API Dependencies | Purpose |
|---|---|---|
| `/targets` | Targets list/create/update | Manage target profiles |
| `/sessions` | Sessions list/create/update | Manage recon sessions |
| `/sessions/:id` | Session details/lock scope | Review and lock session scope |
| `/runs/:id` | Run status/logs | Monitor run execution |
| `/dashboard` | Health + summary placeholders | Part 1 base dashboard shell |

## Contract Rules

1. All API responses include request correlation ID.
2. Validation errors return deterministic field messages.
3. Frontend uses one typed client layer; no ad-hoc fetch calls per page.
