using System.Text.Json.Serialization;

namespace TripFlow.Api.Models.DTOs;

public class ProvinceDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("code")]
    public string Code { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("region")]
    public string Region { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("hero_image")]
    public string? HeroImage { get; set; }

    [JsonPropertyName("center_lat")]
    public double CenterLat { get; set; }

    [JsonPropertyName("center_lng")]
    public double CenterLng { get; set; }

    [JsonPropertyName("is_active")]
    public bool IsActive { get; set; } = true;

    [JsonPropertyName("destination_count")]
    public int DestinationCount { get; set; }

    [JsonPropertyName("food_count")]
    public int FoodCount { get; set; }

    [JsonPropertyName("restaurant_count")]
    public int RestaurantCount { get; set; }
}

public class RegionSummaryDto
{
    [JsonPropertyName("region")]
    public string Region { get; set; } = string.Empty;

    [JsonPropertyName("province_count")]
    public int ProvinceCount { get; set; }

    [JsonPropertyName("provinces")]
    public List<ProvinceDto> Provinces { get; set; } = new();
}

public class CategoryDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("code")]
    public string Code { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("icon_name")]
    public string IconName { get; set; } = "place";

    [JsonPropertyName("description")]
    public string? Description { get; set; }
}

public class DestinationImageDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("destination_id")]
    public int DestinationId { get; set; }

    [JsonPropertyName("image_url")]
    public string ImageUrl { get; set; } = string.Empty;

    [JsonPropertyName("thumbnail_url")]
    public string? ThumbnailUrl { get; set; }

    [JsonPropertyName("caption")]
    public string? Caption { get; set; }

    [JsonPropertyName("sort_order")]
    public int SortOrder { get; set; } = 1;

    [JsonPropertyName("license_type")]
    public string LicenseType { get; set; } = "owned";

    [JsonPropertyName("credit_author")]
    public string CreditAuthor { get; set; } = "TripFlow Studio";
}

public class DestinationDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("province_id")]
    public int ProvinceId { get; set; }

    [JsonPropertyName("province_name")]
    public string? ProvinceName { get; set; }

    [JsonPropertyName("category_id")]
    public int? CategoryId { get; set; }

    [JsonPropertyName("category_name")]
    public string? CategoryName { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("slug")]
    public string? Slug { get; set; }

    [JsonPropertyName("description")]
    public string Description { get; set; } = string.Empty;

    [JsonPropertyName("address")]
    public string Address { get; set; } = string.Empty;

    [JsonPropertyName("latitude")]
    public double Latitude { get; set; }

    [JsonPropertyName("longitude")]
    public double Longitude { get; set; }

    [JsonPropertyName("opening_hours")]
    public string OpeningHours { get; set; } = "07:30 - 17:30";

    [JsonPropertyName("ticket_price_info")]
    public string TicketPriceInfo { get; set; } = "Miễn phí";

    [JsonPropertyName("rating")]
    public double Rating { get; set; } = 4.7;

    [JsonPropertyName("review_count")]
    public int ReviewCount { get; set; } = 120;

    [JsonPropertyName("recommended_duration_mins")]
    public int RecommendedDurationMins { get; set; } = 90;

    [JsonPropertyName("thumbnail_url")]
    public string? ThumbnailUrl { get; set; }

    [JsonPropertyName("detail_image_url")]
    public string? DetailImageUrl { get; set; }

    [JsonPropertyName("is_featured")]
    public bool IsFeatured { get; set; }

    [JsonPropertyName("is_sponsored")]
    public bool IsSponsored { get; set; }

    [JsonPropertyName("sponsor_label")]
    public string? SponsorLabel { get; set; }

    [JsonPropertyName("is_verified")]
    public bool IsVerified { get; set; }

    [JsonPropertyName("source")]
    public string Source { get; set; } = "admin";

    [JsonPropertyName("source_url")]
    public string? SourceUrl { get; set; }

    [JsonPropertyName("status")]
    public string Status { get; set; } = "published";

    [JsonPropertyName("data_source")]
    public string DataSource { get; set; } = "internal";

    [JsonPropertyName("source_attribution")]
    public string SourceAttribution { get; set; } = "Ban Biên Tập TripFlow";

    [JsonPropertyName("images")]
    public List<DestinationImageDto> Images { get; set; } = new();
}

public class DestinationDetailDto : DestinationDto
{
    [JsonPropertyName("related_destinations")]
    public List<DestinationDto> RelatedDestinations { get; set; } = new();
}

public class RestaurantDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("province_id")]
    public int ProvinceId { get; set; }

    [JsonPropertyName("province_name")]
    public string? ProvinceName { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("address")]
    public string Address { get; set; } = string.Empty;

    [JsonPropertyName("latitude")]
    public double Latitude { get; set; }

    [JsonPropertyName("longitude")]
    public double Longitude { get; set; }

    [JsonPropertyName("cuisine_type")]
    public string CuisineType { get; set; } = "Đặc sản";

    [JsonPropertyName("specialty_dishes")]
    public string? SpecialtyDishes { get; set; }

    [JsonPropertyName("price_range")]
    public string PriceRange { get; set; } = "45.000đ - 120.000đ";

    [JsonPropertyName("opening_hours")]
    public string OpeningHours { get; set; } = "06:30 - 22:00";

    [JsonPropertyName("contact_phone")]
    public string? ContactPhone { get; set; }

    [JsonPropertyName("rating")]
    public double Rating { get; set; } = 4.6;

    [JsonPropertyName("review_count")]
    public int ReviewCount { get; set; } = 150;

    [JsonPropertyName("reviews_count")]
    public int ReviewsCount { get; set; } = 120;

    [JsonPropertyName("is_high_rated")]
    public bool IsHighRated { get; set; } = true;

    [JsonPropertyName("specialties")]
    public string? Specialties { get; set; }

    [JsonPropertyName("image_url")]
    public string? ImageUrl { get; set; }

    [JsonPropertyName("thumbnail_url")]
    public string? ThumbnailUrl { get; set; }

    [JsonPropertyName("image_credit")]
    public string? ImageCredit { get; set; }

    [JsonPropertyName("image_license")]
    public string? ImageLicense { get; set; }

    [JsonPropertyName("image_source_url")]
    public string? ImageSourceUrl { get; set; }

    [JsonPropertyName("is_sponsored")]
    public bool IsSponsored { get; set; }

    [JsonPropertyName("sponsor_label")]
    public string? SponsorLabel { get; set; }

    [JsonPropertyName("is_verified")]
    public bool IsVerified { get; set; }

    [JsonPropertyName("source")]
    public string Source { get; set; } = "admin";

    [JsonPropertyName("source_url")]
    public string? SourceUrl { get; set; }

    [JsonPropertyName("status")]
    public string Status { get; set; } = "published";

    [JsonPropertyName("sample_reviews")]
    public List<object> SampleReviews { get; set; } = new();
}

public class LocalFoodDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("province_id")]
    public int ProvinceId { get; set; }

    [JsonPropertyName("province_name")]
    public string? ProvinceName { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string Description { get; set; } = string.Empty;

    [JsonPropertyName("story_origin")]
    public string? StoryOrigin { get; set; }

    [JsonPropertyName("image_url")]
    public string? ImageUrl { get; set; }

    [JsonPropertyName("thumbnail_url")]
    public string? ThumbnailUrl { get; set; }

    [JsonPropertyName("best_season_or_time")]
    public string BestSeasonOrTime { get; set; } = "Quanh năm";

    [JsonPropertyName("avg_price_range")]
    public string AvgPriceRange { get; set; } = "40.000đ - 85.000đ";

    [JsonPropertyName("status")]
    public string Status { get; set; } = "published";

    [JsonPropertyName("recommended_restaurants")]
    public List<RestaurantDto> RecommendedRestaurants { get; set; } = new();
}

public class RestStopDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("province_id")]
    public int ProvinceId { get; set; }

    [JsonPropertyName("category")]
    public string Category { get; set; } = "rest";

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("address")]
    public string Address { get; set; } = string.Empty;

    [JsonPropertyName("latitude")]
    public double Latitude { get; set; }

    [JsonPropertyName("longitude")]
    public double Longitude { get; set; }

    [JsonPropertyName("opening_hours")]
    public string OpeningHours { get; set; } = string.Empty;

    [JsonPropertyName("phone")]
    public string? Phone { get; set; }

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("brand")]
    public string? Brand { get; set; }

    [JsonPropertyName("image_url")]
    public string? ImageUrl { get; set; }

    [JsonPropertyName("thumbnail_url")]
    public string? ThumbnailUrl { get; set; }

    [JsonPropertyName("rating")]
    public double Rating { get; set; } = 4.5;

    [JsonPropertyName("review_count")]
    public int ReviewCount { get; set; } = 0;

    [JsonPropertyName("is_verified")]
    public bool IsVerified { get; set; }
}

public class ReportRequest
{
    [JsonPropertyName("issue_type")]
    public string IssueType { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string Description { get; set; } = string.Empty;

    [JsonPropertyName("rating")]
    public int? Rating { get; set; }
}
