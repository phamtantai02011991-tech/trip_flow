using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TripFlow.Api.Data;
using TripFlow.Api.Models.DTOs;

namespace TripFlow.Api.Controllers;

[ApiController]
[Route("api/v1/local-foods")]
public class LocalFoodsController : ControllerBase
{
    private readonly TripFlowDbContext _db;

    public LocalFoodsController(TripFlowDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<IActionResult> ListLocalFoods([FromQuery] int? province_id = null, [FromQuery] string? q = null)
    {
        var query = _db.LocalFoods
            .AsNoTracking()
            .Include(f => f.Province)
            .AsQueryable();

        if (province_id.HasValue)
        {
            query = query.Where(f => f.ProvinceId == province_id.Value);
        }

        if (!string.IsNullOrWhiteSpace(q))
        {
            var search = q.Trim().ToLower();
            query = query.Where(f => f.Name.ToLower().Contains(search) || f.Description.ToLower().Contains(search));
        }

        var foods = await query
            .OrderBy(f => f.Id)
            .Select(f => new LocalFoodDto
            {
                Id = f.Id,
                ProvinceId = f.ProvinceId,
                ProvinceName = f.Province != null ? f.Province.Name : null,
                Name = f.Name,
                Description = f.Description,
                StoryOrigin = f.StoryOrigin,
                ImageUrl = f.ImageUrl,
                ThumbnailUrl = f.ThumbnailUrl,
                BestSeasonOrTime = f.BestSeasonOrTime,
                AvgPriceRange = f.AvgPriceRange,
                Status = f.Status
            })
            .ToListAsync();

        return Ok(foods);
    }

    [HttpGet("{food_id}")]
    public async Task<IActionResult> GetLocalFoodDetail(int food_id)
    {
        var food = await _db.LocalFoods
            .AsNoTracking()
            .Include(f => f.Province)
            .FirstOrDefaultAsync(f => f.Id == food_id);

        if (food == null)
        {
            return NotFound(new ErrorEnvelope($"Không tìm thấy món ăn ID {food_id}."));
        }

        var restIds = new List<int>();
        if (!string.IsNullOrWhiteSpace(food.RecommendedRestaurantIdsJson))
        {
            try
            {
                restIds = JsonSerializer.Deserialize<List<int>>(food.RecommendedRestaurantIdsJson) ?? new();
            }
            catch { }
        }

        var restaurants = await _db.Restaurants
            .AsNoTracking()
            .Where(r => restIds.Contains(r.Id))
            .Select(r => new RestaurantDto
            {
                Id = r.Id,
                ProvinceId = r.ProvinceId,
                Name = r.Name,
                Address = r.Address,
                Rating = r.Rating,
                ReviewCount = r.ReviewCount,
                PriceRange = r.PriceRange,
                ImageUrl = r.ImageUrl,
                ThumbnailUrl = r.ThumbnailUrl
            })
            .ToListAsync();

        return Ok(new LocalFoodDto
        {
            Id = food.Id,
            ProvinceId = food.ProvinceId,
            ProvinceName = food.Province?.Name,
            Name = food.Name,
            Description = food.Description,
            StoryOrigin = food.StoryOrigin,
            ImageUrl = food.ImageUrl,
            ThumbnailUrl = food.ThumbnailUrl,
            BestSeasonOrTime = food.BestSeasonOrTime,
            AvgPriceRange = food.AvgPriceRange,
            Status = food.Status,
            RecommendedRestaurants = restaurants
        });
    }
}
