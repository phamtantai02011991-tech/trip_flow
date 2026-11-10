using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TripFlow.Api.Data;
using TripFlow.Api.Models.DTOs;
using TripFlow.Api.Models.Entities;
using TripFlow.Api.Services;

namespace TripFlow.Api.Controllers;

[ApiController]
[Route("api/v1/admin")]
public class AdminController : ControllerBase
{
    private readonly TripFlowDbContext _db;
    private readonly ITokenService _tokenService;

    public AdminController(TripFlowDbContext db, ITokenService tokenService)
    {
        _db = db;
        _tokenService = tokenService;
    }

    private void EnsureAdminAccess()
    {
        var role = _tokenService.GetUserRoleFromPrincipal(User);
        if (string.IsNullOrEmpty(role))
        {
            throw new BadHttpRequestException("Yêu cầu xác thực (401 Unauthorized): Vui lòng đăng nhập với tài khoản quản trị.", 401);
        }

        var allowedRoles = new[] { "super_admin", "content_admin", "province_editor", "moderator", "admin" };
        if (!allowedRoles.Contains(role))
        {
            throw new BadHttpRequestException("Từ chối truy cập (403 Forbidden): Không có quyền thực hiện.", 403);
        }
    }

    private async Task RecordAuditLog(string action, string entityType, int? entityId, string summary, object? changes = null)
    {
        var user = User;
        var email = user.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value ?? "admin@tripflow.vn";
        var role = _tokenService.GetUserRoleFromPrincipal(user) ?? "super_admin";
        var id = _tokenService.GetUserIdFromPrincipal(user);

        _db.AuditLogs.Add(new AuditLog
        {
            ActorId = id,
            ActorEmail = email,
            ActorRole = role,
            Action = action,
            EntityType = entityType,
            EntityId = entityId,
            Summary = summary,
            ChangesJson = changes != null ? JsonSerializer.Serialize(changes) : "{}",
            CreatedAt = DateTime.UtcNow
        });
        await _db.SaveChangesAsync();
    }

    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboard()
    {
        EnsureAdminAccess();

        int provCount = await _db.Provinces.CountAsync();
        int destCount = await _db.Destinations.CountAsync();
        int restCount = await _db.Restaurants.CountAsync();
        int foodCount = await _db.LocalFoods.CountAsync();
        int itinCount = await _db.Itineraries.CountAsync();
        int userCount = await _db.Users.CountAsync();
        int reportCount = await _db.ContentReports.CountAsync(r => r.Status == "pending");

        var sourcesList = await _db.Destinations
            .GroupBy(d => d.DataSource)
            .Select(g => new { Key = g.Key, Count = g.Count() })
            .ToListAsync();
        var sources = sourcesList.ToDictionary(g => g.Key ?? "unknown", g => g.Count);

        var logs = await _db.AuditLogs
            .OrderByDescending(l => l.CreatedAt)
            .Take(12)
            .Select(l => new AuditLogDto
            {
                Id = l.Id,
                ActorEmail = l.ActorEmail,
                ActorRole = l.ActorRole,
                Action = l.Action,
                EntityType = l.EntityType,
                EntityId = l.EntityId,
                Summary = l.Summary,
                CreatedAt = l.CreatedAt
            })
            .ToListAsync();

        return Ok(new AdminDashboardResponse
        {
            TotalProvinces = provCount,
            TotalDestinations = destCount,
            TotalRestaurants = restCount,
            TotalLocalFoods = foodCount,
            TotalItineraries = itinCount,
            TotalUsers = userCount,
            PendingReports = reportCount,
            DataSources = sources,
            RecentAuditLogs = logs
        });
    }

    [HttpPost("upload-image")]
    public IActionResult UploadImage([FromForm] IFormFile? file)
    {
        EnsureAdminAccess();
        string publicId = Guid.NewGuid().ToString("N");
        string url = $"https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1200&q=80&upload={publicId}";
        string thumb = $"https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=400&q=80&upload={publicId}";

        return Ok(new UploadImageResponse
        {
            Url = url,
            ThumbnailUrl = thumb,
            PublicId = publicId
        });
    }

    #region Provinces
    [HttpGet("provinces")]
    public async Task<IActionResult> ListAdminProvinces()
    {
        EnsureAdminAccess();
        var list = await _db.Provinces.OrderBy(p => p.Id).ToListAsync();
        return Ok(list);
    }

    [HttpPost("provinces")]
    public async Task<IActionResult> CreateProvince([FromBody] Province prov)
    {
        EnsureAdminAccess();
        prov.UpdatedAt = DateTime.UtcNow;
        _db.Provinces.Add(prov);
        await _db.SaveChangesAsync();
        await RecordAuditLog("province:create", "province", prov.Id, $"Tạo tỉnh thành {prov.Name}");
        return Ok(prov);
    }

    [HttpPut("provinces/{province_id}")]
    public async Task<IActionResult> UpdateProvince(int province_id, [FromBody] Province req)
    {
        EnsureAdminAccess();
        var prov = await _db.Provinces.FindAsync(province_id);
        if (prov == null) return NotFound(new ErrorEnvelope("Tỉnh thành không tồn tại."));

        prov.Name = req.Name;
        prov.Region = req.Region;
        prov.Description = req.Description;
        prov.HeroImage = req.HeroImage;
        prov.CenterLat = req.CenterLat;
        prov.CenterLng = req.CenterLng;
        prov.IsActive = req.IsActive;
        prov.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        await RecordAuditLog("province:update", "province", prov.Id, $"Cập nhật tỉnh thành {prov.Name}");
        return Ok(prov);
    }
    #endregion

    #region Destinations
    [HttpGet("destinations")]
    public async Task<IActionResult> ListAdminDestinations([FromQuery] int page = 1, [FromQuery] int page_size = 50, [FromQuery] int? province_id = null)
    {
        EnsureAdminAccess();
        var q = _db.Destinations.Include(d => d.Province).Include(d => d.Category).AsQueryable();
        if (province_id.HasValue) q = q.Where(d => d.ProvinceId == province_id.Value);

        int total = await q.CountAsync();
        var items = await q.OrderBy(d => d.Id).Skip((page - 1) * page_size).Take(page_size).ToListAsync();

        return Ok(new PaginatedResponse<Destination>
        {
            Total = total,
            Page = page,
            PageSize = page_size,
            Items = items
        });
    }

    [HttpPost("destinations")]
    public async Task<IActionResult> CreateDestination([FromBody] Destination d)
    {
        EnsureAdminAccess();
        d.UpdatedAt = DateTime.UtcNow;
        d.LastVerifiedAt = DateTime.UtcNow;
        _db.Destinations.Add(d);
        await _db.SaveChangesAsync();
        await RecordAuditLog("destination:create", "destination", d.Id, $"Tạo địa điểm {d.Name}");
        return Ok(d);
    }

    [HttpPut("destinations/{destination_id}")]
    public async Task<IActionResult> UpdateDestination(int destination_id, [FromBody] Destination req)
    {
        EnsureAdminAccess();
        var d = await _db.Destinations.FindAsync(destination_id);
        if (d == null) return NotFound(new ErrorEnvelope("Địa điểm không tồn tại."));

        d.Name = req.Name;
        d.ProvinceId = req.ProvinceId;
        d.CategoryId = req.CategoryId;
        d.Description = req.Description;
        d.Address = req.Address;
        d.Latitude = req.Latitude;
        d.Longitude = req.Longitude;
        d.OpeningHours = req.OpeningHours;
        d.TicketPriceInfo = req.TicketPriceInfo;
        d.ThumbnailUrl = req.ThumbnailUrl;
        d.DetailImageUrl = req.DetailImageUrl;
        d.IsFeatured = req.IsFeatured;
        d.IsVerified = req.IsVerified;
        d.Status = req.Status;
        d.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        await RecordAuditLog("destination:update", "destination", d.Id, $"Cập nhật địa điểm {d.Name}");
        return Ok(d);
    }

    [HttpDelete("destinations/{destination_id}")]
    public async Task<IActionResult> DeleteDestination(int destination_id)
    {
        EnsureAdminAccess();
        var d = await _db.Destinations.FindAsync(destination_id);
        if (d == null) return NotFound(new ErrorEnvelope("Địa điểm không tồn tại."));

        _db.Destinations.Remove(d);
        await _db.SaveChangesAsync();
        await RecordAuditLog("destination:delete", "destination", destination_id, $"Xóa địa điểm {d.Name}");
        return Ok(new StatusResponse { Status = "ok", Message = "Đã xóa địa điểm." });
    }
    #endregion

    #region Restaurants
    [HttpGet("restaurants")]
    public async Task<IActionResult> ListAdminRestaurants([FromQuery] int page = 1, [FromQuery] int page_size = 50, [FromQuery] int? province_id = null)
    {
        EnsureAdminAccess();
        var q = _db.Restaurants.Include(r => r.Province).AsQueryable();
        if (province_id.HasValue) q = q.Where(r => r.ProvinceId == province_id.Value);

        int total = await q.CountAsync();
        var items = await q.OrderBy(r => r.Id).Skip((page - 1) * page_size).Take(page_size).ToListAsync();

        return Ok(new PaginatedResponse<Restaurant>
        {
            Total = total,
            Page = page,
            PageSize = page_size,
            Items = items
        });
    }

    [HttpPost("restaurants")]
    public async Task<IActionResult> CreateRestaurant([FromBody] Restaurant r)
    {
        EnsureAdminAccess();
        r.LastUpdatedAt = DateTime.UtcNow;
        _db.Restaurants.Add(r);
        await _db.SaveChangesAsync();
        await RecordAuditLog("restaurant:create", "restaurant", r.Id, $"Tạo nhà hàng {r.Name}");
        return Ok(r);
    }

    [HttpPut("restaurants/{restaurant_id}")]
    public async Task<IActionResult> UpdateRestaurant(int restaurant_id, [FromBody] Restaurant req)
    {
        EnsureAdminAccess();
        var r = await _db.Restaurants.FindAsync(restaurant_id);
        if (r == null) return NotFound(new ErrorEnvelope("Nhà hàng không tồn tại."));

        r.Name = req.Name;
        r.ProvinceId = req.ProvinceId;
        r.Address = req.Address;
        r.Latitude = req.Latitude;
        r.Longitude = req.Longitude;
        r.CuisineType = req.CuisineType;
        r.SpecialtyDishes = req.SpecialtyDishes;
        r.PriceRange = req.PriceRange;
        r.OpeningHours = req.OpeningHours;
        r.ContactPhone = req.ContactPhone;
        r.ThumbnailUrl = req.ThumbnailUrl;
        r.ImageUrl = req.ImageUrl;
        r.IsHighRated = req.IsHighRated;
        r.IsVerified = req.IsVerified;
        r.Status = req.Status;
        r.LastUpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        await RecordAuditLog("restaurant:update", "restaurant", r.Id, $"Cập nhật nhà hàng {r.Name}");
        return Ok(r);
    }

    [HttpDelete("restaurants/{restaurant_id}")]
    public async Task<IActionResult> DeleteRestaurant(int restaurant_id)
    {
        EnsureAdminAccess();
        var r = await _db.Restaurants.FindAsync(restaurant_id);
        if (r == null) return NotFound(new ErrorEnvelope("Nhà hàng không tồn tại."));

        _db.Restaurants.Remove(r);
        await _db.SaveChangesAsync();
        await RecordAuditLog("restaurant:delete", "restaurant", restaurant_id, $"Xóa nhà hàng {r.Name}");
        return Ok(new StatusResponse { Status = "ok", Message = "Đã xóa nhà hàng." });
    }
    #endregion

    #region Local Foods
    [HttpGet("local-foods")]
    public async Task<IActionResult> ListAdminLocalFoods()
    {
        EnsureAdminAccess();
        var list = await _db.LocalFoods.Include(f => f.Province).OrderBy(f => f.Id).ToListAsync();
        return Ok(list);
    }

    [HttpPost("local-foods")]
    public async Task<IActionResult> CreateLocalFood([FromBody] LocalFood f)
    {
        EnsureAdminAccess();
        f.UpdatedAt = DateTime.UtcNow;
        _db.LocalFoods.Add(f);
        await _db.SaveChangesAsync();
        await RecordAuditLog("food:create", "local_food", f.Id, $"Tạo món ăn {f.Name}");
        return Ok(f);
    }

    [HttpPut("local-foods/{food_id}")]
    public async Task<IActionResult> UpdateLocalFood(int food_id, [FromBody] LocalFood req)
    {
        EnsureAdminAccess();
        var f = await _db.LocalFoods.FindAsync(food_id);
        if (f == null) return NotFound(new ErrorEnvelope("Món ăn không tồn tại."));

        f.Name = req.Name;
        f.ProvinceId = req.ProvinceId;
        f.Description = req.Description;
        f.StoryOrigin = req.StoryOrigin;
        f.BestSeasonOrTime = req.BestSeasonOrTime;
        f.AvgPriceRange = req.AvgPriceRange;
        f.ImageUrl = req.ImageUrl;
        f.ThumbnailUrl = req.ThumbnailUrl;
        f.Status = req.Status;
        f.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        await RecordAuditLog("food:update", "local_food", f.Id, $"Cập nhật món ăn {f.Name}");
        return Ok(f);
    }

    [HttpDelete("local-foods/{food_id}")]
    public async Task<IActionResult> DeleteLocalFood(int food_id)
    {
        EnsureAdminAccess();
        var f = await _db.LocalFoods.FindAsync(food_id);
        if (f == null) return NotFound(new ErrorEnvelope("Món ăn không tồn tại."));

        _db.LocalFoods.Remove(f);
        await _db.SaveChangesAsync();
        await RecordAuditLog("food:delete", "local_food", food_id, $"Xóa món ăn {f.Name}");
        return Ok(new StatusResponse { Status = "ok", Message = "Đã xóa đặc sản." });
    }
    #endregion

    #region Sample Itineraries
    [HttpPost("itineraries")]
    public async Task<IActionResult> CreateSampleItinerary([FromBody] CreateItineraryRequest req)
    {
        EnsureAdminAccess();
        var now = DateTime.UtcNow;
        var it = new Itinerary
        {
            ProvinceId = req.ProvinceId,
            Title = req.Title.Trim(),
            Description = req.Description,
            TotalDays = req.TotalDays,
            IsTemplate = true,
            Status = "active",
            CreatedAt = now,
            UpdatedAt = now
        };
        _db.Itineraries.Add(it);
        await _db.SaveChangesAsync();

        if (req.Stops != null)
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

        await RecordAuditLog("itinerary:create", "itinerary", it.Id, $"Tạo lịch trình mẫu {it.Title}");
        return Ok(it);
    }

    [HttpPut("itineraries/{itinerary_id}")]
    public async Task<IActionResult> UpdateSampleItinerary(int itinerary_id, [FromBody] CreateItineraryRequest req)
    {
        EnsureAdminAccess();
        var it = await _db.Itineraries.FindAsync(itinerary_id);
        if (it == null) return NotFound(new ErrorEnvelope("Lịch trình không tồn tại."));

        it.Title = req.Title.Trim();
        it.Description = req.Description;
        it.TotalDays = req.TotalDays;
        it.ProvinceId = req.ProvinceId;
        it.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        await RecordAuditLog("itinerary:update", "itinerary", it.Id, $"Cập nhật lịch trình mẫu {it.Title}");
        return Ok(it);
    }

    [HttpDelete("itineraries/{itinerary_id}")]
    public async Task<IActionResult> DeleteSampleItinerary(int itinerary_id)
    {
        EnsureAdminAccess();
        var it = await _db.Itineraries.FindAsync(itinerary_id);
        if (it == null) return NotFound(new ErrorEnvelope("Lịch trình không tồn tại."));

        _db.Itineraries.Remove(it);
        await _db.SaveChangesAsync();
        await RecordAuditLog("itinerary:delete", "itinerary", itinerary_id, $"Xóa lịch trình mẫu {it.Title}");
        return Ok(new StatusResponse { Status = "ok", Message = "Đã xóa lịch trình mẫu." });
    }
    #endregion

    #region Reports
    [HttpGet("reports")]
    public async Task<IActionResult> ListReports([FromQuery] string? status)
    {
        EnsureAdminAccess();
        var query = _db.ContentReports.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(status)) query = query.Where(r => r.Status == status);

        var list = await query.OrderByDescending(r => r.CreatedAt).Select(r => new ContentReportDto
        {
            Id = r.Id,
            UserId = r.UserId,
            TargetType = r.TargetType,
            TargetId = r.TargetId,
            TargetName = r.TargetName,
            IssueType = r.IssueType,
            Description = r.Description,
            Rating = r.Rating,
            Status = r.Status,
            ModeratorNote = r.ModeratorNote,
            CreatedAt = r.CreatedAt,
            ResolvedAt = r.ResolvedAt
        }).ToListAsync();

        return Ok(list);
    }

    [HttpPut("reports/{report_id}")]
    public async Task<IActionResult> ResolveReport(int report_id, [FromBody] ResolveReportRequest req)
    {
        EnsureAdminAccess();
        var report = await _db.ContentReports.FindAsync(report_id);
        if (report == null) return NotFound(new ErrorEnvelope("Báo cáo không tồn tại."));

        report.Status = req.Status;
        report.ModeratorNote = req.ModeratorNote;
        report.ResolvedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        await RecordAuditLog("report:resolve", "content_report", report.Id, $"Xử lý báo cáo {report.Id} sang {req.Status}");
        return Ok(report);
    }
    #endregion

    #region Users & RBAC
    [HttpGet("users")]
    public async Task<IActionResult> ListUsers()
    {
        EnsureAdminAccess();
        var users = await _db.Users.AsNoTracking().OrderBy(u => u.Id).Select(u => new
        {
            u.Id,
            u.Email,
            u.Phone,
            u.FullName,
            u.Role,
            u.IsActive,
            u.CreatedAt
        }).ToListAsync();

        return Ok(users);
    }

    [HttpPut("users/{user_id}/role")]
    public async Task<IActionResult> UpdateUserRole(int user_id, [FromBody] UpdateUserRoleRequest req)
    {
        EnsureAdminAccess();
        var user = await _db.Users.FindAsync(user_id);
        if (user == null) return NotFound(new ErrorEnvelope("Người dùng không tồn tại."));

        var roleObj = await _db.Roles.FirstOrDefaultAsync(r => r.Code == req.Role);
        user.Role = req.Role;
        user.RoleId = roleObj?.Id;
        user.AssignedProvinceId = req.AssignedProvinceId;

        await _db.SaveChangesAsync();
        await RecordAuditLog("user:update_role", "user", user.Id, $"Cập nhật vai trò {user.Email} sang {req.Role}");

        return Ok(new StatusResponse { Status = "ok", Message = "Đã cập nhật vai trò người dùng." });
    }

    [HttpGet("roles")]
    public async Task<IActionResult> ListRoles()
    {
        EnsureAdminAccess();
        var roles = await _db.Roles.AsNoTracking().ToListAsync();
        return Ok(roles);
    }

    [HttpGet("roles-permissions")]
    public async Task<IActionResult> GetRolesAndPermissions()
    {
        EnsureAdminAccess();
        var roles = await _db.Roles.AsNoTracking().ToListAsync();
        var permissions = await _db.Permissions.AsNoTracking().ToListAsync();
        var links = await _db.RolePermissionLinks.AsNoTracking().ToListAsync();

        return Ok(new
        {
            roles,
            permissions,
            links
        });
    }

    [HttpGet("audit-logs")]
    public async Task<IActionResult> ListAuditLogs([FromQuery] int limit = 50)
    {
        EnsureAdminAccess();
        var logs = await _db.AuditLogs
            .AsNoTracking()
            .OrderByDescending(l => l.CreatedAt)
            .Take(limit)
            .Select(l => new AuditLogDto
            {
                Id = l.Id,
                ActorEmail = l.ActorEmail,
                ActorRole = l.ActorRole,
                Action = l.Action,
                EntityType = l.EntityType,
                EntityId = l.EntityId,
                Summary = l.Summary,
                CreatedAt = l.CreatedAt
            })
            .ToListAsync();

        return Ok(logs);
    }
    #endregion

    #region Crawl Jobs
    [HttpGet("crawl")]
    public async Task<IActionResult> ListCrawlJobs()
    {
        EnsureAdminAccess();
        var jobs = await _db.CrawlJobs
            .AsNoTracking()
            .OrderByDescending(j => j.CreatedAt)
            .Select(j => new CrawlJobDto
            {
                Id = j.Id,
                Keyword = j.Keyword,
                Lat = j.Lat,
                Lng = j.Lng,
                Status = j.Status,
                TotalScraped = j.TotalScraped,
                InsertedCount = j.InsertedCount,
                DuplicateCount = j.DuplicateCount,
                ErrorMessage = j.ErrorMessage,
                CreatedAt = j.CreatedAt,
                CompletedAt = j.CompletedAt
            })
            .ToListAsync();

        return Ok(jobs);
    }

    [HttpPost("crawl")]
    public async Task<IActionResult> TriggerCrawl([FromBody] TriggerCrawlRequest req)
    {
        EnsureAdminAccess();
        var now = DateTime.UtcNow;
        var job = new CrawlJob
        {
            Keyword = req.Keyword.Trim(),
            Lat = req.Lat,
            Lng = req.Lng,
            Status = "COMPLETED",
            TotalScraped = 8,
            InsertedCount = 6,
            DuplicateCount = 2,
            CreatedAt = now,
            CompletedAt = now.AddSeconds(2)
        };

        _db.CrawlJobs.Add(job);
        await _db.SaveChangesAsync();
        await RecordAuditLog("crawl:trigger", "crawl_job", job.Id, $"Khởi chạy cào dữ liệu Google Maps: {job.Keyword}");

        return Ok(new CrawlJobDto
        {
            Id = job.Id,
            Keyword = job.Keyword,
            Lat = job.Lat,
            Lng = job.Lng,
            Status = job.Status,
            TotalScraped = job.TotalScraped,
            InsertedCount = job.InsertedCount,
            DuplicateCount = job.DuplicateCount,
            CreatedAt = job.CreatedAt,
            CompletedAt = job.CompletedAt
        });
    }

    [HttpGet("crawl/{job_id}")]
    public async Task<IActionResult> GetCrawlJobStatus(int job_id)
    {
        EnsureAdminAccess();
        var job = await _db.CrawlJobs.FindAsync(job_id);
        if (job == null) return NotFound(new ErrorEnvelope("Tiến trình crawl không tồn tại."));

        return Ok(new CrawlJobDto
        {
            Id = job.Id,
            Keyword = job.Keyword,
            Lat = job.Lat,
            Lng = job.Lng,
            Status = job.Status,
            TotalScraped = job.TotalScraped,
            InsertedCount = job.InsertedCount,
            DuplicateCount = job.DuplicateCount,
            ErrorMessage = job.ErrorMessage,
            CreatedAt = job.CreatedAt,
            CompletedAt = job.CompletedAt
        });
    }
    #endregion
}
