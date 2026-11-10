using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TripFlow.Api.Data;
using TripFlow.Api.Models.DTOs;

namespace TripFlow.Api.Controllers;

[ApiController]
[Route("api/v1/assistant")]
public class AssistantController : ControllerBase
{
    private readonly TripFlowDbContext _db;

    public AssistantController(TripFlowDbContext db)
    {
        _db = db;
    }

    [HttpPost("chat")]
    public async Task<IActionResult> Chat([FromBody] ChatRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Message))
        {
            return BadRequest(new ErrorEnvelope("Nội dung tin nhắn không được để trống."));
        }

        var provId = req.ProvinceId ?? 1;
        var places = await _db.Destinations
            .AsNoTracking()
            .Where(d => d.ProvinceId == provId)
            .OrderByDescending(d => d.Rating)
            .Take(3)
            .Select(d => new
            {
                id = $"d_{d.Id}",
                name = d.Name,
                address = d.Address,
                rating = d.Rating,
                thumbnail_url = d.ThumbnailUrl
            })
            .ToListAsync();

        var reply = $"Chào bạn! TripFlow AI Assistant rất vui được đồng hành cùng bạn. Với yêu cầu '{req.Message}', mình xin gợi ý các địa điểm tiêu biểu và phù hợp nhất tại khu vực.";

        return Ok(new ChatResponse
        {
            Reply = reply,
            SuggestedPlaces = places.Cast<object>().ToList()
        });
    }
}
