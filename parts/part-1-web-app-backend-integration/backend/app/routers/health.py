from fastapi import APIRouter, Depends, Request
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.schemas import APIResponse, HealthOut

router = APIRouter(prefix="/api/v1", tags=["health"])


@router.get("/health", response_model=APIResponse)
def health_check(request: Request, db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        db_status = "ok"
    except Exception:
        db_status = "error"

    return APIResponse(
        success=True,
        correlation_id=getattr(request.state, "correlation_id", None),
        data=HealthOut(
            status="ok",
            version=settings.VERSION,
            database=db_status,
        ).model_dump(),
    )
