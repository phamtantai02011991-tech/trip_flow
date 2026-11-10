using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using OtpNet;
using TripFlow.Api.Data;
using TripFlow.Api.Models.DTOs;
using TripFlow.Api.Models.Entities;
using TripFlow.Api.Services;

namespace TripFlow.Api.Controllers;

[ApiController]
[Route("api/v1/auth")]
public class AuthController : ControllerBase
{
    private readonly TripFlowDbContext _db;
    private readonly ISmsService _smsService;
    private readonly ITokenService _tokenService;

    public AuthController(TripFlowDbContext db, ISmsService smsService, ITokenService tokenService)
    {
        _db = db;
        _smsService = smsService;
        _tokenService = tokenService;
    }

    private async Task<List<string>> GetUserPermissionsAsync(User user)
    {
        if (user.RoleId == null)
        {
            return new List<string> { "destination:read", "restaurant:read", "local_food:read", "itinerary:read" };
        }

        var permCodes = await _db.RolePermissionLinks
            .Where(rpl => rpl.RoleId == user.RoleId)
            .Include(rpl => rpl.Permission)
            .Select(rpl => rpl.Permission!.Code)
            .ToListAsync();

        return permCodes;
    }

    private UserDto ToUserDto(User user, List<string> permissions) => new()
    {
        Id = user.Id,
        Email = user.Email,
        Phone = user.Phone,
        FullName = user.FullName,
        Role = user.Role,
        AssignedProvinceId = user.AssignedProvinceId,
        Permissions = permissions,
        CreatedAt = user.CreatedAt
    };

    [HttpPost("otp/send")]
    public async Task<IActionResult> SendOtp([FromBody] SendOtpRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Phone))
        {
            return BadRequest(new ErrorEnvelope("Số điện thoại không được để trống."));
        }

        var res = await _smsService.SendOtpAsync(req.Phone, req.FullName);
        return Ok(res);
    }

    [HttpPost("otp/verify")]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Phone) || string.IsNullOrWhiteSpace(req.OtpCode))
        {
            return BadRequest(new ErrorEnvelope("Vui lòng nhập đầy đủ số điện thoại và mã OTP."));
        }

        var user = await _smsService.VerifyOtpAsync(req.Phone, req.OtpCode, req.FullName);
        var permissions = await GetUserPermissionsAsync(user);
        var token = _tokenService.GenerateAccessToken(user, permissions);

        return Ok(new TokenResponse
        {
            AccessToken = token,
            TokenType = "bearer",
            User = ToUserDto(user, permissions)
        });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.Password))
        {
            return BadRequest(new ErrorEnvelope("Vui lòng cung cấp email và mật khẩu."));
        }

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == req.Email.Trim().ToLower());
        if (user == null)
        {
            return Unauthorized(new ErrorEnvelope("Email hoặc mật khẩu không chính xác."));
        }

        var now = DateTime.UtcNow;
        if (user.LockedUntil.HasValue && user.LockedUntil > now)
        {
            int remainingMins = (int)Math.Ceiling((user.LockedUntil.Value - now).TotalMinutes);
            return StatusCode(423, new ErrorEnvelope($"Tài khoản đang tạm khoá do đăng nhập sai nhiều lần. Vui lòng thử lại sau {remainingMins} phút."));
        }

        bool verified = false;
        try
        {
            verified = BCrypt.Net.BCrypt.Verify(req.Password, user.HashedPassword);
        }
        catch
        {
            verified = false;
        }

        if (!verified)
        {
            user.FailedLoginAttempts += 1;
            if (user.FailedLoginAttempts >= 5)
            {
                user.LockedUntil = now.AddMinutes(15);
            }
            await _db.SaveChangesAsync();
            return Unauthorized(new ErrorEnvelope("Email hoặc mật khẩu không chính xác."));
        }

        // Kiểm tra 2FA nếu tài khoản đã kích hoạt
        if (user.TotpEnabled)
        {
            if (string.IsNullOrWhiteSpace(req.OtpCode))
            {
                return Unauthorized(new ErrorEnvelope("2FA_REQUIRED: Vui lòng nhập mã xác thực 6 số từ ứng dụng Google Authenticator."));
            }

            if (string.IsNullOrEmpty(user.TotpSecret))
            {
                return Unauthorized(new ErrorEnvelope("Lỗi cấu hình 2FA trên tài khoản."));
            }

            var totp = new Totp(Base32Encoding.ToBytes(user.TotpSecret));
            bool isTotpValid = totp.VerifyTotp(req.OtpCode.Trim(), out _, new VerificationWindow(previous: 1, future: 1));
            if (!isTotpValid)
            {
                return Unauthorized(new ErrorEnvelope("Mã 2FA không chính xác hoặc đã hết hạn."));
            }
        }

        user.FailedLoginAttempts = 0;
        user.LockedUntil = null;
        await _db.SaveChangesAsync();

        var permissions = await GetUserPermissionsAsync(user);
        var token = _tokenService.GenerateAccessToken(user, permissions);

        // Ghi AuditLog nếu là quyền admin
        if (user.Role is "super_admin" or "content_admin")
        {
            _db.AuditLogs.Add(new AuditLog
            {
                ActorId = user.Id,
                ActorEmail = user.Email,
                ActorRole = user.Role,
                Action = "auth:login",
                EntityType = "user",
                EntityId = user.Id,
                Summary = $"Quản trị viên {user.FullName} đăng nhập thành công",
                CreatedAt = now
            });
            await _db.SaveChangesAsync();
        }

        return Ok(new TokenResponse
        {
            AccessToken = token,
            TokenType = "bearer",
            User = ToUserDto(user, permissions)
        });
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.Password) || string.IsNullOrWhiteSpace(req.FullName))
        {
            return BadRequest(new ErrorEnvelope("Vui lòng điền đầy đủ email, mật khẩu và họ tên."));
        }

        var normalizedEmail = req.Email.Trim().ToLower();
        if (await _db.Users.AnyAsync(u => u.Email == normalizedEmail))
        {
            return BadRequest(new ErrorEnvelope("Email này đã được sử dụng."));
        }

        var user = new User
        {
            Email = normalizedEmail,
            Phone = req.Phone?.Trim(),
            FullName = req.FullName.Trim(),
            HashedPassword = BCrypt.Net.BCrypt.HashPassword(req.Password),
            Role = "user",
            RoleId = 5,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        var permissions = await GetUserPermissionsAsync(user);
        var token = _tokenService.GenerateAccessToken(user, permissions);

        return Ok(new TokenResponse
        {
            AccessToken = token,
            TokenType = "bearer",
            User = ToUserDto(user, permissions)
        });
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetMe()
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        if (!userId.HasValue)
        {
            return Unauthorized(new ErrorEnvelope("Vui lòng đăng nhập để tiếp tục."));
        }

        var user = await _db.Users.FindAsync(userId.Value);
        if (user == null || !user.IsActive)
        {
            return Unauthorized(new ErrorEnvelope("Tài khoản không tồn tại hoặc đã bị khóa."));
        }

        var permissions = await GetUserPermissionsAsync(user);
        return Ok(ToUserDto(user, permissions));
    }

    [HttpGet("2fa/status")]
    public async Task<IActionResult> GetTwoFactorStatus()
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        if (!userId.HasValue) return Unauthorized(new ErrorEnvelope("Chưa đăng nhập."));

        var user = await _db.Users.FindAsync(userId.Value);
        return Ok(new TwoFactorStatusResponse { Enabled = user?.TotpEnabled ?? false });
    }

    [HttpPost("2fa/setup")]
    public async Task<IActionResult> SetupTwoFactor()
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        if (!userId.HasValue) return Unauthorized(new ErrorEnvelope("Chưa đăng nhập."));

        var user = await _db.Users.FindAsync(userId.Value);
        if (user == null) return NotFound(new ErrorEnvelope("Người dùng không tồn tại."));

        var secretBytes = KeyGeneration.GenerateRandomKey(20);
        var base32Secret = Base32Encoding.ToString(secretBytes);

        user.TotpSecret = base32Secret;
        await _db.SaveChangesAsync();

        var otpauth = $"otpauth://totp/TripFlow:{Uri.EscapeDataString(user.Email)}?secret={base32Secret}&issuer=TripFlow";

        return Ok(new TwoFactorSetupResponse
        {
            Secret = base32Secret,
            OtpauthUrl = otpauth
        });
    }

    [HttpPost("2fa/enable")]
    public async Task<IActionResult> EnableTwoFactor([FromBody] TwoFactorVerifyRequest req)
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        if (!userId.HasValue) return Unauthorized(new ErrorEnvelope("Chưa đăng nhập."));

        var user = await _db.Users.FindAsync(userId.Value);
        if (user == null || string.IsNullOrEmpty(user.TotpSecret))
        {
            return BadRequest(new ErrorEnvelope("Vui lòng gọi setup 2FA trước."));
        }

        var totp = new Totp(Base32Encoding.ToBytes(user.TotpSecret));
        if (!totp.VerifyTotp(req.OtpCode.Trim(), out _, new VerificationWindow(1, 1)))
        {
            return BadRequest(new ErrorEnvelope("Mã xác thực 2FA không chính xác."));
        }

        user.TotpEnabled = true;
        await _db.SaveChangesAsync();

        return Ok(new StatusResponse { Status = "ok", Message = "Đã kích hoạt xác thực 2 bước thành công." });
    }

    [HttpPost("2fa/disable")]
    public async Task<IActionResult> DisableTwoFactor([FromBody] TwoFactorVerifyRequest req)
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        if (!userId.HasValue) return Unauthorized(new ErrorEnvelope("Chưa đăng nhập."));

        var user = await _db.Users.FindAsync(userId.Value);
        if (user == null || !user.TotpEnabled || string.IsNullOrEmpty(user.TotpSecret))
        {
            return BadRequest(new ErrorEnvelope("Tài khoản chưa bật 2FA."));
        }

        var totp = new Totp(Base32Encoding.ToBytes(user.TotpSecret));
        if (!totp.VerifyTotp(req.OtpCode.Trim(), out _, new VerificationWindow(1, 1)))
        {
            return BadRequest(new ErrorEnvelope("Mã xác thực 2FA không chính xác."));
        }

        user.TotpEnabled = false;
        user.TotpSecret = null;
        await _db.SaveChangesAsync();

        return Ok(new StatusResponse { Status = "ok", Message = "Đã hủy kích hoạt xác thực 2 bước." });
    }

    [HttpGet("me/export")]
    public async Task<IActionResult> ExportData()
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        if (!userId.HasValue) return Unauthorized(new ErrorEnvelope("Chưa đăng nhập."));

        var user = await _db.Users.FindAsync(userId.Value);
        if (user == null) return NotFound(new ErrorEnvelope("Người dùng không tồn tại."));

        var permissions = await GetUserPermissionsAsync(user);
        var trips = await _db.Trips.Where(t => t.UserId == user.Id).Include(t => t.Days).ThenInclude(d => d.Stops).Include(t => t.Expenses).ToListAsync();
        var itineraries = await _db.Itineraries.Where(i => i.UserId == user.Id).Include(i => i.Stops).ToListAsync();
        var favorites = await _db.Favorites.Where(f => f.UserId == user.Id).ToListAsync();
        var reviews = await _db.PlaceReviews.Where(r => r.UserId == user.Id).ToListAsync();
        var searches = await _db.SearchHistories.Where(s => s.UserId == user.Id).ToListAsync();

        return Ok(new ExportDataResponse
        {
            User = ToUserDto(user, permissions),
            Trips = trips.Cast<object>().ToList(),
            Itineraries = itineraries.Cast<object>().ToList(),
            Favorites = favorites.Cast<object>().ToList(),
            Reviews = reviews.Cast<object>().ToList(),
            SearchHistory = searches.Cast<object>().ToList()
        });
    }

    [HttpDelete("account")]
    public async Task<IActionResult> DeleteAccount([FromQuery] string? confirm)
    {
        var userId = _tokenService.GetUserIdFromPrincipal(User);
        if (!userId.HasValue) return Unauthorized(new ErrorEnvelope("Chưa đăng nhập."));

        if (confirm != "DELETE")
        {
            return BadRequest(new ErrorEnvelope("Nhập confirm=DELETE để xác nhận xoá tài khoản vĩnh viễn."));
        }

        var user = await _db.Users.FindAsync(userId.Value);
        if (user == null) return NotFound(new ErrorEnvelope("Người dùng không tồn tại."));

        // Xóa cascade dữ liệu của user
        var trips = await _db.Trips.Where(t => t.UserId == user.Id).ToListAsync();
        _db.Trips.RemoveRange(trips);

        var itineraries = await _db.Itineraries.Where(i => i.UserId == user.Id).ToListAsync();
        _db.Itineraries.RemoveRange(itineraries);

        var favorites = await _db.Favorites.Where(f => f.UserId == user.Id).ToListAsync();
        _db.Favorites.RemoveRange(favorites);

        var reviews = await _db.PlaceReviews.Where(r => r.UserId == user.Id).ToListAsync();
        _db.PlaceReviews.RemoveRange(reviews);

        var searches = await _db.SearchHistories.Where(s => s.UserId == user.Id).ToListAsync();
        _db.SearchHistories.RemoveRange(searches);

        _db.Users.Remove(user);
        await _db.SaveChangesAsync();

        return Ok(new StatusResponse { Status = "ok", Message = "Tài khoản và toàn bộ dữ liệu cá nhân đã được xóa vĩnh viễn." });
    }
}
