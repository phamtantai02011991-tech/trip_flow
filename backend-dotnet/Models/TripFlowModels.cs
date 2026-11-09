using System.Text.Json.Serialization;

namespace TripFlow.Api.Models;

public class Province
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
    public string Description { get; set; } = string.Empty;

    [JsonPropertyName("hero_image")]
    public string HeroImage { get; set; } = string.Empty;

    [JsonPropertyName("center_lat")]
    public double CenterLat { get; set; }

    [JsonPropertyName("center_lng")]
    public double CenterLng { get; set; }

    [JsonPropertyName("destination_count")]
    public int DestinationCount { get; set; }

    [JsonPropertyName("food_count")]
    public int FoodCount { get; set; }

    [JsonPropertyName("restaurant_count")]
    public int RestaurantCount { get; set; }
}

public class Destination
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("province_id")]
    public int ProvinceId { get; set; }

    [JsonPropertyName("province_name")]
    public string ProvinceName { get; set; } = string.Empty;

    [JsonPropertyName("category")]
    public string Category { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string Description { get; set; } = string.Empty;

    [JsonPropertyName("image_url")]
    public string ImageUrl { get; set; } = string.Empty;

    [JsonPropertyName("latitude")]
    public double Latitude { get; set; }

    [JsonPropertyName("longitude")]
    public double Longitude { get; set; }

    [JsonPropertyName("rating")]
    public double Rating { get; set; }

    [JsonPropertyName("reviews_count")]
    public int ReviewsCount { get; set; }

    [JsonPropertyName("address")]
    public string Address { get; set; } = string.Empty;

    [JsonPropertyName("ticket_price")]
    public double TicketPrice { get; set; }
}

public class RestaurantReview
{
    [JsonPropertyName("author")]
    public string Author { get; set; } = string.Empty;

    [JsonPropertyName("rating")]
    public double Rating { get; set; }

    [JsonPropertyName("text")]
    public string Text { get; set; } = string.Empty;
}

public class Restaurant
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("province_id")]
    public int ProvinceId { get; set; }

    [JsonPropertyName("province_name")]
    public string ProvinceName { get; set; } = string.Empty;

    [JsonPropertyName("cuisine_type")]
    public string CuisineType { get; set; } = string.Empty;

    [JsonPropertyName("specialties")]
    public string Specialties { get; set; } = string.Empty;

    [JsonPropertyName("specialty_dishes")]
    public string SpecialtyDishes { get; set; } = string.Empty;

    [JsonPropertyName("address")]
    public string Address { get; set; } = string.Empty;

    [JsonPropertyName("latitude")]
    public double Latitude { get; set; }

    [JsonPropertyName("longitude")]
    public double Longitude { get; set; }

    [JsonPropertyName("rating")]
    public double Rating { get; set; }

    [JsonPropertyName("reviews_count")]
    public int ReviewsCount { get; set; }

    [JsonPropertyName("price_range")]
    public string PriceRange { get; set; } = string.Empty;

    [JsonPropertyName("image_url")]
    public string ImageUrl { get; set; } = string.Empty;

    [JsonPropertyName("is_high_rated")]
    public bool IsHighRated { get; set; }

    [JsonPropertyName("sample_reviews")]
    public List<RestaurantReview> SampleReviews { get; set; } = new();
}

public class Hotel
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("province_id")]
    public int ProvinceId { get; set; }

    [JsonPropertyName("province_name")]
    public string ProvinceName { get; set; } = string.Empty;

    [JsonPropertyName("address")]
    public string Address { get; set; } = string.Empty;

    [JsonPropertyName("star_rating")]
    public double StarRating { get; set; }

    [JsonPropertyName("price_per_night")]
    public double PricePerNight { get; set; }

    [JsonPropertyName("image_url")]
    public string ImageUrl { get; set; } = string.Empty;

    [JsonPropertyName("has_wifi")]
    public bool HasWifi { get; set; } = true;

    [JsonPropertyName("has_pool")]
    public bool HasPool { get; set; }

    [JsonPropertyName("booking_partner")]
    public string BookingPartner { get; set; } = "Agoda";

    [JsonPropertyName("booking_url")]
    public string BookingUrl { get; set; } = string.Empty;
}

public class LocalFood
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("province_id")]
    public int ProvinceId { get; set; }

    [JsonPropertyName("province_name")]
    public string ProvinceName { get; set; } = string.Empty;

    [JsonPropertyName("price_from")]
    public double PriceFrom { get; set; }

    [JsonPropertyName("price_to")]
    public double PriceTo { get; set; }

    [JsonPropertyName("description")]
    public string Description { get; set; } = string.Empty;

    [JsonPropertyName("image_url")]
    public string ImageUrl { get; set; } = string.Empty;

    [JsonPropertyName("story_origin")]
    public string StoryOrigin { get; set; } = string.Empty;

    [JsonPropertyName("best_place_to_eat")]
    public string BestPlaceToEat { get; set; } = string.Empty;
}

public class ItineraryStop
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("stop_type")]
    public string StopType { get; set; } = "destination"; // destination, meal, hotel

    [JsonPropertyName("planned_time")]
    public string PlannedTime { get; set; } = "09:00";

    [JsonPropertyName("day_number")]
    public int DayNumber { get; set; } = 1;

    [JsonPropertyName("notes")]
    public string Notes { get; set; } = string.Empty;
}

public class Itinerary
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string Description { get; set; } = string.Empty;

    [JsonPropertyName("province_id")]
    public int ProvinceId { get; set; }

    [JsonPropertyName("province_name")]
    public string ProvinceName { get; set; } = string.Empty;

    [JsonPropertyName("days_count")]
    public int DaysCount { get; set; } = 3;

    [JsonPropertyName("total_budget")]
    public double TotalBudget { get; set; }

    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [JsonPropertyName("stops")]
    public List<ItineraryStop> Stops { get; set; } = new();
}

public class OtpRequestDto
{
    [JsonPropertyName("phone_number")]
    public string PhoneNumber { get; set; } = string.Empty;
}

public class OtpVerifyDto
{
    [JsonPropertyName("phone_number")]
    public string PhoneNumber { get; set; } = string.Empty;

    [JsonPropertyName("otp_code")]
    public string OtpCode { get; set; } = string.Empty;
}

public class UserDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; } = 1;

    [JsonPropertyName("phone_number")]
    public string PhoneNumber { get; set; } = string.Empty;

    [JsonPropertyName("full_name")]
    public string FullName { get; set; } = "Phạm Tấn Tài";

    [JsonPropertyName("role")]
    public string Role { get; set; } = "admin";
}

public class AssistantChatRequest
{
    [JsonPropertyName("question")]
    public string Question { get; set; } = string.Empty;

    [JsonPropertyName("trip_id")]
    public int? TripId { get; set; }
}

public class AssistantChatResponse
{
    [JsonPropertyName("reply")]
    public string Reply { get; set; } = string.Empty;

    [JsonPropertyName("tips")]
    public List<string> Tips { get; set; } = new();

    [JsonPropertyName("applied")]
    public List<object> Applied { get; set; } = new();

    [JsonPropertyName("rejected")]
    public List<object> Rejected { get; set; } = new();
}
