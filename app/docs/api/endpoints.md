# Part 1 — API Endpoint Reference

## Base URL

```
http://localhost:8000/api/v1
```

## Correlation IDs

Every response includes `X-Correlation-ID` header. Pass `X-Correlation-ID` in requests to trace end-to-end.

## Response Envelope

All endpoints return:

```json
{
  "success": true,
  "correlation_id": "uuid",
  "data": { ... },
  "error": null
}
```

On failure:

```json
{
  "success": false,
  "correlation_id": "uuid",
  "data": null,
  "error": { "code": "HTTP_404", "message": "Target not found" }
}
```

---

## Health

### GET /health

Returns service and database status.

```json
{ "status": "ok", "version": "1.0.0", "database": "ok" }
```

---

## Targets

| Method | Path | Description |
|--------|------|-------------|
| GET | /targets | List all targets |
| POST | /targets | Create target |
| GET | /targets/{id} | Get target |
| PATCH | /targets/{id} | Update target |
| DELETE | /targets/{id} | Delete target |

**Target fields:** `id`, `name`, `primary_domain`, `tags[]`, `owner`, `status`, `created_at`, `updated_at`

---

## Sessions

| Method | Path | Description |
|--------|------|-------------|
| GET | /sessions | List sessions (filter: `?target_id=`) |
| POST | /sessions | Create session |
| GET | /sessions/{id} | Get session |
| PATCH | /sessions/{id} | Update session |
| POST | /sessions/{id}/lock-scope | Lock session scope |

**Session fields:** `id`, `target_id`, `name`, `profile` (core/advanced), `scope_definition`, `scope_locked`, `status`, `created_at`, `updated_at`

---

## Runs

| Method | Path | Description |
|--------|------|-------------|
| GET | /runs | List runs (filter: `?session_id=`) |
| POST | /runs | Start run (`{ "session_id": "..." }`) |
| GET | /runs/{id} | Run status |
| GET | /runs/{id}/logs | Run logs/events |
| POST | /runs/{id}/cancel | Cancel run |

**Run stages:** queued → subdomain_discovery → dns_enrichment → certificate_scan → historical_urls → metadata_collection → normalization → completed

**Run statuses:** pending → running → completed / failed / cancelled
