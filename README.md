```
  ╔══════════════════════════════════════════════════════════════╗
  ║       ██╗    ██╗██╗███████╗██████╗ ███████╗██████╗          ║
  ║       ██║    ██║██║██╔════╝██╔══██╗██╔════╝██╔══██╗         ║
  ║       ██║ █╗ ██║██║███████╗██████╔╝█████╗  ██████╔╝         ║
  ║       ██║███╗██║██║╚════██║██╔═══╝ ██╔══╝  ██╔══██╗         ║
  ║       ╚███╔███╔╝██║███████║██║     ███████╗██║  ██║         ║
  ║        ╚══╝╚══╝ ╚═╝╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝         ║
  ║                   A L P H A  v1.0                            ║
  ║           Automated Web Attack Surface Mapper                ║
  ╚══════════════════════════════════════════════════════════════╝
```

<div align="center">

![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20WSL%20%7C%20Kali-blue?style=flat-square&logo=linux)
![Shell](https://img.shields.io/badge/shell-bash-green?style=flat-square&logo=gnubash)
![Mode](https://img.shields.io/badge/mode-passive%20recon-orange?style=flat-square)
![Tools](https://img.shields.io/badge/tools-14%20integrated-informational?style=flat-square)
![AI](https://img.shields.io/badge/AI%20analysis-Gemini%20%7C%20OpenAI%20%7C%20Anthropic-purple?style=flat-square)
![License](https://img.shields.io/badge/license-Educational-red?style=flat-square)

**Automated passive reconnaissance orchestrator for web attack surface mapping.**  
Designed for penetration testers and security researchers.

</div>

---

## ⚡ Overview

**Wisper Alpha** is a fully terminal-driven passive recon framework that orchestrates multiple OSINT and DNS tools in a structured 8-step session flow — then compiles all findings into a detailed static report, with optional AI-powered threat analysis using any major LLM provider.

> ⚠️ **For authorized use only.** Only run against targets you have explicit written permission to test.

---

## 🔁 Recon Flow

```
  Session  →  Scope  →  Profile  →  Run  →  Dashboard  →  Inspect  →  Evidence  →  Report
  ────────    ─────    ────────    ───    ─────────────    ───────    ────────      ──────
  STEP 1      STEP 2   STEP 3    STEP 4    STEP 5         STEP 6     STEP 7        STEP 8
```

Each run creates an isolated session folder with all tool outputs and a structured report:

```
sessions/
└── WA-20260513-C77B1A_target_com/
    ├── core/          ← Phase A: subfinder, whois, dig, dnsrecon, waybackurls, gau, whatweb
    ├── advanced/      ← Phase B: amass, theHarvester, crt.sh, shodan
    │                  ← Phase C: dnsx (resolve), httpx (probe), nuclei (scan)
    ├── evidence/      ← archived copy of all findings
    └── reports/
        ├── WISPER_REPORT_<session>.txt       ← full structured static report
        └── WISPER_AI_ANALYSIS_<session>.md   ← AI threat analysis (optional)
```

---

## 🛠️ Tool Matrix

### Profile 1 — `core-passive`
> Fast baseline. ~2–5 min. Low noise.

| Tool | Purpose | Output |
|---|---|---|
| `subfinder` | Passive subdomain enumeration via cert/DNS sources | `01_subfinder.txt` |
| `whois` / RDAP | Domain registration lookup | `02_whois.txt` |
| `dig` | DNS A / MX / NS / TXT records | `03_dig_*.txt` |
| `nslookup` | DNS resolution fallback | `04_nslookup.txt` |
| `dnsrecon` | DNS enumeration (std scan) | `05_dnsrecon.txt` |
| `waybackurls` | Historical URL harvesting (Wayback Machine) | `06_waybackurls.txt` |
| `gau` | Multi-source URL aggregation (Wayback + OTX + CommonCrawl + URLScan) | `06b_gau.txt` |
| `whatweb` | HTTP technology fingerprinting | `07_whatweb.txt` |

### Profile 2 — `advanced-deep-passive`
> Full enrichment pipeline. ~15–30 min. High depth.

Runs all core tools **+** three additional phases:

**Phase B — Deep OSINT**

| Tool | Purpose | Output |
|---|---|---|
| `amass` | Deep passive asset discovery & graph mapping | `01_amass.txt` |
| `theHarvester` | Email / hostname OSINT harvesting | `02_theharvester.txt` |
| `crt.sh` | Certificate transparency subdomain search | `03_crtsh.txt` |
| `shodan` CLI | Host exposure data (if API key configured) | `04_shodan.txt` |
| Censys hint | Manual search URL + CLI setup instructions | `05_censys_manual.txt` |

**Phase C — Enrichment & Validation** *(new)*

| Tool | Purpose | Output |
|---|---|---|
| `dnsx` | DNS-validates combined subfinder+amass subdomain list — returns only live, resolving hosts | `06_dnsx.txt` |
| `httpx` | HTTP-probes live hosts — status codes, page titles, tech stack, redirect chains | `07_httpx.txt` |
| `nuclei` | Passive template scan — exposed panels, TLS issues, header misconfigs, subdomain takeover | `08_nuclei.txt` |

---

## 📋 Report Sections

The static report (`WISPER_REPORT_*.txt`) is always generated — no API key required.

| Section | Content |
|---|---|
| Discovery Summary | Count table: subdomains, URLs, gau URLs, certs, DNS lines |
| 1. Subdomains | Full Subfinder + Amass output |
| 2. DNS Records | A / MX / NS / TXT + DNSRecon full output |
| 3. WHOIS | Full domain registration data |
| 4. Tech Fingerprinting | WhatWeb + httpx stack identification |
| 5. Certificate Transparency | crt.sh subdomain exposure |
| 6. Email Harvesting | theHarvester collected addresses & hosts |
| 7. Historical URLs | Wayback + gau URLs — sensitive path highlights + full list |
| 8. File Index | All output files with line counts |

The AI analysis report (`WISPER_AI_ANALYSIS_*.md`) adds:

| Section | Content |
|---|---|
| Executive Summary | Overall risk level + top 3 concerns |
| Attack Surface Overview | Asset table with exposure levels |
| Findings Table | Severity / likelihood / impact per finding |
| Detailed Findings | Evidence-quoted analysis with confidence ratings |
| Historical URL Analysis | URL categorisation by risk type (admin, API, backup, debug) |
| Infrastructure Profile | Hosting, ASN, DNS architecture, TLS, CDN |
| Prioritised Remediation | Immediate / 30-day / long-term hardening steps |
| Confidence & Validation | What active testing would confirm |

---

## 🚀 Quick Start

```bash
# Clone the repo
git clone https://github.com/OmarBadranOnline/Wisper-Alpha.git
cd Wisper-Alpha

# Make scripts executable
chmod +x ./*.sh automation/wisper.sh

# Install all dependencies (first time only)
./install-dependencies.sh

# Launch Wisper Alpha
./start.sh
```

---

## 🤖 AI Threat Analysis (Optional)

Wisper Alpha supports AI-powered threat analysis at Step 8. Supported providers:

| Provider | Env Variable | Free Tier | Default Model |
|---|---|---|---|
| **Gemini** | `GEMINI_API_KEY` | ✅ Yes | `gemini-1.5-flash` |
| **OpenAI** | `OPENAI_API_KEY` | ❌ No | `gpt-4o-mini` |
| **Anthropic** | `ANTHROPIC_API_KEY` | ❌ No | `claude-3-5-haiku-latest` |
| **OpenRouter** | `OPENROUTER_API_KEY` | 🔸 Credits | `openai/gpt-4o-mini` |

Create a `.env` file in the project root (or configure interactively during the run):

```env
LLM_PROVIDER=gemini
LLM_MODEL=gemini-1.5-flash
GEMINI_API_KEY=your_key_here
```

Get a free Gemini key → [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)

> The AI report is generated from a curated subset of tool outputs — gau, dnsx, httpx, and nuclei findings are all included in the prompt context for deeper analysis.

---

## 📁 Project Layout

```
wisper-alpha/
├── automation/
│   └── wisper.sh              ← Main recon orchestrator (~1950+ lines)
├── sessions/                  ← Auto-created per-session output folders
├── start.sh                   ← Launcher (entry point)
├── install-dependencies.sh    ← Installs all required tools via Go + apt + pip
├── run-unit-tests.sh          ← Syntax + integration checks
└── .env                       ← API keys (create manually, gitignored)
```

---

## 🧪 Tested Against

| Target | Type |
|---|---|
| `testphp.vulnweb.com` | Intentionally vulnerable PHP app |
| `testhtml5.vulnweb.com` | Intentionally vulnerable HTML5 app |
| `testaspnet.vulnweb.com` | Intentionally vulnerable ASP.NET app |

> All Acunetix demo targets — publicly available for security testing practice.

---

## 🔧 Troubleshooting

| Issue | Fix |
|---|---|
| `env: 'bash\r': No such file or directory` | CRLF in shell files — run `git add --renormalize .` or re-clone |
| `Input/output error` removing `.venv` | Windows file lock — remove `app/backend/.venv` from PowerShell first |
| DNS timeouts (`dig`, `nslookup`) | WSL2 DNS resolver issue — tools log the error and continue; recon doesn't stop |
| Script stops mid-run | All tool failures use `\|\| true` guards — update to latest version |
| `httpx -version` fails on Kali | Kali ships `python3-httpx` at `/usr/bin/httpx` which shadows the Go scanner. Wisper prepends `~/go/bin` to PATH automatically. Verify with `~/go/bin/httpx -version` |
| `gau`/`dnsx`/`nuclei` not found after install | Run `export PATH=$PATH:$(go env GOPATH)/bin` or add it to `~/.bashrc` |

**Best stability:** clone and run inside the native Linux filesystem (`~/wisper-alpha/`) rather than `/mnt/d/...`.

---

## ⚙️ Full Dependency List

Install automatically with `./install-dependencies.sh`, or manually:

```bash
# Go tools (all 7 — requires Go 1.21+)
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/owasp-amass/amass/v4/...@master
go install github.com/tomnomnom/waybackurls@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest

# Ensure Go bin is in PATH
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc && source ~/.bashrc

# System tools
sudo apt install -y whois dnsutils dnsrecon whatweb curl

# Python tools
pip3 install theHarvester dnsrecon
```

---

## 📜 Disclaimer

> This tool is intended for **educational and authorized security testing purposes only.**  
> The authors are not responsible for any misuse or damage caused by this tool.  
> Always obtain **explicit written permission** before running reconnaissance against any target.

---

<div align="center">

**Wisper Alpha v1.0** · Built for security professionals · Educational use only

</div>
