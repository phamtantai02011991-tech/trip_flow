import base64
import hashlib
import hmac
import json
import os
import time
from typing import List, Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlmodel import Session, select

from app.core.config import settings
from app.db.session import get_db
from app.models.models import Permission, Role, RolePermissionLink, User

bearer_scheme = HTTPBearer(auto_error=False)

# Bảng ánh xạ quyền mặc định theo vai trò nếu DB vừa khởi tạo
DEFAULT_ROLE_PERMISSIONS = {
    "super_admin": [
        "destination:read",
        "destination:write",
        "destination:delete",
        "food:write",
        "restaurant:write",
        "itinerary:write",
        "report:moderate",
        "partner:manage",
        "user:manage",
        "audit:read",
    ],
    "content_admin": [
        "destination:read",
        "destination:write",
        "destination:delete",
        "food:write",
        "restaurant:write",
        "itinerary:write",
        "partner:manage",
        "audit:read",
    ],
    "province_editor": [
        "destination:read",
        "destination:write",
        "food:write",
        "restaurant:write",
        "itinerary:write",
    ],
    "moderator": [
        "destination:read",
        "report:moderate",
        "audit:read",
    ],
    "user": [
        "destination:read",
    ],
}


def get_password_hash(password: str) -> str:
    """Băm mật khẩu an toàn bằng PBKDF2-HMAC-SHA256 kèm salt ngẫu nhiên."""
    salt = os.urandom(16).hex()
    dk = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        120000,
    )
    return f"pbkdf2_sha256$120000${salt}${dk.hex()}"


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Kiểm tra mật khẩu người dùng nhập vào với chuỗi băm lưu trong DB."""
    if not hashed_password or not plain_password:
        return False
    try:
        parts = hashed_password.split("$")
        if len(parts) != 4 or parts[0] != "pbkdf2_sha256":
            return False
        iterations = int(parts[1])
        salt = parts[2]
        expected_hash = parts[3]
        dk = hashlib.pbkdf2_hmac(
            "sha256",
            plain_password.encode("utf-8"),
            salt.encode("utf-8"),
            iterations,
        )
        return hmac.compare_digest(dk.hex(), expected_hash)
    except Exception:
        return False


def get_role_permissions(db: Session, role_code: str) -> List[str]:
    """
    Truy vấn bảng Role -> RolePermissionLink -> Permission trong SQLModel (Pitfall #2)
    để lấy danh sách mã quyền (permissions) thực tế của một vai trò.
    """
    try:
        stmt = (
            select(Permission.code)
            .join(RolePermissionLink, RolePermissionLink.permission_id == Permission.id)
            .join(Role, Role.id == RolePermissionLink.role_id)
            .where(Role.code == role_code)
        )
        perms = list(db.exec(stmt).all())
        if perms:
            return perms
    except Exception:
        pass
    return list(DEFAULT_ROLE_PERMISSIONS.get(role_code, ["destination:read"]))


def _b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("utf-8")


def _b64url_decode(data: str) -> bytes:
    padding = "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode(data + padding)


def create_access_token(
    subject: str,
    role: str,
    permissions: Optional[List[str]] = None,
    assigned_province_id: Optional[int] = None,
    expires_delta_minutes: Optional[int] = None,
) -> str:
    """
    Tạo JWT Access Token chuẩn HS256 chứa email, role, permissions[] và assigned_province_id (Pitfall #2).
    """
    expire_minutes = expires_delta_minutes or settings.ACCESS_TOKEN_EXPIRE_MINUTES
    now = int(time.time())
    resolved_perms = permissions if permissions is not None else DEFAULT_ROLE_PERMISSIONS.get(role, ["destination:read"])
    header = {"alg": settings.ALGORITHM, "typ": "JWT"}
    payload = {
        "sub": str(subject),
        "role": role,
        "permissions": resolved_perms,
        "assigned_province_id": assigned_province_id,
        "iat": now,
        "exp": now + expire_minutes * 60,
    }
    header_b64 = _b64url_encode(json.dumps(header, separators=(",", ":")).encode("utf-8"))
    payload_b64 = _b64url_encode(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    signing_input = f"{header_b64}.{payload_b64}".encode("utf-8")
    signature = hmac.new(
        settings.SECRET_KEY.encode("utf-8"),
        signing_input,
        hashlib.sha256,
    ).digest()
    return f"{header_b64}.{payload_b64}.{_b64url_encode(signature)}"


def decode_access_token(token: str) -> dict:
    """Giải mã và xác thực chữ ký + hạn dùng của JWT Token."""
    try:
        parts = token.split(".")
        if len(parts) != 3:
            raise ValueError("Invalid token structure")
        header_b64, payload_b64, signature_b64 = parts
        signing_input = f"{header_b64}.{payload_b64}".encode("utf-8")
        expected_sig = hmac.new(
            settings.SECRET_KEY.encode("utf-8"),
            signing_input,
            hashlib.sha256,
        ).digest()
        actual_sig = _b64url_decode(signature_b64)
        if not hmac.compare_digest(expected_sig, actual_sig):
            raise ValueError("Invalid token signature")
        payload = json.loads(_b64url_decode(payload_b64).decode("utf-8"))
        if payload.get("exp", 0) < int(time.time()):
            raise ValueError("Token expired")
        return payload
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token xác thực không hợp lệ hoặc đã hết hạn.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc


def get_current_user_optional(
    db: Session = Depends(get_db),
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
) -> Optional[User]:
    """Trả về User hiện tại nếu có truyền Bearer Token hợp lệ, ngược lại trả về None (cho phép Guest Mode)."""
    if not credentials or not credentials.credentials:
        return None
    try:
        payload = decode_access_token(credentials.credentials)
        email = payload.get("sub")
        if not email:
            return None
        user = db.query(User).filter(User.email == email, User.is_active == True).first()
        return user
    except Exception:
        return None


def get_current_user(
    db: Session = Depends(get_db),
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
) -> User:
    """Bắt buộc người dùng phải đăng nhập hợp lệ."""
    if not credentials or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Vui lòng đăng nhập để thực hiện thao tác này.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    payload = decode_access_token(credentials.credentials)
    email = payload.get("sub")
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Tài khoản không tồn tại trong hệ thống.",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tài khoản của bạn đã bị khóa bởi Quản trị viên.",
        )
    return user


def require_roles(allowed_roles: List[str]):
    """Dependency kiểm tra phân quyền RBAC theo bảng Role."""

    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=(
                    f"Truy cập bị từ chối. Vai trò '{current_user.role}' không có quyền thực hiện thao tác này. "
                    f"Yêu cầu một trong các quyền: {', '.join(allowed_roles)}."
                ),
            )
        return current_user

    return role_checker


def require_permissions(required_permissions: List[str]):
    """
    Dependency kiểm tra phân quyền chi tiết dựa trên bảng Role & Permission (Pitfall #2).
    """

    def perm_checker(
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user),
    ) -> User:
        user_perms = set(get_role_permissions(db, current_user.role))
        if current_user.role == "super_admin":
            return current_user
        missing = [p for p in required_permissions if p not in user_perms]
        if missing:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=(
                    f"Truy cập bị từ chối. Tài khoản '{current_user.email}' (role={current_user.role}) "
                    f"thiếu quyền hạn bắt buộc: {', '.join(missing)}."
                ),
            )
        return current_user

    return perm_checker


def check_province_permission(user: User, province_id: int) -> None:
    """Kiểm tra giới hạn phạm vi tỉnh/thành đối với vai trò province_editor."""
    if user.role == "province_editor":
        if user.assigned_province_id is None or int(user.assigned_province_id) != int(province_id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=(
                    f"Bạn là Biên tập viên theo tỉnh (province_editor) và chỉ được phép quản lý dữ liệu "
                    f"thuộc tỉnh/thành có ID={user.assigned_province_id} (không có quyền trên province_id={province_id})."
                ),
            )


def get_current_active_superuser(
    current_user: User = Depends(get_current_user),
) -> User:
    """
    Dependency bảo vệ các API quản trị cấp cao (như AI Data Ingestion Crawler).
    Chỉ cho phép tài khoản Admin đang hoạt động (`super_admin` hoặc `content_admin`).
    """
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tài khoản quản trị viên đang bị khóa.",
        )
    if current_user.role not in ("super_admin", "content_admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                f"Truy cập bị từ chối. Chỉ Superuser/Admin mới được phép kích hoạt tiến trình cào dữ liệu "
                f"(vai trò hiện tại: '{current_user.role}')."
            ),
        )
    return current_user


def require_admin_2fa(
    current_user: User = Depends(get_current_user),
) -> User:
    """Khi REQUIRE_ADMIN_2FA=1, admin chưa bật TOTP không được gọi API quản trị.

    Vẫn cho phép gọi `/auth/2fa/*` vì các endpoint đó không nằm trong router admin.
    """
    if (
        settings.REQUIRE_ADMIN_2FA
        and current_user.role != "user"
        and not current_user.totp_enabled
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="2FA_SETUP_REQUIRED: Bật 2FA trước khi sử dụng API quản trị.",
        )
    return current_user

