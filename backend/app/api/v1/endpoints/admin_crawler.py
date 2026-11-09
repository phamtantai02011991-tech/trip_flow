"""
Endpoints Quản trị Tiến trình Cào Dữ liệu Ngầm (AI Data Ingestion - Google Maps Crawler).
- POST /api/v1/admin/crawl: Tạo CrawlJob(status='PENDING') và đẩy `process_crawl_job` vào `BackgroundTasks`
- GET /api/v1/admin/crawl/{job_id}: Xem trạng thái và kết quả chi tiết của job cào dữ liệu
- GET /api/v1/admin/crawl: Xem danh sách lịch sử các job cào dữ liệu gần nhất.
"""

from datetime import datetime, timezone
from typing import List
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from sqlmodel import Session, select

from app.core.config import settings
from app.core.security import get_current_active_superuser
from app.db.session import get_db
from app.models.crawl_job import CrawlJob
from app.models.models import User
from app.repositories.repositories import log_admin_action
from app.schemas.schemas import (
    CrawlJobOut,
    CrawlTriggerRequest,
    CrawlTriggerResponse,
)
from app.services.crawler.normalizer import is_valid_vn_location
from app.services.ingestion_service import process_crawl_job

router = APIRouter()


def _serialize_crawl_job(job: CrawlJob) -> CrawlJobOut:
    return CrawlJobOut(
        id=job.id,
        job_id=job.id,
        keyword=job.keyword,
        lat=job.lat,
        lng=job.lng,
        status=job.status,
        total_scraped=job.total_scraped,
        inserted_count=job.inserted_count,
        duplicate_count=job.duplicate_count,
        error_message=job.error_message,
        created_at=job.created_at,
        completed_at=job.completed_at,
    )


@router.post("/crawl", response_model=CrawlTriggerResponse)
async def trigger_google_maps_crawl(
    payload: CrawlTriggerRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_superuser),
):
    """
    Kích hoạt tiến trình cào dữ liệu địa điểm/quán ăn từ Google Maps chạy ngầm qua `BackgroundTasks`.
    Trả về ngay lập tức `job_id` và trạng thái `PENDING` mà không làm treo request của Admin.
    """
    keyword = (payload.keyword or "").strip()
    if not keyword:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Từ khóa tìm kiếm (keyword) không được để trống.",
        )

    if settings.is_production and not settings.ENABLE_GOOGLE_CRAWLER:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "Tính năng cào dữ liệu Google Maps bị tắt ở production vì lý do điều khoản "
                "sử dụng và pháp lý. Đặt ENABLE_GOOGLE_CRAWLER=1 nếu đã có thỏa thuận dữ liệu."
            ),
        )

    if not is_valid_vn_location(payload.lat, payload.lng):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Tọa độ ({payload.lat}, {payload.lng}) nằm ngoài lãnh thổ Việt Nam "
                "(yêu cầu vĩ độ 8.18..23.39, kinh độ 102.14..109.46)."
            ),
        )

    job = CrawlJob(
        keyword=keyword,
        lat=payload.lat,
        lng=payload.lng,
        status="PENDING",
        total_scraped=0,
        inserted_count=0,
        duplicate_count=0,
        created_at=datetime.now(timezone.utc),
    )
    db.add(job)
    db.commit()
    db.refresh(job)

    log_admin_action(
        db=db,
        actor=current_user,
        action="CRAWL_TRIGGER",
        entity_type="crawl_job",
        entity_id=job.id,
        summary=f"Kích hoạt AI Crawler Google Maps cho từ khóa '{keyword}' tại ({payload.lat}, {payload.lng})",
        changes={
            "job_id": job.id,
            "keyword": keyword,
            "lat": payload.lat,
            "lng": payload.lng,
            "province_id": payload.province_id,
        },
    )

    background_tasks.add_task(
        process_crawl_job,
        job.id,
        keyword,
        payload.lat,
        payload.lng,
        payload.province_id,
    )

    return CrawlTriggerResponse(
        job_id=job.id,
        status=job.status,
        keyword=job.keyword,
        lat=job.lat,
        lng=job.lng,
        message="Đã tạo tiến trình cào dữ liệu ngầm thành công.",
    )


@router.get("/crawl/{job_id}", response_model=CrawlJobOut)
def get_crawl_job_status(
    job_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_superuser),
):
    """Kiểm tra trạng thái hiện tại (`PENDING`, `RUNNING`, `COMPLETED`, `FAILED`) của một tiến trình cào."""
    job = db.get(CrawlJob, job_id)
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy tiến trình cào dữ liệu với job_id={job_id}.",
        )
    return _serialize_crawl_job(job)


@router.get("/crawl", response_model=List[CrawlJobOut])
def list_crawl_jobs(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_superuser),
):
    """Lấy danh sách lịch sử các tiến trình cào dữ liệu gần nhất."""
    stmt = select(CrawlJob).order_by(CrawlJob.id.desc()).limit(50)
    jobs = list(db.exec(stmt).all())
    return [_serialize_crawl_job(j) for j in jobs]
