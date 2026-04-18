# 02. Technical Structure (Part 1)

## Proposed Folder Structure

```text
part-1-web-app-backend-integration/
  backend/
    src/
      api/
      domain/
      services/
      middleware/
      config/
    tests/
  frontend/
    src/
      app/
      pages/
      components/
      services/
      state/
      routes/
    tests/
  shared/
    contracts/
    types/
    constants/
  docs/
    api/
    ux/
```

## Integration Architecture

1. Frontend calls backend through typed API client.
2. Backend validates request and maps to domain service.
3. Service returns structured success or typed error.
4. Frontend maps response to UI state (loading/success/error).
5. Run console polls (or streams) run state until terminal status.

## Baseline API Domains

1. **Health**
   - `/api/v1/health`
2. **Targets**
   - `/api/v1/targets`
3. **Sessions**
   - `/api/v1/sessions`
4. **Runs**
   - `/api/v1/runs`

## Error and Response Contract

- Standard response envelope for success and failure.
- Stable error code set for frontend handling.
- Validation errors returned with field-level details.

## Non-Functional Baseline

1. Clear logs for run lifecycle and API failures.
2. Configuration managed via environment profiles.
3. No silent failure paths in API request handling.
