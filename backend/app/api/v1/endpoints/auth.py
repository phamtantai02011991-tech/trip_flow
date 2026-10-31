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
from app.models.models import Role, User
from app.repositories.repositories import log_admin_action
from app.schemas.schemas import LoginRequest, RegisterRequest, TokenResponse, UserOut

router = APIRouter()


def _serialize_user_with_permissions(db: Session, user: User) -> UserOut:
    perms = get_role_permissions(db, user.role)
    return UserOut(
        id=user.id,
        email=user.email,
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


@router.get("/me", response_model=UserOut)
def get_me(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Lấy thông tin hồ sơ của tài khoản đang đăng nhập kèm danh sách quyền hạn."""
    return _serialize_user_with_permissions(db, current_user)
