"""Pydantic/SQLModel schema cho API /trips (Module 1, 2, 6)."""

from datetime import date, datetime
from typing import List, Optional

from pydantic import Field
from sqlmodel import SQLModel

from app.models.trip import BudgetLevel, TripStatus, VehicleType


class TripCreate(SQLModel):
    title: str = Field(min_length=3, max_length=160)
    origin_name: str = Field(min_length=2, max_length=200)
    origin_lat: float = Field(ge=-90, le=90)
    origin_lng: float = Field(ge=-180, le=180)
    destination_name: Optional[str] = None
    destination_lat: Optional[float] = Field(default=None, ge=-90, le=90)
    destination_lng: Optional[float] = Field(default=None, ge=-180, le=180)
    province_id: Optional[int] = None
    start_date: Optional[date] = None
    total_days: int = Field(default=1, ge=1, le=14)
    party_size: int = Field(default=2, ge=1, le=20)
    vehicle: VehicleType = VehicleType.motorbike
    budget_level: BudgetLevel = BudgetLevel.balanced
    budget_amount: Optional[int] = Field(default=None, ge=0)
    preferences: List[str] = Field(default_factory=list, max_length=12)


class TripUpdate(SQLModel):
    title: Optional[str] = Field(default=None, min_length=3, max_length=160)
    destination_name: Optional[str] = None
    destination_lat: Optional[float] = None
    destination_lng: Optional[float] = None
    start_date: Optional[date] = None
    total_days: Optional[int] = Field(default=None, ge=1, le=14)
    party_size: Optional[int] = Field(default=None, ge=1, le=20)
    vehicle: Optional[VehicleType] = None
    budget_level: Optional[BudgetLevel] = None
    budget_amount: Optional[int] = Field(default=None, ge=0)
    preferences: Optional[List[str]] = None
    status: Optional[TripStatus] = None


class TripStopIn(SQLModel):
    name: str = Field(min_length=1, max_length=200)
    address: str = ""
    lat: float
    lng: float
    kind: str = "custom"
    place_id: Optional[str] = None
    ref_table: Optional[str] = None
    ref_id: Optional[int] = None
    arrive_at: Optional[datetime] = None
    stay_mins: int = Field(default=60, ge=0, le=1440)
    est_cost: Optional[int] = Field(default=None, ge=0)
    note: Optional[str] = None


class TripStopOut(SQLModel):
    id: int
    day_number: int
    order: int
    kind: str
    place_id: Optional[str] = None
    name: str
    address: str
    lat: float
    lng: float
    arrive_at: Optional[datetime] = None
    stay_mins: int
    travel_mins_from_prev: Optional[int] = None
    distance_km_from_prev: Optional[float] = None
    est_cost: Optional[int] = None
    source: str


class TripDayOut(SQLModel):
    id: int
    day_number: int
    date: Optional[date] = None
    title: Optional[str] = None
    stops: List[TripStopOut] = Field(default_factory=list)


class TripTotals(SQLModel):
    distance_km: float = 0.0
    travel_mins: int = 0
    est_cost: int = 0
    spent: int = 0
    stop_count: int = 0


class TripOut(SQLModel):
    id: int
    title: str
    status: TripStatus
    origin_name: str
    origin_lat: float
    origin_lng: float
    destination_name: Optional[str] = None
    destination_lat: Optional[float] = None
    destination_lng: Optional[float] = None
    start_date: Optional[date] = None
    total_days: int
    party_size: int
    vehicle: VehicleType
    budget_level: BudgetLevel
    budget_amount: Optional[int] = None
    preferences: List[str] = Field(default_factory=list)
    days: List[TripDayOut] = Field(default_factory=list)
    totals: TripTotals = Field(default_factory=TripTotals)
    ai_generated: bool = False
    share_token: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class GenerateRequest(SQLModel):
    """Ghi chú điều chỉnh khi tạo lại lộ trình (Module 2)."""

    feedback: Optional[str] = Field(default=None, max_length=400)
    regenerate: bool = False
