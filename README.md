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

![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20WSL-blue?style=flat-square&logo=linux)
![Shell](https://img.shields.io/badge/shell-bash-green?style=flat-square&logo=gnubash)
![Mode](https://img.shields.io/badge/mode-passive%20recon-orange?style=flat-square)
![AI](https://img.shields.io/badge/AI%20analysis-Gemini%20%7C%20OpenAI%20%7C%20Anthropic-purple?style=flat-square)
![License](https://img.shields.io/badge/license-Educational-red?style=flat-square)

**Automated passive reconnaissance orchestrator for web attack surface mapping.**  
Designed for penetration testers and security researchers.

</div>

---

## ⚡ Overview

**Wisper Alpha** is a fully terminal-driven passive recon framework that orchestrates multiple OSINT and DNS tools in a structured session flow — then compiles all findings into a detailed report, with optional AI-powered threat analysis.

> ⚠️ **For authorized use only.** Only run against targets you have explicit written permission to test.

---

## 🔁 Recon Flow

```
  Session  →  Scope  →  Profile  →  Run  →  Dashboard  →  Inspect  →  Evidence  →  Report
  ────────    ─────    ────────    ───    ─────────────    ───────    ────────      ──────
  STEP 1      STEP 2   STEP 3    STEP 4    STEP 5         STEP 6     STEP 7        STEP 8
```

Each run creates an isolated session folder:

```
sessions/
└── WA-20260513-C77B1A_target_com/
    ├── core/          ← passive tools output (subfinder, whois, dig, dnsrecon, waybackurls, whatweb)
    ├── advanced/      ← enrichment tools output (amass, theHarvester, crt.sh, shodan)
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
| `subfinder` | Passive subdomain enumeration | `01_subfinder.txt` |
| `whois` / RDAP | Domain registration lookup | `02_whois.txt` |
| `dig` | DNS A / MX / NS / TXT records | `03_dig_*.txt` |
| `nslookup` | DNS resolution fallback | `04_nslookup.txt` |
| `dnsrecon` | DNS enumeration (std scan) | `05_dnsrecon.txt` |
| `waybackurls` | Historical URL harvesting | `06_waybackurls.txt` |
| `whatweb` | HTTP technology fingerprinting | `07_whatweb.txt` |

### Profile 2 — `advanced-deep-passive`
> Full enrichment. ~10–20 min. High depth.

Runs all core tools **+**:

| Tool | Purpose | Output |
|---|---|---|
| `amass` | Deep passive asset discovery | `01_amass.txt` |
| `theHarvester` | Email / host OSINT harvesting | `02_theharvester.txt` |
| `crt.sh` | Certificate transparency search | `03_crtsh.txt` |
| `shodan` CLI | Host exposure data (if configured) | `04_shodan.txt` |
| Censys hint | Manual search URL | `05_censys_manual.txt` |
| SpiderFoot | OSINT aggregation (if installed) | noted |
| Recon-ng | Modular recon framework guide | noted |

---

## 📋 Report Sections

The static report (`WISPER_REPORT_*.txt`) is always generated — no API key needed.

| Section | Content |
|---|---|
| Discovery Summary | Count table: subdomains, URLs, certs, DNS lines |
| 1. Subdomains | Full Subfinder + Amass output |
| 2. DNS Records | A / MX / NS / TXT + DNSRecon full output |
| 3. WHOIS | Full domain registration data |
| 4. Tech Fingerprinting | WhatWeb stack identification |
| 5. Certificate Transparency | crt.sh subdomain exposure |
| 6. Email Harvesting | theHarvester collected addresses & hosts |
| 7. Historical URLs | Wayback Machine URLs — sensitive path highlights + full list |
| 8. File Index | All output files with line counts |

The AI analysis report (`WISPER_AI_ANALYSIS_*.md`) adds:

| Section | Content |
|---|---|
| Executive Summary | Overall risk level + top 3 concerns |
| Attack Surface Overview | Asset table with exposure levels |
| Findings Table | Severity / likelihood / impact per finding |
| Detailed Findings | Evidence-quoted analysis with confidence |
| Historical URL Analysis | URL categorisation by risk type |
| Infrastructure Profile | Hosting, ASN, DNS arch, TLS, CDN |
| Prioritised Remediation | Immediate / 30-day / long-term hardening |
| Confidence & Validation | What active testing would confirm |

---

## 🚀 Quick Start

```bash
# Make all scripts executable
chmod +x ./*.sh automation/wisper.sh

# Install all dependencies (first time)
./install-dependencies.sh

# Launch Wisper Alpha
./start.sh
```

---

## 🤖 AI Threat Analysis (Optional)

Wisper Alpha supports AI-powered threat analysis at the end of Step 8. Supported providers:

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

---

## 📁 Project Layout

```
wisper-alpha/
├── automation/
│   └── wisper.sh              ← Main recon orchestrator (1800+ lines)
├── sessions/                  ← Auto-created per-session output folders
├── start.sh                   ← Launcher (passes directly to wisper.sh)
├── install-dependencies.sh    ← Installs all required tools
├── run-unit-tests.sh          ← Syntax + integration checks
├── app_gui_draft.zip          ← Archived web GUI (draft)
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

## 🔧 WSL / Windows Troubleshooting

| Issue | Fix |
|---|---|
| `env: 'bash\r': No such file or directory` | CRLF in shell files — fixed via `.gitattributes`. Re-clone or run `git add --renormalize .` |
| `Input/output error` removing `.venv` | Windows file lock — remove `app/backend/.venv` from PowerShell first |
| DNS timeouts (`dig`, `nslookup`) | WSL2 DNS resolver issue — tools continue and log the error, recon doesn't stop |
| Script stops mid-run | All tool failures now use `|| true` — update to latest version |

**Best stability:** clone and run inside native Linux filesystem (`~/wisper-alpha/`) rather than `/mnt/d/...`.

---

## ⚙️ Dependencies

Install automatically with `./install-dependencies.sh`, or manually:

```bash
# Go tools
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/owasp-amass/amass/v4/...@master
go install github.com/tomnomnom/waybackurls@latest

# System tools
sudo apt install -y whois dnsutils dnsrecon whatweb

# Python tools
pip3 install theHarvester
```

---

## 📜 Disclaimer

> This tool is intended for **educational and authorized security testing purposes only**.  
> The authors are not responsible for any misuse or damage caused by this tool.  
> Always obtain **explicit written permission** before running reconnaissance against any target.

---

<div align="center">

**Wisper Alpha v1.0** · Built for security professionals · Educational use only

</div>
