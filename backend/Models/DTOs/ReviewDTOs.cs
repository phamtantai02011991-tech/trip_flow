using System.Text.Json.Serialization;

namespace TripFlow.Api.Models.DTOs;

public class CreateReviewRequest
{
    [JsonPropertyName("rating")]
    public int Rating { get; set; } = 5;

    [JsonPropertyName("comment")]
    public string Comment { get; set; } = string.Empty;

    [JsonPropertyName("author_name")]
    public string? AuthorName { get; set; }
}

public class ReviewDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("place_key")]
    public string PlaceKey { get; set; } = string.Empty;

    [JsonPropertyName("author_name")]
    public string AuthorName { get; set; } = "Khách";

    [JsonPropertyName("rating")]
    public int Rating { get; set; } = 5;

    [JsonPropertyName("comment")]
    public string Comment { get; set; } = string.Empty;

    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; }
}

public class ReviewSummaryDto
{
    [JsonPropertyName("place_key")]
    public string PlaceKey { get; set; } = string.Empty;

    [JsonPropertyName("avg_rating")]
    public double AvgRating { get; set; } = 0.0;

    [JsonPropertyName("review_count")]
    public int ReviewCount { get; set; } = 0;

    [JsonPropertyName("distribution")]
    public Dictionary<string, int> Distribution { get; set; } = new()
    {
        { "1", 0 }, { "2", 0 }, { "3", 0 }, { "4", 0 }, { "5", 0 }
    };

    [JsonPropertyName("hidden_gem")]
    public bool HiddenGem { get; set; } = false;
}

public class FavoriteDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("target_type")]
    public string TargetType { get; set; } = "destination";

    [JsonPropertyName("target_id")]
    public int TargetId { get; set; }

    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; }

    [JsonPropertyName("target")]
    public object? Target { get; set; }
}

public class FavoriteToggleRequest
{
    [JsonPropertyName("target_type")]
    public string TargetType { get; set; } = "destination";

    [JsonPropertyName("target_id")]
    public int TargetId { get; set; }
}

public class FavoriteToggleResponse
{
    [JsonPropertyName("favorited")]
    public bool Favorited { get; set; }

    [JsonPropertyName("favorite_id")]
    public int? FavoriteId { get; set; }
}
