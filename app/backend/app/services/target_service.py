from datetime import datetime
from typing import List, Optional, Tuple

from sqlalchemy.orm import Session

from app.models import Target
from app.schemas import TargetCreate, TargetUpdate


def list_targets(db: Session, skip: int = 0, limit: int = 100) -> Tuple[List[Target], int]:
    total = db.query(Target).count()
    items = db.query(Target).offset(skip).limit(limit).all()
    return items, total


def get_target(db: Session, target_id: str) -> Optional[Target]:
    return db.query(Target).filter(Target.id == target_id).first()


def create_target(db: Session, data: TargetCreate) -> Target:
    target = Target(**data.model_dump())
    db.add(target)
    db.commit()
    db.refresh(target)
    return target


def update_target(db: Session, target_id: str, data: TargetUpdate) -> Optional[Target]:
    target = get_target(db, target_id)
    if not target:
        return None
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(target, field, value)
    target.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(target)
    return target


def delete_target(db: Session, target_id: str) -> bool:
    target = get_target(db, target_id)
    if not target:
        return False
    db.delete(target)
    db.commit()
    return True
