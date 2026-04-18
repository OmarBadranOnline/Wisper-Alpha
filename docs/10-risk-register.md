# 10. Risk Register

| ID | Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|---|
| R-01 | API rate limits block data collection | High | Medium | Add provider-level throttling, retries, and fallbacks |
| R-02 | Over-reliance on one source creates blind spots | High | Medium | Use multi-source collection and confidence weighting |
| R-03 | False positives from noisy datasets | Medium | Medium | Cross-source verification and confidence scoring |
| R-04 | Scope misunderstanding causes legal exposure | High | Low | Enforce explicit scope approval workflow |
| R-05 | Tool output format changes break parsers | Medium | Medium | Adapter tests with versioned fixtures |
| R-06 | Demo instability during presentation | Medium | Medium | Pre-seeded datasets and offline replay mode |
| R-07 | Data leakage from stored evidence | High | Low | Encryption, RBAC, and retention controls |
| R-08 | Passive-only policy drift over time | Medium | Medium | Enforce allowlisted command profiles |
| R-09 | Advanced profile runtime is too long for operations/demo | Medium | Medium | Profile presets, stage timeout budgets, checkpointed runs |
| R-10 | Session data from one website appears in another website view | High | Low | Mandatory session_id filters and scope-lock validation |
| R-11 | API key exhaustion in concurrent advanced sessions | Medium | Medium | Per-session quotas, key pools, and adaptive throttling |

## Improvement Focus

Prioritize R-01, R-02, R-04, and R-10 first because they directly affect reliability, legal safety, and data isolation integrity.

