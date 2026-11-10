using System.Text.Json.Serialization;

namespace TripFlow.Api.Models.DTOs;

public class NearbyPlaceItem
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("kind")]
    public string Kind { get; set; } = "sight";

    [JsonPropertyName("category_name")]
    public string? CategoryName { get; set; }

    [JsonPropertyName("address")]
    public string Address { get; set; } = string.Empty;

    [JsonPropertyName("lat")]
    public double Lat { get; set; }

    [JsonPropertyName("lng")]
    public double Lng { get; set; }

    [JsonPropertyName("distance_km")]
    public double DistanceKm { get; set; }

    [JsonPropertyName("rating")]
    public double Rating { get; set; }

    [JsonPropertyName("review_count")]
    public int ReviewCount { get; set; }

    [JsonPropertyName("price_range")]
    public string? PriceRange { get; set; }

    [JsonPropertyName("image_url")]
    public string? ImageUrl { get; set; }

    [JsonPropertyName("quality")]
    public string Quality { get; set; } = "normal";

    [JsonPropertyName("is_verified")]
    public bool IsVerified { get; set; }
}

public class NearbyResponse
{
    [JsonPropertyName("total")]
    public int Total { get; set; }

    [JsonPropertyName("items")]
    public List<NearbyPlaceItem> Items { get; set; } = new();
}

public class PlaceSuggestItem
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("kind")]
    public string Kind { get; set; } = "destination";

    [JsonPropertyName("address")]
    public string Address { get; set; } = string.Empty;

    [JsonPropertyName("province_name")]
    public string? ProvinceName { get; set; }

    [JsonPropertyName("lat")]
    public double Lat { get; set; }

    [JsonPropertyName("lng")]
    public double Lng { get; set; }
}

public class AlongRouteRequest
{
    [JsonPropertyName("origin_lat")]
    public double OriginLat { get; set; }

    [JsonPropertyName("origin_lng")]
    public double OriginLng { get; set; }

    [JsonPropertyName("dest_lat")]
    public double DestLat { get; set; }

    [JsonPropertyName("dest_lng")]
    public double DestLng { get; set; }

    [JsonPropertyName("corridor_radius_km")]
    public double CorridorRadiusKm { get; set; } = 2.0;

    [JsonPropertyName("kinds")]
    public string Kinds { get; set; } = "rest,gas,ev,cafe";

    [JsonPropertyName("polyline")]
    public string? Polyline { get; set; }
}

public class AlongRouteStop
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("kind")]
    public string Kind { get; set; } = "rest";

    [JsonPropertyName("lat")]
    public double Lat { get; set; }

    [JsonPropertyName("lng")]
    public double Lng { get; set; }

    [JsonPropertyName("address")]
    public string Address { get; set; } = string.Empty;

    [JsonPropertyName("distance_to_route_km")]
    public double DistanceToRouteKm { get; set; }

    [JsonPropertyName("detour_distance_km")]
    public double DetourDistanceKm { get; set; }

    [JsonPropertyName("estimated_detour_mins")]
    public int EstimatedDetourMins { get; set; }

    [JsonPropertyName("route_progress_pct")]
    public double RouteProgressPct { get; set; }

    [JsonPropertyName("rating")]
    public double Rating { get; set; }

    [JsonPropertyName("image_url")]
    public string? ImageUrl { get; set; }
}

public class AlongRouteResponse
{
    [JsonPropertyName("count")]
    public int Count { get; set; }

    [JsonPropertyName("corridor_radius_km")]
    public double CorridorRadiusKm { get; set; }

    [JsonPropertyName("route_distance_km")]
    public double RouteDistanceKm { get; set; }

    [JsonPropertyName("stops")]
    public List<AlongRouteStop> Stops { get; set; } = new();
}

public class CorridorSearchRequest
{
    [JsonPropertyName("origin_lat")]
    public double OriginLat { get; set; }

    [JsonPropertyName("origin_lng")]
    public double OriginLng { get; set; }

    [JsonPropertyName("dest_lat")]
    public double DestLat { get; set; }

    [JsonPropertyName("dest_lng")]
    public double DestLng { get; set; }

    [JsonPropertyName("corridor_radius_km")]
    public double CorridorRadiusKm { get; set; } = 2.0;

    [JsonPropertyName("cuisine_type")]
    public string? CuisineType { get; set; }

    [JsonPropertyName("min_rating")]
    public double? MinRating { get; set; }
}

public class CorridorSearchResult
{
    [JsonPropertyName("restaurant")]
    public RestaurantDto Restaurant { get; set; } = new();

    [JsonPropertyName("distance_to_route_km")]
    public double DistanceToRouteKm { get; set; }

    [JsonPropertyName("detour_distance_km")]
    public double DetourDistanceKm { get; set; }

    [JsonPropertyName("estimated_detour_mins")]
    public int EstimatedDetourMins { get; set; }

    [JsonPropertyName("route_progress_pct")]
    public double RouteProgressPct { get; set; }

    [JsonPropertyName("sfcs_score")]
    public double SfcsScore { get; set; }
}

public class CorridorSearchResponse
{
    [JsonPropertyName("count")]
    public int Count { get; set; }

    [JsonPropertyName("corridor_radius_km")]
    public double CorridorRadiusKm { get; set; }

    [JsonPropertyName("items")]
    public List<CorridorSearchResult> Items { get; set; } = new();
}

public class SearchHistoryItemDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("query")]
    public string Query { get; set; } = string.Empty;

    [JsonPropertyName("kind")]
    public string Kind { get; set; } = "text";

    [JsonPropertyName("place_id")]
    public string? PlaceId { get; set; }

    [JsonPropertyName("lat")]
    public double? Lat { get; set; }

    [JsonPropertyName("lng")]
    public double? Lng { get; set; }

    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; }
}

public class CreateSearchHistoryRequest
{
    [JsonPropertyName("query")]
    public string Query { get; set; } = string.Empty;

    [JsonPropertyName("kind")]
    public string? Kind { get; set; } = "text";

    [JsonPropertyName("place_id")]
    public string? PlaceId { get; set; }

    [JsonPropertyName("lat")]
    public double? Lat { get; set; }

    [JsonPropertyName("lng")]
    public double? Lng { get; set; }
}
