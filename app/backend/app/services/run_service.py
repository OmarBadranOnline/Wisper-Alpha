import threading
import time
from datetime import datetime
from typing import List, Optional, Tuple

from sqlalchemy.orm import Session as DBSession

from app.models import ReconRun
from app.schemas import RunCreate

_STAGES = [
    "subdomain_discovery",
    "dns_enrichment",
    "certificate_scan",
    "historical_urls",
    "metadata_collection",
    "normalization",
]

_STAGE_MESSAGES = {
    "subdomain_discovery": [
        "Initializing passive subdomain enumeration...",
        "Running Subfinder against primary domain...",
        "Found 12 subdomains via Subfinder",
        "Running Amass in passive mode...",
        "Amass returned 8 additional subdomains",
        "Stage complete: 18 unique subdomains discovered",
    ],
    "dns_enrichment": [
        "Resolving DNS records for 18 subdomains...",
        "Querying A, MX, NS, TXT, CNAME records via dig...",
        "Running DNSRecon in passive profile...",
        "DNS enrichment complete: 54 records collected",
    ],
    "certificate_scan": [
        "Querying certificate transparency logs (crt.sh)...",
        "Found 7 certificates for in-scope domains",
        "Extracting SANs and alternate domain names...",
        "Certificate scan complete: 3 new subdomains from SANs",
    ],
    "historical_urls": [
        "Querying Wayback Machine archive...",
        "Retrieved 143 historical URLs",
        "Filtering for potentially active endpoints...",
        "Historical URL collection complete",
    ],
    "metadata_collection": [
        "Running theHarvester for email and metadata discovery...",
        "Running WhatWeb fingerprint scan on discovered hosts...",
        "Technology fingerprinting complete: 6 stacks identified",
        "Metadata collection complete",
    ],
    "normalization": [
        "Normalizing hostnames to canonical form...",
        "Deduplicating results across all sources...",
        "Merging cross-source findings...",
        "Applying confidence scoring model...",
        "Normalization and scoring complete",
    ],
}


def list_runs(
    db: DBSession, session_id: Optional[str] = None, skip: int = 0, limit: int = 50
) -> Tuple[List[ReconRun], int]:
    q = db.query(ReconRun)
    if session_id:
        q = q.filter(ReconRun.session_id == session_id)
    q = q.order_by(ReconRun.created_at.desc())
    total = q.count()
    items = q.offset(skip).limit(limit).all()
    return items, total


def get_run(db: DBSession, run_id: str) -> Optional[ReconRun]:
    return db.query(ReconRun).filter(ReconRun.id == run_id).first()


def create_run(db: DBSession, data: RunCreate) -> ReconRun:
    run = ReconRun(session_id=data.session_id, stage="queued", status="pending", logs=[])
    db.add(run)
    db.commit()
    db.refresh(run)
    run_id = run.id
    threading.Thread(target=_simulate_run, args=(run_id,), daemon=True).start()
    return run


def cancel_run(db: DBSession, run_id: str) -> Optional[ReconRun]:
    run = get_run(db, run_id)
    if not run:
        return None
    if run.status in ("completed", "failed", "cancelled"):
        return run
    run.status = "cancelled"
    run.completed_at = datetime.utcnow()
    run.updated_at = datetime.utcnow()
    _append_log(run, "warn", "system", "Run cancelled by user")
    db.commit()
    db.refresh(run)
    return run


def _append_log(run: ReconRun, level: str, stage: str, message: str) -> None:
    entry = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "level": level,
        "stage": stage,
        "message": message,
    }
    logs = list(run.logs or [])
    logs.append(entry)
    run.logs = logs


def _simulate_run(run_id: str) -> None:
    from app.database import SessionLocal

    db = SessionLocal()
    try:
        run = db.query(ReconRun).filter(ReconRun.id == run_id).first()
        if not run:
            return

        time.sleep(0.8)
        run.status = "running"
        run.started_at = datetime.utcnow()
        run.stage = "queued"
        run.updated_at = datetime.utcnow()
        _append_log(run, "info", "queued", "Recon run started — passive profile active")
        db.commit()

        for stage in _STAGES:
            run = db.query(ReconRun).filter(ReconRun.id == run_id).first()
            if not run or run.status == "cancelled":
                return

            run.stage = stage
            run.updated_at = datetime.utcnow()
            _append_log(run, "info", stage, f"=== Stage: {stage.replace('_', ' ').title()} ===")
            db.commit()

            for msg in _STAGE_MESSAGES.get(stage, [f"{stage} running..."]):
                time.sleep(1.5)
                run = db.query(ReconRun).filter(ReconRun.id == run_id).first()
                if not run or run.status == "cancelled":
                    return
                _append_log(run, "info", stage, msg)
                run.updated_at = datetime.utcnow()
                db.commit()

        run = db.query(ReconRun).filter(ReconRun.id == run_id).first()
        if run and run.status != "cancelled":
            run.stage = "completed"
            run.status = "completed"
            run.completed_at = datetime.utcnow()
            run.updated_at = datetime.utcnow()
            _append_log(run, "info", "completed", "All stages complete — run finished successfully")
            db.commit()

    except Exception as exc:
        try:
            run = db.query(ReconRun).filter(ReconRun.id == run_id).first()
            if run:
                run.status = "failed"
                run.error = str(exc)
                run.completed_at = datetime.utcnow()
                run.updated_at = datetime.utcnow()
                db.commit()
        except Exception:
            pass
    finally:
        db.close()
