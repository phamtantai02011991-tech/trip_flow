using System.Text.Json.Serialization;

namespace TripFlow.Api.Models.DTOs;

public class AdminDashboardResponse
{
    [JsonPropertyName("total_provinces")]
    public int TotalProvinces { get; set; }

    [JsonPropertyName("total_destinations")]
    public int TotalDestinations { get; set; }

    [JsonPropertyName("total_restaurants")]
    public int TotalRestaurants { get; set; }

    [JsonPropertyName("total_local_foods")]
    public int TotalLocalFoods { get; set; }

    [JsonPropertyName("total_itineraries")]
    public int TotalItineraries { get; set; }

    [JsonPropertyName("total_users")]
    public int TotalUsers { get; set; }

    [JsonPropertyName("pending_reports")]
    public int PendingReports { get; set; }

    [JsonPropertyName("data_sources")]
    public Dictionary<string, int> DataSources { get; set; } = new();

    [JsonPropertyName("maps_api_quota")]
    public object MapsApiQuota { get; set; } = new
    {
        provider = "Goong Maps",
        used_today = 42,
        daily_limit = 2500,
        remaining = 2458
    };

    [JsonPropertyName("recent_audit_logs")]
    public List<AuditLogDto> RecentAuditLogs { get; set; } = new();
}

public class AuditLogDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("actor_email")]
    public string ActorEmail { get; set; } = string.Empty;

    [JsonPropertyName("actor_role")]
    public string ActorRole { get; set; } = string.Empty;

    [JsonPropertyName("action")]
    public string Action { get; set; } = string.Empty;

    [JsonPropertyName("entity_type")]
    public string EntityType { get; set; } = string.Empty;

    [JsonPropertyName("entity_id")]
    public int? EntityId { get; set; }

    [JsonPropertyName("summary")]
    public string Summary { get; set; } = string.Empty;

    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; }
}

public class ContentReportDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("user_id")]
    public int? UserId { get; set; }

    [JsonPropertyName("target_type")]
    public string TargetType { get; set; } = "destination";

    [JsonPropertyName("target_id")]
    public int TargetId { get; set; }

    [JsonPropertyName("target_name")]
    public string TargetName { get; set; } = string.Empty;

    [JsonPropertyName("issue_type")]
    public string IssueType { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string Description { get; set; } = string.Empty;

    [JsonPropertyName("rating")]
    public int? Rating { get; set; }

    [JsonPropertyName("status")]
    public string Status { get; set; } = "pending";

    [JsonPropertyName("moderator_note")]
    public string? ModeratorNote { get; set; }

    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; }

    [JsonPropertyName("resolved_at")]
    public DateTime? ResolvedAt { get; set; }
}

public class ResolveReportRequest
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = "resolved";

    [JsonPropertyName("moderator_note")]
    public string? ModeratorNote { get; set; }
}

public class UpdateUserRoleRequest
{
    [JsonPropertyName("role")]
    public string Role { get; set; } = "user";

    [JsonPropertyName("assigned_province_id")]
    public int? AssignedProvinceId { get; set; }
}

public class TriggerCrawlRequest
{
    [JsonPropertyName("keyword")]
    public string Keyword { get; set; } = string.Empty;

    [JsonPropertyName("lat")]
    public double Lat { get; set; }

    [JsonPropertyName("lng")]
    public double Lng { get; set; }
}

public class CrawlJobDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("keyword")]
    public string Keyword { get; set; } = string.Empty;

    [JsonPropertyName("lat")]
    public double Lat { get; set; }

    [JsonPropertyName("lng")]
    public double Lng { get; set; }

    [JsonPropertyName("status")]
    public string Status { get; set; } = "PENDING";

    [JsonPropertyName("total_scraped")]
    public int TotalScraped { get; set; }

    [JsonPropertyName("inserted_count")]
    public int InsertedCount { get; set; }

    [JsonPropertyName("duplicate_count")]
    public int DuplicateCount { get; set; }

    [JsonPropertyName("error_message")]
    public string? ErrorMessage { get; set; }

    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; }

    [JsonPropertyName("completed_at")]
    public DateTime? CompletedAt { get; set; }
}

public class UploadImageResponse
{
    [JsonPropertyName("url")]
    public string Url { get; set; } = string.Empty;

    [JsonPropertyName("thumbnail_url")]
    public string ThumbnailUrl { get; set; } = string.Empty;

    [JsonPropertyName("public_id")]
    public string PublicId { get; set; } = string.Empty;
}

public class ChatRequest
{
    [JsonPropertyName("message")]
    public string Message { get; set; } = string.Empty;

    [JsonPropertyName("province_id")]
    public int? ProvinceId { get; set; }

    [JsonPropertyName("trip_id")]
    public int? TripId { get; set; }
}

public class ChatResponse
{
    [JsonPropertyName("reply")]
    public string Reply { get; set; } = string.Empty;

    [JsonPropertyName("suggested_places")]
    public List<object> SuggestedPlaces { get; set; } = new();

    [JsonPropertyName("suggested_itinerary")]
    public object? SuggestedItinerary { get; set; }
}

public class DirectionsResponse
{
    [JsonPropertyName("distance_km")]
    public double DistanceKm { get; set; }

    [JsonPropertyName("duration_mins")]
    public int DurationMins { get; set; }

    [JsonPropertyName("polyline")]
    public string Polyline { get; set; } = string.Empty;

    [JsonPropertyName("steps")]
    public List<object> Steps { get; set; } = new();
}
