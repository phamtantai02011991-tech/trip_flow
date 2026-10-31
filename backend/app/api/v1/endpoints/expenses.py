"""API Module 7 — chi phí chuyến đi."""

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session

from app.api.v1.endpoints.trips import get_owned_trip
from app.db.session import get_db
from app.models.trip import Trip
from app.schemas.expense import BudgetSummary, ExpenseCreate, ExpenseOut, ExpenseUpdate
from app.services import expense_service

router = APIRouter()


@router.get("/{trip_id}/expenses", response_model=List[ExpenseOut])
def list_expenses(trip: Trip = Depends(get_owned_trip), db: Session = Depends(get_db)):
    return expense_service.list_expenses(db, trip)


@router.post("/{trip_id}/expenses", response_model=ExpenseOut, status_code=201)
def add_expense(
    payload: ExpenseCreate,
    trip: Trip = Depends(get_owned_trip),
    db: Session = Depends(get_db),
):
    try:
        return expense_service.add_expense(db, trip, payload)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc


@router.put("/{trip_id}/expenses/{expense_id}", response_model=ExpenseOut)
def update_expense(
    expense_id: int,
    payload: ExpenseUpdate,
    trip: Trip = Depends(get_owned_trip),
    db: Session = Depends(get_db),
):
    result = expense_service.update_expense(db, trip, expense_id, payload)
    if result is None:
        raise HTTPException(status_code=404, detail="Không tìm thấy chi phí")
    return result


@router.delete("/{trip_id}/expenses/{expense_id}", status_code=204)
def delete_expense(
    expense_id: int,
    trip: Trip = Depends(get_owned_trip),
    db: Session = Depends(get_db),
):
    if not expense_service.delete_expense(db, trip, expense_id):
        raise HTTPException(status_code=404, detail="Không tìm thấy chi phí")
    return None


@router.get("/{trip_id}/budget-summary", response_model=BudgetSummary)
def budget_summary(trip: Trip = Depends(get_owned_trip), db: Session = Depends(get_db)):
    return expense_service.budget_summary(db, trip)
