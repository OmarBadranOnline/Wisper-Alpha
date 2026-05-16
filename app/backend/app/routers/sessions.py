from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas import APIResponse, SessionCreate, SessionOut, SessionUpdate
from app.services import session_service

router = APIRouter(prefix="/api/v1/sessions", tags=["sessions"])


def _corr(request: Request) -> Optional[str]:
    return getattr(request.state, "correlation_id", None)


@router.get("", response_model=APIResponse)
def list_sessions(
    request: Request,
    target_id: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    items, total = session_service.list_sessions(db, target_id, skip, limit)
    return APIResponse(
        success=True,
        correlation_id=_corr(request),
        data={
            "items": [SessionOut.model_validate(s).model_dump() for s in items],
            "total": total,
        },
    )


@router.post("", response_model=APIResponse, status_code=status.HTTP_201_CREATED)
def create_session(request: Request, body: SessionCreate, db: Session = Depends(get_db)):
    sess = session_service.create_session(db, body)
    return APIResponse(
        success=True,
        correlation_id=_corr(request),
        data=SessionOut.model_validate(sess).model_dump(),
    )


@router.get("/{session_id}", response_model=APIResponse)
def get_session(request: Request, session_id: str, db: Session = Depends(get_db)):
    sess = session_service.get_session(db, session_id)
    if not sess:
        raise HTTPException(status_code=404, detail="Session not found")
    return APIResponse(
        success=True,
        correlation_id=_corr(request),
        data=SessionOut.model_validate(sess).model_dump(),
    )


@router.patch("/{session_id}", response_model=APIResponse)
def update_session(
    request: Request,
    session_id: str,
    body: SessionUpdate,
    db: Session = Depends(get_db),
):
    try:
        sess = session_service.update_session(db, session_id, body)
    except ValueError as exc:
        raise HTTPException(status_code=409, detail=str(exc))
    if not sess:
        raise HTTPException(status_code=404, detail="Session not found")
    return APIResponse(
        success=True,
        correlation_id=_corr(request),
        data=SessionOut.model_validate(sess).model_dump(),
    )


@router.post("/{session_id}/lock-scope", response_model=APIResponse)
def lock_scope(request: Request, session_id: str, db: Session = Depends(get_db)):
    sess = session_service.lock_scope(db, session_id)
    if not sess:
        raise HTTPException(status_code=404, detail="Session not found")
    return APIResponse(
        success=True,
        correlation_id=_corr(request),
        data=SessionOut.model_validate(sess).model_dump(),
    )
