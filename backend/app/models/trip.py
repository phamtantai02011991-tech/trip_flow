"""Model cho Module 1/2/6/7: chuyến đi, ngày, điểm dừng, chi phí.

Tách khỏi `models.py` (catalog) để không phá 18 bảng cũ. Mọi bảng đều có
khoá ngoại thật và index theo `trip_id` để truy vấn theo chuyến.
"""

import datetime as dt
from datetime import datetime
from enum import Enum
from typing import Optional

# pyrefly: ignore[missing-import]
from sqlmodel import Field, SQLModel


class TripStatus(str, Enum):
    draft = "draft"
    planned = "planned"
    active = "active"
    completed = "completed"
    archived = "archived"


class VehicleType(str, Enum):
    motorbike = "motorbike"
    car = "car"
    coach = "coach"


class BudgetLevel(str, Enum):
    saver = "saver"
    balanced = "balanced"
    comfort = "comfort"


class StopKind(str, Enum):
    destination = "destination"
    restaurant = "restaurant"
    cafe = "cafe"
    hotel = "hotel"
    gas = "gas"
    ev = "ev"
    rest = "rest"
    custom = "custom"


class ExpenseCategory(str, Enum):
    fuel = "fuel"
    food = "food"
    hotel = "hotel"
    ticket = "ticket"
    other = "other"


class Trip(SQLModel, table=True):
    __tablename__ = "trips"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: Optional[int] = Field(default=None, foreign_key="users.id", index=True)

    title: str = Field(max_length=160)
    province_id: Optional[int] = Field(default=None, foreign_key="provinces.id")

    origin_name: str = Field(max_length=200)
    origin_lat: float
    origin_lng: float
    destination_name: Optional[str] = Field(default=None, max_length=200)
    destination_lat: Optional[float] = None
    destination_lng: Optional[float] = None

    start_date: Optional[dt.date] = None
    total_days: int = Field(default=1, ge=1, le=14)
    party_size: int = Field(default=2, ge=1, le=20)
    vehicle: VehicleType = VehicleType.motorbike
    budget_level: BudgetLevel = BudgetLevel.balanced
    budget_amount: Optional[int] = None

    preferences_json: str = Field(default="[]")
    status: TripStatus = TripStatus.draft
    share_token: Optional[str] = Field(default=None, unique=True, index=True)

    ai_generated: bool = False
    generation_meta_json: str = Field(default="{}")

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class TripDay(SQLModel, table=True):
    __tablename__ = "trip_days"

    id: Optional[int] = Field(default=None, primary_key=True)
    trip_id: int = Field(foreign_key="trips.id", index=True)
    day_number: int = Field(ge=1)
    date: Optional[dt.date] = None
    title: Optional[str] = Field(default=None, max_length=200)
    note: Optional[str] = None


class TripStop(SQLModel, table=True):
    __tablename__ = "trip_stops"

    id: Optional[int] = Field(default=None, primary_key=True)
    trip_day_id: int = Field(foreign_key="trip_days.id", index=True)
    trip_id: int = Field(foreign_key="trips.id", index=True)

    stop_order: int = Field(default=0)
    kind: str = Field(default=StopKind.destination.value, max_length=24)

    # place_id chỉ có khi điểm dừng đến từ catalog/Places; custom stop thì bỏ trống
    place_id: Optional[str] = Field(default=None, max_length=200)
    ref_table: Optional[str] = Field(default=None, max_length=32)
    ref_id: Optional[int] = None

    name: str = Field(max_length=200)
    address: str = Field(default="", max_length=400)
    lat: float
    lng: float

    arrive_at: Optional[datetime] = None
    stay_mins: int = Field(default=60, ge=0, le=1440)
    travel_mins_from_prev: Optional[int] = None
    distance_km_from_prev: Optional[float] = None
    est_cost: Optional[int] = None
    note: Optional[str] = None

    # manual | ai | nearby | template — dùng để biết điểm nào do AI đề xuất
    source: str = Field(default="manual", max_length=16)


class Expense(SQLModel, table=True):
    __tablename__ = "expenses"

    id: Optional[int] = Field(default=None, primary_key=True)
    trip_id: int = Field(foreign_key="trips.id", index=True)
    trip_day_id: Optional[int] = Field(default=None, foreign_key="trip_days.id")

    category: ExpenseCategory = ExpenseCategory.other
    title: str = Field(max_length=160)
    amount: int = Field(ge=0)
    planned: bool = Field(default=True)
    spent_at: Optional[datetime] = None
    paid_by: Optional[str] = Field(default=None, max_length=80)
    note: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
