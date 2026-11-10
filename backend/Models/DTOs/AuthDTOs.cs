using System.Text.Json.Serialization;

namespace TripFlow.Api.Models.DTOs;

public class SendOtpRequest
{
    [JsonPropertyName("phone")]
    public string Phone { get; set; } = string.Empty;

    [JsonPropertyName("full_name")]
    public string? FullName { get; set; }
}

public class SendOtpResponse
{
    [JsonPropertyName("phone")]
    public string Phone { get; set; } = string.Empty;

    [JsonPropertyName("message")]
    public string Message { get; set; } = string.Empty;

    [JsonPropertyName("expires_in_seconds")]
    public int ExpiresInSeconds { get; set; } = 300;

    [JsonPropertyName("debug_otp")]
    public string? DebugOtp { get; set; }
}

public class VerifyOtpRequest
{
    [JsonPropertyName("phone")]
    public string Phone { get; set; } = string.Empty;

    [JsonPropertyName("otp_code")]
    public string OtpCode { get; set; } = string.Empty;

    [JsonPropertyName("full_name")]
    public string? FullName { get; set; }
}

public class LoginRequest
{
    [JsonPropertyName("email")]
    public string Email { get; set; } = string.Empty;

    [JsonPropertyName("password")]
    public string Password { get; set; } = string.Empty;

    [JsonPropertyName("otp_code")]
    public string? OtpCode { get; set; }
}

public class RegisterRequest
{
    [JsonPropertyName("email")]
    public string Email { get; set; } = string.Empty;

    [JsonPropertyName("password")]
    public string Password { get; set; } = string.Empty;

    [JsonPropertyName("full_name")]
    public string FullName { get; set; } = string.Empty;

    [JsonPropertyName("phone")]
    public string? Phone { get; set; }
}

public class UserDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("email")]
    public string Email { get; set; } = string.Empty;

    [JsonPropertyName("phone")]
    public string? Phone { get; set; }

    [JsonPropertyName("full_name")]
    public string FullName { get; set; } = string.Empty;

    [JsonPropertyName("role")]
    public string Role { get; set; } = "user";

    [JsonPropertyName("assigned_province_id")]
    public int? AssignedProvinceId { get; set; }

    [JsonPropertyName("permissions")]
    public List<string> Permissions { get; set; } = new();

    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; }
}

public class TokenResponse
{
    [JsonPropertyName("access_token")]
    public string AccessToken { get; set; } = string.Empty;

    [JsonPropertyName("token_type")]
    public string TokenType { get; set; } = "bearer";

    [JsonPropertyName("user")]
    public UserDto User { get; set; } = new();
}

public class TwoFactorStatusResponse
{
    [JsonPropertyName("enabled")]
    public bool Enabled { get; set; }
}

public class TwoFactorSetupResponse
{
    [JsonPropertyName("secret")]
    public string Secret { get; set; } = string.Empty;

    [JsonPropertyName("otpauth_url")]
    public string OtpauthUrl { get; set; } = string.Empty;
}

public class TwoFactorVerifyRequest
{
    [JsonPropertyName("otp_code")]
    public string OtpCode { get; set; } = string.Empty;
}

public class ExportDataResponse
{
    [JsonPropertyName("user")]
    public UserDto User { get; set; } = new();

    [JsonPropertyName("trips")]
    public List<object> Trips { get; set; } = new();

    [JsonPropertyName("itineraries")]
    public List<object> Itineraries { get; set; } = new();

    [JsonPropertyName("favorites")]
    public List<object> Favorites { get; set; } = new();

    [JsonPropertyName("reviews")]
    public List<object> Reviews { get; set; } = new();

    [JsonPropertyName("search_history")]
    public List<object> SearchHistory { get; set; } = new();
}
