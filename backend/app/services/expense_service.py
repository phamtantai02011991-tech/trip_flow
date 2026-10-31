"""Module 7 — Chi phí chuyến đi: dự kiến vs thực tế, tổng theo loại/ngày."""

from typing import Dict, List, Optional

from sqlmodel import Session, select

from app.models.trip import Expense, ExpenseCategory, Trip, TripDay
from app.schemas.expense import BudgetSummary, ExpenseCreate, ExpenseOut, ExpenseUpdate
from app.services import trip_service


def list_expenses(db: Session, trip: Trip) -> List[ExpenseOut]:
    rows = db.exec(
        select(Expense).where(Expense.trip_id == trip.id).order_by(Expense.created_at.desc())
    ).all()
    return [_serialize(r) for r in rows]


def add_expense(db: Session, trip: Trip, payload: ExpenseCreate) -> ExpenseOut:
    if payload.trip_day_id is not None:
        day = db.get(TripDay, payload.trip_day_id)
        if day is None or day.trip_id != trip.id:
            raise ValueError("Ngày không thuộc chuyến đi này")
    row = Expense(trip_id=trip.id, **payload.model_dump())
    db.add(row)
    db.commit()
    db.refresh(row)
    return _serialize(row)


def update_expense(db: Session, trip: Trip, expense_id: int, payload: ExpenseUpdate) -> Optional[ExpenseOut]:
    row = db.get(Expense, expense_id)
    if row is None or row.trip_id != trip.id:
        return None
    for key, value in payload.model_dump(exclude_unset=True).items():
        if value is not None:
            setattr(row, key, value)
    db.add(row)
    db.commit()
    db.refresh(row)
    return _serialize(row)


def delete_expense(db: Session, trip: Trip, expense_id: int) -> bool:
    row = db.get(Expense, expense_id)
    if row is None or row.trip_id != trip.id:
        return False
    db.delete(row)
    db.commit()
    return True


def budget_summary(db: Session, trip: Trip) -> BudgetSummary:
    rows = db.exec(select(Expense).where(Expense.trip_id == trip.id)).all()

    by_category: Dict[str, int] = {c.value: 0 for c in ExpenseCategory}
    planned_total = 0
    actual_total = 0
    by_day: Dict[int, int] = {}

    days = {d.id: d.day_number for d in trip_service.get_days(db, trip.id)}

    for row in rows:
        by_category[row.category.value] = by_category.get(row.category.value, 0) + row.amount
        if row.planned:
            planned_total += row.amount
        else:
            actual_total += row.amount
        if row.trip_day_id in days:
            day_number = days[row.trip_day_id]
            by_day[day_number] = by_day.get(day_number, 0) + row.amount

    estimate = trip_service.totals(db, trip)["est_cost"]
    budget = trip.budget_amount or 0
    total_estimate = estimate + planned_total

    return BudgetSummary(
        trip_id=trip.id,
        budget_amount=budget,
        estimate_from_stops=estimate,
        planned_total=planned_total,
        actual_total=actual_total,
        total_estimate=total_estimate,
        per_person=round((actual_total or total_estimate) / max(1, trip.party_size)),
        remaining=(budget - actual_total) if budget else None,
        over_budget=bool(budget and (actual_total or total_estimate) > budget),
        by_category=by_category,
        by_day={str(k): v for k, v in sorted(by_day.items())},
    )


def _serialize(row: Expense) -> ExpenseOut:
    return ExpenseOut(
        id=row.id,
        trip_id=row.trip_id,
        trip_day_id=row.trip_day_id,
        category=row.category,
        title=row.title,
        amount=row.amount,
        planned=row.planned,
        spent_at=row.spent_at,
        paid_by=row.paid_by,
        note=row.note,
    )
