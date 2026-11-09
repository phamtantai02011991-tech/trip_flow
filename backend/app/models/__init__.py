"""SQLModel ORM models package."""

from app.models.crawl_job import CrawlJob
from app.models.destination import Destination, DestinationImage
from app.models.models import (
    AdminRole,
    AuditLog,
    Category,
    ContentReport,
    Favorite,
    Itinerary,
    ItineraryStop,
    LocalFood,
    Permission,
    Province,
    Role,
    RolePermissionLink,
    SMSOTPVerification,
    User,
)
from app.models.restaurant import Restaurant
from app.models.rest_stop import RestStop

__all__ = [
    "Province",
    "Category",
    "Destination",
    "DestinationImage",
    "LocalFood",
    "Restaurant",
    "RestStop",
    "CrawlJob",
    "Role",
    "Permission",
    "RolePermissionLink",
    "AdminRole",
    "User",
    "SMSOTPVerification",
    "Favorite",
    "Itinerary",
    "ItineraryStop",
    "ContentReport",
    "AuditLog",
]
