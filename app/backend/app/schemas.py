import re
from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, field_validator


# ── Envelope ─────────────────────────────────────────────────────────────────

class APIResponse(BaseModel):
    success: bool
    correlation_id: Optional[str] = None
    data: Optional[Any] = None
    error: Optional[Dict[str, Any]] = None


# ── Target ────────────────────────────────────────────────────────────────────

class TargetCreate(BaseModel):
    name: str
    primary_domain: str
    tags: List[str] = []
    owner: Optional[str] = None

    @field_validator("primary_domain")
    @classmethod
    def validate_domain(cls, v: str) -> str:
        v = v.strip().lower()
        if not re.match(r"^[a-z0-9]([a-z0-9\-\.]*[a-z0-9])?$", v):
            raise ValueError("Invalid domain format")
        return v


class TargetUpdate(BaseModel):
    name: Optional[str] = None
    tags: Optional[List[str]] = None
    owner: Optional[str] = None
    status: Optional[str] = None


class TargetOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    primary_domain: str
    tags: List[str]
    owner: Optional[str]
    status: str
    created_at: datetime
    updated_at: datetime


# ── Session ───────────────────────────────────────────────────────────────────

class SessionCreate(BaseModel):
    target_id: str
    name: Optional[str] = None
    profile: str = "core"
    scope_definition: Dict[str, Any] = {}

    @field_validator("profile")
    @classmethod
    def validate_profile(cls, v: str) -> str:
        if v not in {"core", "advanced"}:
            raise ValueError("profile must be 'core' or 'advanced'")
        return v


class SessionUpdate(BaseModel):
    name: Optional[str] = None
    profile: Optional[str] = None
    scope_definition: Optional[Dict[str, Any]] = None
    status: Optional[str] = None


class SessionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    target_id: str
    name: Optional[str]
    profile: str
    scope_definition: Dict[str, Any]
    scope_locked: bool
    status: str
    created_at: datetime
    updated_at: datetime


# ── Run ───────────────────────────────────────────────────────────────────────

class RunCreate(BaseModel):
    session_id: str


class RunOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    session_id: str
    stage: str
    status: str
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    error: Optional[str]
    created_at: datetime
    updated_at: datetime


class RunLogEntry(BaseModel):
    timestamp: str
    level: str
    stage: str
    message: str


class RunLogsOut(BaseModel):
    run_id: str
    status: str
    stage: str
    logs: List[RunLogEntry]


# ── Health ────────────────────────────────────────────────────────────────────

class HealthOut(BaseModel):
    status: str
    version: str
    database: str
