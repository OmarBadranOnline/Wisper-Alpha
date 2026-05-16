"""
app/web/app.py — Wisper Alpha Web GUI (V1 — bash script edition)

Drives automation/wisper.sh directly.
Reads output from sessions/<session_id>_<safe_domain>/ directories.
No dependency on wisper-v2 whatsoever.

Start:  python app/web/app.py
        — or —  bash start.sh  (option 1)
Open:   http://localhost:5000
"""

import json
import os
import re
import sqlite3
import subprocess
import sys
import threading
import uuid
from datetime import datetime
from pathlib import Path

# ── Paths ──────────────────────────────────────────────────────────────────────
THIS_DIR    = Path(__file__).parent.resolve()
PROJECT_ROOT = THIS_DIR.parent.parent.resolve()   # …/Project
SESSIONS_DIR = PROJECT_ROOT / "sessions"
RECON_SCRIPT = PROJECT_ROOT / "automation" / "wisper.sh"
DB_PATH      = THIS_DIR / "wisper_gui.db"

from flask import Flask, jsonify, redirect, render_template, request, url_for, send_file

app = Flask(__name__, template_folder="templates")
app.secret_key = os.urandom(24)

# ── In-memory live log store  ──────────────────────────────────────────────────
# { session_id -> {"status": "running"|"done"|"error", "log": [...]} }
_live: dict = {}


# ── Database ───────────────────────────────────────────────────────────────────
def db_connect():
    con = sqlite3.connect(str(DB_PATH))
    con.row_factory = sqlite3.Row
    return con


def db_init():
    con = db_connect()
    con.execute("""
        CREATE TABLE IF NOT EXISTS sessions (
            id            TEXT PRIMARY KEY,
            folder_name   TEXT,
            target_domain TEXT,
            profile       TEXT,
            status        TEXT DEFAULT 'running',
            started_at    TEXT,
            completed_at  TEXT
        )
    """)
    con.commit()
    con.close()


# ── Session folder helpers ─────────────────────────────────────────────────────
def _safe_name(domain: str) -> str:
    return re.sub(r"[^a-z0-9]", "_", domain.lower())


def _find_session_folder(session_id: str) -> Path | None:
    """Locate a session directory by its WA-… ID prefix."""
    for d in SESSIONS_DIR.iterdir():
        if d.is_dir() and d.name.startswith(session_id):
            return d
    return None


def _read_txt(path: Path, skip_header: bool = True) -> list[str]:
    """Read meaningful lines from a tool output .txt file."""
    if not path.exists():
        return []
    lines = []
    header_pattern = re.compile(
        r"^(={40,}|\s*$| TOOL\s*:| COMMAND\s*:| STARTED\s*:|\[ FINISHED|\[ TIMED OUT)"
    )
    for line in path.read_text(errors="ignore").splitlines():
        if skip_header and header_pattern.match(line):
            continue
        stripped = line.strip()
        if stripped:
            lines.append(stripped)
    return lines


def _parse_session_txt(folder: Path) -> dict:
    """Parse the session.txt manifest into a dict."""
    meta = {}
    txt = folder / "session.txt"
    if not txt.exists():
        return meta
    for line in txt.read_text(errors="ignore").splitlines():
        if ":" in line:
            k, _, v = line.partition(":")
            meta[k.strip().lstrip(" ")] = v.strip()
    return meta


def _count_lines(path: Path) -> int:
    return len(_read_txt(path))


def _get_findings(folder: Path) -> dict:
    """
    Return a dict of finding category → list of items, read from
    the bash script's output files in sessions/<folder>/core/ and /advanced/.
    """
    core = folder / "core"
    adv  = folder / "advanced"
    findings = {}

    # Subdomains
    subs = set()
    for f in [core / "01_subfinder.txt", adv / "01_amass.txt"]:
        for line in _read_txt(f):
            if re.match(r"^[\w\-]+\.[\w\.\-]+$", line):
                subs.add(line)
    if subs:
        findings["Subdomains"] = sorted(subs)

    # DNS Records
    dns_lines = []
    for rec in ["A", "MX", "NS", "TXT"]:
        for line in _read_txt(core / f"03_dig_{rec}.txt"):
            dns_lines.append(f"[{rec}] {line}")
    if dns_lines:
        findings["DNS Records"] = dns_lines

    # Historical URLs
    urls = _read_txt(core / "06_waybackurls.txt")
    if not urls:
        urls = _read_txt(core / "06b_gau.txt")
    if urls:
        findings["Historical URLs"] = urls

    # Tech Fingerprint
    tech = _read_txt(core / "07_whatweb.txt")
    if tech:
        findings["Technology"] = tech

    # Certificate Transparency
    certs = _read_txt(adv / "03_crtsh.txt")
    if certs:
        findings["Certificates"] = certs

    # Email Harvesting
    emails = _read_txt(adv / "02_theharvester.txt")
    if emails:
        findings["Email Harvest"] = emails

    # WHOIS
    whois = _read_txt(core / "02_whois.txt")
    if whois:
        findings["WHOIS"] = whois

    return findings


def _count_findings(folder: Path) -> dict:
    f = _get_findings(folder)
    return {k: len(v) for k, v in f.items()}


def _list_reports(folder: Path) -> list[Path]:
    rep = folder / "reports"
    if not rep.exists():
        return []
    return sorted(rep.glob("*.txt"), reverse=True) + sorted(rep.glob("*.md"), reverse=True)


# ── Background scan runner ─────────────────────────────────────────────────────
def _run_scan_bg(session_id: str, target: str, profile: str, ai_ans: str = "N"):
    """
    Launch automation/wisper.sh in a subprocess with piped stdin.

    wisper.sh interactive prompts answered in order:
      1. All deps present — continue? → Y
      2. Target domain  → <target>
      3. Validation warning (if any) → y  (accept anyway)
      4. Profile choice → 1 (core) | 2 (advanced)
      5. AI analysis?   → y/N
    """
    _live[session_id] = {"status": "running", "log": []}

    def log(msg: str):
        _live[session_id]["log"].append(msg)

    profile_num = "1" if profile == "core-passive" else "2"

    # Validation in python matching the bash script
    is_valid = bool(re.match(r"^[a-zA-Z0-9][a-zA-Z0-9\.\-]+\.[a-zA-Z]{2,}$", target))

    answers = [
        "Y",           # 1. Dependency check OR continue prompt
        target,        # 2. Target domain
    ]
    if not is_valid:
        answers.append("y")  # 3. Accept anyway (conditional)

    answers.extend([
        profile_num,   # 4. Profile choice [1/2]
        "s",           # 5. Inspect findings [s]kip
        ai_ans,        # 6. AI Report [y/N]
    ])

    stdin_answers = "\n".join(answers) + "\n"

    import tempfile
    
    # Write answers to a temp file to avoid WSL pipe closure crash.
    # CRITICAL: We must force unix newlines so Bash read -r doesn't capture \r and fail validation
    fd, tmp_path = tempfile.mkstemp(text=True)
    with open(tmp_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(stdin_answers)

    try:
        env = os.environ.copy()
        env["TERM"] = "dumb"  # suppress colour codes

        log_file = PROJECT_ROOT / f"debug_scan_output_{session_id}.txt"
        
        with open(tmp_path, "r", encoding="utf-8") as f_in:
            proc = subprocess.Popen(
                ["bash", "-c", f"automation/wisper.sh > {log_file.name} 2>&1"],
                cwd=str(PROJECT_ROOT),
                stdin=f_in,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.STDOUT,
                env=env,
            )
            _live[session_id]["process"] = proc

            import time
            f_tail = None
            
            with open(PROJECT_ROOT / f"internal_tail_debug_{session_id}.txt", "w", encoding="utf-8") as _debug:
                _debug.write(f"Starting tail loop for {log_file.name}\n")
                _debug.flush()
                
                while proc.poll() is None:
                    if not log_file.exists():
                        _debug.write("Log file does not exist yet...\n")
                        _debug.flush()
                        time.sleep(0.2)
                        continue
                    
                    if f_tail is None:
                        _debug.write("Opening log file for tailing...\n")
                        _debug.flush()
                        f_tail = open(log_file, "r", encoding="utf-8", errors="replace")
                    
                    line = f_tail.readline()
                    if line:
                        _debug.write(f"Read line: {line.strip()}\n")
                        _debug.flush()
                        clean = re.sub(r"\x1b\[[0-9;]*m", "", line).rstrip()
                        if clean and not clean.startswith("<3>WSL"):
                            log(clean)
                    else:
                        time.sleep(0.2)
                
                _debug.write(f"Process exited with {proc.returncode}. Draining remaining...\n")
                _debug.flush()
                
                # Drain remaining after proc exits
                if f_tail is None and log_file.exists():
                    f_tail = open(log_file, "r", encoding="utf-8", errors="replace")
                    
                if f_tail is not None:
                    for line in f_tail:
                        clean = re.sub(r"\x1b\[[0-9;]*m", "", line).rstrip()
                        if clean and not clean.startswith("<3>WSL"):
                            log(clean)
                    f_tail.close()

            proc.wait()

        # Update DB on completion
        con = db_connect()
        status = "done" if proc.returncode == 0 else "error"
        con.execute(
            "UPDATE sessions SET status=?, completed_at=? WHERE id=?",
            (status, datetime.utcnow().isoformat(), session_id),
        )
        # Try to fill in the folder_name from actual folder created
        for d in SESSIONS_DIR.iterdir():
            if d.is_dir() and d.name.startswith(session_id.replace("WA-", "WA-")):
                con.execute("UPDATE sessions SET folder_name=? WHERE id=?",
                            (d.name, session_id))
                break
        con.commit()
        con.close()

        _live[session_id]["status"] = status
        log(f"[+] Scan {status}.")

    except Exception as exc:
        with open("debug_scan_error.txt", "w") as f_err:
            f_err.write(str(exc))
        log(f"[!] Error: {exc}")
        if _live[session_id].get("status") != "killed":
            _live[session_id]["status"] = "error"
        try:
            con = db_connect()
            con.execute("UPDATE sessions SET status='error', completed_at=? WHERE id=?",
                        (datetime.utcnow().isoformat(), session_id))
            con.commit()
            con.close()
        except:
            pass
    finally:
        try:
            os.remove(tmp_path)
        except:
            pass
        try:
            if 'log_file' in locals() and log_file.exists():
                os.remove(log_file)
        except:
            pass


@app.route("/api/scan/<session_id>/kill", methods=["POST"])
def kill_scan(session_id):
    if session_id in _live:
        proc = _live[session_id].get("process")
        if proc:
            try:
                proc.kill()
            except:
                pass
        _live[session_id]["status"] = "killed"
        _live[session_id]["log"].append("[!] Scan Force Stopped.")
        try:
            con = db_connect()
            con.execute("UPDATE sessions SET status='killed', completed_at=? WHERE id=?",
                        (datetime.utcnow().isoformat(), session_id))
            con.commit()
            con.close()
        except:
            pass
        return jsonify({"status": "killed"})
    return jsonify({"error": "not found"}), 404


# ── Routes ─────────────────────────────────────────────────────────────────────

@app.route("/")
def index():
    con = db_connect()
    db_rows = con.execute(
        "SELECT * FROM sessions ORDER BY started_at DESC LIMIT 100"
    ).fetchall()
    con.close()

    # Also discover sessions not yet in DB (e.g. from CLI runs)
    known_ids = {r["id"] for r in db_rows}
    extra_sessions = []

    if SESSIONS_DIR.exists():
        for d in sorted(SESSIONS_DIR.iterdir(), reverse=True):
            if not d.is_dir():
                continue
            meta = _parse_session_txt(d)
            sid = meta.get("Session ID", "")
            if sid and sid not in known_ids:
                known_ids.add(sid)
                extra_sessions.append({
                    "id": sid,
                    "folder_name": d.name,
                    "target_domain": meta.get("Target", d.name),
                    "profile": "core-passive",
                    "status": "completed",
                    "started_at": meta.get("Started", ""),
                    "completed_at": "",
                })

    sessions = [dict(r) for r in db_rows] + extra_sessions

    # Attach finding counts
    counts = {}
    for s in sessions:
        folder = _find_session_folder(s["id"]) if not s.get("folder_name") else SESSIONS_DIR / s["folder_name"]
        if folder and folder.exists():
            counts[s["id"]] = _count_findings(folder)
        else:
            counts[s["id"]] = {}

    return render_template("index.html", sessions=sessions, counts=counts)


@app.route("/scan", methods=["GET", "POST"])
def new_scan():
    if request.method == "POST":
        raw     = request.form.get("target", "").strip()
        profile = request.form.get("profile", "core-passive")
        ai_req  = request.form.get("ai_report") == "on"

        # Check if .env has GEMINI_API_KEY
        ai_ans = "N"
        if ai_req:
            env_file = PROJECT_ROOT / ".env"
            if env_file.exists():
                content = env_file.read_text(errors="ignore")
                if "GEMINI_API_KEY" in content:
                    ai_ans = "y"

        # Normalise domain
        target = re.sub(r"https?://", "", raw).split("/")[0].split(":")[0].lower().strip()
        if not target:
            return render_template("scan.html", error="Target domain is required.")

        # Generate a session ID matching wisper.sh format
        rand = uuid.uuid4().hex[:6].upper()
        session_id = f"WA-{datetime.utcnow().strftime('%Y%m%d')}-{rand}"

        # Persist immediately
        con = db_connect()
        con.execute(
            "INSERT OR IGNORE INTO sessions (id, target_domain, profile, status, started_at) VALUES (?,?,?,?,?)",
            (session_id, target, profile, "running", datetime.utcnow().isoformat()),
        )
        con.commit()
        con.close()

        threading.Thread(
            target=_run_scan_bg, args=(session_id, target, profile, ai_ans), daemon=True
        ).start()

        return redirect(url_for("scan_live", session_id=session_id))

    return render_template("scan.html")


@app.route("/scan/<session_id>/live")
def scan_live(session_id):
    return render_template("live.html", session_id=session_id)


@app.route("/api/scan/<session_id>/status")
def api_status(session_id):
    data = _live.get(session_id, {"status": "unknown", "log": []})
    return jsonify(data)


@app.route("/api/scan/<session_id>", methods=["DELETE"])
def delete_session(session_id):
    con = None
    try:
        con = db_connect()
        con.execute("DELETE FROM sessions WHERE id=?", (session_id,))
        con.commit()
        
        import shutil
        for d in SESSIONS_DIR.iterdir():
            if d.is_dir() and (session_id in d.name):
                try:
                    shutil.rmtree(d)
                except:
                    pass

        return jsonify({"status": "success"})
    except Exception as e:
        if con:
            con.rollback()
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        if con:
            con.close()


@app.route("/session/<session_id>")
def session_detail(session_id):
    # Look up in DB first, then fall back to scanning folders
    con = db_connect()
    row = con.execute("SELECT * FROM sessions WHERE id=?", (session_id,)).fetchone()
    con.close()

    folder = None
    if row and row["folder_name"]:
        folder = SESSIONS_DIR / row["folder_name"]
    if not folder or not folder.exists():
        folder = _find_session_folder(session_id)

    if not folder:
        return "Session not found", 404

    meta = _parse_session_txt(folder)
    session = {
        "id":            session_id,
        "target_domain": meta.get("Target", session_id),
        "profile":       row["profile"] if row else "core-passive",
        "status":        row["status"]  if row else "completed",
        "started_at":    meta.get("Started", ""),
        "completed_at":  row["completed_at"] if row else "",
        "folder":        str(folder),
    }
    findings = _get_findings(folder)
    reports  = _list_reports(folder)
    return render_template("session.html", session=session,
                           findings=findings, reports=reports)


@app.route("/session/<session_id>/reports/<filename>")
def serve_report(session_id, filename):
    folder = _find_session_folder(session_id)
    if not folder:
        return "Not found", 404
    path = folder / "reports" / filename
    if not path.exists():
        return "File not found", 404
    return send_file(str(path), as_attachment=False, mimetype="text/plain")


# ── Port helper ────────────────────────────────────────────────────────────────
def find_free_port(start: int = 5000) -> int:
    import socket
    for port in range(start, start + 20):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(("127.0.0.1", port)) != 0:
                return port
    return start


if __name__ == "__main__":
    SESSIONS_DIR.mkdir(exist_ok=True)
    db_init()
    port = find_free_port(5000)
    print(f"\n  Wisper Alpha Web GUI → http://localhost:{port}\n")
    app.run(host="0.0.0.0", port=port, debug=False)
