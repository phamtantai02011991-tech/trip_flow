using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TripFlow.Api.Data;
using TripFlow.Api.Models.DTOs;
using TripFlow.Api.Models.Entities;
using TripFlow.Api.Services;

namespace TripFlow.Api.Controllers;

[ApiController]
[Route("api/v1/destinations")]
public class DestinationsController : ControllerBase
{
    private readonly TripFlowDbContext _db;
    private readonly ITokenService _tokenService;

    public DestinationsController(TripFlowDbContext db, ITokenService tokenService)
    {
        _db = db;
        _tokenService = tokenService;
    }

    [HttpGet]
    public async Task<IActionResult> ListDestinations(
        [FromQuery] int page = 1,
        [FromQuery] int page_size = 20,
        [FromQuery] int? province_id = null,
        [FromQuery] int? category_id = null,
        [FromQuery] string? q = null,
        [FromQuery] bool? is_featured = null,
        [FromQuery] bool? is_verified = null)
    {
        if (page < 1) page = 1;
        if (page_size < 1) page_size = 20;

        var query = _db.Destinations
            .AsNoTracking()
            .Include(d => d.Province)
            .Include(d => d.Category)
            .Include(d => d.Images)
            .AsQueryable();

        if (province_id.HasValue) query = query.Where(d => d.ProvinceId == province_id.Value);
        if (category_id.HasValue) query = query.Where(d => d.CategoryId == category_id.Value);
        if (is_featured.HasValue) query = query.Where(d => d.IsFeatured == is_featured.Value);
        if (is_verified.HasValue) query = query.Where(d => d.IsVerified == is_verified.Value);

        if (!string.IsNullOrWhiteSpace(q))
        {
            var search = q.Trim().ToLower();
            query = query.Where(d => d.Name.ToLower().Contains(search) || d.Description.ToLower().Contains(search) || d.Address.ToLower().Contains(search));
        }

        int total = await query.CountAsync();
        var items = await query
            .OrderByDescending(d => d.IsFeatured)
            .ThenByDescending(d => d.Rating)
            .Skip((page - 1) * page_size)
            .Take(page_size)
            .Select(d => new DestinationDto
            {
                Id = d.Id,
                ProvinceId = d.ProvinceId,
                ProvinceName = d.Province != null ? d.Province.Name : null,
                CategoryId = d.CategoryId,
                CategoryName = d.Category != null ? d.Category.Name : null,
                Name = d.Name,
                Slug = d.Slug,
                Description = d.Description,
                Address = d.Address,
                Latitude = d.Latitude,
                Longitude = d.Longitude,
                OpeningHours = d.OpeningHours,
                TicketPriceInfo = d.TicketPriceInfo,
                Rating = d.Rating,
                ReviewCount = d.ReviewCount,
                RecommendedDurationMins = d.RecommendedDurationMins,
                ThumbnailUrl = d.ThumbnailUrl,
                DetailImageUrl = d.DetailImageUrl,
                IsFeatured = d.IsFeatured,
                IsSponsored = d.IsSponsored,
                SponsorLabel = d.SponsorLabel,
                IsVerified = d.IsVerified,
                Source = d.Source,
                SourceUrl = d.SourceUrl,
                Status = d.Status,
                DataSource = d.DataSource,
                SourceAttribution = d.SourceAttribution,
                Images = d.Images.Select(img => new DestinationImageDto
                {
                    Id = img.Id,
                    DestinationId = img.DestinationId,
                    ImageUrl = img.ImageUrl,
                    ThumbnailUrl = img.ThumbnailUrl,
                    Caption = img.Caption,
                    SortOrder = img.SortOrder,
                    LicenseType = img.LicenseType,
                    CreditAuthor = img.CreditAuthor
                }).ToList()
            })
            .ToListAsync();

        return Ok(new PaginatedResponse<DestinationDto>
        {
            Total = total,
            Page = page,
            PageSize = page_size,
            Items = items
        });
    }

    [HttpGet("{destination_id}")]
    public async Task<IActionResult> GetDestinationDetail(int destination_id)
    {
        var d = await _db.Destinations
            .AsNoTracking()
            .Include(x => x.Province)
            .Include(x => x.Category)
            .Include(x => x.Images)
            .FirstOrDefaultAsync(x => x.Id == destination_id);

        if (d == null)
        {
            return NotFound(new ErrorEnvelope($"Không tìm thấy địa điểm ID {destination_id}."));
        }

        var related = await _db.Destinations
            .AsNoTracking()
            .Where(x => x.ProvinceId == d.ProvinceId && x.Id != d.Id)
            .Take(4)
            .Select(x => new DestinationDto
            {
                Id = x.Id,
                ProvinceId = x.ProvinceId,
                Name = x.Name,
                ThumbnailUrl = x.ThumbnailUrl,
                Rating = x.Rating,
                Address = x.Address,
                Latitude = x.Latitude,
                Longitude = x.Longitude
            })
            .ToListAsync();

        var detail = new DestinationDetailDto
        {
            Id = d.Id,
            ProvinceId = d.ProvinceId,
            ProvinceName = d.Province?.Name,
            CategoryId = d.CategoryId,
            CategoryName = d.Category?.Name,
            Name = d.Name,
            Slug = d.Slug,
            Description = d.Description,
            Address = d.Address,
            Latitude = d.Latitude,
            Longitude = d.Longitude,
            OpeningHours = d.OpeningHours,
            TicketPriceInfo = d.TicketPriceInfo,
            Rating = d.Rating,
            ReviewCount = d.ReviewCount,
            RecommendedDurationMins = d.RecommendedDurationMins,
            ThumbnailUrl = d.ThumbnailUrl,
            DetailImageUrl = d.DetailImageUrl,
            IsFeatured = d.IsFeatured,
            IsSponsored = d.IsSponsored,
            SponsorLabel = d.SponsorLabel,
            IsVerified = d.IsVerified,
            Source = d.Source,
            SourceUrl = d.SourceUrl,
            Status = d.Status,
            DataSource = d.DataSource,
            SourceAttribution = d.SourceAttribution,
            Images = d.Images.Select(img => new DestinationImageDto
            {
                Id = img.Id,
                DestinationId = img.DestinationId,
                ImageUrl = img.ImageUrl,
                ThumbnailUrl = img.ThumbnailUrl,
                Caption = img.Caption,
                SortOrder = img.SortOrder,
                LicenseType = img.LicenseType,
                CreditAuthor = img.CreditAuthor
            }).ToList(),
            RelatedDestinations = related
        };

        return Ok(detail);
    }

    [HttpPost("{destination_id}/report")]
    public async Task<IActionResult> ReportDestination(int destination_id, [FromBody] ReportRequest req)
    {
        var d = await _db.Destinations.FindAsync(destination_id);
        if (d == null)
        {
            return NotFound(new ErrorEnvelope("Địa điểm không tồn tại."));
        }

        var userId = _tokenService.GetUserIdFromPrincipal(User);

        var report = new ContentReport
        {
            UserId = userId,
            TargetType = "destination",
            TargetId = d.Id,
            TargetName = d.Name,
            IssueType = req.IssueType,
            Description = req.Description,
            Rating = req.Rating,
            Status = "pending",
            CreatedAt = DateTime.UtcNow
        };

        _db.ContentReports.Add(report);
        await _db.SaveChangesAsync();

        return Ok(new StatusResponse { Status = "ok", Message = "Cảm ơn bạn đã gửi phản hồi. Ban quản trị sẽ rà soát thông tin." });
    }
}
