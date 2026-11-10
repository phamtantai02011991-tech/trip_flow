using System.Security.Cryptography;
using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using TripFlow.Api.Data;
using TripFlow.Api.Models.DTOs;
using TripFlow.Api.Models.Entities;

namespace TripFlow.Api.Services;

public interface ISmsService
{
    Task<SendOtpResponse> SendOtpAsync(string phone, string? fullName);
    Task<User> VerifyOtpAsync(string phone, string otpCode, string? fullName);
}

public class SmsService : ISmsService
{
    private readonly TripFlowDbContext _db;
    private readonly IConfiguration _config;
    private static readonly Regex PhoneRegex = new(@"^(03|05|07|08|09)\d{8}$", RegexOptions.Compiled);

    public SmsService(TripFlowDbContext db, IConfiguration config)
    {
        _db = db;
        _config = config;
    }

    public async Task<SendOtpResponse> SendOtpAsync(string phone, string? fullName)
    {
        var cleanPhone = phone.Trim().Replace(" ", "").Replace("+84", "0");
        if (!PhoneRegex.IsMatch(cleanPhone))
        {
            throw new BadHttpRequestException("Số điện thoại không đúng định dạng di động Việt Nam (10 chữ số, đầu 03, 05, 07, 08, 09).", 400);
        }

        var now = DateTime.UtcNow;
        var lastOtp = await _db.SMSOTPVerifications
            .Where(x => x.Phone == cleanPhone)
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefaultAsync();

        if (lastOtp != null && (now - lastOtp.CreatedAt).TotalSeconds < 60)
        {
            var retryAfter = 60 - (int)(now - lastOtp.CreatedAt).TotalSeconds;
            throw new BadHttpRequestException($"Mã OTP vừa được gửi. Vui lòng đợi {retryAfter} giây trước khi yêu cầu mã mới.", 429);
        }

        // Sinh mã 6 số ngẫu nhiên
        var otpCode = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
        var expiresAt = now.AddMinutes(5);

        var record = new SMSOTPVerification
        {
            Phone = cleanPhone,
            OtpCode = otpCode,
            ExpiresAt = expiresAt,
            IsUsed = false,
            Attempts = 0,
            FullName = fullName,
            CreatedAt = now
        };

        _db.SMSOTPVerifications.Add(record);
        await _db.SaveChangesAsync();

        bool devOtp = _config.GetValue<bool>("DevOtpEnabled", true);

        return new SendOtpResponse
        {
            Phone = cleanPhone,
            Message = "Mã xác thực OTP 6 số đã được gửi qua tin nhắn SMS tới số điện thoại của bạn.",
            ExpiresInSeconds = 300,
            DebugOtp = devOtp ? otpCode : null
        };
    }

    public async Task<User> VerifyOtpAsync(string phone, string otpCode, string? fullName)
    {
        var cleanPhone = phone.Trim().Replace(" ", "").Replace("+84", "0");
        var now = DateTime.UtcNow;

        var record = await _db.SMSOTPVerifications
            .Where(x => x.Phone == cleanPhone && !x.IsUsed && x.ExpiresAt > now)
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefaultAsync();

        if (record == null)
        {
            throw new BadHttpRequestException("Mã OTP không tồn tại hoặc đã hết hạn. Vui lòng yêu cầu mã mới.", 400);
        }

        if (record.Attempts >= 5)
        {
            throw new BadHttpRequestException("Bạn đã nhập sai mã OTP quá 5 lần. Vui lòng yêu cầu mã mới.", 400);
        }

        if (record.OtpCode != otpCode.Trim())
        {
            record.Attempts += 1;
            await _db.SaveChangesAsync();
            int remaining = 5 - record.Attempts;
            throw new BadHttpRequestException($"Mã xác thực OTP không chính xác. Bạn còn {remaining} lần thử.", 400);
        }

        record.IsUsed = true;
        await _db.SaveChangesAsync();

        // Tìm User hoặc tạo mới
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Phone == cleanPhone);
        if (user == null)
        {
            user = new User
            {
                Email = $"{cleanPhone}@tripflow.vn",
                Phone = cleanPhone,
                FullName = string.IsNullOrWhiteSpace(fullName) ? $"Khách {cleanPhone[^4..]}" : fullName.Trim(),
                HashedPassword = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString("N")),
                Role = "user",
                RoleId = 5,
                IsActive = true,
                CreatedAt = now
            };
            _db.Users.Add(user);
            await _db.SaveChangesAsync();
        }

        return user;
    }
}
