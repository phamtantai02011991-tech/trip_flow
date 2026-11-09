from datetime import datetime, timedelta, timezone
import hmac
from typing import Optional

import pyotp
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import delete, update
from sqlmodel import Session, select

from app.core.config import settings
from app.core.security import (
    create_access_token,
    get_current_user,
    get_password_hash,
    get_role_permissions,
    verify_password,
)
from app.core.time import as_utc, utcnow
from app.db.session import get_db
from app.models.models import (
    AuditLog,
    ContentReport,
    Favorite,
    Itinerary,
    ItineraryStop,
    Role,
    SMSOTPVerification,
    User,
)
from app.models.place import SearchHistory
from app.models.review import PlaceReview
from app.models.trip import Expense, Trip, TripDay, TripStop
from app.repositories.repositories import log_admin_action
from app.schemas.schemas import (
    LoginRequest,
    RegisterRequest,
    SendOtpRequest,
    SendOtpResponse,
    TokenResponse,
    TwoFactorCodeRequest,
    TwoFactorSetupResponse,
    TwoFactorStatusResponse,
    UserOut,
    VerifyOtpRequest,
)
from app.services.sms_service import (
    SMSDeliveryError,
    dispatch_sms,
    generate_otp_code,
    is_valid_vn_phone,
    normalize_vn_phone,
)

router = APIRouter()


def _serialize_user_with_permissions(db: Session, user: User) -> UserOut:
    perms = get_role_permissions(db, user.role)
    return UserOut(
        id=user.id,
        email=user.email,
        phone=user.phone,
        full_name=user.full_name,
        role=user.role,
        role_id=user.role_id,
        assigned_province_id=user.assigned_province_id,
        is_active=user.is_active,
        totp_enabled=bool(user.totp_enabled),
        permissions=perms,
        created_at=user.created_at,
    )


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    """
    Đăng nhập người dùng hoặc quản trị viên, trả về JWT Access Token chứa
    cả `role` và mảng `permissions[]` truy vấn từ bảng Role & Permission (Pitfall #2).
    """
    email = payload.email.strip().lower()
    user = db.query(User).filter(User.email == email).first()
    now = utcnow()

    if user is not None:
        locked_until = as_utc(user.locked_until)
        if locked_until is not None and locked_until > now:
            minutes = max(1, int((locked_until - now).total_seconds() // 60) + 1)
            raise HTTPException(
                status_code=status.HTTP_423_LOCKED,
                detail=f"Tài khoản đang tạm khoá do đăng nhập sai nhiều lần. "
                f"Vui lòng thử lại sau {minutes} phút.",
            )
        if locked_until is not None and locked_until <= now:
            user.locked_until = None
            user.failed_login_attempts = 0
            db.add(user)
            db.commit()

    if user is None or not verify_password(payload.password, user.hashed_password):
        if user is not None:
            user.failed_login_attempts = (user.failed_login_attempts or 0) + 1
            if user.failed_login_attempts >= 5:
                user.locked_until = now + timedelta(minutes=15)
                db.add(user)
                db.commit()
                raise HTTPException(
                    status_code=status.HTTP_423_LOCKED,
                    detail="Sai mật khẩu 5 lần. Tài khoản bị tạm khoá 15 phút.",
                )
            db.add(user)
            db.commit()
            remaining = 5 - user.failed_login_attempts
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Email hoặc mật khẩu không chính xác. Còn {remaining} lần thử.",
            )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email hoặc mật khẩu không chính xác.",
        )
    if user.failed_login_attempts or user.locked_until is not None:
        user.failed_login_attempts = 0
        user.locked_until = None
        db.add(user)
        db.commit()
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tài khoản đã bị vô hiệu hóa.",
        )

    if user.totp_enabled:
        if not payload.otp_code:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="2FA_REQUIRED: Nhập mã 6 số từ ứng dụng xác thực.",
            )
        if not user.totp_secret or not pyotp.TOTP(user.totp_secret).verify(
            payload.otp_code.strip(), valid_window=1
        ):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Mã 2FA không đúng hoặc đã hết hạn.",
            )

    permissions = get_role_permissions(db, user.role)
    token = create_access_token(
        subject=user.email,
        role=user.role,
        permissions=permissions,
        assigned_province_id=user.assigned_province_id,
    )

    if user.role != "user":
        log_admin_action(
            db=db,
            actor=user,
            action="LOGIN",
            entity_type="user",
            entity_id=user.id,
            summary=f"Quản trị viên {user.email} ({user.role}) đăng nhập hệ thống.",
            changes={"role": user.role, "permissions_count": len(permissions)},
        )

    return {
        "access_token": token,
        "token_type": "bearer",
        "user": _serialize_user_with_permissions(db, user),
    }


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    """Đăng ký tài khoản người dùng du lịch mới (mặc định role = 'user')."""
    email = payload.email.strip().lower()
    existing = db.query(User).filter(User.email == email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email này đã được đăng ký trong hệ thống.",
        )

    user_role = db.query(Role).filter(Role.code == "user").first()
    new_user = User(
        email=email,
        full_name=payload.full_name.strip(),
        hashed_password=get_password_hash(payload.password),
        role="user",
        role_id=user_role.id if user_role else 5,
        assigned_province_id=None,
        is_active=True,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    permissions = get_role_permissions(db, new_user.role)
    token = create_access_token(
        subject=new_user.email,
        role=new_user.role,
        permissions=permissions,
        assigned_province_id=None,
    )
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": _serialize_user_with_permissions(db, new_user),
    }


@router.post("/otp/send", response_model=SendOtpResponse)
def send_otp(payload: SendOtpRequest, db: Session = Depends(get_db)):
    """
    Gửi mã xác thực OTP 6 số qua tin nhắn SMS:
    - Kiểm tra định dạng số điện thoại di động Việt Nam 10 chữ số (03x, 05x, 07x, 08x, 09x).
    - Rate limit chống spam SMS: Yêu cầu giãn cách tối thiểu 60 giây giữa các lần gửi cho cùng một SĐT.
    - Sinh mã OTP 6 số, lưu vào DB với thời hạn 5 phút (300 giây).
    - Gửi tin nhắn qua SMS Gateway Simulator (in console và trả debug_otp phục vụ kiểm thử).
    """
    raw_phone = payload.phone.strip() if payload.phone else ""
    phone = normalize_vn_phone(raw_phone)
    if not is_valid_vn_phone(phone):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Số điện thoại không đúng định dạng di động Việt Nam (10 số, bắt đầu bằng 03, 05, 07, 08, 09).",
        )

    now = datetime.now(timezone.utc)
    # Kiểm tra Rate Limit 60 giây chống Spam SMS
    latest_verification = (
        db.query(SMSOTPVerification)
        .filter(SMSOTPVerification.phone == phone)
        .order_by(SMSOTPVerification.created_at.desc())
        .first()
    )
    if latest_verification:
        seconds_passed = (now - latest_verification.created_at).total_seconds()
        if seconds_passed < 60:
            retry_after = int(60 - seconds_passed)
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Mã OTP vừa được gửi. Vui lòng đợi {retry_after} giây trước khi yêu cầu mã mới.",
            )

    dev_mode = settings.DEV_OTP_ENABLED and not settings.is_production
    otp_code = (
        (settings.DEV_OTP or generate_otp_code(6))
        if dev_mode
        else generate_otp_code(6)
    )
    expires_at = now + timedelta(minutes=5)

    verification = SMSOTPVerification(
        phone=phone,
        otp_code=otp_code,
        expires_at=expires_at,
        is_used=False,
        attempts=0,
        full_name=payload.full_name.strip() if payload.full_name else None,
        created_at=now,
    )
    db.add(verification)
    db.commit()

    try:
        dispatch_sms(phone=phone, otp_code=otp_code)
    except SMSDeliveryError as exc:
        # Không trả mã lỗi nội bộ cho client; mã OTP đã lưu sẽ hết hạn sau 5 phút.
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Hiện chưa gửi được tin nhắn SMS. Vui lòng thử lại sau ít phút.",
        ) from exc

    return SendOtpResponse(
        phone=phone,
        message="Mã xác thực OTP 6 số đã được gửi qua tin nhắn SMS tới số điện thoại của bạn.",
        expires_in_seconds=300,
        # Chỉ trả mã khi bật cờ dev tường minh; production luôn None.
        debug_otp=otp_code if dev_mode else None,
    )


@router.post("/otp/verify", response_model=TokenResponse)
def verify_otp(payload: VerifyOtpRequest, db: Session = Depends(get_db)):
    """
    Xác thực mã OTP gửi qua tin nhắn SMS & Đăng ký / Đăng nhập người dùng:
    - Kiểm tra mã OTP khớp và còn trong thời hạn 5 phút.
    - Giới hạn tối đa 5 lần thử sai cho mỗi mã OTP.
    - Khi mã đúng: Đánh dấu is_used = True, tạo tài khoản mới nếu chưa có hoặc cập nhật tài khoản đã có.
    - Cấp JWT Bearer Token chuẩn có quyền truy cập ứng dụng.
    """
    raw_phone = payload.phone.strip() if payload.phone else ""
    phone = normalize_vn_phone(raw_phone)
    if not phone:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Số điện thoại không được để trống.",
        )

    now = datetime.now(timezone.utc)
    verification = (
        db.query(SMSOTPVerification)
        .filter(
            SMSOTPVerification.phone == phone,
            SMSOTPVerification.is_used == False,
        )
        .order_by(SMSOTPVerification.created_at.desc())
        .first()
    )

    if not verification:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mã xác thực OTP không tồn tại hoặc đã hết hiệu lực (5 phút). Vui lòng yêu cầu mã mới.",
        )

    if now > verification.expires_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mã xác thực OTP đã hết hiệu lực (5 phút). Vui lòng yêu cầu mã mới.",
        )

    if verification.attempts >= 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bạn đã nhập sai mã OTP quá 5 lần. Vui lòng yêu cầu mã OTP mới.",
        )

    submitted_otp = payload.otp_code.strip() if payload.otp_code else ""
    if not hmac.compare_digest(submitted_otp, verification.otp_code):
        verification.attempts += 1
        db.commit()
        remaining = 5 - verification.attempts
        detail_msg = (
            f"Mã xác thực OTP không chính xác. Bạn còn {remaining} lần thử."
            if remaining > 0
            else "Bạn đã nhập sai mã OTP quá 5 lần. Vui lòng yêu cầu mã OTP mới."
        )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=detail_msg,
        )

    # Đánh dấu mã đã sử dụng thành công
    verification.is_used = True

    # Tìm hoặc tạo người dùng liên kết với số điện thoại này
    user = db.query(User).filter(User.phone == phone).first()
    canonical_email = f"{phone}@tripflow.vn"
    if not user:
        user_by_email = db.query(User).filter(User.email == canonical_email).first()
        if user_by_email:
            user = user_by_email
            user.phone = phone

    if not user:
        # Đăng ký tài khoản du khách mới
        full_name = (
            (payload.full_name or verification.full_name or f"Du khách {phone[-4:]}")
            .strip()
        )
        user_role = db.query(Role).filter(Role.code == "user").first()
        user = User(
            email=canonical_email,
            phone=phone,
            full_name=full_name,
            hashed_password=get_password_hash("otp_verified"),
            role="user",
            role_id=user_role.id if user_role else 5,
            assigned_province_id=None,
            is_active=True,
            created_at=now,
        )
        db.add(user)
    else:
        # Nếu đã có người dùng và có gửi tên mới
        if payload.full_name and payload.full_name.strip():
            user.full_name = payload.full_name.strip()
        if not user.phone:
            user.phone = phone

    db.commit()
    db.refresh(user)

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tài khoản này đã bị tạm khóa.",
        )

    permissions = get_role_permissions(db, user.role)
    token = create_access_token(
        subject=user.email,
        role=user.role,
        permissions=permissions,
        assigned_province_id=user.assigned_province_id,
    )

    return {
        "access_token": token,
        "token_type": "bearer",
        "user": _serialize_user_with_permissions(db, user),
    }


@router.get("/me", response_model=UserOut)
def get_me(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Lấy thông tin hồ sơ của tài khoản đang đăng nhập kèm danh sách quyền hạn."""
    return _serialize_user_with_permissions(db, current_user)


def _iso(value: Optional[datetime]) -> Optional[str]:
    return value.isoformat() if value is not None else None


@router.get("/2fa/status", response_model=TwoFactorStatusResponse)
def two_factor_status(current_user: User = Depends(get_current_user)):
    return {"enabled": bool(current_user.totp_enabled)}


@router.post("/2fa/setup", response_model=TwoFactorSetupResponse)
def setup_two_factor(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Tạo secret TOTP mới (chưa bật cho tới khi xác nhận mã)."""
    if current_user.totp_enabled:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="2FA đang bật. Tắt 2FA trước khi tạo secret mới.",
        )
    secret = pyotp.random_base32()
    current_user.totp_secret = secret
    current_user.totp_enabled = False
    db.add(current_user)
    db.commit()
    uri = pyotp.TOTP(secret).provisioning_uri(
        name=current_user.email, issuer_name="TripFlow"
    )
    return {"secret": secret, "otpauth_url": uri}


@router.post("/2fa/enable", response_model=TwoFactorStatusResponse)
def enable_two_factor(
    payload: TwoFactorCodeRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.totp_secret:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Chưa có secret 2FA. Gọi /auth/2fa/setup trước.",
        )
    if not pyotp.TOTP(current_user.totp_secret).verify(
        payload.code.strip(), valid_window=1
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mã 2FA không đúng hoặc đã hết hạn.",
        )
    current_user.totp_enabled = True
    db.add(current_user)
    db.commit()
    return {"enabled": True}


@router.post("/2fa/disable", response_model=TwoFactorStatusResponse)
def disable_two_factor(
    payload: TwoFactorCodeRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.totp_enabled and not pyotp.TOTP(
        current_user.totp_secret or ""
    ).verify(payload.code.strip(), valid_window=1):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mã 2FA không đúng hoặc đã hết hạn.",
        )
    current_user.totp_enabled = False
    current_user.totp_secret = None
    db.add(current_user)
    db.commit()
    return {"enabled": False}


@router.get("/me/export")
def export_my_data(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Xuất toàn bộ dữ liệu cá nhân của tài khoản (quyền riêng tư / GDPR-style)."""
    itineraries = db.exec(
        select(Itinerary).where(Itinerary.user_id == current_user.id)
    ).all()
    trips = db.exec(select(Trip).where(Trip.user_id == current_user.id)).all()
    trip_ids = [trip.id for trip in trips if trip.id is not None]
    days = (
        db.exec(select(TripDay).where(TripDay.trip_id.in_(trip_ids))).all()
        if trip_ids
        else []
    )
    stops = (
        db.exec(select(TripStop).where(TripStop.trip_id.in_(trip_ids))).all()
        if trip_ids
        else []
    )
    expenses = (
        db.exec(select(Expense).where(Expense.trip_id.in_(trip_ids))).all()
        if trip_ids
        else []
    )
    reviews = db.exec(
        select(PlaceReview).where(PlaceReview.user_id == current_user.id)
    ).all()
    favorites = db.exec(
        select(Favorite).where(Favorite.user_id == current_user.id)
    ).all()
    searches = db.exec(
        select(SearchHistory).where(SearchHistory.user_id == current_user.id)
    ).all()

    return {
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "profile": {
            "id": current_user.id,
            "email": current_user.email,
            "phone": current_user.phone,
            "full_name": current_user.full_name,
            "role": current_user.role,
            "created_at": _iso(current_user.created_at),
        },
        "itineraries": [
            {
                "id": item.id,
                "title": item.title,
                "description": item.description,
                "total_days": item.total_days,
                "status": item.status,
                "created_at": _iso(item.created_at),
                "stops": [
                    {
                        "day_number": stop.day_number,
                        "stop_order": stop.stop_order,
                        "title": stop.title,
                        "address": stop.address,
                        "latitude": stop.latitude,
                        "longitude": stop.longitude,
                        "planned_time": stop.planned_time,
                        "notes": stop.notes,
                    }
                    for stop in item.stops
                ],
            }
            for item in itineraries
        ],
        "trips": [
            {
                "id": trip.id,
                "title": trip.title,
                "origin_name": trip.origin_name,
                "destination_name": trip.destination_name,
                "start_date": trip.start_date.isoformat() if trip.start_date else None,
                "total_days": trip.total_days,
                "status": str(trip.status),
                "created_at": _iso(trip.created_at),
                "days": [
                    {
                        "day_number": day.day_number,
                        "date": day.date.isoformat() if day.date else None,
                        "title": day.title,
                        "note": day.note,
                    }
                    for day in days
                    if day.trip_id == trip.id
                ],
                "stops": [
                    {
                        "name": stop.name,
                        "address": stop.address,
                        "lat": stop.lat,
                        "lng": stop.lng,
                        "stay_mins": stop.stay_mins,
                        "note": stop.note,
                    }
                    for stop in stops
                    if stop.trip_id == trip.id
                ],
                "expenses": [
                    {
                        "title": expense.title,
                        "amount": expense.amount,
                        "category": str(expense.category),
                    }
                    for expense in expenses
                    if expense.trip_id == trip.id
                ],
            }
            for trip in trips
        ],
        "reviews": [
            {
                "place_key": review.place_key,
                "rating": review.rating,
                "comment": review.comment,
                "created_at": _iso(review.created_at),
            }
            for review in reviews
        ],
        "favorites": [
            {"target_type": fav.target_type, "target_id": fav.target_id}
            for fav in favorites
        ],
        "search_history": [
            {"query": item.query, "kind": item.kind, "created_at": _iso(item.created_at)}
            for item in searches
        ],
    }


@router.delete("/account")
def delete_my_account(
    confirm: str = Query(..., description="Nhập đúng chữ DELETE để xác nhận"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Xoá vĩnh viễn tài khoản và dữ liệu cá nhân (quyền được xoá)."""
    if confirm != "DELETE":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Nhập confirm=DELETE để xác nhận xoá tài khoản.",
        )

    user_id = current_user.id
    itinerary_ids = [
        row.id
        for row in db.exec(
            select(Itinerary).where(Itinerary.user_id == user_id)
        ).all()
        if row.id is not None
    ]
    if itinerary_ids:
        db.exec(
            delete(ItineraryStop).where(
                ItineraryStop.itinerary_id.in_(itinerary_ids)
            )
        )
        db.exec(delete(Itinerary).where(Itinerary.id.in_(itinerary_ids)))

    trip_ids = [
        row.id
        for row in db.exec(select(Trip).where(Trip.user_id == user_id)).all()
        if row.id is not None
    ]
    if trip_ids:
        db.exec(delete(Expense).where(Expense.trip_id.in_(trip_ids)))
        db.exec(delete(TripStop).where(TripStop.trip_id.in_(trip_ids)))
        db.exec(delete(TripDay).where(TripDay.trip_id.in_(trip_ids)))
        db.exec(delete(Trip).where(Trip.id.in_(trip_ids)))

    db.exec(delete(PlaceReview).where(PlaceReview.user_id == user_id))
    db.exec(delete(Favorite).where(Favorite.user_id == user_id))
    db.exec(delete(SearchHistory).where(SearchHistory.user_id == user_id))
    db.exec(delete(ContentReport).where(ContentReport.user_id == user_id))
    # Giữ audit log phục vụ truy vết nhưng ẩn danh người thao tác.
    db.exec(
        update(AuditLog)
        .where(AuditLog.actor_id == user_id)
        .values(actor_id=None, actor_email="deleted-user")
    )
    if current_user.phone:
        db.exec(
            delete(SMSOTPVerification).where(
                SMSOTPVerification.phone == current_user.phone
            )
        )

    db.delete(current_user)
    db.commit()
    return {"deleted": True, "user_id": user_id}
