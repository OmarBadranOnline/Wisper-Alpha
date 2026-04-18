# 13. Advanced Phase and Session Mode

## 1) Why Advanced Phase

Core passive recon is fast and useful, but advanced phase is designed to:

- increase asset coverage depth
- improve confidence by cross-validating sources
- expose infrastructure patterns not visible in baseline mode

Tradeoff: **more runtime and API usage**, but **better intelligence quality**.

## 2) Advanced Outcomes to Highlight

1. New assets found only in advanced mode
2. Confidence score improvements from multi-source confirmation
3. TLS and certificate risk indicators (expired, weak config, mismatch)
4. ASN/CIDR exposure insights and infrastructure expansion map
5. Deeper metadata and technology fingerprint coverage

## 3) Session Mode for Different Websites

Each website should be handled in a dedicated session:

- `session_id`: unique workspace container
- `target_scope`: exact allowed domains/subdomains
- `profile`: core-passive / advanced-deep-passive / advanced-controlled-metadata
- `status`: draft / running / completed / archived

### Session Guarantees

- No cross-website evidence blending
- Separate run history per website
- Separate report exports per session
- Explicit compare mode when needed

## 4) Session Lifecycle

```mermaid
flowchart LR
    A[Create Session] --> B[Define Website Scope]
    B --> C[Select Recon Profile]
    C --> D[Run Recon Pipeline]
    D --> E[Review Findings]
    E --> F[Generate Session Report]
    F --> G[Archive Session]
```

## 5) Session Comparison Model

For the same website, run:

- Session A: `core-passive`
- Session B: `advanced-*`

Then compute:

- `new_assets = assets(B) - assets(A)`
- `confidence_gain = avg_conf(B) - avg_conf(A)`
- `time_cost = runtime(B) - runtime(A)`

This gives a measurable quality-vs-time discussion for course defense.

## 6) Advanced Stage Controls

- Per-stage timeout budget
- Provider-specific rate limits
- Retry with bounded backoff
- Early-stop thresholds if quality gain is too low

## 7) Reporting Additions

Each session report should include:

1. Profile used and runtime summary
2. Top advanced-only findings
3. Evidence expansion metrics (records collected, source count)
4. Recommended next operational mode for the target

## 8) Recommended Default Policy

- Start every new website with `core-passive`.
- Escalate to advanced profile when:
  - baseline confidence is low,
  - target is high value,
  - or stakeholders require deeper evidence.

