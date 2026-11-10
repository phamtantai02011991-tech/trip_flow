using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TripFlow.Api.Data;
using TripFlow.Api.Models.DTOs;
using TripFlow.Api.Models.Entities;

namespace TripFlow.Api.Controllers;

[ApiController]
[Route("api/v1/provinces")]
public class ProvincesController : ControllerBase
{
    private readonly TripFlowDbContext _db;

    public ProvincesController(TripFlowDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<IActionResult> ListProvinces([FromQuery] string? region, [FromQuery] bool? is_active)
    {
        var query = _db.Provinces.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(region))
        {
            query = query.Where(p => p.Region == region);
        }

        if (is_active.HasValue)
        {
            query = query.Where(p => p.IsActive == is_active.Value);
        }

        var provinces = await query
            .Select(p => new ProvinceDto
            {
                Id = p.Id,
                Code = p.Code,
                Name = p.Name,
                Region = p.Region,
                Description = p.Description,
                HeroImage = p.HeroImage,
                CenterLat = p.CenterLat,
                CenterLng = p.CenterLng,
                IsActive = p.IsActive,
                DestinationCount = p.Destinations.Count,
                FoodCount = p.LocalFoods.Count,
                RestaurantCount = p.Restaurants.Count
            })
            .ToListAsync();

        return Ok(provinces);
    }

    [HttpGet("categories")]
    public async Task<IActionResult> ListCategories()
    {
        var categories = await _db.Categories
            .AsNoTracking()
            .Select(c => new CategoryDto
            {
                Id = c.Id,
                Code = c.Code,
                Name = c.Name,
                IconName = c.IconName,
                Description = c.Description
            })
            .ToListAsync();

        return Ok(categories);
    }

    [HttpGet("regions/summary")]
    public async Task<IActionResult> GetRegionsSummary()
    {
        var provinces = await _db.Provinces
            .AsNoTracking()
            .Select(p => new ProvinceDto
            {
                Id = p.Id,
                Code = p.Code,
                Name = p.Name,
                Region = p.Region,
                Description = p.Description,
                HeroImage = p.HeroImage,
                CenterLat = p.CenterLat,
                CenterLng = p.CenterLng,
                IsActive = p.IsActive,
                DestinationCount = p.Destinations.Count,
                FoodCount = p.LocalFoods.Count,
                RestaurantCount = p.Restaurants.Count
            })
            .ToListAsync();

        var summary = provinces
            .GroupBy(p => p.Region)
            .Select(g => new RegionSummaryDto
            {
                Region = g.Key,
                ProvinceCount = g.Count(),
                Provinces = g.ToList()
            })
            .ToList();

        return Ok(summary);
    }

    [HttpGet("{province_id}")]
    public async Task<IActionResult> GetProvinceDetail(int province_id)
    {
        var p = await _db.Provinces
            .AsNoTracking()
            .Where(x => x.Id == province_id)
            .Select(x => new ProvinceDto
            {
                Id = x.Id,
                Code = x.Code,
                Name = x.Name,
                Region = x.Region,
                Description = x.Description,
                HeroImage = x.HeroImage,
                CenterLat = x.CenterLat,
                CenterLng = x.CenterLng,
                IsActive = x.IsActive,
                DestinationCount = x.Destinations.Count,
                FoodCount = x.LocalFoods.Count,
                RestaurantCount = x.Restaurants.Count
            })
            .FirstOrDefaultAsync();

        if (p == null)
        {
            return NotFound(new ErrorEnvelope($"Không tìm thấy tỉnh thành có ID {province_id}."));
        }

        return Ok(p);
    }
}
