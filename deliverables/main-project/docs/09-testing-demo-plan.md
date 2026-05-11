# 09. Testing, QA, and Demo Plan

## 1) Testing Strategy

## Unit Tests

- Parser correctness per adapter
- Canonicalization and dedupe rules
- Confidence scoring edge cases

## Integration Tests

- End-to-end run orchestration
- DB persistence and relationship integrity
- Report generation correctness
- Session isolation across different websites
- Core-vs-advanced profile pipeline branching

## UI Tests

- Target creation and run trigger flow
- Session creation and website switching flow
- Findings drill-down and evidence view
- Export behavior (JSON/CSV/PDF)

## 2) Test Data Approach

- Use safe public demo domains for reproducibility.
- Keep deterministic fixture inputs for parser tests.
- Version sample raw outputs from each tool.

## 3) Quality Gates

- No silent ingestion failures
- No unlinked finding without evidence source
- No report export with missing methodology section

## 4) Demo Scenario (Course)

1. Create target.
2. Create two sessions for different websites.
3. Launch core recon on one session and advanced recon on the other.
4. Show live run progress and runtime difference.
5. Explore findings, advanced deltas, and evidence chain.
6. Export final report and explain recommendations.

## 5) Demo Backup Plan

- Pre-seeded dataset to avoid live API failure risk.
- Cached output snapshots for each pipeline stage.
- Screenshot sequence in case of environment issues.

