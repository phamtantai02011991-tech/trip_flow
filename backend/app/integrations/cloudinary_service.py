import hashlib
from typing import Any, Dict, Optional

try:
    import cloudinary
    import cloudinary.uploader
    import cloudinary.utils
    CLOUDINARY_SDK_AVAILABLE = True
except ImportError:  # pragma: no cover
    CLOUDINARY_SDK_AVAILABLE = False

from app.core.config import settings


class CloudinaryService:
    """
    Dịch vụ quản lý và tối ưu hóa hình ảnh qua Cloudinary CDN (Thay đổi cốt lõi #5).
    - Không lưu ảnh gốc nặng hàng chục MB vào Database.
    - Tự động sinh URL ảnh thumbnail nhẹ cho danh sách: `c_fill,w_400,h_300,q_auto,f_auto`
    - Tự động sinh URL ảnh sắc nét cho trang chi tiết: `w_1200,q_auto,f_auto`
    """

    THUMBNAIL_TRANSFORMATION = "c_fill,w_400,h_300,q_auto,f_auto"
    DETAIL_TRANSFORMATION = "w_1200,q_auto,f_auto"

    def __init__(self) -> None:
        self.cloud_name = settings.CLOUDINARY_CLOUD_NAME or "demo"
        self.api_key = settings.CLOUDINARY_API_KEY
        self.api_secret = settings.CLOUDINARY_API_SECRET
        if CLOUDINARY_SDK_AVAILABLE:
            cloudinary.config(
                cloud_name=self.cloud_name,
                api_key=self.api_key,
                api_secret=self.api_secret,
                secure=True,
            )

    def build_optimized_url(
        self,
        original_url: Optional[str],
        transformation: str = THUMBNAIL_TRANSFORMATION,
    ) -> str:
        """
        Biến đổi bất kỳ URL ảnh nào sang URL tối ưu hóa qua Cloudinary CDN với tham số nén tự động.
        """
        if not original_url or not original_url.strip():
            default_sample = "https://res.cloudinary.com/demo/image/upload/v1/tripflow/saigon_heritage.jpg"
            return default_sample.replace(
                "/image/upload/", f"/image/upload/{transformation}/"
            )

        url = original_url.strip()

        # Nếu đã là URL Cloudinary chuẩn (/image/upload/ hoặc /image/fetch/)
        if "res.cloudinary.com" in url:
            if f"/{transformation}/" in url:
                return url
            for marker in ("/image/upload/", "/image/fetch/"):
                if marker in url:
                    # Nếu đã có transformation trước đó thì thay thế, hoặc chèn mới
                    parts = url.split(marker, 1)
                    rest = parts[1]
                    if rest.startswith("c_") or rest.startswith("w_"):
                        subparts = rest.split("/", 1)
                        rest = subparts[1] if len(subparts) > 1 else rest
                    return f"{parts[0]}{marker}{transformation}/{rest}"

        # Ảnh ngoài (Wikimedia/Unsplash/đối tác):
        # - Nếu CHƯA cấu hình Cloudinary thật (cloud_name=demo hoặc thiếu API key),
        #   trả nguyên URL gốc. Trước đây mọi ảnh bị bọc qua cloud "demo" nên luôn lỗi.
        # - Nếu đã cấu hình, mới bọc qua Cloudinary Fetch để nén/cắt.
        if self.cloud_name in ("", "demo") or not self.api_key:
            return url
        return f"https://res.cloudinary.com/{self.cloud_name}/image/fetch/{transformation}/{url}"

    def build_thumbnail_url(self, original_url: Optional[str]) -> str:
        """Sinh URL ảnh Thumbnail (w_400,h_300,q_auto,f_auto) cho màn hình danh sách."""
        return self.build_optimized_url(original_url, self.THUMBNAIL_TRANSFORMATION)

    def build_detail_url(self, original_url: Optional[str]) -> str:
        """Sinh URL ảnh Chi tiết (w_1200,q_auto,f_auto) cho màn hình chi tiết địa điểm/nhà hàng."""
        return self.build_optimized_url(original_url, self.DETAIL_TRANSFORMATION)

    def upload_image(
        self,
        image_url: Optional[str] = None,
        file_bytes: Optional[bytes] = None,
        filename: str = "tripflow_place.jpg",
        folder: str = "tripflow/destinations",
    ) -> Dict[str, Any]:
        """
        Upload hình ảnh lên Cloudinary (hoặc chuẩn hóa URL qua Cloudinary CDN nếu môi trường local chưa gắn API Secret).
        Trả về bộ 3 URL: original_url, thumbnail_url (w_400,h_300) và detail_url (w_1200).
        """
        if CLOUDINARY_SDK_AVAILABLE and self.api_key and self.api_secret and (file_bytes or image_url):
            try:
                source = file_bytes if file_bytes is not None else image_url
                upload_result = cloudinary.uploader.upload(
                    source,
                    folder=folder,
                    resource_type="image",
                )
                secure_url = upload_result.get("secure_url", "")
                pub_id = upload_result.get("public_id", f"{folder}/{filename}")
                return {
                    "provider": "cloudinary",
                    "public_id": pub_id,
                    "original_url": secure_url,
                    "thumbnail_url": self.build_thumbnail_url(secure_url),
                    "detail_url": self.build_detail_url(secure_url),
                    "transformations": {
                        "thumbnail": self.THUMBNAIL_TRANSFORMATION,
                        "detail": self.DETAIL_TRANSFORMATION,
                    },
                }
            except Exception:
                pass

        digest = hashlib.md5(f"{filename}_{image_url or ''}".encode("utf-8")).hexdigest()[:10]
        clean_name = filename.rsplit(".", 1)[0].replace(" ", "_").lower()
        public_id = f"{folder}/{clean_name}_{digest}"

        if image_url and image_url.startswith("http"):
            base_url = image_url
            thumb_url = self.build_thumbnail_url(image_url)
            detail_url = self.build_detail_url(image_url)
        else:
            base_url = f"https://res.cloudinary.com/{self.cloud_name}/image/upload/{public_id}.jpg"
            thumb_url = f"https://res.cloudinary.com/{self.cloud_name}/image/upload/{self.THUMBNAIL_TRANSFORMATION}/{public_id}.jpg"
            detail_url = f"https://res.cloudinary.com/{self.cloud_name}/image/upload/{self.DETAIL_TRANSFORMATION}/{public_id}.jpg"

        return {
            "provider": "cloudinary",
            "public_id": public_id,
            "original_url": base_url,
            "thumbnail_url": thumb_url,
            "detail_url": detail_url,
            "transformations": {
                "thumbnail": self.THUMBNAIL_TRANSFORMATION,
                "detail": self.DETAIL_TRANSFORMATION,
            },
        }


cloudinary_service = CloudinaryService()
