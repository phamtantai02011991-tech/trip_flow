import time
from collections import defaultdict
from typing import Callable, Dict, List
from fastapi import HTTPException, Request, status
from fastapi.responses import JSONResponse

try:
    from slowapi import Limiter
    from slowapi.errors import RateLimitExceeded
    from slowapi.util import get_remote_address
    SLOWAPI_AVAILABLE = True
except ImportError:  # pragma: no cover
    SLOWAPI_AVAILABLE = False
    RateLimitExceeded = Exception

    def get_remote_address(request: Request) -> str:
        if request.client and request.client.host:
            return request.client.host
        return "127.0.0.1"


def get_client_identifier(request: Request) -> str:
    """
    Xác định định danh Client/IP để áp dụng Rate Limiting (Pitfall #6).
    Ưu tiên X-Client-ID hoặc X-Forwarded-For (nếu đứng sau Reverse Proxy) rồi tới IP remote.
    """
    client_id = request.headers.get("X-Client-ID")
    if client_id:
        return client_id.strip()
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return get_remote_address(request)


if SLOWAPI_AVAILABLE:
    limiter = Limiter(key_func=get_client_identifier, default_limits=["200/minute"])
else:
    class _FallbackLimiter:
        def limit(self, limit_value: str) -> Callable:
            def decorator(func: Callable) -> Callable:
                return func
            return decorator

    limiter = _FallbackLimiter()


# Bộ đếm sliding-window 60 giây bổ trợ để đảm bảo 100% tính nhất quán cả trong TestClient
_corridor_request_timestamps: Dict[str, List[float]] = defaultdict(list)


def reset_corridor_rate_limit_store() -> None:
    """Xóa bộ đếm rate limit (dùng khi khởi tạo từng test case độc lập)."""
    _corridor_request_timestamps.clear()


def enforce_corridor_rate_limit(request: Request, max_calls: int = 10, window_seconds: int = 60) -> None:
    """
    Đảm bảo mỗi IP / Client chỉ được gọi API tìm đường (Corridor Search) tối đa 10 lần/phút.
    Bảo vệ hạn mức phí Goong Maps API và chống spam làm treo Backend (Pitfall #6).
    """
    key = get_client_identifier(request)
    now = time.time()
    cutoff = now - window_seconds
    history = [ts for ts in _corridor_request_timestamps[key] if ts > cutoff]
    if len(history) >= max_calls:
        _corridor_request_timestamps[key] = history
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=(
                "Bạn đã vượt quá giới hạn 10 lần tìm kiếm lộ trình mỗi phút (Rate Limit 10/minute). "
                "Vui lòng đợi ít giây rồi thử lại để bảo vệ hạn mức Goong Maps API."
            ),
        )
    history.append(now)
    _corridor_request_timestamps[key] = history


async def custom_rate_limit_exceeded_handler(request: Request, exc: Exception) -> JSONResponse:
    """Handler trả về lỗi HTTP 429 chuẩn tiếng Việt khi slowapi phát hiện vượt ngưỡng."""
    return JSONResponse(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        content={
            "detail": (
                "Bạn đã vượt quá giới hạn 10 lần tìm kiếm lộ trình mỗi phút (Rate Limit 10/minute). "
                "Vui lòng đợi ít giây rồi thử lại."
            ),
            "rate_limit": "10/minute",
        },
    )
