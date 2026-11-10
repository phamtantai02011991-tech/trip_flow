using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using TripFlow.Api.Models.Entities;

namespace TripFlow.Api.Services;

public interface ITokenService
{
    string GenerateAccessToken(User user, IEnumerable<string> permissions);
    int? GetUserIdFromPrincipal(ClaimsPrincipal principal);
    string? GetUserRoleFromPrincipal(ClaimsPrincipal principal);
}

public class TokenService : ITokenService
{
    private readonly IConfiguration _config;
    private readonly byte[] _key;

    public TokenService(IConfiguration config)
    {
        _config = config;
        var secret = _config["Jwt:Secret"] ?? "TripFlowSuperSecretKey2026ForAuthenticationJwtBearer!";
        _key = Encoding.UTF8.GetBytes(secret.PadRight(32));
    }

    public string GenerateAccessToken(User user, IEnumerable<string> permissions)
    {
        var tokenHandler = new JwtSecurityTokenHandler();
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Email, user.Email),
            new(ClaimTypes.Name, user.FullName),
            new(ClaimTypes.Role, user.Role),
            new("role", user.Role)
        };

        foreach (var perm in permissions)
        {
            claims.Add(new Claim("permission", perm));
        }

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddDays(30),
            SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(_key), SecurityAlgorithms.HmacSha256Signature)
        };

        var token = tokenHandler.CreateToken(tokenDescriptor);
        return tokenHandler.WriteToken(token);
    }

    public int? GetUserIdFromPrincipal(ClaimsPrincipal principal)
    {
        var idClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value 
                   ?? principal.FindFirst("sub")?.Value;
        return int.TryParse(idClaim, out var id) ? id : null;
    }

    public string? GetUserRoleFromPrincipal(ClaimsPrincipal principal)
    {
        return principal.FindFirst(ClaimTypes.Role)?.Value 
            ?? principal.FindFirst("role")?.Value;
    }
}
