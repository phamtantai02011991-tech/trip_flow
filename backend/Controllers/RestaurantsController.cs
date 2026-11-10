using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TripFlow.Api.Data;
using TripFlow.Api.Models.DTOs;
using TripFlow.Api.Models.Entities;
using TripFlow.Api.Services;

namespace TripFlow.Api.Controllers;

[ApiController]
[Route("api/v1/restaurants")]
public class RestaurantsController : ControllerBase
{
    private readonly TripFlowDbContext _db;
    private readonly IGeoService _geoService;

    public RestaurantsController(TripFlowDbContext db, IGeoService geoService)
    {
        _db = db;
        _geoService = geoService;
    }

    private static List<object> ParseSampleReviews(string? json)
    {
        if (string.IsNullOrWhiteSpace(json)) return new();
        try
        {
            return JsonSerializer.Deserialize<List<object>>(json) ?? new();
        }
        catch
        {
            return new();
        }
    }

    [HttpGet]
    public async Task<IActionResult> ListRestaurants(
        [FromQuery] int page = 1,
        [FromQuery] int page_size = 20,
        [FromQuery] int? province_id = null,
        [FromQuery] string? cuisine_type = null,
        [FromQuery] string? q = null,
        [FromQuery] bool? is_high_rated = null,
        [FromQuery] double? min_rating = null)
    {
        if (page < 1) page = 1;
        if (page_size < 1) page_size = 20;

        var query = _db.Restaurants
            .AsNoTracking()
            .Include(r => r.Province)
            .AsQueryable();

        if (province_id.HasValue) query = query.Where(r => r.ProvinceId == province_id.Value);
        if (!string.IsNullOrWhiteSpace(cuisine_type)) query = query.Where(r => r.CuisineType.Contains(cuisine_type));
        if (is_high_rated.HasValue) query = query.Where(r => r.IsHighRated == is_high_rated.Value);
        if (min_rating.HasValue) query = query.Where(r => r.Rating >= min_rating.Value);

        if (!string.IsNullOrWhiteSpace(q))
        {
            var search = q.Trim().ToLower();
            query = query.Where(r => r.Name.ToLower().Contains(search) || r.Address.ToLower().Contains(search) || (r.SpecialtyDishes != null && r.SpecialtyDishes.ToLower().Contains(search)));
        }

        int total = await query.CountAsync();
        var items = await query
            .OrderByDescending(r => r.IsHighRated)
            .ThenByDescending(r => r.Rating)
            .Skip((page - 1) * page_size)
            .Take(page_size)
            .Select(r => new RestaurantDto
            {
                Id = r.Id,
                ProvinceId = r.ProvinceId,
                ProvinceName = r.Province != null ? r.Province.Name : null,
                Name = r.Name,
                Address = r.Address,
                Latitude = r.Latitude,
                Longitude = r.Longitude,
                CuisineType = r.CuisineType,
                SpecialtyDishes = r.SpecialtyDishes,
                PriceRange = r.PriceRange,
                OpeningHours = r.OpeningHours,
                ContactPhone = r.ContactPhone,
                Rating = r.Rating,
                ReviewCount = r.ReviewCount,
                ReviewsCount = r.ReviewsCount,
                IsHighRated = r.IsHighRated,
                Specialties = r.Specialties,
                ImageUrl = r.ImageUrl,
                ThumbnailUrl = r.ThumbnailUrl,
                ImageCredit = r.ImageCredit,
                ImageLicense = r.ImageLicense,
                ImageSourceUrl = r.ImageSourceUrl,
                IsSponsored = r.IsSponsored,
                SponsorLabel = r.SponsorLabel,
                IsVerified = r.IsVerified,
                Source = r.Source,
                SourceUrl = r.SourceUrl,
                Status = r.Status,
                SampleReviews = ParseSampleReviews(r.SampleReviewsJson)
            })
            .ToListAsync();

        return Ok(new PaginatedResponse<RestaurantDto>
        {
            Total = total,
            Page = page,
            PageSize = page_size,
            Items = items
        });
    }

    [HttpGet("{restaurant_id}")]
    public async Task<IActionResult> GetRestaurantDetail(int restaurant_id)
    {
        var r = await _db.Restaurants
            .AsNoTracking()
            .Include(x => x.Province)
            .FirstOrDefaultAsync(x => x.Id == restaurant_id);

        if (r == null)
        {
            return NotFound(new ErrorEnvelope($"Không tìm thấy quán ăn ID {restaurant_id}."));
        }

        return Ok(new RestaurantDto
        {
            Id = r.Id,
            ProvinceId = r.ProvinceId,
            ProvinceName = r.Province?.Name,
            Name = r.Name,
            Address = r.Address,
            Latitude = r.Latitude,
            Longitude = r.Longitude,
            CuisineType = r.CuisineType,
            SpecialtyDishes = r.SpecialtyDishes,
            PriceRange = r.PriceRange,
            OpeningHours = r.OpeningHours,
            ContactPhone = r.ContactPhone,
            Rating = r.Rating,
            ReviewCount = r.ReviewCount,
            ReviewsCount = r.ReviewsCount,
            IsHighRated = r.IsHighRated,
            Specialties = r.Specialties,
            ImageUrl = r.ImageUrl,
            ThumbnailUrl = r.ThumbnailUrl,
            ImageCredit = r.ImageCredit,
            ImageLicense = r.ImageLicense,
            ImageSourceUrl = r.ImageSourceUrl,
            IsSponsored = r.IsSponsored,
            SponsorLabel = r.SponsorLabel,
            IsVerified = r.IsVerified,
            Source = r.Source,
            SourceUrl = r.SourceUrl,
            Status = r.Status,
            SampleReviews = ParseSampleReviews(r.SampleReviewsJson)
        });
    }

    [HttpPost("corridor-search")]
    public async Task<IActionResult> CorridorSearch([FromBody] CorridorSearchRequest req)
    {
        return await ExecuteCorridorSearch(req.OriginLat, req.OriginLng, req.DestLat, req.DestLng, req.CorridorRadiusKm, req.CuisineType, req.MinRating);
    }

    [HttpGet("on-route")]
    public async Task<IActionResult> OnRoute(
        [FromQuery] double origin_lat,
        [FromQuery] double origin_lng,
        [FromQuery] double dest_lat,
        [FromQuery] double dest_lng,
        [FromQuery] double corridor_radius_km = 2.0,
        [FromQuery] string? cuisine_type = null,
        [FromQuery] double? min_rating = null)
    {
        return await ExecuteCorridorSearch(origin_lat, origin_lng, dest_lat, dest_lng, corridor_radius_km, cuisine_type, min_rating);
    }

    private async Task<IActionResult> ExecuteCorridorSearch(
        double originLat, double originLng, double destLat, double destLng,
        double corridorRadiusKm, string? cuisineType, double? minRating)
    {
        if (corridorRadiusKm <= 0) corridorRadiusKm = 2.0;

        var routePoints = new List<PointD>
        {
            new(originLat, originLng),
            new(destLat, destLng)
        };

        var (minLat, maxLat, minLng, maxLng) = _geoService.BoundingBox(routePoints, corridorRadiusKm + 1.0);

        var candidateQuery = _db.Restaurants
            .AsNoTracking()
            .Include(r => r.Province)
            .Where(r => r.Latitude >= minLat && r.Latitude <= maxLat &&
                        r.Longitude >= minLng && r.Longitude <= maxLng);

        if (!string.IsNullOrWhiteSpace(cuisineType))
        {
            candidateQuery = candidateQuery.Where(r => r.CuisineType.Contains(cuisineType));
        }

        if (minRating.HasValue)
        {
            candidateQuery = candidateQuery.Where(r => r.Rating >= minRating.Value);
        }

        var candidates = await candidateQuery.ToListAsync();
        var results = new List<CorridorSearchResult>();

        foreach (var r in candidates)
        {
            var proj = _geoService.ProjectPointToRoute(r.Latitude, r.Longitude, routePoints);
            if (proj.DistanceToRouteKm <= corridorRadiusKm)
            {
                double score = _geoService.CalculateSfcsScore(r.Rating, r.ReviewCount, r.IsHighRated, proj.DistanceToRouteKm);

                results.Add(new CorridorSearchResult
                {
                    Restaurant = new RestaurantDto
                    {
                        Id = r.Id,
                        ProvinceId = r.ProvinceId,
                        ProvinceName = r.Province?.Name,
                        Name = r.Name,
                        Address = r.Address,
                        Latitude = r.Latitude,
                        Longitude = r.Longitude,
                        CuisineType = r.CuisineType,
                        SpecialtyDishes = r.SpecialtyDishes,
                        PriceRange = r.PriceRange,
                        OpeningHours = r.OpeningHours,
                        ContactPhone = r.ContactPhone,
                        Rating = r.Rating,
                        ReviewCount = r.ReviewCount,
                        ReviewsCount = r.ReviewsCount,
                        IsHighRated = r.IsHighRated,
                        ImageUrl = r.ImageUrl,
                        ThumbnailUrl = r.ThumbnailUrl,
                        SampleReviews = ParseSampleReviews(r.SampleReviewsJson)
                    },
                    DistanceToRouteKm = proj.DistanceToRouteKm,
                    DetourDistanceKm = proj.DetourDistanceKm,
                    EstimatedDetourMins = proj.EstimatedDetourMins,
                    RouteProgressPct = proj.RouteProgressPct,
                    SfcsScore = score
                });
            }
        }

        var ordered = results.OrderByDescending(x => x.SfcsScore).Take(50).ToList();

        return Ok(new CorridorSearchResponse
        {
            Count = ordered.Count,
            CorridorRadiusKm = corridorRadiusKm,
            Items = ordered
        });
    }
}
