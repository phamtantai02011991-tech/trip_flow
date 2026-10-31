"""API Module 4 — trợ lý du lịch AI."""

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import Field
from sqlmodel import Session, SQLModel

from app.core.security import get_current_user_optional
from app.db.session import get_db
from app.models.models import User
from app.models.trip import Trip
from app.services import trip_service
from app.services.ai.assistant_service import AssistantError, chat
from app.services.ai.gemini_client import GeminiError

router = APIRouter()


class ChatRequest(SQLModel):
    message: str = Field(min_length=1, max_length=1000)
    trip_id: Optional[int] = None


@router.post("/chat")
async def assistant_chat(
    payload: ChatRequest,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    trip: Optional[Trip] = None
    if payload.trip_id is not None:
        trip = trip_service.get_trip(db, payload.trip_id)
        if trip is None:
            raise HTTPException(status_code=404, detail="Không tìm thấy chuyến đi")
        if trip.user_id is not None and (current_user is None or trip.user_id != current_user.id):
            raise HTTPException(status_code=404, detail="Không tìm thấy chuyến đi")

    try:
        result = await chat(db, trip, payload.message)
    except AssistantError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except GeminiError as exc:
        raise HTTPException(
            status_code=exc.status, detail={"code": exc.code, "message": str(exc)}
        ) from exc

    return result
