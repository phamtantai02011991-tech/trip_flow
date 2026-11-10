using Microsoft.AspNetCore.Mvc;
using TripFlow.Api.Models.DTOs;
using TripFlow.Api.Services;

namespace TripFlow.Api.Controllers;

[ApiController]
[Route("api/v1/maps")]
public class MapsController : ControllerBase
{
    private readonly IGeoService _geoService;

    public MapsController(IGeoService geoService)
    {
        _geoService = geoService;
    }

    [HttpGet("directions")]
    public IActionResult GetDirections(
        [FromQuery] double origin_lat,
        [FromQuery] double origin_lng,
        [FromQuery] double dest_lat,
        [FromQuery] double dest_lng,
        [FromQuery] string vehicle = "motorbike")
    {
        double distKm = Math.Round(_geoService.DistanceKm(origin_lat, origin_lng, dest_lat, dest_lng), 2);
        double speedKmH = vehicle == "car" ? 45.0 : 35.0;
        int durationMins = Math.Max(5, (int)Math.Round((distKm / speedKmH) * 60));

        var steps = new List<object>
        {
            new { instruction = "Xuất phát theo tuyến đường chính", distance_km = Math.Round(distKm * 0.2, 2) },
            new { instruction = "Tiếp tục chạy thẳng theo quốc lộ", distance_km = Math.Round(distKm * 0.6, 2) },
            new { instruction = "Rẽ vào điểm đến", distance_km = Math.Round(distKm * 0.2, 2) }
        };

        return Ok(new DirectionsResponse
        {
            DistanceKm = distKm,
            DurationMins = durationMins,
            Polyline = $"{origin_lat},{origin_lng};{dest_lat},{dest_lng}",
            Steps = steps
        });
    }
}
