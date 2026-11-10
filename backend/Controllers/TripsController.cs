using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TripFlow.Api.Data;
using TripFlow.Api.Models.DTOs;
using TripFlow.Api.Models.Entities;
using TripFlow.Api.Services;

namespace TripFlow.Api.Controllers;

[ApiController]
[Route("api/v1/trips")]
public class TripsController : ControllerBase
{
    private readonly TripFlowDbContext _db;
    private readonly ITokenService _tokenService;

    public TripsController(TripFlowDbContext db, ITokenService tokenService)
    {
        _db = db;
        _tokenService = tokenService;
    }

    private string? GetGuestToken()
    {
        return Request.Headers.TryGetValue("X-Guest-Token", out var val) ? val.ToString() : null;
    }

    private static List<string> ParsePreferences(string? json)
    {
        if (string.IsNullOrWhiteSpace(json)) return new();
        try { return JsonSerializer.Deserialize<List<string>>(json) ?? new(); }
        catch { return new(); }
    }

    private static TripDetailDto MapToTripDetail(Trip t) => new()
    {
        Id = t.Id,
        UserId = t.UserId,
        ProvinceId = t.ProvinceId,
        ProvinceName = t.Province?.Name,
        Title = t.Title,
        OriginName = t.OriginName,
        OriginLat = t.OriginLat,
        OriginLng = t.OriginLng,
        DestinationName = t.DestinationName,
        DestinationLat = t.DestinationLat,
        DestinationLng = t.DestinationLng,
        StartDate = t.StartDate,
        TotalDays = t.TotalDays,
        PartySize = t.PartySize,
        Vehicle = t.Vehicle,
        BudgetLevel = t.BudgetLevel,
        BudgetAmount = t.BudgetAmount,
        Preferences = ParsePreferences(t.PreferencesJson),
        Status = t.Status,
        ShareToken = t.ShareToken,
        AiGenerated = t.AiGenerated,
        CreatedAt = t.CreatedAt,
        UpdatedAt = t.UpdatedAt,
        Days = t.Days.OrderBy(d => d.DayNumber).Select(d => new TripDayDto
        {
            Id = d.Id,
            TripId = d.TripId,
            DayNumber = d.DayNumber,
            Date = d.Date,
            Title = d.Title,
            Note = d.Note,
            Stops = d.Stops.OrderBy(s => s.StopOrder).Select(s => new TripStopDto
            {
                Id = s.Id,
                TripDayId = s.TripDayId,
                TripId = s.TripId,
                StopOrder = s.StopOrder,
                Kind = s.Kind,
                PlaceId = s.PlaceId,
                RefTable = s.RefTable,
                RefId = s.RefId,
                Name = s.Name,
                Address = s.Address,
                Lat = s.Lat,
                Lng = s.Lng,
                ArriveAt = s.ArriveAt,
                StayMins = s.StayMins,
                TravelMinsFromPrev = s.TravelMinsFromPrev,
                DistanceKmFromPrev = s.DistanceKmFromPrev,
                EstCost = s.EstCost,
                Note = s.Note,
                Source = s.Source
            }).ToList()
        }).ToList(),
        Expenses = t.Expenses.OrderByDescending(e => e.CreatedAt).Select(e => new ExpenseDto
        {
            Id = e.Id,
            TripId = e.TripId,
            TripDayId = e.TripDayId,
            Category = e.Category,
            Title = e.Title,
            Amount = e.Amount,
            Planned = e.Planned,
            SpentAt = e.SpentAt,
            PaidBy = e.PaidBy,
            Note = e.Note,
            CreatedAt = e.CreatedAt
        }).ToList()
    };

    [HttpGet]
    public async Task<IActionResult> ListTrips()
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        var guestToken = GetGuestToken();

        var query = _db.Trips
            .AsNoTracking()
            .Include(t => t.Province)
            .Include(t => t.Days).ThenInclude(d => d.Stops)
            .Include(t => t.Expenses)
            .AsQueryable();

        if (userId.HasValue)
        {
            query = query.Where(t => t.UserId == userId.Value);
        }
        else if (!string.IsNullOrWhiteSpace(guestToken))
        {
            query = query.Where(t => t.GuestToken == guestToken && t.UserId == null);
        }
        else
        {
            return Ok(new List<TripDetailDto>());
        }

        var trips = await query.OrderByDescending(t => t.UpdatedAt).ToListAsync();
        return Ok(trips.Select(MapToTripDetail).ToList());
    }

    [HttpPost]
    public async Task<IActionResult> CreateTrip([FromBody] CreateTripRequest req)
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        var guestToken = GetGuestToken();

        var now = DateTime.UtcNow;
        var trip = new Trip
        {
            UserId = userId,
            GuestToken = userId == null ? guestToken : null,
            Title = string.IsNullOrWhiteSpace(req.Title) ? $"Chuyến đi {req.OriginName}" : req.Title.Trim(),
            OriginName = req.OriginName.Trim(),
            OriginLat = req.OriginLat,
            OriginLng = req.OriginLng,
            DestinationName = req.DestinationName?.Trim(),
            DestinationLat = req.DestinationLat,
            DestinationLng = req.DestinationLng,
            ProvinceId = req.ProvinceId,
            StartDate = req.StartDate,
            TotalDays = Math.Clamp(req.TotalDays, 1, 14),
            PartySize = Math.Clamp(req.PartySize, 1, 20),
            Vehicle = req.Vehicle ?? "motorbike",
            BudgetLevel = req.BudgetLevel ?? "balanced",
            BudgetAmount = req.BudgetAmount,
            PreferencesJson = req.Preferences != null ? JsonSerializer.Serialize(req.Preferences) : "[]",
            Status = "draft",
            ShareToken = Guid.NewGuid().ToString("N")[..12],
            CreatedAt = now,
            UpdatedAt = now
        };

        _db.Trips.Add(trip);
        await _db.SaveChangesAsync();

        // Tự động sinh danh sách các ngày
        for (int i = 1; i <= trip.TotalDays; i++)
        {
            var day = new TripDay
            {
                TripId = trip.Id,
                DayNumber = i,
                Title = $"Ngày {i}",
                Date = req.StartDate.HasValue ? req.StartDate.Value.AddDays(i - 1) : null
            };
            _db.TripDays.Add(day);
        }
        await _db.SaveChangesAsync();

        var loaded = await _db.Trips
            .Include(t => t.Province)
            .Include(t => t.Days).ThenInclude(d => d.Stops)
            .Include(t => t.Expenses)
            .FirstAsync(t => t.Id == trip.Id);

        return Ok(MapToTripDetail(loaded));
    }

    [HttpGet("{trip_id}")]
    public async Task<IActionResult> GetTrip(int trip_id)
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        var guestToken = GetGuestToken();

        var trip = await _db.Trips
            .Include(t => t.Province)
            .Include(t => t.Days).ThenInclude(d => d.Stops)
            .Include(t => t.Expenses)
            .FirstOrDefaultAsync(t => t.Id == trip_id);

        if (trip == null)
        {
            return NotFound(new ErrorEnvelope("Chuyến đi không tồn tại."));
        }

        if (trip.UserId.HasValue)
        {
            if (trip.UserId != userId && trip.ShareToken == null)
            {
                return NotFound(new ErrorEnvelope("Bạn không có quyền truy cập chuyến đi này."));
            }
        }
        else if (!string.IsNullOrEmpty(trip.GuestToken) && trip.GuestToken != guestToken)
        {
            return NotFound(new ErrorEnvelope("Chuyến đi không tồn tại."));
        }

        return Ok(MapToTripDetail(trip));
    }

    [HttpPut("{trip_id}")]
    public async Task<IActionResult> UpdateTrip(int trip_id, [FromBody] UpdateTripRequest req)
    {
        var trip = await _db.Trips
            .Include(t => t.Province)
            .Include(t => t.Days).ThenInclude(d => d.Stops)
            .Include(t => t.Expenses)
            .FirstOrDefaultAsync(t => t.Id == trip_id);

        if (trip == null) return NotFound(new ErrorEnvelope("Chuyến đi không tồn tại."));

        if (!string.IsNullOrWhiteSpace(req.Title)) trip.Title = req.Title.Trim();
        if (!string.IsNullOrWhiteSpace(req.OriginName)) trip.OriginName = req.OriginName.Trim();
        if (!string.IsNullOrWhiteSpace(req.DestinationName)) trip.DestinationName = req.DestinationName.Trim();
        if (req.StartDate.HasValue) trip.StartDate = req.StartDate.Value;
        if (req.PartySize.HasValue) trip.PartySize = req.PartySize.Value;
        if (!string.IsNullOrWhiteSpace(req.Vehicle)) trip.Vehicle = req.Vehicle;
        if (!string.IsNullOrWhiteSpace(req.BudgetLevel)) trip.BudgetLevel = req.BudgetLevel;
        if (req.BudgetAmount.HasValue) trip.BudgetAmount = req.BudgetAmount.Value;
        if (!string.IsNullOrWhiteSpace(req.Status)) trip.Status = req.Status;
        if (req.Preferences != null) trip.PreferencesJson = JsonSerializer.Serialize(req.Preferences);

        trip.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Ok(MapToTripDetail(trip));
    }

    [HttpDelete("{trip_id}")]
    public async Task<IActionResult> DeleteTrip(int trip_id)
    {
        var trip = await _db.Trips.FindAsync(trip_id);
        if (trip == null) return NotFound(new ErrorEnvelope("Chuyến đi không tồn tại."));

        _db.Trips.Remove(trip);
        await _db.SaveChangesAsync();

        return Ok(new StatusResponse { Status = "ok", Message = "Đã xóa chuyến đi thành công." });
    }

    [HttpPost("{trip_id}/duplicate")]
    public async Task<IActionResult> DuplicateTrip(int trip_id)
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        var original = await _db.Trips
            .Include(t => t.Days).ThenInclude(d => d.Stops)
            .Include(t => t.Expenses)
            .FirstOrDefaultAsync(t => t.Id == trip_id);

        if (original == null) return NotFound(new ErrorEnvelope("Chuyến đi gốc không tồn tại."));

        var now = DateTime.UtcNow;
        var dup = new Trip
        {
            UserId = userId,
            GuestToken = userId == null ? GetGuestToken() : null,
            Title = $"{original.Title} (Bản sao)",
            OriginName = original.OriginName,
            OriginLat = original.OriginLat,
            OriginLng = original.OriginLng,
            DestinationName = original.DestinationName,
            DestinationLat = original.DestinationLat,
            DestinationLng = original.DestinationLng,
            ProvinceId = original.ProvinceId,
            StartDate = original.StartDate,
            TotalDays = original.TotalDays,
            PartySize = original.PartySize,
            Vehicle = original.Vehicle,
            BudgetLevel = original.BudgetLevel,
            BudgetAmount = original.BudgetAmount,
            PreferencesJson = original.PreferencesJson,
            Status = "draft",
            ShareToken = Guid.NewGuid().ToString("N")[..12],
            CreatedAt = now,
            UpdatedAt = now
        };
        _db.Trips.Add(dup);
        await _db.SaveChangesAsync();

        foreach (var od in original.Days)
        {
            var nd = new TripDay
            {
                TripId = dup.Id,
                DayNumber = od.DayNumber,
                Date = od.Date,
                Title = od.Title,
                Note = od.Note
            };
            _db.TripDays.Add(nd);
            await _db.SaveChangesAsync();

            foreach (var os in od.Stops)
            {
                _db.TripStops.Add(new TripStop
                {
                    TripDayId = nd.Id,
                    TripId = dup.Id,
                    StopOrder = os.StopOrder,
                    Kind = os.Kind,
                    PlaceId = os.PlaceId,
                    RefTable = os.RefTable,
                    RefId = os.RefId,
                    Name = os.Name,
                    Address = os.Address,
                    Lat = os.Lat,
                    Lng = os.Lng,
                    ArriveAt = os.ArriveAt,
                    StayMins = os.StayMins,
                    TravelMinsFromPrev = os.TravelMinsFromPrev,
                    DistanceKmFromPrev = os.DistanceKmFromPrev,
                    EstCost = os.EstCost,
                    Note = os.Note,
                    Source = os.Source
                });
            }
        }

        await _db.SaveChangesAsync();

        var loaded = await _db.Trips
            .Include(t => t.Province)
            .Include(t => t.Days).ThenInclude(d => d.Stops)
            .Include(t => t.Expenses)
            .FirstAsync(t => t.Id == dup.Id);

        return Ok(MapToTripDetail(loaded));
    }

    [HttpPost("{trip_id}/share")]
    public async Task<IActionResult> ShareTrip(int trip_id)
    {
        var trip = await _db.Trips.FindAsync(trip_id);
        if (trip == null) return NotFound(new ErrorEnvelope("Chuyến đi không tồn tại."));

        if (string.IsNullOrEmpty(trip.ShareToken))
        {
            trip.ShareToken = Guid.NewGuid().ToString("N")[..12];
            await _db.SaveChangesAsync();
        }

        return Ok(new ShareTripResponse
        {
            ShareToken = trip.ShareToken,
            ShareUrl = $"https://tripflow.vn/share/{trip.ShareToken}"
        });
    }

    [HttpPost("{trip_id}/days/{day_number}/stops")]
    public async Task<IActionResult> AddStop(int trip_id, int day_number, [FromBody] AddStopRequest req)
    {
        var trip = await _db.Trips.Include(t => t.Days).FirstOrDefaultAsync(t => t.Id == trip_id);
        if (trip == null) return NotFound(new ErrorEnvelope("Chuyến đi không tồn tại."));

        var day = trip.Days.FirstOrDefault(d => d.DayNumber == day_number);
        if (day == null)
        {
            day = new TripDay { TripId = trip.Id, DayNumber = day_number, Title = $"Ngày {day_number}" };
            _db.TripDays.Add(day);
            await _db.SaveChangesAsync();
        }

        int currentCount = await _db.TripStops.CountAsync(s => s.TripDayId == day.Id);

        var stop = new TripStop
        {
            TripDayId = day.Id,
            TripId = trip.Id,
            StopOrder = currentCount + 1,
            Kind = req.Kind,
            Name = req.Name,
            Address = req.Address ?? "",
            Lat = req.Lat,
            Lng = req.Lng,
            PlaceId = req.PlaceId,
            RefTable = req.RefTable,
            RefId = req.RefId,
            StayMins = req.StayMins ?? 60,
            EstCost = req.EstCost,
            Note = req.Note,
            Source = "manual"
        };

        _db.TripStops.Add(stop);
        trip.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Ok(new TripStopDto
        {
            Id = stop.Id,
            TripDayId = stop.TripDayId,
            TripId = stop.TripId,
            StopOrder = stop.StopOrder,
            Kind = stop.Kind,
            PlaceId = stop.PlaceId,
            RefTable = stop.RefTable,
            RefId = stop.RefId,
            Name = stop.Name,
            Address = stop.Address,
            Lat = stop.Lat,
            Lng = stop.Lng,
            StayMins = stop.StayMins,
            EstCost = stop.EstCost,
            Note = stop.Note,
            Source = stop.Source
        });
    }

    [HttpDelete("{trip_id}/stops/{stop_id}")]
    public async Task<IActionResult> DeleteStop(int trip_id, int stop_id)
    {
        var stop = await _db.TripStops.FirstOrDefaultAsync(s => s.Id == stop_id && s.TripId == trip_id);
        if (stop == null) return NotFound(new ErrorEnvelope("Điểm dừng không tồn tại."));

        _db.TripStops.Remove(stop);
        await _db.SaveChangesAsync();

        return Ok(new StatusResponse { Status = "ok", Message = "Đã xóa điểm dừng." });
    }

    [HttpPut("{trip_id}/days/{day_number}/reorder")]
    public async Task<IActionResult> ReorderStops(int trip_id, int day_number, [FromBody] ReorderStopsRequest req)
    {
        var day = await _db.TripDays.FirstOrDefaultAsync(d => d.TripId == trip_id && d.DayNumber == day_number);
        if (day == null) return NotFound(new ErrorEnvelope("Ngày không tồn tại."));

        var stops = await _db.TripStops.Where(s => s.TripDayId == day.Id).ToListAsync();
        var map = stops.ToDictionary(s => s.Id);

        int order = 1;
        foreach (var id in req.StopIds)
        {
            if (map.TryGetValue(id, out var s))
            {
                s.StopOrder = order++;
            }
        }

        await _db.SaveChangesAsync();
        return Ok(new StatusResponse { Status = "ok", Message = "Đã sắp xếp lại thứ tự điểm dừng." });
    }

    [HttpPost("{trip_id}/generate")]
    public async Task<IActionResult> GenerateTrip(int trip_id)
    {
        var trip = await _db.Trips.Include(t => t.Days).FirstOrDefaultAsync(t => t.Id == trip_id);
        if (trip == null) return NotFound(new ErrorEnvelope("Chuyến đi không tồn tại."));

        int provId = trip.ProvinceId ?? 1;

        // Grounded: lấy danh lam thắng cảnh và quán ăn thật từ DB
        var dests = await _db.Destinations.Where(d => d.ProvinceId == provId).Take(trip.TotalDays * 2).ToListAsync();
        var rests = await _db.Restaurants.Where(r => r.ProvinceId == provId).Take(trip.TotalDays).ToListAsync();

        int destIdx = 0;
        int restIdx = 0;

        foreach (var day in trip.Days.OrderBy(d => d.DayNumber))
        {
            int order = 1;
            if (destIdx < dests.Count)
            {
                var d1 = dests[destIdx++];
                _db.TripStops.Add(new TripStop
                {
                    TripDayId = day.Id,
                    TripId = trip.Id,
                    StopOrder = order++,
                    Kind = "destination",
                    PlaceId = $"d_{d1.Id}",
                    RefTable = "destinations",
                    RefId = d1.Id,
                    Name = d1.Name,
                    Address = d1.Address,
                    Lat = d1.Latitude,
                    Lng = d1.Longitude,
                    StayMins = 90,
                    Source = "ai"
                });
            }

            if (restIdx < rests.Count)
            {
                var r = rests[restIdx++];
                _db.TripStops.Add(new TripStop
                {
                    TripDayId = day.Id,
                    TripId = trip.Id,
                    StopOrder = order++,
                    Kind = "restaurant",
                    PlaceId = $"r_{r.Id}",
                    RefTable = "restaurants",
                    RefId = r.Id,
                    Name = r.Name,
                    Address = r.Address,
                    Lat = r.Latitude,
                    Lng = r.Longitude,
                    StayMins = 60,
                    Source = "ai"
                });
            }

            if (destIdx < dests.Count)
            {
                var d2 = dests[destIdx++];
                _db.TripStops.Add(new TripStop
                {
                    TripDayId = day.Id,
                    TripId = trip.Id,
                    StopOrder = order++,
                    Kind = "destination",
                    PlaceId = $"d_{d2.Id}",
                    RefTable = "destinations",
                    RefId = d2.Id,
                    Name = d2.Name,
                    Address = d2.Address,
                    Lat = d2.Latitude,
                    Lng = d2.Longitude,
                    StayMins = 90,
                    Source = "ai"
                });
            }
        }

        trip.AiGenerated = true;
        trip.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Ok(new GenerateItineraryResponse
        {
            TripId = trip.Id,
            Status = "completed",
            Message = "Lộ trình đã được tạo tự động thành công từ dữ liệu địa phương."
        });
    }

    [HttpGet("{trip_id}/ai-status")]
    public async Task<IActionResult> GetAiStatus(int trip_id)
    {
        var trip = await _db.Trips.FindAsync(trip_id);
        if (trip == null) return NotFound(new ErrorEnvelope("Chuyến đi không tồn tại."));

        return Ok(new AiStatusResponse
        {
            Status = "ready",
            ProgressPct = 100,
            Message = "Lịch trình đã sẵn sàng"
        });
    }
}
