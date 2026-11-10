using System.Globalization;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TripFlow.Api.Data;
using TripFlow.Api.Models.DTOs;
using TripFlow.Api.Models.Entities;
using TripFlow.Api.Services;

namespace TripFlow.Api.Controllers;

[ApiController]
[Route("api/v1/places")]
public class PlacesController : ControllerBase
{
    private readonly TripFlowDbContext _db;
    private readonly IGeoService _geoService;
    private readonly ITokenService _tokenService;

    public PlacesController(TripFlowDbContext db, IGeoService geoService, ITokenService tokenService)
    {
        _db = db;
        _geoService = geoService;
        _tokenService = tokenService;
    }

    private static string RemoveDiacritics(string text)
    {
        if (string.IsNullOrWhiteSpace(text)) return string.Empty;
        var normalizedString = text.Normalize(NormalizationForm.FormD);
        var stringBuilder = new StringBuilder(normalizedString.Length);

        foreach (var c in normalizedString)
        {
            var unicodeCategory = CharUnicodeInfo.GetUnicodeCategory(c);
            if (unicodeCategory != UnicodeCategory.NonSpacingMark)
            {
                stringBuilder.Append(c);
            }
        }

        return stringBuilder.ToString().Normalize(NormalizationForm.FormC).ToLower().Replace('đ', 'd').Replace('Đ', 'd');
    }

    [HttpGet("nearby")]
    public async Task<IActionResult> Nearby(
        [FromQuery] double lat,
        [FromQuery] double lng,
        [FromQuery] double radius_km = 5.0,
        [FromQuery] string? kinds = null,
        [FromQuery] string? sort_by = "distance")
    {
        if (radius_km <= 0) radius_km = 5.0;
        var kindList = (kinds ?? "sight,food,gas,rest,ev,cafe")
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(k => k.ToLower())
            .ToHashSet();

        var (minLat, maxLat, minLng, maxLng) = _geoService.BoundingBox(new[] { new PointD(lat, lng) }, radius_km);
        var items = new List<NearbyPlaceItem>();

        // 1. Quán ăn / Nhà hàng
        if (kindList.Contains("food") || kindList.Contains("cafe"))
        {
            var restaurants = await _db.Restaurants
                .AsNoTracking()
                .Where(r => r.Latitude >= minLat && r.Latitude <= maxLat &&
                            r.Longitude >= minLng && r.Longitude <= maxLng)
                .ToListAsync();

            foreach (var r in restaurants)
            {
                double d = _geoService.DistanceKm(lat, lng, r.Latitude, r.Longitude);
                if (d <= radius_km)
                {
                    string quality = (r.Rating >= 4.7 && r.ReviewCount <= 200) ? "hidden_gem" : (r.Rating >= 4.6 ? "top_rated" : "normal");
                    items.Add(new NearbyPlaceItem
                    {
                        Id = $"r_{r.Id}",
                        Name = r.Name,
                        Kind = "food",
                        CategoryName = r.CuisineType,
                        Address = r.Address,
                        Lat = r.Latitude,
                        Lng = r.Longitude,
                        DistanceKm = Math.Round(d, 2),
                        Rating = r.Rating,
                        ReviewCount = r.ReviewCount,
                        PriceRange = r.PriceRange,
                        ImageUrl = r.ThumbnailUrl ?? r.ImageUrl,
                        Quality = quality,
                        IsVerified = r.IsVerified
                    });
                }
            }
        }

        // 2. Điểm tham quan / Danh thắng
        if (kindList.Contains("sight") || kindList.Contains("destination"))
        {
            var destinations = await _db.Destinations
                .AsNoTracking()
                .Include(d => d.Category)
                .Where(d => d.Latitude >= minLat && d.Latitude <= maxLat &&
                            d.Longitude >= minLng && d.Longitude <= maxLng)
                .ToListAsync();

            foreach (var d in destinations)
            {
                double dist = _geoService.DistanceKm(lat, lng, d.Latitude, d.Longitude);
                if (dist <= radius_km)
                {
                    string quality = (d.Rating >= 4.7 && d.ReviewCount <= 200) ? "hidden_gem" : (d.Rating >= 4.7 ? "top_rated" : "normal");
                    items.Add(new NearbyPlaceItem
                    {
                        Id = $"d_{d.Id}",
                        Name = d.Name,
                        Kind = "sight",
                        CategoryName = d.Category?.Name ?? "Tham quan",
                        Address = d.Address,
                        Lat = d.Latitude,
                        Lng = d.Longitude,
                        DistanceKm = Math.Round(dist, 2),
                        Rating = d.Rating,
                        ReviewCount = d.ReviewCount,
                        PriceRange = d.TicketPriceInfo,
                        ImageUrl = d.ThumbnailUrl ?? d.DetailImageUrl,
                        Quality = quality,
                        IsVerified = d.IsVerified
                    });
                }
            }
        }

        // 3. Trạm dừng nghỉ / Cây xăng / EV
        if (kindList.Contains("gas") || kindList.Contains("ev") || kindList.Contains("rest"))
        {
            var restStops = await _db.RestStops
                .AsNoTracking()
                .Where(rs => rs.Latitude >= minLat && rs.Latitude <= maxLat &&
                             rs.Longitude >= minLng && rs.Longitude <= maxLng)
                .ToListAsync();

            foreach (var s in restStops)
            {
                double dist = _geoService.DistanceKm(lat, lng, s.Latitude, s.Longitude);
                if (dist <= radius_km)
                {
                    string mappedKind = s.Category == "fuel" ? "gas" : s.Category;
                    if (kindList.Contains(mappedKind) || kindList.Contains(s.Category) || (s.Category == "fuel" && kindList.Contains("gas")))
                    {
                        items.Add(new NearbyPlaceItem
                        {
                            Id = $"p_{s.Id}",
                            Name = s.Name,
                            Kind = mappedKind,
                            CategoryName = s.Brand ?? (s.Category == "fuel" ? "Cây xăng" : "Trạm nghỉ"),
                            Address = s.Address,
                            Lat = s.Latitude,
                            Lng = s.Longitude,
                            DistanceKm = Math.Round(dist, 2),
                            Rating = s.Rating > 0 ? s.Rating : 4.5,
                            ReviewCount = s.ReviewCount,
                            ImageUrl = s.ThumbnailUrl ?? s.ImageUrl,
                            Quality = "normal",
                            IsVerified = s.IsVerified
                        });
                    }
                }
            }
        }

        // Sort items
        var sorted = sort_by switch
        {
            "rating" => items.OrderByDescending(x => x.Rating).ToList(),
            "quality" => items.OrderBy(x => x.Quality == "hidden_gem" ? 0 : x.Quality == "top_rated" ? 1 : 2).ThenBy(x => x.DistanceKm).ToList(),
            _ => items.OrderBy(x => x.DistanceKm).ToList()
        };

        return Ok(new NearbyResponse
        {
            Total = sorted.Count,
            Items = sorted
        });
    }

    [HttpGet("suggest")]
    public async Task<IActionResult> Suggest([FromQuery] string? q)
    {
        if (string.IsNullOrWhiteSpace(q))
        {
            return Ok(new List<PlaceSuggestItem>());
        }

        var normalizedSearch = RemoveDiacritics(q.Trim());
        var results = new List<PlaceSuggestItem>();

        var destinations = await _db.Destinations
            .AsNoTracking()
            .Include(d => d.Province)
            .ToListAsync();

        foreach (var d in destinations)
        {
            var normName = RemoveDiacritics(d.Name);
            var normProv = RemoveDiacritics(d.Province?.Name ?? "");
            var normAddr = RemoveDiacritics(d.Address);

            if (normName.Contains(normalizedSearch) || normProv.Contains(normalizedSearch) || normAddr.Contains(normalizedSearch))
            {
                results.Add(new PlaceSuggestItem
                {
                    Id = $"d_{d.Id}",
                    Name = d.Name,
                    Kind = "destination",
                    Address = d.Address,
                    ProvinceName = d.Province?.Name,
                    Lat = d.Latitude,
                    Lng = d.Longitude
                });
            }
        }

        var restaurants = await _db.Restaurants
            .AsNoTracking()
            .Include(r => r.Province)
            .ToListAsync();

        foreach (var r in restaurants)
        {
            var normName = RemoveDiacritics(r.Name);
            var normProv = RemoveDiacritics(r.Province?.Name ?? "");
            var normAddr = RemoveDiacritics(r.Address);

            if (normName.Contains(normalizedSearch) || normProv.Contains(normalizedSearch) || normAddr.Contains(normalizedSearch))
            {
                results.Add(new PlaceSuggestItem
                {
                    Id = $"r_{r.Id}",
                    Name = r.Name,
                    Kind = "restaurant",
                    Address = r.Address,
                    ProvinceName = r.Province?.Name,
                    Lat = r.Latitude,
                    Lng = r.Longitude
                });
            }
        }

        var restStops = await _db.RestStops
            .AsNoTracking()
            .Include(s => s.Province)
            .ToListAsync();

        foreach (var s in restStops)
        {
            var normName = RemoveDiacritics(s.Name);
            var normBrand = RemoveDiacritics(s.Brand ?? "");
            var normProv = RemoveDiacritics(s.Province?.Name ?? "");

            if (normName.Contains(normalizedSearch) || normBrand.Contains(normalizedSearch) || normProv.Contains(normalizedSearch))
            {
                results.Add(new PlaceSuggestItem
                {
                    Id = $"p_{s.Id}",
                    Name = s.Name,
                    Kind = s.Category == "fuel" ? "gas" : s.Category,
                    Address = s.Address,
                    ProvinceName = s.Province?.Name,
                    Lat = s.Latitude,
                    Lng = s.Longitude
                });
            }
        }

        return Ok(results.Take(20).ToList());
    }

    [HttpPost("along-route")]
    public async Task<IActionResult> AlongRoute([FromBody] AlongRouteRequest req)
    {
        double radius = req.CorridorRadiusKm > 0 ? req.CorridorRadiusKm : 2.0;
        var routePoints = new List<PointD>
        {
            new(req.OriginLat, req.OriginLng),
            new(req.DestLat, req.DestLng)
        };

        double routeDistKm = Math.Round(_geoService.DistanceKm(req.OriginLat, req.OriginLng, req.DestLat, req.DestLng), 2);
        var (minLat, maxLat, minLng, maxLng) = _geoService.BoundingBox(routePoints, radius + 1.0);

        var kinds = (req.Kinds ?? "rest,gas,ev,cafe")
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(k => k.ToLower())
            .ToHashSet();

        var stops = new List<AlongRouteStop>();

        // 1. RestStops (gas, ev, rest)
        var restStops = await _db.RestStops
            .AsNoTracking()
            .Where(s => s.Latitude >= minLat && s.Latitude <= maxLat &&
                        s.Longitude >= minLng && s.Longitude <= maxLng)
            .ToListAsync();

        foreach (var s in restStops)
        {
            var proj = _geoService.ProjectPointToRoute(s.Latitude, s.Longitude, routePoints);
            if (proj.DistanceToRouteKm <= radius)
            {
                string mappedKind = s.Category == "fuel" ? "gas" : s.Category;
                stops.Add(new AlongRouteStop
                {
                    Id = $"p_{s.Id}",
                    Name = s.Name,
                    Kind = mappedKind,
                    Lat = s.Latitude,
                    Lng = s.Longitude,
                    Address = s.Address,
                    DistanceToRouteKm = proj.DistanceToRouteKm,
                    DetourDistanceKm = proj.DetourDistanceKm,
                    EstimatedDetourMins = proj.EstimatedDetourMins,
                    RouteProgressPct = proj.RouteProgressPct,
                    Rating = s.Rating > 0 ? s.Rating : 4.5,
                    ImageUrl = s.ThumbnailUrl ?? s.ImageUrl
                });
            }
        }

        // 2. Restaurants / Cafe
        if (kinds.Contains("cafe") || kinds.Contains("food") || kinds.Contains("restaurant"))
        {
            var restaurants = await _db.Restaurants
                .AsNoTracking()
                .Where(r => r.Latitude >= minLat && r.Latitude <= maxLat &&
                            r.Longitude >= minLng && r.Longitude <= maxLng)
                .ToListAsync();

            foreach (var r in restaurants)
            {
                var proj = _geoService.ProjectPointToRoute(r.Latitude, r.Longitude, routePoints);
                if (proj.DistanceToRouteKm <= radius)
                {
                    stops.Add(new AlongRouteStop
                    {
                        Id = $"r_{r.Id}",
                        Name = r.Name,
                        Kind = "cafe",
                        Lat = r.Latitude,
                        Lng = r.Longitude,
                        Address = r.Address,
                        DistanceToRouteKm = proj.DistanceToRouteKm,
                        DetourDistanceKm = proj.DetourDistanceKm,
                        EstimatedDetourMins = proj.EstimatedDetourMins,
                        RouteProgressPct = proj.RouteProgressPct,
                        Rating = r.Rating,
                        ImageUrl = r.ThumbnailUrl ?? r.ImageUrl
                    });
                }
            }
        }

        var orderedStops = stops.OrderBy(s => s.RouteProgressPct).ToList();

        return Ok(new AlongRouteResponse
        {
            Count = orderedStops.Count,
            CorridorRadiusKm = radius,
            RouteDistanceKm = routeDistKm,
            Stops = orderedStops
        });
    }

    [HttpGet("history")]
    public async Task<IActionResult> ListHistory()
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        if (!userId.HasValue) return Ok(new List<SearchHistoryItemDto>());

        var list = await _db.SearchHistories
            .AsNoTracking()
            .Where(h => h.UserId == userId.Value)
            .OrderByDescending(h => h.CreatedAt)
            .Take(30)
            .Select(h => new SearchHistoryItemDto
            {
                Id = h.Id,
                Query = h.Query,
                Kind = h.Kind,
                PlaceId = h.PlaceId,
                Lat = h.Lat,
                Lng = h.Lng,
                CreatedAt = h.CreatedAt
            })
            .ToListAsync();

        return Ok(list);
    }

    [HttpPost("history")]
    public async Task<IActionResult> AddHistory([FromBody] CreateSearchHistoryRequest req)
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        if (!userId.HasValue || string.IsNullOrWhiteSpace(req.Query))
        {
            return Ok(new StatusResponse { Status = "ok" });
        }

        var item = new SearchHistory
        {
            UserId = userId.Value,
            Query = req.Query.Trim(),
            Kind = req.Kind ?? "text",
            PlaceId = req.PlaceId,
            Lat = req.Lat,
            Lng = req.Lng,
            CreatedAt = DateTime.UtcNow
        };

        _db.SearchHistories.Add(item);
        await _db.SaveChangesAsync();

        return Ok(new StatusResponse { Status = "ok", Message = "Đã lưu lịch sử tìm kiếm." });
    }

    [HttpDelete("history")]
    public async Task<IActionResult> ClearHistory()
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        if (userId.HasValue)
        {
            var items = await _db.SearchHistories.Where(h => h.UserId == userId.Value).ToListAsync();
            _db.SearchHistories.RemoveRange(items);
            await _db.SaveChangesAsync();
        }

        return Ok(new StatusResponse { Status = "ok", Message = "Đã xóa toàn bộ lịch sử tìm kiếm." });
    }

    [HttpDelete("history/{item_id}")]
    public async Task<IActionResult> DeleteHistory(int item_id)
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        if (userId.HasValue)
        {
            var item = await _db.SearchHistories.FirstOrDefaultAsync(h => h.Id == item_id && h.UserId == userId.Value);
            if (item != null)
            {
                _db.SearchHistories.Remove(item);
                await _db.SaveChangesAsync();
            }
        }

        return Ok(new StatusResponse { Status = "ok", Message = "Đã xóa mục lịch sử." });
    }
}
