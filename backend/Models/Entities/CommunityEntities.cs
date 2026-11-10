using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace TripFlow.Api.Models.Entities;

[Table("place_reviews")]
[Index(nameof(PlaceKey), Name = "ix_place_reviews_place_key")]
public class PlaceReview
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("place_key")]
    [MaxLength(120)]
    public string PlaceKey { get; set; } = string.Empty;

    [Column("user_id")]
    public int? UserId { get; set; }
    public User? User { get; set; }

    [Column("author_name")]
    [MaxLength(80)]
    public string AuthorName { get; set; } = "Khách";

    [Column("rating")]
    public int Rating { get; set; } = 5;

    [Column("comment")]
    [MaxLength(1000)]
    public string Comment { get; set; } = string.Empty;

    [Column("visited_on")]
    public DateTime? VisitedOn { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Column("is_hidden")]
    public bool IsHidden { get; set; } = false;
}

[Table("favorites")]
public class Favorite
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("user_id")]
    public int UserId { get; set; }
    public User? User { get; set; }

    [Column("target_type")]
    [MaxLength(40)]
    public string TargetType { get; set; } = "destination";

    [Column("target_id")]
    public int TargetId { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

[Table("content_reports")]
public class ContentReport
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("user_id")]
    public int? UserId { get; set; }
    public User? User { get; set; }

    [Column("target_type")]
    [MaxLength(40)]
    public string TargetType { get; set; } = "destination";

    [Column("target_id")]
    public int TargetId { get; set; }

    [Column("target_name")]
    [MaxLength(220)]
    public string TargetName { get; set; } = string.Empty;

    [Column("issue_type")]
    [MaxLength(80)]
    public string IssueType { get; set; } = string.Empty;

    [Column("description")]
    public string Description { get; set; } = string.Empty;

    [Column("rating")]
    public int? Rating { get; set; }

    [Column("status")]
    [MaxLength(30)]
    public string Status { get; set; } = "pending";

    [Column("moderator_note")]
    public string? ModeratorNote { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Column("resolved_at")]
    public DateTime? ResolvedAt { get; set; }
}

[Table("audit_logs")]
[Index(nameof(CreatedAt), Name = "ix_audit_logs_created_at")]
public class AuditLog
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("actor_id")]
    public int? ActorId { get; set; }
    public User? Actor { get; set; }

    [Column("actor_email")]
    [MaxLength(180)]
    public string ActorEmail { get; set; } = string.Empty;

    [Column("actor_role")]
    [MaxLength(60)]
    public string ActorRole { get; set; } = string.Empty;

    [Column("action")]
    [MaxLength(50)]
    public string Action { get; set; } = string.Empty;

    [Column("entity_type")]
    [MaxLength(60)]
    public string EntityType { get; set; } = string.Empty;

    [Column("entity_id")]
    public int? EntityId { get; set; }

    [Column("summary")]
    [MaxLength(400)]
    public string Summary { get; set; } = string.Empty;

    [Column("changes_json")]
    public string ChangesJson { get; set; } = "{}";

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

[Table("place_cache")]
[Index(nameof(Provider), Name = "ix_place_cache_provider")]
[Index(nameof(CacheKey), Name = "ix_place_cache_cache_key")]
public class PlaceCache
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("provider")]
    [MaxLength(16)]
    public string Provider { get; set; } = "goong";

    [Column("cache_key")]
    [MaxLength(200)]
    public string CacheKey { get; set; } = string.Empty;

    [Column("payload_json")]
    public string PayloadJson { get; set; } = "{}";

    [Column("fetched_at")]
    public DateTime FetchedAt { get; set; } = DateTime.UtcNow;

    [Column("expires_at")]
    public DateTime ExpiresAt { get; set; }
}

[Table("search_history")]
[Index(nameof(UserId), Name = "ix_search_history_user_id")]
public class SearchHistory
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("user_id")]
    public int? UserId { get; set; }
    public User? User { get; set; }

    [Column("query")]
    [MaxLength(200)]
    public string Query { get; set; } = string.Empty;

    [Column("kind")]
    [MaxLength(24)]
    public string Kind { get; set; } = "text";

    [Column("place_id")]
    [MaxLength(200)]
    public string? PlaceId { get; set; }

    [Column("lat")]
    public double? Lat { get; set; }

    [Column("lng")]
    public double? Lng { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

[Table("crawl_jobs")]
[Index(nameof(Keyword), Name = "ix_crawl_jobs_keyword")]
[Index(nameof(Status), Name = "ix_crawl_jobs_status")]
public class CrawlJob
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("keyword")]
    [MaxLength(250)]
    public string Keyword { get; set; } = string.Empty;

    [Column("lat")]
    public double Lat { get; set; }

    [Column("lng")]
    public double Lng { get; set; }

    [Column("status")]
    [MaxLength(30)]
    public string Status { get; set; } = "PENDING";

    [Column("total_scraped")]
    public int TotalScraped { get; set; } = 0;

    [Column("inserted_count")]
    public int InsertedCount { get; set; } = 0;

    [Column("duplicate_count")]
    public int DuplicateCount { get; set; } = 0;

    [Column("error_message")]
    public string? ErrorMessage { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Column("completed_at")]
    public DateTime? CompletedAt { get; set; }
}
