using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TripFlow.Api.Models.Entities;

public enum TripStatus
{
    draft,
    planned,
    active,
    completed,
    archived
}

public enum VehicleType
{
    motorbike,
    car,
    coach
}

public enum BudgetLevel
{
    saver,
    balanced,
    comfort
}

public enum StopKind
{
    destination,
    restaurant,
    cafe,
    hotel,
    gas,
    ev,
    rest,
    custom
}

public enum ExpenseCategory
{
    fuel,
    food,
    hotel,
    ticket,
    other
}

[Table("trips")]
public class Trip
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("user_id")]
    public int? UserId { get; set; }
    public User? User { get; set; }

    [Column("province_id")]
    public int? ProvinceId { get; set; }
    public Province? Province { get; set; }

    [Column("title")]
    [MaxLength(160)]
    public string Title { get; set; } = string.Empty;

    [Column("origin_name")]
    [MaxLength(200)]
    public string OriginName { get; set; } = string.Empty;

    [Column("origin_lat")]
    public double OriginLat { get; set; }

    [Column("origin_lng")]
    public double OriginLng { get; set; }

    [Column("destination_name")]
    [MaxLength(200)]
    public string? DestinationName { get; set; }

    [Column("destination_lat")]
    public double? DestinationLat { get; set; }

    [Column("destination_lng")]
    public double? DestinationLng { get; set; }

    [Column("start_date")]
    public DateOnly? StartDate { get; set; }

    [Column("total_days")]
    public int TotalDays { get; set; } = 1;

    [Column("party_size")]
    public int PartySize { get; set; } = 2;

    [Column("vehicle")]
    [MaxLength(30)]
    public string Vehicle { get; set; } = "motorbike";

    [Column("budget_level")]
    [MaxLength(30)]
    public string BudgetLevel { get; set; } = "balanced";

    [Column("budget_amount")]
    public int? BudgetAmount { get; set; }

    [Column("preferences_json")]
    public string PreferencesJson { get; set; } = "[]";

    [Column("status")]
    [MaxLength(30)]
    public string Status { get; set; } = "draft";

    [Column("share_token")]
    [MaxLength(100)]
    public string? ShareToken { get; set; }

    [Column("guest_token")]
    [MaxLength(64)]
    public string? GuestToken { get; set; }

    [Column("ai_generated")]
    public bool AiGenerated { get; set; } = false;

    [Column("generation_meta_json")]
    public string GenerationMetaJson { get; set; } = "{}";

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<TripDay> Days { get; set; } = new List<TripDay>();
    public ICollection<TripStop> Stops { get; set; } = new List<TripStop>();
    public ICollection<Expense> Expenses { get; set; } = new List<Expense>();
}

[Table("trip_days")]
public class TripDay
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("trip_id")]
    public int TripId { get; set; }
    public Trip? Trip { get; set; }

    [Column("day_number")]
    public int DayNumber { get; set; } = 1;

    [Column("date")]
    public DateOnly? Date { get; set; }

    [Column("title")]
    [MaxLength(200)]
    public string? Title { get; set; }

    [Column("note")]
    public string? Note { get; set; }

    public ICollection<TripStop> Stops { get; set; } = new List<TripStop>();
}

[Table("trip_stops")]
public class TripStop
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("trip_day_id")]
    public int TripDayId { get; set; }
    public TripDay? TripDay { get; set; }

    [Column("trip_id")]
    public int TripId { get; set; }
    public Trip? Trip { get; set; }

    [Column("stop_order")]
    public int StopOrder { get; set; } = 0;

    [Column("kind")]
    [MaxLength(24)]
    public string Kind { get; set; } = "destination";

    [Column("place_id")]
    [MaxLength(200)]
    public string? PlaceId { get; set; }

    [Column("ref_table")]
    [MaxLength(32)]
    public string? RefTable { get; set; }

    [Column("ref_id")]
    public int? RefId { get; set; }

    [Column("name")]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [Column("address")]
    [MaxLength(400)]
    public string Address { get; set; } = string.Empty;

    [Column("lat")]
    public double Lat { get; set; }

    [Column("lng")]
    public double Lng { get; set; }

    [Column("arrive_at")]
    public DateTime? ArriveAt { get; set; }

    [Column("stay_mins")]
    public int StayMins { get; set; } = 60;

    [Column("travel_mins_from_prev")]
    public int? TravelMinsFromPrev { get; set; }

    [Column("distance_km_from_prev")]
    public double? DistanceKmFromPrev { get; set; }

    [Column("est_cost")]
    public int? EstCost { get; set; }

    [Column("note")]
    public string? Note { get; set; }

    [Column("source")]
    [MaxLength(16)]
    public string Source { get; set; } = "manual";
}

[Table("expenses")]
public class Expense
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("trip_id")]
    public int TripId { get; set; }
    public Trip? Trip { get; set; }

    [Column("trip_day_id")]
    public int? TripDayId { get; set; }
    public TripDay? TripDay { get; set; }

    [Column("category")]
    [MaxLength(30)]
    public string Category { get; set; } = "other";

    [Column("title")]
    [MaxLength(160)]
    public string Title { get; set; } = string.Empty;

    [Column("amount")]
    public int Amount { get; set; } = 0;

    [Column("planned")]
    public bool Planned { get; set; } = true;

    [Column("spent_at")]
    public DateTime? SpentAt { get; set; }

    [Column("paid_by")]
    [MaxLength(80)]
    public string? PaidBy { get; set; }

    [Column("note")]
    public string? Note { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

[Table("itineraries")]
public class Itinerary
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("user_id")]
    public int? UserId { get; set; }
    public User? User { get; set; }

    [Column("province_id")]
    public int ProvinceId { get; set; }
    public Province? Province { get; set; }

    [Column("title")]
    [MaxLength(220)]
    public string Title { get; set; } = string.Empty;

    [Column("description")]
    public string? Description { get; set; }

    [Column("total_days")]
    public int TotalDays { get; set; } = 1;

    [Column("is_template")]
    public bool IsTemplate { get; set; } = false;

    [Column("status")]
    [MaxLength(30)]
    public string Status { get; set; } = "active";

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<ItineraryStop> Stops { get; set; } = new List<ItineraryStop>();
}

[Table("itinerary_stops")]
public class ItineraryStop
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("itinerary_id")]
    public int ItineraryId { get; set; }
    public Itinerary? Itinerary { get; set; }

    [Column("day_number")]
    public int DayNumber { get; set; } = 1;

    [Column("stop_order")]
    public int StopOrder { get; set; } = 1;

    [Column("stop_type")]
    [MaxLength(40)]
    public string StopType { get; set; } = "destination";

    [Column("reference_id")]
    public int? ReferenceId { get; set; }

    [Column("title")]
    [MaxLength(220)]
    public string Title { get; set; } = string.Empty;

    [Column("address")]
    [MaxLength(350)]
    public string? Address { get; set; }

    [Column("latitude")]
    public double Latitude { get; set; } = 10.7769;

    [Column("longitude")]
    public double Longitude { get; set; } = 106.7009;

    [Column("planned_time")]
    [MaxLength(60)]
    public string PlannedTime { get; set; } = "08:30 - 10:00";

    [Column("duration_mins")]
    public int DurationMins { get; set; } = 90;

    [Column("notes")]
    public string? Notes { get; set; }
}
