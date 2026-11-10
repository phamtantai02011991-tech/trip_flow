using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using Npgsql;
using TripFlow.Api.Data;
using TripFlow.Api.Middleware;
using TripFlow.Api.Models.DTOs;
using TripFlow.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// 1. JSON Configuration: SnakeCaseLower + StringEnumConverter + Custom 400 Envelope
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower;
        options.JsonSerializerOptions.DictionaryKeyPolicy = JsonNamingPolicy.SnakeCaseLower;
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter(JsonNamingPolicy.SnakeCaseLower));
        options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
    })
    .ConfigureApiBehaviorOptions(options =>
    {
        options.InvalidModelStateResponseFactory = context =>
        {
            var errors = context.ModelState.Values
                .SelectMany(v => v.Errors)
                .Select(e => e.ErrorMessage)
                .ToList();
            var detailMessage = string.Join("; ", errors);
            return new BadRequestObjectResult(new ErrorEnvelope(detailMessage));
        };
    });

// 2. CORS: AllowAll
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// 3. Database Context Setup (PostgreSQL with resilient fallback to In-Memory)
static string? ConvertPostgresUrlToNpgsql(string? url)
{
    if (string.IsNullOrWhiteSpace(url)) return null;
    if (!url.StartsWith("postgres://") && !url.StartsWith("postgresql://")) return url;
    try
    {
        var uri = new Uri(url);
        var userInfo = uri.UserInfo.Split(':');
        var user = userInfo[0];
        var password = userInfo.Length > 1 ? userInfo[1] : "";
        var host = uri.Host;
        var port = uri.Port > 0 ? uri.Port : 5432;
        var database = uri.AbsolutePath.TrimStart('/');
        return $"Host={host};Port={port};Database={database};Username={user};Password={password};Include Error Detail=true";
    }
    catch
    {
        return url;
    }
}

string? rawConnStr = Environment.GetEnvironmentVariable("DATABASE_URL")
    ?? builder.Configuration.GetConnectionString("DefaultConnection");
string? npgsqlConnStr = ConvertPostgresUrlToNpgsql(rawConnStr);

// Kiểm tra nhanh xem PostgreSQL có thể kết nối được không
bool usePostgres = false;
if (!string.IsNullOrWhiteSpace(npgsqlConnStr))
{
    try
    {
        using var testConn = new NpgsqlConnection(npgsqlConnStr);
        testConn.Open();
        usePostgres = true;
    }
    catch
    {
        usePostgres = false;
    }
}

if (usePostgres && !string.IsNullOrWhiteSpace(npgsqlConnStr))
{
    builder.Services.AddDbContext<TripFlowDbContext>(options =>
    {
        options.UseNpgsql(npgsqlConnStr);
    });
}
else
{
    builder.Services.AddDbContext<TripFlowDbContext>(options =>
    {
        options.UseInMemoryDatabase("TripFlowDb");
    });
}

// 4. JWT Authentication
var jwtSecret = builder.Configuration["Jwt:Secret"] ?? "TripFlowSuperSecretKey2026ForAuthenticationJwtBearer1234567890!";
var keyBytes = Encoding.UTF8.GetBytes(jwtSecret.PadRight(32));

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(keyBytes),
        ValidateIssuer = false,
        ValidateAudience = false,
        ClockSkew = TimeSpan.Zero
    };
});

// 5. Dependency Injection
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<ISmsService, SmsService>();
builder.Services.AddScoped<IGeoService, GeoService>();

// 6. Swagger / OpenAPI Documentation
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "TripFlow API (.NET 10 Web API)",
        Version = "v1",
        Description = "Nền tảng Du lịch & Lộ trình Phượt Thông minh TripFlow - ASP.NET Core Web API Parity 100%",
        Contact = new OpenApiContact
        {
            Name = "TripFlow Team",
            Url = new Uri("https://tripflow.vn")
        }
    });
});

var app = builder.Build();

// 7. Seed Database Data Idempotently
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<TripFlowDbContext>();
    try
    {
        await db.Database.EnsureCreatedAsync();
        await DatabaseSeeder.SeedAsync(db);
    }
    catch (Exception ex)
    {
        app.Logger.LogError(ex, "Lỗi trong quá trình khởi tạo và seed dữ liệu.");
    }
}

// 8. Middleware Pipeline
app.UseMiddleware<ErrorEnvelopeMiddleware>();

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "TripFlow API v1");
    c.RoutePrefix = "swagger";
});

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();

namespace TripFlow.Api
{
    public partial class Program { }
}
