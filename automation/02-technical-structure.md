# 02. Technical Structure (Part 2)

## Proposed Folder Structure

```text
part-2-tools-reports-automation/
  adapters/
    core/
    advanced/
    contracts/
  orchestrator/
    stages/
    scheduler/
    retry-policy/
    state-machine/
  correlation/
    normalization/
    merge/
    scoring/
  findings/
    rules/
    generator/
  reporting/
    templates/
    renderers/
    exporters/
  observability/
    metrics/
    audit/
    diagnostics/
  docs/
    adapter-spec/
    report-spec/
```

## Processing Flow

1. Orchestrator selects profile and stage sequence.
2. Adapters collect raw source outputs.
3. Normalization + merge produce unified entities.
4. Scoring computes confidence/relevance.
5. Findings generator builds report-ready objects.
6. Reporting module renders templates and export files.
7. Observability module records stage metrics and diagnostics.

## Core Contracts

1. Adapter input/output contract.
2. Stage lifecycle contract (`pending`, `running`, `completed`, `failed`, `partial`).
3. Findings schema contract with evidence links.
4. Report/export metadata contract.

## Non-Functional Baseline

1. Deterministic retries and timeout handling.
2. Provider/rate-limit aware execution controls.
3. No untracked adapter failures.
4. Reproducible report rendering for the same run snapshot.
