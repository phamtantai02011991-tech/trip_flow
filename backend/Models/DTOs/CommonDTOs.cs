using System.Text.Json.Serialization;

namespace TripFlow.Api.Models.DTOs;

public class PaginatedResponse<T>
{
    [JsonPropertyName("total")]
    public int Total { get; set; }

    [JsonPropertyName("page")]
    public int Page { get; set; } = 1;

    [JsonPropertyName("page_size")]
    public int PageSize { get; set; } = 20;

    [JsonPropertyName("total_pages")]
    public int TotalPages => PageSize > 0 ? (int)Math.Ceiling((double)Total / PageSize) : 0;

    [JsonPropertyName("items")]
    public List<T> Items { get; set; } = new();
}

public class ErrorEnvelope
{
    [JsonPropertyName("detail")]
    public object Detail { get; set; } = string.Empty;

    public ErrorEnvelope() { }

    public ErrorEnvelope(string message)
    {
        Detail = message;
    }

    public ErrorEnvelope(object structured)
    {
        Detail = structured;
    }
}

public class StatusResponse
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = "ok";

    [JsonPropertyName("message")]
    public string? Message { get; set; }
}

public class HealthResponse
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = "ok";

    [JsonPropertyName("timestamp")]
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    [JsonPropertyName("version")]
    public string Version { get; set; } = "1.0.0";
}

public class ReadyResponse
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = "ok";

    [JsonPropertyName("database")]
    public string Database { get; set; } = "ok";

    [JsonPropertyName("timestamp")]
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
