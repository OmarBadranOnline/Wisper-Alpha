# 04. Tool Stack and Integration Plan (Approved Tools Only)

## 1) Selection Principles

- Passive-first and low-risk data collection
- Broad source diversity for better coverage
- Scriptability and machine-readable output
- Stable licensing and active maintenance
- Profile-based runtime control (fast baseline vs deep advanced)
- Tooling restricted to the approved project list only

## 2) Approved Tool Matrix

| Layer | Tool/Source | Purpose | Passive Status | Notes |
|---|---|---|---|---|
| Subdomain discovery | `Subfinder` | Passive subdomain enumeration | Passive | Baseline discovery source |
| Subdomain discovery | `Amass` | Passive asset discovery and mapping | Passive mode | Strong enrichment potential |
| Subdomain discovery / metadata | `theHarvester` | Subdomains, emails, and related intelligence | Passive | Also used for email discovery |
| WHOIS & domain intelligence | `whois` | Registration and domain ownership context | Passive | Linux built-in utility |
| WHOIS & domain intelligence | `Recon-ng` | Domain intelligence and correlated recon modules | Passive-focused | Module-driven enrichment |
| DNS enumeration | `dig`, `nslookup` | DNS record intelligence (A, MX, NS, TXT, etc.) | Passive/low-noise | Controlled query behavior |
| DNS enumeration | `DNSRecon` | Structured DNS enumeration in passive mode | Passive mode | Use passive profile only |
| Public exposure search | `Shodan` | Internet-exposed service intelligence | Passive API/search | High-value external exposure data |
| Public exposure search | `Censys` | Internet exposure and certificate intelligence | Passive API/search | Complements Shodan coverage |
| Historical URLs | `waybackurls` | Historical endpoint discovery | Passive | Archive-driven source |
| Metadata & email discovery | `SpiderFoot` | OSINT aggregation for emails/metadata | Passive-focused | Multi-source enrichment |
| Technology fingerprinting | `Wappalyzer` | Web technology identification | Passive/low-noise | App stack visibility |
| Technology fingerprinting | `WhatWeb` | Web fingerprinting and stack indicators | Passive/low-noise | Adds fingerprint confidence |

## 4) Recon Profiles

| Profile | Goal | Typical Runtime | Data Depth |
|---|---|---|---|
| `core-passive` | Fast baseline mapping with passive-first tools | Low | Good |
| `advanced-deep-passive` | Deeper intelligence using approved enrichment/search tools | Medium | High |
| `advanced-correlated-osint` | Maximum correlation depth with approved toolset only | High | Very High |

## 5) Recommended Provider Categories

1. WHOIS and registration intelligence
2. Passive DNS and domain record intelligence
3. Public exposure search datasets
4. Historical archive datasets
5. Metadata and technology fingerprinting datasets

## 6) Integration Pattern

Each tool is wrapped by an adapter with a standard contract:

```text
run(target, config) -> raw_output
parse(raw_output) -> normalized_records[]
attach_metadata(records, source, timestamp, confidence)
persist(records)
```

Each adapter also writes:

- `session_id`
- `target_id`
- `profile_id`
- `stage_id`
- `tool_runtime_ms`
- `quality_gain_score`

## 7) Command Profiles (Examples)

```bash
subfinder -d example.com -silent -o subfinder.txt
amass enum -passive -d example.com -o amass.txt
cat domains.txt | waybackurls > wayback_urls.txt
```

Advanced examples:

```bash
theHarvester -d example.com -b all
whois example.com
dig example.com ANY
dnsrecon -d example.com -t std
recon-ng
whatweb https://example.com
```

## 8) Quality and Deduping Rules

- Normalize hostnames to lowercase + punycode rules.
- Trim URL fragments and canonicalize query-key ordering.
- Merge identical entities from multiple sources.
- Raise confidence when a finding appears in multiple independent sources.
- Store per-stage runtime and highlight quality-vs-time tradeoff in reports.

## 9) Session-Mode Integration

- Each website session has independent profile settings.
- API key consumption and rate-limit counters tracked per session.
- Results are queryable by `(session_id, target_id)` to prevent data mixing.
- Session comparison view highlights what advanced mode added vs core mode.

## 10) Improvement Opportunities

- Add source trust weighting per approved provider.
- Add adaptive profile logic (when to escalate to advanced mode).
- Add stronger cross-tool confidence fusion between Shodan/Censys/WHOIS/DNS layers.

