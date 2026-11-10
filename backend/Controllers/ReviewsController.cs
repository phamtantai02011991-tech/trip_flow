using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TripFlow.Api.Data;
using TripFlow.Api.Models.DTOs;
using TripFlow.Api.Models.Entities;
using TripFlow.Api.Services;

namespace TripFlow.Api.Controllers;

[ApiController]
[Route("api/v1/reviews")]
public class ReviewsController : ControllerBase
{
    private readonly TripFlowDbContext _db;
    private readonly ITokenService _tokenService;

    public ReviewsController(TripFlowDbContext db, ITokenService tokenService)
    {
        _db = db;
        _tokenService = tokenService;
    }

    [HttpGet("{place_key}")]
    public async Task<IActionResult> ListReviews(string place_key)
    {
        var reviews = await _db.PlaceReviews
            .AsNoTracking()
            .Where(r => r.PlaceKey == place_key && !r.IsHidden)
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => new ReviewDto
            {
                Id = r.Id,
                PlaceKey = r.PlaceKey,
                AuthorName = r.AuthorName,
                Rating = r.Rating,
                Comment = r.Comment,
                CreatedAt = r.CreatedAt
            })
            .ToListAsync();

        return Ok(reviews);
    }

    [HttpPost("{place_key}")]
    public async Task<IActionResult> CreateReview(string place_key, [FromBody] CreateReviewRequest req)
    {
        if (req.Rating < 1 || req.Rating > 5)
        {
            return BadRequest(new ErrorEnvelope("Điểm đánh giá phải từ 1 đến 5 sao."));
        }

        var userId = _tokenService.GetUserIdFromPrincipal(User);
        PlaceReview? existing = null;

        if (userId.HasValue)
        {
            existing = await _db.PlaceReviews.FirstOrDefaultAsync(r => r.PlaceKey == place_key && r.UserId == userId.Value);
        }

        var author = req.AuthorName ?? (userId.HasValue ? (await _db.Users.FindAsync(userId.Value))?.FullName : null) ?? "Du khách";

        if (existing != null)
        {
            existing.Rating = req.Rating;
            existing.Comment = req.Comment.Trim();
            existing.CreatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return Ok(new ReviewDto
            {
                Id = existing.Id,
                PlaceKey = existing.PlaceKey,
                AuthorName = existing.AuthorName,
                Rating = existing.Rating,
                Comment = existing.Comment,
                CreatedAt = existing.CreatedAt
            });
        }

        var review = new PlaceReview
        {
            PlaceKey = place_key,
            UserId = userId,
            AuthorName = author,
            Rating = req.Rating,
            Comment = req.Comment.Trim(),
            CreatedAt = DateTime.UtcNow,
            IsHidden = false
        };

        _db.PlaceReviews.Add(review);
        await _db.SaveChangesAsync();

        return Ok(new ReviewDto
        {
            Id = review.Id,
            PlaceKey = review.PlaceKey,
            AuthorName = review.AuthorName,
            Rating = review.Rating,
            Comment = review.Comment,
            CreatedAt = review.CreatedAt
        });
    }

    [HttpGet("{place_key}/summary")]
    public async Task<IActionResult> ReviewSummary(string place_key)
    {
        var reviews = await _db.PlaceReviews
            .AsNoTracking()
            .Where(r => r.PlaceKey == place_key && !r.IsHidden)
            .ToListAsync();

        int count = reviews.Count;
        double avg = count > 0 ? Math.Round(reviews.Average(r => r.Rating), 1) : 0.0;

        var dist = new Dictionary<string, int>
        {
            { "1", reviews.Count(r => r.Rating == 1) },
            { "2", reviews.Count(r => r.Rating == 2) },
            { "3", reviews.Count(r => r.Rating == 3) },
            { "4", reviews.Count(r => r.Rating == 4) },
            { "5", reviews.Count(r => r.Rating == 5) }
        };

        bool hiddenGem = avg >= 4.5 && count >= 3 && count <= 200;

        return Ok(new ReviewSummaryDto
        {
            PlaceKey = place_key,
            AvgRating = avg,
            ReviewCount = count,
            Distribution = dist,
            HiddenGem = hiddenGem
        });
    }

    [HttpDelete("{place_key}/{review_id}")]
    public async Task<IActionResult> DeleteReview(string place_key, int review_id)
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        var review = await _db.PlaceReviews.FirstOrDefaultAsync(r => r.Id == review_id && r.PlaceKey == place_key);
        if (review == null) return NotFound(new ErrorEnvelope("Đánh giá không tồn tại."));

        if (userId.HasValue && review.UserId == userId.Value)
        {
            _db.PlaceReviews.Remove(review);
            await _db.SaveChangesAsync();
            return Ok(new StatusResponse { Status = "ok", Message = "Đã xóa đánh giá." });
        }

        // Hoặc admin xóa
        var role = _tokenService.GetUserRoleFromPrincipal(User);
        if (role is "super_admin" or "moderator")
        {
            _db.PlaceReviews.Remove(review);
            await _db.SaveChangesAsync();
            return Ok(new StatusResponse { Status = "ok", Message = "Đã xóa đánh giá bởi quản trị viên." });
        }

        return Forbid();
    }
}
