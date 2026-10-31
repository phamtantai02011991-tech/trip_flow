import logging
import re
import secrets
from typing import Optional

logger = logging.getLogger("tripflow.sms")

# Biểu thức chính quy cho các đầu số di động 10 số tại Việt Nam
# Viettel (032-039, 086, 096-098)
# Mobifone (070, 076-079, 089, 090, 093)
# Vinaphone (081-085, 088, 091, 094)
# Vietnamobile (052, 056, 058, 092)
# Gmobile & Wintel (059, 055, 087, 099)
VN_PHONE_REGEX = re.compile(r"^0(3[2-9]|5[25689]|7[06-9]|8[1-9]|9[0-9])[0-9]{7}$")


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


def dispatch_sms(phone: str, otp_code: str, custom_message: Optional[str] = None) -> str:
    """
    Mô phỏng Gateway gửi SMS (SMS Gateway Simulator) cho người dùng.
    In khối thông báo trực quan ra console và trả về nội dung tin nhắn để phục vụ kiểm thử và debug.
    Sẵn sàng tích hợp các SMS Gateway thương mại như eSMS, SpeedSMS hoặc Twilio khi triển khai thực tế.
    """
    message = (
        custom_message
        or f"[TripFlow] Ma xac thuc OTP cua ban la: {otp_code}. "
        f"Ma co hieu luc trong 5 phut. Vui long KHONG chia se ma nay cho bat ky ai."
    )

    divider = "=" * 80
    banner = (
        f"\n{divider}\n"
        f" [SMS GATEWAY SIMULATOR] TIN NHAN SMS GUI DEN: {phone}\n"
        f" Nguoi gui: TRIPFLOW-OTP\n"
        f" Noi dung: {message}\n"
        f"{divider}\n"
    )
    print(banner)
    logger.info("Sent SMS OTP [%s] to phone [%s]", otp_code, phone)
    return message
