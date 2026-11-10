using Microsoft.EntityFrameworkCore;

namespace TripFlow.Api.Data;

public static class SeederExtensions
{
    public static async Task ResetPostgresSequencesAsync(TripFlowDbContext db)
    {
        // Chỉ chạy nếu đang dùng PostgreSQL
        if (!db.Database.IsNpgsql())
        {
            return;
        }

        var tableNames = new[]
        {
            "provinces", "categories", "destinations", "destination_images",
            "local_foods", "restaurants", "rest_stops", "users", "roles",
            "permissions", "itineraries", "itinerary_stops", "trips",
            "trip_days", "trip_stops", "expenses", "place_reviews",
            "favorites", "content_reports", "audit_logs",
            "sms_otp_verifications", "search_history", "crawl_jobs"
        };

        foreach (var table in tableNames)
        {
            try
            {
                var sql = $"SELECT setval(pg_get_serial_sequence('{table}', 'id'), COALESCE(MAX(id), 1), MAX(id) IS NOT NULL) FROM {table};";
                await db.Database.ExecuteSqlRawAsync(sql);
            }
            catch
            {
                // Bỏ qua nếu bảng không dùng sequence serial tự sinh
            }
        }
    }
}
