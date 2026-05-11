from datetime import datetime
from typing import List, Optional, Tuple

from sqlalchemy.orm import Session as DBSession

from app.models import ReconSession
from app.schemas import SessionCreate, SessionUpdate


def list_sessions(
    db: DBSession,
    target_id: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
) -> Tuple[List[ReconSession], int]:
    q = db.query(ReconSession)
    if target_id:
        q = q.filter(ReconSession.target_id == target_id)
    total = q.count()
    items = q.offset(skip).limit(limit).all()
    return items, total


def get_session(db: DBSession, session_id: str) -> Optional[ReconSession]:
    return db.query(ReconSession).filter(ReconSession.id == session_id).first()


def create_session(db: DBSession, data: SessionCreate) -> ReconSession:
    session = ReconSession(**data.model_dump())
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


def update_session(
    db: DBSession, session_id: str, data: SessionUpdate
) -> Optional[ReconSession]:
    session = get_session(db, session_id)
    if not session:
        return None
    if session.scope_locked and data.scope_definition is not None:
        raise ValueError("Cannot modify scope_definition on a locked session")
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(session, field, value)
    session.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(session)
    return session


def lock_scope(db: DBSession, session_id: str) -> Optional[ReconSession]:
    session = get_session(db, session_id)
    if not session:
        return None
    session.scope_locked = True
    session.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(session)
    return session
