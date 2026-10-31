from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session

from app.core.security import (
    create_access_token,
    get_current_user,
    get_password_hash,
    get_role_permissions,
    verify_password,
)
from app.db.session import get_db
from app.models.models import Role, SMSOTPVerification, User
from app.repositories.repositories import log_admin_action
from app.schemas.schemas import (
    LoginRequest,
    RegisterRequest,
    SendOtpRequest,
    SendOtpResponse,
    TokenResponse,
    UserOut,
    VerifyOtpRequest,
)
from app.services.sms_service import (
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
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email hoặc mật khẩu không chính xác.",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tài khoản đã bị vô hiệu hóa.",
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

    now = datetime.utcnow()
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

    otp_code = generate_otp_code(6)
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

    dispatch_sms(phone=phone, otp_code=otp_code)

    return SendOtpResponse(
        phone=phone,
        message="Mã xác thực OTP 6 số đã được gửi qua tin nhắn SMS tới số điện thoại của bạn.",
        expires_in_seconds=300,
        debug_otp=otp_code,
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

    now = datetime.utcnow()
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
    if submitted_otp != verification.otp_code:
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
