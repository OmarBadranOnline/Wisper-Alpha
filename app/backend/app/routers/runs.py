from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas import APIResponse, RunCreate, RunLogsOut, RunOut
from app.services import run_service

router = APIRouter(prefix="/api/v1/runs", tags=["runs"])


def _corr(request: Request) -> Optional[str]:
    return getattr(request.state, "correlation_id", None)


@router.get("", response_model=APIResponse)
def list_runs(
    request: Request,
    session_id: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    items, total = run_service.list_runs(db, session_id, skip, limit)
    return APIResponse(
        success=True,
        correlation_id=_corr(request),
        data={
            "items": [RunOut.model_validate(r).model_dump() for r in items],
            "total": total,
        },
    )


@router.post("", response_model=APIResponse, status_code=status.HTTP_201_CREATED)
def start_run(request: Request, body: RunCreate, db: Session = Depends(get_db)):
    run = run_service.create_run(db, body)
    return APIResponse(
        success=True,
        correlation_id=_corr(request),
        data=RunOut.model_validate(run).model_dump(),
    )


@router.get("/{run_id}", response_model=APIResponse)
def get_run(request: Request, run_id: str, db: Session = Depends(get_db)):
    run = run_service.get_run(db, run_id)
    if not run:
        raise HTTPException(status_code=404, detail="Run not found")
    return APIResponse(
        success=True,
        correlation_id=_corr(request),
        data=RunOut.model_validate(run).model_dump(),
    )


@router.get("/{run_id}/logs", response_model=APIResponse)
def get_run_logs(request: Request, run_id: str, db: Session = Depends(get_db)):
    run = run_service.get_run(db, run_id)
    if not run:
        raise HTTPException(status_code=404, detail="Run not found")
    return APIResponse(
        success=True,
        correlation_id=_corr(request),
        data=RunLogsOut(
            run_id=run.id,
            status=run.status,
            stage=run.stage,
            logs=run.logs or [],
        ).model_dump(),
    )


@router.post("/{run_id}/cancel", response_model=APIResponse)
def cancel_run(request: Request, run_id: str, db: Session = Depends(get_db)):
    run = run_service.cancel_run(db, run_id)
    if not run:
        raise HTTPException(status_code=404, detail="Run not found")
    return APIResponse(
        success=True,
        correlation_id=_corr(request),
        data=RunOut.model_validate(run).model_dump(),
    )
