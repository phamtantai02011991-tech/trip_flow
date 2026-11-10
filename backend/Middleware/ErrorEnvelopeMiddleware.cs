using System.Text.Json;
using TripFlow.Api.Models.DTOs;

namespace TripFlow.Api.Middleware;

public class ErrorEnvelopeMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ErrorEnvelopeMiddleware> _logger;

    public ErrorEnvelopeMiddleware(RequestDelegate next, ILogger<ErrorEnvelopeMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);

            if (!context.Response.HasStarted)
            {
                if (context.Response.StatusCode == StatusCodes.Status401Unauthorized)
                {
                    context.Response.ContentType = "application/json";
                    await context.Response.WriteAsJsonAsync(new ErrorEnvelope("Vui lòng đăng nhập để tiếp tục."));
                }
                else if (context.Response.StatusCode == StatusCodes.Status403Forbidden)
                {
                    context.Response.ContentType = "application/json";
                    await context.Response.WriteAsJsonAsync(new ErrorEnvelope("Từ chối truy cập (403 Forbidden): Bạn không có quyền thực hiện hành động này."));
                }
            }
        }
        catch (BadHttpRequestException ex)
        {
            _logger.LogWarning("Bad request: {Message}", ex.Message);
            if (!context.Response.HasStarted)
            {
                context.Response.StatusCode = ex.StatusCode;
                context.Response.ContentType = "application/json";
                await context.Response.WriteAsJsonAsync(new ErrorEnvelope(ex.Message));
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled Exception: {Message}", ex.Message);
            if (!context.Response.HasStarted)
            {
                context.Response.StatusCode = StatusCodes.Status500InternalServerError;
                context.Response.ContentType = "application/json";
                await context.Response.WriteAsJsonAsync(new ErrorEnvelope("Đã xảy ra lỗi máy chủ nội bộ. Vui lòng thử lại sau."));
            }
        }
    }
}
