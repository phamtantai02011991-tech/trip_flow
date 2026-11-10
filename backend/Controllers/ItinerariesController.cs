using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TripFlow.Api.Data;
using TripFlow.Api.Models.DTOs;
using TripFlow.Api.Models.Entities;
using TripFlow.Api.Services;

namespace TripFlow.Api.Controllers;

[ApiController]
[Route("api/v1/itineraries")]
public class ItinerariesController : ControllerBase
{
    private readonly TripFlowDbContext _db;
    private readonly ITokenService _tokenService;

    public ItinerariesController(TripFlowDbContext db, ITokenService tokenService)
    {
        _db = db;
        _tokenService = tokenService;
    }

    private static ItineraryDto MapToItineraryDto(Itinerary i) => new()
    {
        Id = i.Id,
        UserId = i.UserId,
        ProvinceId = i.ProvinceId,
        ProvinceName = i.Province?.Name,
        Title = i.Title,
        Description = i.Description,
        TotalDays = i.TotalDays,
        IsTemplate = i.IsTemplate,
        Status = i.Status,
        CreatedAt = i.CreatedAt,
        UpdatedAt = i.UpdatedAt,
        Stops = i.Stops.OrderBy(s => s.DayNumber).ThenBy(s => s.StopOrder).Select(s => new ItineraryStopDto
        {
            Id = s.Id,
            ItineraryId = s.ItineraryId,
            DayNumber = s.DayNumber,
            StopOrder = s.StopOrder,
            StopType = s.StopType,
            ReferenceId = s.ReferenceId,
            Title = s.Title,
            Address = s.Address,
            Latitude = s.Latitude,
            Longitude = s.Longitude,
            PlannedTime = s.PlannedTime,
            DurationMins = s.DurationMins,
            Notes = s.Notes
        }).ToList()
    };

    [HttpGet]
    public async Task<IActionResult> ListItineraries([FromQuery] int? province_id = null, [FromQuery] bool? is_template = null)
    {
        var query = _db.Itineraries
            .AsNoTracking()
            .Include(i => i.Province)
            .Include(i => i.Stops)
            .AsQueryable();

        if (province_id.HasValue) query = query.Where(i => i.ProvinceId == province_id.Value);
        if (is_template.HasValue) query = query.Where(i => i.IsTemplate == is_template.Value);

        var list = await query.OrderByDescending(i => i.IsTemplate).ThenBy(i => i.Id).ToListAsync();
        return Ok(list.Select(MapToItineraryDto).ToList());
    }

    [HttpPost]
    public async Task<IActionResult> CreateItinerary([FromBody] CreateItineraryRequest req)
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        var now = DateTime.UtcNow;

        var it = new Itinerary
        {
            UserId = userId,
            ProvinceId = req.ProvinceId,
            Title = req.Title.Trim(),
            Description = req.Description,
            TotalDays = req.TotalDays > 0 ? req.TotalDays : 1,
            IsTemplate = req.IsTemplate ?? false,
            Status = "active",
            CreatedAt = now,
            UpdatedAt = now
        };

        _db.Itineraries.Add(it);
        await _db.SaveChangesAsync();

        if (req.Stops != null && req.Stops.Count > 0)
        {
            foreach (var s in req.Stops)
            {
                _db.ItineraryStops.Add(new ItineraryStop
                {
                    ItineraryId = it.Id,
                    DayNumber = s.DayNumber,
                    StopOrder = s.StopOrder,
                    StopType = s.StopType,
                    ReferenceId = s.ReferenceId,
                    Title = s.Title,
                    Address = s.Address,
                    Latitude = s.Latitude,
                    Longitude = s.Longitude,
                    PlannedTime = s.PlannedTime,
                    DurationMins = s.DurationMins,
                    Notes = s.Notes
                });
            }
            await _db.SaveChangesAsync();
        }

        var loaded = await _db.Itineraries
            .Include(i => i.Province)
            .Include(i => i.Stops)
            .FirstAsync(i => i.Id == it.Id);

        return Ok(MapToItineraryDto(loaded));
    }

    [HttpPost("sync")]
    public async Task<IActionResult> SyncOffline([FromBody] SyncItineraryRequest req)
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        var now = DateTime.UtcNow;
        var createdList = new List<ItineraryDto>();

        foreach (var item in req.Itineraries)
        {
            var it = new Itinerary
            {
                UserId = userId,
                ProvinceId = item.ProvinceId,
                Title = item.Title.Trim(),
                Description = item.Description,
                TotalDays = item.TotalDays,
                IsTemplate = false,
                Status = "active",
                CreatedAt = now,
                UpdatedAt = now
            };
            _db.Itineraries.Add(it);
            await _db.SaveChangesAsync();

            if (item.Stops != null)
            {
                foreach (var s in item.Stops)
                {
                    _db.ItineraryStops.Add(new ItineraryStop
                    {
                        ItineraryId = it.Id,
                        DayNumber = s.DayNumber,
                        StopOrder = s.StopOrder,
                        StopType = s.StopType,
                        ReferenceId = s.ReferenceId,
                        Title = s.Title,
                        Address = s.Address,
                        Latitude = s.Latitude,
                        Longitude = s.Longitude,
                        PlannedTime = s.PlannedTime,
                        DurationMins = s.DurationMins,
                        Notes = s.Notes
                    });
                }
                await _db.SaveChangesAsync();
            }

            var loaded = await _db.Itineraries.Include(i => i.Province).Include(i => i.Stops).FirstAsync(i => i.Id == it.Id);
            createdList.Add(MapToItineraryDto(loaded));
        }

        return Ok(createdList);
    }

    [HttpGet("{itinerary_id}")]
    public async Task<IActionResult> GetItineraryDetail(int itinerary_id)
    {
        var it = await _db.Itineraries
            .Include(i => i.Province)
            .Include(i => i.Stops)
            .FirstOrDefaultAsync(i => i.Id == itinerary_id);

        if (it == null) return NotFound(new ErrorEnvelope("Lịch trình không tồn tại."));
        return Ok(MapToItineraryDto(it));
    }

    [HttpPut("{itinerary_id}")]
    public async Task<IActionResult> UpdateItinerary(int itinerary_id, [FromBody] CreateItineraryRequest req)
    {
        var it = await _db.Itineraries.Include(i => i.Province).Include(i => i.Stops).FirstOrDefaultAsync(i => i.Id == itinerary_id);
        if (it == null) return NotFound(new ErrorEnvelope("Lịch trình không tồn tại."));

        if (!string.IsNullOrWhiteSpace(req.Title)) it.Title = req.Title.Trim();
        if (req.Description != null) it.Description = req.Description;
        if (req.TotalDays > 0) it.TotalDays = req.TotalDays;
        if (req.ProvinceId > 0) it.ProvinceId = req.ProvinceId;

        it.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Ok(MapToItineraryDto(it));
    }

    [HttpDelete("{itinerary_id}")]
    public async Task<IActionResult> DeleteItinerary(int itinerary_id)
    {
        var it = await _db.Itineraries.FindAsync(itinerary_id);
        if (it == null) return NotFound(new ErrorEnvelope("Lịch trình không tồn tại."));

        _db.Itineraries.Remove(it);
        await _db.SaveChangesAsync();

        return Ok(new StatusResponse { Status = "ok", Message = "Đã xóa lịch trình." });
    }

    [HttpPost("{itinerary_id}/stops")]
    public async Task<IActionResult> AddStopEndpoint(int itinerary_id, [FromBody] ItineraryStopDto req)
    {
        var it = await _db.Itineraries.FindAsync(itinerary_id);
        if (it == null) return NotFound(new ErrorEnvelope("Lịch trình không tồn tại."));

        var stop = new ItineraryStop
        {
            ItineraryId = it.Id,
            DayNumber = req.DayNumber,
            StopOrder = req.StopOrder,
            StopType = req.StopType,
            ReferenceId = req.ReferenceId,
            Title = req.Title,
            Address = req.Address,
            Latitude = req.Latitude,
            Longitude = req.Longitude,
            PlannedTime = req.PlannedTime,
            DurationMins = req.DurationMins,
            Notes = req.Notes
        };

        _db.ItineraryStops.Add(stop);
        it.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Ok(req);
    }

    [HttpPost("{itinerary_id}/smart-meal-stops")]
    public async Task<IActionResult> InsertSmartMealStop(int itinerary_id, [FromBody] SmartMealStopsRequest req)
    {
        var it = await _db.Itineraries.Include(i => i.Stops).FirstOrDefaultAsync(i => i.Id == itinerary_id);
        if (it == null) return NotFound(new ErrorEnvelope("Lịch trình không tồn tại."));

        var restaurant = await _db.Restaurants.Where(r => r.ProvinceId == it.ProvinceId).OrderByDescending(r => r.Rating).FirstOrDefaultAsync();
        if (restaurant != null)
        {
            var stop = new ItineraryStop
            {
                ItineraryId = it.Id,
                DayNumber = req.DayNumber,
                StopOrder = 2,
                StopType = "meal",
                ReferenceId = restaurant.Id,
                Title = req.MealType == "dinner" ? $"Ăn tối tại {restaurant.Name}" : $"Ăn trưa tại {restaurant.Name}",
                Address = restaurant.Address,
                Latitude = restaurant.Latitude,
                Longitude = restaurant.Longitude,
                PlannedTime = req.MealType == "dinner" ? "18:30 - 20:00" : "12:00 - 13:15",
                DurationMins = 75,
                Notes = $"Đặc sản: {restaurant.SpecialtyDishes}"
            };
            _db.ItineraryStops.Add(stop);
            await _db.SaveChangesAsync();
        }

        var loaded = await _db.Itineraries.Include(i => i.Province).Include(i => i.Stops).FirstAsync(i => i.Id == it.Id);
        return Ok(MapToItineraryDto(loaded));
    }
}
