import uuid
from datetime import datetime
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, JSON, String
from sqlalchemy.orm import relationship
from app.database import Base


def _uuid() -> str:
    return str(uuid.uuid4())


class Target(Base):
    __tablename__ = "targets"

    id = Column(String, primary_key=True, default=_uuid)
    name = Column(String(255), nullable=False)
    primary_domain = Column(String(255), nullable=False)
    tags = Column(JSON, default=list)
    owner = Column(String(255), nullable=True)
    status = Column(String(50), default="active")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow)

    sessions = relationship(
        "ReconSession", back_populates="target", cascade="all, delete-orphan"
    )


class ReconSession(Base):
    __tablename__ = "recon_sessions"

    id = Column(String, primary_key=True, default=_uuid)
    target_id = Column(String, ForeignKey("targets.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(255), nullable=True)
    profile = Column(String(50), default="core")
    scope_definition = Column(JSON, default=dict)
    scope_locked = Column(Boolean, default=False)
    status = Column(String(50), default="active")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow)

    target = relationship("Target", back_populates="sessions")
    runs = relationship(
        "ReconRun", back_populates="session", cascade="all, delete-orphan"
    )


class ReconRun(Base):
    __tablename__ = "recon_runs"

    id = Column(String, primary_key=True, default=_uuid)
    session_id = Column(
        String, ForeignKey("recon_sessions.id", ondelete="CASCADE"), nullable=False
    )
    stage = Column(String(100), default="queued")
    status = Column(String(50), default="pending")
    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    error = Column(String, nullable=True)
    logs = Column(JSON, default=list)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow)

    session = relationship("ReconSession", back_populates="runs")
