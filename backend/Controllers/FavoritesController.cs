using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TripFlow.Api.Data;
using TripFlow.Api.Models.DTOs;
using TripFlow.Api.Models.Entities;
using TripFlow.Api.Services;

namespace TripFlow.Api.Controllers;

[ApiController]
[Route("api/v1/favorites")]
public class FavoritesController : ControllerBase
{
    private readonly TripFlowDbContext _db;
    private readonly ITokenService _tokenService;

    public FavoritesController(TripFlowDbContext db, ITokenService tokenService)
    {
        _db = db;
        _tokenService = tokenService;
    }

    [HttpGet]
    public async Task<IActionResult> ListFavorites()
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        if (!userId.HasValue) return Ok(new List<FavoriteDto>());

        var favorites = await _db.Favorites
            .AsNoTracking()
            .Where(f => f.UserId == userId.Value)
            .OrderByDescending(f => f.CreatedAt)
            .ToListAsync();

        var result = new List<FavoriteDto>();
        foreach (var f in favorites)
        {
            object? target = null;
            if (f.TargetType == "destination")
            {
                target = await _db.Destinations.AsNoTracking().Where(d => d.Id == f.TargetId).Select(d => new { d.Id, d.Name, d.Address, d.ThumbnailUrl, d.Rating }).FirstOrDefaultAsync();
            }
            else if (f.TargetType == "restaurant")
            {
                target = await _db.Restaurants.AsNoTracking().Where(r => r.Id == f.TargetId).Select(r => new { r.Id, r.Name, r.Address, r.ThumbnailUrl, r.Rating }).FirstOrDefaultAsync();
            }

            result.Add(new FavoriteDto
            {
                Id = f.Id,
                TargetType = f.TargetType,
                TargetId = f.TargetId,
                CreatedAt = f.CreatedAt,
                Target = target
            });
        }

        return Ok(result);
    }

    [HttpPost]
    public async Task<IActionResult> ToggleFavorite([FromBody] FavoriteToggleRequest req)
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        if (!userId.HasValue) return Unauthorized(new ErrorEnvelope("Vui lòng đăng nhập để lưu mục yêu thích."));

        var existing = await _db.Favorites.FirstOrDefaultAsync(f => f.UserId == userId.Value && f.TargetType == req.TargetType && f.TargetId == req.TargetId);
        if (existing != null)
        {
            _db.Favorites.Remove(existing);
            await _db.SaveChangesAsync();
            return Ok(new FavoriteToggleResponse { Favorited = false });
        }

        var fav = new Favorite
        {
            UserId = userId.Value,
            TargetType = req.TargetType,
            TargetId = req.TargetId,
            CreatedAt = DateTime.UtcNow
        };
        _db.Favorites.Add(fav);
        await _db.SaveChangesAsync();

        return Ok(new FavoriteToggleResponse
        {
            Favorited = true,
            FavoriteId = fav.Id
        });
    }

    [HttpDelete("{favorite_id}")]
    public async Task<IActionResult> DeleteFavorite(int favorite_id)
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        if (!userId.HasValue) return Unauthorized(new ErrorEnvelope("Chưa đăng nhập."));

        var fav = await _db.Favorites.FirstOrDefaultAsync(f => f.Id == favorite_id && f.UserId == userId.Value);
        if (fav != null)
        {
            _db.Favorites.Remove(fav);
            await _db.SaveChangesAsync();
        }

        return Ok(new StatusResponse { Status = "ok", Message = "Đã bỏ yêu thích." });
    }
}
