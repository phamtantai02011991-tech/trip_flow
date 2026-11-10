using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TripFlow.Api.Data;
using TripFlow.Api.Models.DTOs;

namespace TripFlow.Api.Controllers;

[ApiController]
public class HealthController : ControllerBase
{
    private readonly TripFlowDbContext _db;

    public HealthController(TripFlowDbContext db)
    {
        _db = db;
    }

    [HttpGet("/")]
    public IActionResult Root()
    {
        return Ok(new
        {
            name = "TripFlow API",
            framework = "ASP.NET Core (.NET 10 / C#)",
            version = "1.0.0",
            docs = "/swagger",
            database = "PostgreSQL"
        });
    }

    [HttpGet("/health")]
    public IActionResult Health()
    {
        return Ok(new HealthResponse
        {
            Status = "ok",
            Timestamp = DateTime.UtcNow,
            Version = "1.0.0"
        });
    }

    [HttpGet("/health/ready")]
    public async Task<IActionResult> Ready()
    {
        bool dbOk = false;
        try
        {
            dbOk = await _db.Database.CanConnectAsync();
        }
        catch
        {
            dbOk = false;
        }

        if (dbOk)
        {
            return Ok(new ReadyResponse
            {
                Status = "ok",
                Database = "ok",
                Timestamp = DateTime.UtcNow
            });
        }

        return StatusCode(503, new
        {
            status = "unhealthy",
            database = "disconnected",
            detail = "Cơ sở dữ liệu chưa sẵn sàng."
        });
    }

    [HttpGet("/api/v1/contract/swagger.json")]
    public async Task<IActionResult> GetSwaggerContract()
    {
        var candidates = new[]
        {
            Path.Combine(AppContext.BaseDirectory, "swagger.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "backend", "swagger.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "..", "backend", "swagger.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "swagger.json"),
            "D:\\trip_flow\\backend\\swagger.json"
        };

        var filePath = candidates.FirstOrDefault(System.IO.File.Exists);
        if (filePath != null)
        {
            var content = await System.IO.File.ReadAllTextAsync(filePath);
            return Content(content, "application/json");
        }

        return NotFound(new ErrorEnvelope("Không tìm thấy swagger.json contract"));
    }
}
