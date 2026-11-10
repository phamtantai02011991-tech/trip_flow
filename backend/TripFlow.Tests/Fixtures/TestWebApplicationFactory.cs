using System.IO;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using TripFlow.Api.Data;

namespace TripFlow.Tests.Fixtures;

public class TestWebApplicationFactory : WebApplicationFactory<TripFlow.Api.Program>
{
    private readonly string _dbName = "TestTripFlowDb_" + Guid.NewGuid().ToString("N");

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        var contentRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "backend"));
        if (!Directory.Exists(contentRoot))
        {
            contentRoot = @"D:\trip_flow\backend";
        }
        builder.UseContentRoot(contentRoot);

        builder.ConfigureServices(services =>
        {
            // Thay thế DbContext bằng In-Memory độc lập cho Test
            var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(DbContextOptions<TripFlowDbContext>));
            if (descriptor != null)
            {
                services.Remove(descriptor);
            }

            services.AddDbContext<TripFlowDbContext>(options =>
            {
                options.UseInMemoryDatabase(_dbName);
            });

            var sp = services.BuildServiceProvider();
            using var scope = sp.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<TripFlowDbContext>();
            db.Database.EnsureCreated();
            DatabaseSeeder.SeedAsync(db).GetAwaiter().GetResult();
        });
    }
}
