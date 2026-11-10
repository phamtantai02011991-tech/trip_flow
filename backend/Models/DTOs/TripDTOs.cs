using System.Text.Json.Serialization;

namespace TripFlow.Api.Models.DTOs;

public class CreateTripRequest
{
    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("origin_name")]
    public string OriginName { get; set; } = string.Empty;

    [JsonPropertyName("origin_lat")]
    public double OriginLat { get; set; }

    [JsonPropertyName("origin_lng")]
    public double OriginLng { get; set; }

    [JsonPropertyName("destination_name")]
    public string? DestinationName { get; set; }

    [JsonPropertyName("destination_lat")]
    public double? DestinationLat { get; set; }

    [JsonPropertyName("destination_lng")]
    public double? DestinationLng { get; set; }

    [JsonPropertyName("province_id")]
    public int? ProvinceId { get; set; }

    [JsonPropertyName("start_date")]
    public DateOnly? StartDate { get; set; }

    [JsonPropertyName("total_days")]
    public int TotalDays { get; set; } = 1;

    [JsonPropertyName("party_size")]
    public int PartySize { get; set; } = 2;

    [JsonPropertyName("vehicle")]
    public string Vehicle { get; set; } = "motorbike";

    [JsonPropertyName("budget_level")]
    public string BudgetLevel { get; set; } = "balanced";

    [JsonPropertyName("budget_amount")]
    public int? BudgetAmount { get; set; }

    [JsonPropertyName("preferences")]
    public List<string>? Preferences { get; set; }
}

public class UpdateTripRequest
{
    [JsonPropertyName("title")]
    public string? Title { get; set; }

    [JsonPropertyName("origin_name")]
    public string? OriginName { get; set; }

    [JsonPropertyName("destination_name")]
    public string? DestinationName { get; set; }

    [JsonPropertyName("start_date")]
    public DateOnly? StartDate { get; set; }

    [JsonPropertyName("total_days")]
    public int? TotalDays { get; set; }

    [JsonPropertyName("party_size")]
    public int? PartySize { get; set; }

    [JsonPropertyName("vehicle")]
    public string? Vehicle { get; set; }

    [JsonPropertyName("budget_level")]
    public string? BudgetLevel { get; set; }

    [JsonPropertyName("budget_amount")]
    public int? BudgetAmount { get; set; }

    [JsonPropertyName("status")]
    public string? Status { get; set; }

    [JsonPropertyName("preferences")]
    public List<string>? Preferences { get; set; }
}

public class TripStopDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("trip_day_id")]
    public int TripDayId { get; set; }

    [JsonPropertyName("trip_id")]
    public int TripId { get; set; }

    [JsonPropertyName("stop_order")]
    public int StopOrder { get; set; }

    [JsonPropertyName("kind")]
    public string Kind { get; set; } = "destination";

    [JsonPropertyName("place_id")]
    public string? PlaceId { get; set; }

    [JsonPropertyName("ref_table")]
    public string? RefTable { get; set; }

    [JsonPropertyName("ref_id")]
    public int? RefId { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("address")]
    public string Address { get; set; } = string.Empty;

    [JsonPropertyName("lat")]
    public double Lat { get; set; }

    [JsonPropertyName("lng")]
    public double Lng { get; set; }

    [JsonPropertyName("arrive_at")]
    public DateTime? ArriveAt { get; set; }

    [JsonPropertyName("stay_mins")]
    public int StayMins { get; set; } = 60;

    [JsonPropertyName("travel_mins_from_prev")]
    public int? TravelMinsFromPrev { get; set; }

    [JsonPropertyName("distance_km_from_prev")]
    public double? DistanceKmFromPrev { get; set; }

    [JsonPropertyName("est_cost")]
    public int? EstCost { get; set; }

    [JsonPropertyName("note")]
    public string? Note { get; set; }

    [JsonPropertyName("source")]
    public string Source { get; set; } = "manual";
}

public class TripDayDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("trip_id")]
    public int TripId { get; set; }

    [JsonPropertyName("day_number")]
    public int DayNumber { get; set; }

    [JsonPropertyName("date")]
    public DateOnly? Date { get; set; }

    [JsonPropertyName("title")]
    public string? Title { get; set; }

    [JsonPropertyName("note")]
    public string? Note { get; set; }

    [JsonPropertyName("stops")]
    public List<TripStopDto> Stops { get; set; } = new();
}

public class ExpenseDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("trip_id")]
    public int TripId { get; set; }

    [JsonPropertyName("trip_day_id")]
    public int? TripDayId { get; set; }

    [JsonPropertyName("category")]
    public string Category { get; set; } = "other";

    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("amount")]
    public int Amount { get; set; }

    [JsonPropertyName("planned")]
    public bool Planned { get; set; } = true;

    [JsonPropertyName("spent_at")]
    public DateTime? SpentAt { get; set; }

    [JsonPropertyName("paid_by")]
    public string? PaidBy { get; set; }

    [JsonPropertyName("note")]
    public string? Note { get; set; }

    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; }
}

public class TripDetailDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("user_id")]
    public int? UserId { get; set; }

    [JsonPropertyName("province_id")]
    public int? ProvinceId { get; set; }

    [JsonPropertyName("province_name")]
    public string? ProvinceName { get; set; }

    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("origin_name")]
    public string OriginName { get; set; } = string.Empty;

    [JsonPropertyName("origin_lat")]
    public double OriginLat { get; set; }

    [JsonPropertyName("origin_lng")]
    public double OriginLng { get; set; }

    [JsonPropertyName("destination_name")]
    public string? DestinationName { get; set; }

    [JsonPropertyName("destination_lat")]
    public double? DestinationLat { get; set; }

    [JsonPropertyName("destination_lng")]
    public double? DestinationLng { get; set; }

    [JsonPropertyName("start_date")]
    public DateOnly? StartDate { get; set; }

    [JsonPropertyName("total_days")]
    public int TotalDays { get; set; }

    [JsonPropertyName("party_size")]
    public int PartySize { get; set; }

    [JsonPropertyName("vehicle")]
    public string Vehicle { get; set; } = "motorbike";

    [JsonPropertyName("budget_level")]
    public string BudgetLevel { get; set; } = "balanced";

    [JsonPropertyName("budget_amount")]
    public int? BudgetAmount { get; set; }

    [JsonPropertyName("preferences")]
    public List<string> Preferences { get; set; } = new();

    [JsonPropertyName("status")]
    public string Status { get; set; } = "draft";

    [JsonPropertyName("share_token")]
    public string? ShareToken { get; set; }

    [JsonPropertyName("ai_generated")]
    public bool AiGenerated { get; set; }

    [JsonPropertyName("days")]
    public List<TripDayDto> Days { get; set; } = new();

    [JsonPropertyName("expenses")]
    public List<ExpenseDto> Expenses { get; set; } = new();

    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; }

    [JsonPropertyName("updated_at")]
    public DateTime UpdatedAt { get; set; }
}

public class AddStopRequest
{
    [JsonPropertyName("kind")]
    public string Kind { get; set; } = "destination";

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("lat")]
    public double Lat { get; set; }

    [JsonPropertyName("lng")]
    public double Lng { get; set; }

    [JsonPropertyName("address")]
    public string? Address { get; set; }

    [JsonPropertyName("place_id")]
    public string? PlaceId { get; set; }

    [JsonPropertyName("ref_table")]
    public string? RefTable { get; set; }

    [JsonPropertyName("ref_id")]
    public int? RefId { get; set; }

    [JsonPropertyName("stay_mins")]
    public int? StayMins { get; set; } = 60;

    [JsonPropertyName("est_cost")]
    public int? EstCost { get; set; }

    [JsonPropertyName("note")]
    public string? Note { get; set; }
}

public class ReorderStopsRequest
{
    [JsonPropertyName("stop_ids")]
    public List<int> StopIds { get; set; } = new();
}

public class ShareTripResponse
{
    [JsonPropertyName("share_token")]
    public string ShareToken { get; set; } = string.Empty;

    [JsonPropertyName("share_url")]
    public string ShareUrl { get; set; } = string.Empty;
}

public class ExpenseCreateRequest
{
    [JsonPropertyName("trip_day_id")]
    public int? TripDayId { get; set; }

    [JsonPropertyName("category")]
    public string Category { get; set; } = "other";

    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("amount")]
    public int Amount { get; set; }

    [JsonPropertyName("planned")]
    public bool Planned { get; set; } = true;

    [JsonPropertyName("spent_at")]
    public DateTime? SpentAt { get; set; }

    [JsonPropertyName("paid_by")]
    public string? PaidBy { get; set; }

    [JsonPropertyName("note")]
    public string? Note { get; set; }
}

public class ExpenseUpdateRequest
{
    [JsonPropertyName("trip_day_id")]
    public int? TripDayId { get; set; }

    [JsonPropertyName("category")]
    public string? Category { get; set; }

    [JsonPropertyName("title")]
    public string? Title { get; set; }

    [JsonPropertyName("amount")]
    public int? Amount { get; set; }

    [JsonPropertyName("planned")]
    public bool? Planned { get; set; }

    [JsonPropertyName("spent_at")]
    public DateTime? SpentAt { get; set; }

    [JsonPropertyName("paid_by")]
    public string? PaidBy { get; set; }

    [JsonPropertyName("note")]
    public string? Note { get; set; }
}

public class BudgetSummaryResponse
{
    [JsonPropertyName("budget_amount")]
    public int BudgetAmount { get; set; }

    [JsonPropertyName("total_spent")]
    public int TotalSpent { get; set; }

    [JsonPropertyName("remaining")]
    public int Remaining => BudgetAmount - TotalSpent;

    [JsonPropertyName("is_over_budget")]
    public bool IsOverBudget => TotalSpent > BudgetAmount && BudgetAmount > 0;

    [JsonPropertyName("categories")]
    public Dictionary<string, int> Categories { get; set; } = new();
}

public class ItineraryStopDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("itinerary_id")]
    public int ItineraryId { get; set; }

    [JsonPropertyName("day_number")]
    public int DayNumber { get; set; } = 1;

    [JsonPropertyName("stop_order")]
    public int StopOrder { get; set; } = 1;

    [JsonPropertyName("stop_type")]
    public string StopType { get; set; } = "destination";

    [JsonPropertyName("reference_id")]
    public int? ReferenceId { get; set; }

    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("address")]
    public string? Address { get; set; }

    [JsonPropertyName("latitude")]
    public double Latitude { get; set; }

    [JsonPropertyName("longitude")]
    public double Longitude { get; set; }

    [JsonPropertyName("planned_time")]
    public string PlannedTime { get; set; } = "08:30 - 10:00";

    [JsonPropertyName("duration_mins")]
    public int DurationMins { get; set; } = 90;

    [JsonPropertyName("notes")]
    public string? Notes { get; set; }
}

public class ItineraryDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("user_id")]
    public int? UserId { get; set; }

    [JsonPropertyName("province_id")]
    public int ProvinceId { get; set; }

    [JsonPropertyName("province_name")]
    public string? ProvinceName { get; set; }

    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("total_days")]
    public int TotalDays { get; set; } = 1;

    [JsonPropertyName("is_template")]
    public bool IsTemplate { get; set; }

    [JsonPropertyName("status")]
    public string Status { get; set; } = "active";

    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; }

    [JsonPropertyName("updated_at")]
    public DateTime UpdatedAt { get; set; }

    [JsonPropertyName("stops")]
    public List<ItineraryStopDto> Stops { get; set; } = new();
}

public class CreateItineraryRequest
{
    [JsonPropertyName("province_id")]
    public int ProvinceId { get; set; }

    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("total_days")]
    public int TotalDays { get; set; } = 1;

    [JsonPropertyName("is_template")]
    public bool? IsTemplate { get; set; } = false;

    [JsonPropertyName("stops")]
    public List<ItineraryStopDto>? Stops { get; set; }
}

public class SyncItineraryRequest
{
    [JsonPropertyName("itineraries")]
    public List<CreateItineraryRequest> Itineraries { get; set; } = new();
}

public class SmartMealStopsRequest
{
    [JsonPropertyName("day_number")]
    public int DayNumber { get; set; } = 1;

    [JsonPropertyName("meal_type")]
    public string MealType { get; set; } = "lunch"; // lunch | dinner

    [JsonPropertyName("max_detour_km")]
    public double MaxDetourKm { get; set; } = 2.0;
}

public class GenerateItineraryResponse
{
    [JsonPropertyName("trip_id")]
    public int TripId { get; set; }

    [JsonPropertyName("status")]
    public string Status { get; set; } = "completed";

    [JsonPropertyName("message")]
    public string Message { get; set; } = "Lịch trình đã được khởi tạo tự động thành công.";
}

public class AiStatusResponse
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = "ready";

    [JsonPropertyName("progress_pct")]
    public int ProgressPct { get; set; } = 100;

    [JsonPropertyName("message")]
    public string Message { get; set; } = "Hoàn tất";
}
