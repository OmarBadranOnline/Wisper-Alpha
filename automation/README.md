# Part 2 - Tools Usage, Reports, and Automation

This folder contains the planning baseline to execute **Part 2** of the project.

## Planning Files

1. `01-scope-and-deliverables.md` - scope boundaries, required outcomes, and acceptance.
2. `02-technical-structure.md` - adapter/orchestration/reporting architecture and data flow.
3. `03-execution-plan.md` - ordered tasks (P2-T01 to P2-T10), dependencies, and outputs.
4. `04-contract-plan.md` - adapter contracts, orchestration contracts, and report/export contracts.

## Part 2 Goal

Integrate reconnaissance tools into a controlled pipeline that:

- collects and normalizes source data,
- correlates and scores findings,
- generates report-ready outputs,
- supports scheduled automation with operational visibility.

## Runtime note

- `wisper.sh` supports dependency verification on Linux environments with `apt-get`.
- Linux package installation behavior depends on available package managers and privileges in the current distro.
