using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace TripFlow.Api.Models.Entities;

[Table("provinces")]
public class Province
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("code")]
    [MaxLength(20)]
    public string Code { get; set; } = string.Empty;

    [Column("name")]
    [MaxLength(120)]
    public string Name { get; set; } = string.Empty;

    [Column("region")]
    [MaxLength(60)]
    public string Region { get; set; } = string.Empty;

    [Column("description")]
    public string? Description { get; set; }

    [Column("hero_image")]
    [MaxLength(500)]
    public string? HeroImage { get; set; }

    [Column("center_lat")]
    public double CenterLat { get; set; } = 10.7769;

    [Column("center_lng")]
    public double CenterLng { get; set; } = 106.7009;

    [Column("is_active")]
    public bool IsActive { get; set; } = true;

    [Column("data_source")]
    [MaxLength(100)]
    public string DataSource { get; set; } = "internal";

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Destination> Destinations { get; set; } = new List<Destination>();
    public ICollection<LocalFood> LocalFoods { get; set; } = new List<LocalFood>();
    public ICollection<Restaurant> Restaurants { get; set; } = new List<Restaurant>();
    public ICollection<RestStop> RestStops { get; set; } = new List<RestStop>();
    public ICollection<Itinerary> Itineraries { get; set; } = new List<Itinerary>();
}

[Table("categories")]
public class Category
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("code")]
    [MaxLength(50)]
    public string Code { get; set; } = string.Empty;

    [Column("name")]
    [MaxLength(120)]
    public string Name { get; set; } = string.Empty;

    [Column("icon_name")]
    [MaxLength(60)]
    public string IconName { get; set; } = "place";

    [Column("description")]
    public string? Description { get; set; }

    public ICollection<Destination> Destinations { get; set; } = new List<Destination>();
}

[Table("destinations")]
[Index(nameof(Latitude), nameof(Longitude), Name = "ix_destinations_lat_lng")]
public class Destination
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("province_id")]
    public int ProvinceId { get; set; }
    public Province? Province { get; set; }

    [Column("category_id")]
    public int? CategoryId { get; set; } = 1;
    public Category? Category { get; set; }

    [Column("name")]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [Column("slug")]
    [MaxLength(220)]
    public string? Slug { get; set; }

    [Column("description")]
    public string Description { get; set; } = string.Empty;

    [Column("address")]
    [MaxLength(350)]
    public string Address { get; set; } = string.Empty;

    [Column("latitude")]
    public double Latitude { get; set; }

    [Column("longitude")]
    public double Longitude { get; set; }

    [Column("opening_hours")]
    [MaxLength(180)]
    public string OpeningHours { get; set; } = "07:30 - 17:30";

    [Column("ticket_price_info")]
    [MaxLength(200)]
    public string TicketPriceInfo { get; set; } = "Miễn phí";

    [Column("rating")]
    public double Rating { get; set; } = 4.7;

    [Column("review_count")]
    public int ReviewCount { get; set; } = 120;

    [Column("recommended_duration_mins")]
    public int RecommendedDurationMins { get; set; } = 90;

    [Column("thumbnail_url")]
    [MaxLength(550)]
    public string? ThumbnailUrl { get; set; }

    [Column("detail_image_url")]
    [MaxLength(550)]
    public string? DetailImageUrl { get; set; }

    [Column("is_featured")]
    public bool IsFeatured { get; set; } = false;

    [Column("is_sponsored")]
    public bool IsSponsored { get; set; } = false;

    [Column("sponsor_label")]
    [MaxLength(150)]
    public string? SponsorLabel { get; set; }

    [Column("is_verified")]
    public bool IsVerified { get; set; } = false;

    [Column("source")]
    [MaxLength(60)]
    public string Source { get; set; } = "admin";

    [Column("source_url")]
    [MaxLength(550)]
    public string? SourceUrl { get; set; }

    [Column("status")]
    [MaxLength(30)]
    public string Status { get; set; } = "published";

    [Column("data_source")]
    [MaxLength(60)]
    public string DataSource { get; set; } = "internal";

    [Column("source_attribution")]
    [MaxLength(300)]
    public string SourceAttribution { get; set; } = "Ban Biên Tập TripFlow & Sở Du lịch TP.HCM";

    [Column("last_verified_at")]
    public DateTime LastVerifiedAt { get; set; } = DateTime.UtcNow;

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<DestinationImage> Images { get; set; } = new List<DestinationImage>();
}

[Table("destination_images")]
public class DestinationImage
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("destination_id")]
    public int DestinationId { get; set; }
    public Destination? Destination { get; set; }

    [Column("image_url")]
    [MaxLength(550)]
    public string ImageUrl { get; set; } = string.Empty;

    [Column("thumbnail_url")]
    [MaxLength(550)]
    public string? ThumbnailUrl { get; set; }

    [Column("caption")]
    [MaxLength(250)]
    public string? Caption { get; set; }

    [Column("sort_order")]
    public int SortOrder { get; set; } = 1;

    [Column("license_type")]
    [MaxLength(80)]
    public string LicenseType { get; set; } = "owned";

    [Column("credit_author")]
    [MaxLength(200)]
    public string CreditAuthor { get; set; } = "TripFlow Studio";
}

[Table("local_foods")]
public class LocalFood
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("province_id")]
    public int ProvinceId { get; set; }
    public Province? Province { get; set; }

    [Column("name")]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [Column("description")]
    public string Description { get; set; } = string.Empty;

    [Column("story_origin")]
    public string? StoryOrigin { get; set; }

    [Column("image_url")]
    [MaxLength(550)]
    public string? ImageUrl { get; set; }

    [Column("thumbnail_url")]
    [MaxLength(550)]
    public string? ThumbnailUrl { get; set; }

    [Column("best_season_or_time")]
    [MaxLength(180)]
    public string BestSeasonOrTime { get; set; } = "Quanh năm (Ngon nhất vào buổi sáng hoặc tối)";

    [Column("avg_price_range")]
    [MaxLength(120)]
    public string AvgPriceRange { get; set; } = "40.000đ - 85.000đ";

    [Column("recommended_restaurant_ids_json")]
    public string RecommendedRestaurantIdsJson { get; set; } = "[]";

    [Column("status")]
    [MaxLength(30)]
    public string Status { get; set; } = "published";

    [Column("data_source")]
    [MaxLength(60)]
    public string DataSource { get; set; } = "internal";

    [Column("license_info")]
    [MaxLength(250)]
    public string LicenseInfo { get; set; } = "Bản quyền nội dung TripFlow Editorial";

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

[Table("restaurants")]
[Index(nameof(Latitude), nameof(Longitude), Name = "ix_restaurants_lat_lng")]
public class Restaurant
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("province_id")]
    public int ProvinceId { get; set; }
    public Province? Province { get; set; }

    [Column("name")]
    [MaxLength(220)]
    public string Name { get; set; } = string.Empty;

    [Column("address")]
    [MaxLength(350)]
    public string Address { get; set; } = string.Empty;

    [Column("latitude")]
    public double Latitude { get; set; }

    [Column("longitude")]
    public double Longitude { get; set; }

    [Column("cuisine_type")]
    [MaxLength(120)]
    public string CuisineType { get; set; } = "Đặc sản";

    [Column("specialty_dishes")]
    [MaxLength(300)]
    public string? SpecialtyDishes { get; set; }

    [Column("price_range")]
    [MaxLength(120)]
    public string PriceRange { get; set; } = "45.000đ - 120.000đ";

    [Column("opening_hours")]
    [MaxLength(150)]
    public string OpeningHours { get; set; } = "06:30 - 22:00";

    [Column("contact_phone")]
    [MaxLength(50)]
    public string? ContactPhone { get; set; }

    [Column("rating")]
    public double Rating { get; set; } = 4.6;

    [Column("review_count")]
    public int ReviewCount { get; set; } = 150;

    [Column("reviews_count")]
    public int ReviewsCount { get; set; } = 120;

    [Column("sample_reviews_json")]
    public string? SampleReviewsJson { get; set; } = "[]";

    [Column("is_high_rated")]
    public bool IsHighRated { get; set; } = true;

    [Column("specialties")]
    [MaxLength(300)]
    public string? Specialties { get; set; }

    [Column("image_url")]
    [MaxLength(550)]
    public string? ImageUrl { get; set; }

    [Column("thumbnail_url")]
    [MaxLength(550)]
    public string? ThumbnailUrl { get; set; }

    [Column("image_credit")]
    [MaxLength(250)]
    public string? ImageCredit { get; set; }

    [Column("image_license")]
    [MaxLength(120)]
    public string? ImageLicense { get; set; }

    [Column("image_source_url")]
    [MaxLength(550)]
    public string? ImageSourceUrl { get; set; }

    [Column("is_sponsored")]
    public bool IsSponsored { get; set; } = false;

    [Column("sponsor_label")]
    [MaxLength(150)]
    public string? SponsorLabel { get; set; }

    [Column("is_verified")]
    public bool IsVerified { get; set; } = false;

    [Column("source")]
    [MaxLength(60)]
    public string Source { get; set; } = "admin";

    [Column("source_url")]
    [MaxLength(550)]
    public string? SourceUrl { get; set; }

    [Column("status")]
    [MaxLength(30)]
    public string Status { get; set; } = "published";

    [Column("data_source")]
    [MaxLength(60)]
    public string DataSource { get; set; } = "internal";

    [Column("last_updated_at")]
    public DateTime LastUpdatedAt { get; set; } = DateTime.UtcNow;
}

[Table("rest_stops")]
[Index(nameof(Latitude), nameof(Longitude), Name = "ix_rest_stops_lat_lng")]
public class RestStop
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("province_id")]
    public int ProvinceId { get; set; }
    public Province? Province { get; set; }

    [Column("category")]
    [MaxLength(30)]
    public string Category { get; set; } = "rest";

    [Column("name")]
    [MaxLength(220)]
    public string Name { get; set; } = string.Empty;

    [Column("address")]
    [MaxLength(350)]
    public string Address { get; set; } = string.Empty;

    [Column("latitude")]
    public double Latitude { get; set; }

    [Column("longitude")]
    public double Longitude { get; set; }

    [Column("opening_hours")]
    [MaxLength(150)]
    public string OpeningHours { get; set; } = string.Empty;

    [Column("phone")]
    [MaxLength(50)]
    public string? Phone { get; set; }

    [Column("description")]
    public string? Description { get; set; }

    [Column("brand")]
    [MaxLength(150)]
    public string? Brand { get; set; }

    [Column("image_url")]
    [MaxLength(550)]
    public string? ImageUrl { get; set; }

    [Column("thumbnail_url")]
    [MaxLength(550)]
    public string? ThumbnailUrl { get; set; }

    [Column("image_credit")]
    [MaxLength(250)]
    public string? ImageCredit { get; set; }

    [Column("image_license")]
    [MaxLength(120)]
    public string? ImageLicense { get; set; }

    [Column("image_source_url")]
    [MaxLength(550)]
    public string? ImageSourceUrl { get; set; }

    [Column("rating")]
    public double Rating { get; set; } = 0.0;

    [Column("review_count")]
    public int ReviewCount { get; set; } = 0;

    [Column("is_verified")]
    public bool IsVerified { get; set; } = false;

    [Column("source")]
    [MaxLength(60)]
    public string Source { get; set; } = "osm";

    [Column("source_url")]
    [MaxLength(550)]
    public string? SourceUrl { get; set; }

    [Column("status")]
    [MaxLength(30)]
    public string Status { get; set; } = "published";

    [Column("data_source")]
    [MaxLength(60)]
    public string DataSource { get; set; } = "osm";

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
