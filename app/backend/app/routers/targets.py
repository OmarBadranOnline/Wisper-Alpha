from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas import APIResponse, TargetCreate, TargetOut, TargetUpdate
from app.services import target_service

router = APIRouter(prefix="/api/v1/targets", tags=["targets"])


def _corr(request: Request) -> Optional[str]:
    return getattr(request.state, "correlation_id", None)


@router.get("", response_model=APIResponse)
def list_targets(
    request: Request,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    items, total = target_service.list_targets(db, skip, limit)
    return APIResponse(
        success=True,
        correlation_id=_corr(request),
        data={
            "items": [TargetOut.model_validate(t).model_dump() for t in items],
            "total": total,
        },
    )


@router.post("", response_model=APIResponse, status_code=status.HTTP_201_CREATED)
def create_target(request: Request, body: TargetCreate, db: Session = Depends(get_db)):
    target = target_service.create_target(db, body)
    return APIResponse(
        success=True,
        correlation_id=_corr(request),
        data=TargetOut.model_validate(target).model_dump(),
    )


@router.get("/{target_id}", response_model=APIResponse)
def get_target(request: Request, target_id: str, db: Session = Depends(get_db)):
    target = target_service.get_target(db, target_id)
    if not target:
        raise HTTPException(status_code=404, detail="Target not found")
    return APIResponse(
        success=True,
        correlation_id=_corr(request),
        data=TargetOut.model_validate(target).model_dump(),
    )


@router.patch("/{target_id}", response_model=APIResponse)
def update_target(
    request: Request,
    target_id: str,
    body: TargetUpdate,
    db: Session = Depends(get_db),
):
    target = target_service.update_target(db, target_id, body)
    if not target:
        raise HTTPException(status_code=404, detail="Target not found")
    return APIResponse(
        success=True,
        correlation_id=_corr(request),
        data=TargetOut.model_validate(target).model_dump(),
    )


@router.delete("/{target_id}", response_model=APIResponse)
def delete_target(request: Request, target_id: str, db: Session = Depends(get_db)):
    deleted = target_service.delete_target(db, target_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Target not found")
    return APIResponse(
        success=True,
        correlation_id=_corr(request),
        data={"deleted": target_id},
    )
