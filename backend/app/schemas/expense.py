"""Schema Module 7 — chi phí chuyến đi."""

from datetime import datetime
from typing import Dict, Optional

from pydantic import Field
from sqlmodel import SQLModel

from app.models.trip import ExpenseCategory


class ExpenseCreate(SQLModel):
    category: ExpenseCategory = ExpenseCategory.other
    title: str = Field(min_length=1, max_length=160)
    amount: int = Field(ge=0)
    planned: bool = True
    trip_day_id: Optional[int] = None
    spent_at: Optional[datetime] = None
    paid_by: Optional[str] = Field(default=None, max_length=80)
    note: Optional[str] = None


class ExpenseUpdate(SQLModel):
    category: Optional[ExpenseCategory] = None
    title: Optional[str] = Field(default=None, min_length=1, max_length=160)
    amount: Optional[int] = Field(default=None, ge=0)
    planned: Optional[bool] = None
    trip_day_id: Optional[int] = None
    spent_at: Optional[datetime] = None
    paid_by: Optional[str] = None
    note: Optional[str] = None


class ExpenseOut(SQLModel):
    id: int
    trip_id: int
    trip_day_id: Optional[int] = None
    category: ExpenseCategory
    title: str
    amount: int
    planned: bool
    spent_at: Optional[datetime] = None
    paid_by: Optional[str] = None
    note: Optional[str] = None


class BudgetSummary(SQLModel):
    trip_id: int
    budget_amount: int
    estimate_from_stops: int
    planned_total: int
    actual_total: int
    total_estimate: int
    per_person: int
    remaining: Optional[int] = None
    over_budget: bool
    by_category: Dict[str, int]
    by_day: Dict[str, int]
