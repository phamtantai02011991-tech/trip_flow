using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TripFlow.Api.Models.Entities;

[Table("roles")]
public class Role
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("code")]
    [MaxLength(50)]
    public string Code { get; set; } = string.Empty;

    [Column("name")]
    [MaxLength(120)]
    public string Name { get; set; } = string.Empty;

    [Column("description")]
    public string? Description { get; set; }

    public ICollection<RolePermissionLink> RolePermissions { get; set; } = new List<RolePermissionLink>();
    public ICollection<User> Users { get; set; } = new List<User>();
}

[Table("permissions")]
public class Permission
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("code")]
    [MaxLength(80)]
    public string Code { get; set; } = string.Empty;

    [Column("name")]
    [MaxLength(150)]
    public string Name { get; set; } = string.Empty;

    [Column("module")]
    [MaxLength(60)]
    public string Module { get; set; } = "general";

    [Column("description")]
    public string? Description { get; set; }

    public ICollection<RolePermissionLink> RolePermissions { get; set; } = new List<RolePermissionLink>();
}

[Table("role_permission_links")]
public class RolePermissionLink
{
    [Column("role_id")]
    public int RoleId { get; set; }
    public Role? Role { get; set; }

    [Column("permission_id")]
    public int PermissionId { get; set; }
    public Permission? Permission { get; set; }
}

[Table("admin_roles")]
public class AdminRole
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("role_code")]
    [MaxLength(50)]
    public string RoleCode { get; set; } = string.Empty;

    [Column("role_name")]
    [MaxLength(120)]
    public string RoleName { get; set; } = string.Empty;

    [Column("permissions_json")]
    public string PermissionsJson { get; set; } = "[]";

    [Column("description")]
    public string? Description { get; set; }
}

[Table("users")]
public class User
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("email")]
    [MaxLength(180)]
    public string Email { get; set; } = string.Empty;

    [Column("phone")]
    [MaxLength(20)]
    public string? Phone { get; set; }

    [Column("full_name")]
    [MaxLength(160)]
    public string FullName { get; set; } = string.Empty;

    [Column("hashed_password")]
    [MaxLength(260)]
    public string HashedPassword { get; set; } = string.Empty;

    [Column("role")]
    [MaxLength(50)]
    public string Role { get; set; } = "user";

    [Column("role_id")]
    public int? RoleId { get; set; }
    public Role? RoleObj { get; set; }

    [Column("assigned_province_id")]
    public int? AssignedProvinceId { get; set; }

    [Column("is_active")]
    public bool IsActive { get; set; } = true;

    [Column("failed_login_attempts")]
    public int FailedLoginAttempts { get; set; } = 0;

    [Column("locked_until")]
    public DateTime? LockedUntil { get; set; }

    [Column("totp_secret")]
    [MaxLength(64)]
    public string? TotpSecret { get; set; }

    [Column("totp_enabled")]
    public bool TotpEnabled { get; set; } = false;

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Favorite> Favorites { get; set; } = new List<Favorite>();
    public ICollection<Itinerary> Itineraries { get; set; } = new List<Itinerary>();
    public ICollection<Trip> Trips { get; set; } = new List<Trip>();
}

[Table("sms_otp_verifications")]
public class SMSOTPVerification
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("phone")]
    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;

    [Column("otp_code")]
    [MaxLength(10)]
    public string OtpCode { get; set; } = string.Empty;

    [Column("expires_at")]
    public DateTime ExpiresAt { get; set; }

    [Column("is_used")]
    public bool IsUsed { get; set; } = false;

    [Column("attempts")]
    public int Attempts { get; set; } = 0;

    [Column("full_name")]
    [MaxLength(160)]
    public string? FullName { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
