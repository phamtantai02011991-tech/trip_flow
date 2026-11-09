import logging
import re
import secrets
from typing import Optional

import httpx

from app.core.config import settings

logger = logging.getLogger("tripflow.sms")

# Biểu thức chính quy cho các đầu số di động 10 số tại Việt Nam
# Viettel (032-039, 086, 096-098)
# Mobifone (070, 076-079, 089, 090, 093)
# Vinaphone (081-085, 088, 091, 094)
# Vietnamobile (052, 056, 058, 092)
# Gmobile & Wintel (059, 055, 087, 099)
VN_PHONE_REGEX = re.compile(r"^0(3[2-9]|5[25689]|7[06-9]|8[1-9]|9[0-9])[0-9]{7}$")

ESMS_ENDPOINT = "https://rest.esms.vn/MainService.svc/json/SendMultipleMessage_V4_post_json/"


class SMSDeliveryError(RuntimeError):
    """Không gửi được SMS qua nhà cung cấp đã cấu hình."""


def normalize_vn_phone(phone: str) -> str:
    """
    Chuẩn hóa số điện thoại Việt Nam về định dạng 10 chữ số bắt đầu bằng '0'.
    - Loại bỏ dấu cộng, khoảng trắng, gạch ngang, dấu chấm và dấu ngoặc.
    - Chuyển mã quốc tế '+84' hoặc '84' ở đầu thành '0'.
    """
    if not phone:
        return ""
    cleaned = re.sub(r"[\s\-\.\(\)\+]", "", str(phone).strip())
    if cleaned.startswith("84") and len(cleaned) == 11:
        cleaned = "0" + cleaned[2:]
    elif cleaned.startswith("084") and len(cleaned) == 12:
        cleaned = "0" + cleaned[3:]
    return cleaned


def is_valid_vn_phone(phone: str) -> bool:
    """
    Kiểm tra xem chuỗi số điện thoại có phải là số di động 10 chữ số hợp lệ của Việt Nam hay không.
    """
    if not phone:
        return False
    normalized = normalize_vn_phone(phone)
    return bool(VN_PHONE_REGEX.match(normalized))


def generate_otp_code(length: int = 6) -> str:
    """
    Sinh mã OTP ngẫu nhiên gồm các chữ số bằng bộ sinh số ngẫu nhiên bảo mật mật mã (Cryptographically Secure).
    """
    return "".join(secrets.choice("0123456789") for _ in range(length))


def _mask_phone(phone: str) -> str:
    if len(phone) >= 7:
        return f"{phone[:3]}****{phone[-3:]}"
    return "***"


def _send_esms(phone: str, message: str) -> str:
    """Gửi SMS qua eSMS.vn (nhà cung cấp phổ biến tại Việt Nam)."""
    if not settings.ESMS_API_KEY or not settings.ESMS_SECRET_KEY:
        raise SMSDeliveryError(
            "Chưa cấu hình ESMS_API_KEY/ESMS_SECRET_KEY nhưng SMS_PROVIDER=esms."
        )
    payload = {
        "ApiKey": settings.ESMS_API_KEY,
        "SecretKey": settings.ESMS_SECRET_KEY,
        "Phone": phone,
        "Content": message,
        "Brandname": settings.ESMS_BRANDNAME,
        "SmsType": "2",
        "IsUnicode": "1",
    }
    try:
        resp = httpx.post(ESMS_ENDPOINT, json=payload, timeout=10.0)
        data = resp.json()
    except Exception as exc:  # pragma: no cover - phụ thuộc mạng
        logger.error("eSMS request failed for %s: %s", _mask_phone(phone), exc)
        raise SMSDeliveryError("Không kết nối được cổng SMS.") from exc

    if str(data.get("CodeResult")) != "100":
        logger.error(
            "eSMS rejected message for %s: CodeResult=%s ErrorMessage=%s",
            _mask_phone(phone),
            data.get("CodeResult"),
            data.get("ErrorMessage"),
        )
        raise SMSDeliveryError(
            f"Nhà cung cấp SMS từ chối gửi tin (mã {data.get('CodeResult')})."
        )
    logger.info("eSMS accepted OTP message for %s", _mask_phone(phone))
    return message


def dispatch_sms(phone: str, otp_code: str, custom_message: Optional[str] = None) -> str:
    """
    Gửi mã OTP qua SMS.

    - `SMS_PROVIDER=simulator` (mặc định ở dev): in ra console để lập trình/kiểm thử.
    - `SMS_PROVIDER=esms`: gọi eSMS thật, yêu cầu đủ API key/secret.
    - Ở production, tuyệt đối không cho phép provider simulator.
    """
    message = (
        custom_message
        or f"[TripFlow] Ma xac thuc OTP cua ban la: {otp_code}. "
        f"Ma co hieu luc trong 5 phut. Vui long KHONG chia se ma nay cho bat ky ai."
    )

    provider = (settings.SMS_PROVIDER or "simulator").strip().lower()

    if provider == "simulator":
        if settings.is_production:
            raise SMSDeliveryError(
                "SMS_PROVIDER=simulator không được dùng ở production. "
                "Hãy cấu hình eSMS (SMS_PROVIDER=esms + ESMS_API_KEY/ESMS_SECRET_KEY)."
            )
        divider = "=" * 80
        print(
            f"\n{divider}\n"
            f" [SMS GATEWAY SIMULATOR] TIN NHAN SMS GUI DEN: {phone}\n"
            f" Nguoi gui: TRIPFLOW-OTP\n"
            f" Noi dung: {message}\n"
            f"{divider}\n"
        )
        # Không ghi mã OTP vào log để tránh lộ mã khi thu thập log.
        logger.info("Simulated SMS OTP delivery to %s", _mask_phone(phone))
        return message

    if provider == "esms":
        return _send_esms(phone, message)

    raise SMSDeliveryError(f"SMS_PROVIDER không hợp lệ: {settings.SMS_PROVIDER}")
