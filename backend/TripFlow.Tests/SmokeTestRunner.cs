using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using TripFlow.Tests.Fixtures;

namespace TripFlow.Tests;

public class SmokeTestRunner : IClassFixture<TestWebApplicationFactory>
{
    private readonly HttpClient _client;

    public SmokeTestRunner(TestWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task RunAll7SmokeChecks()
    {
        Console.WriteLine("\n================================================================");
        Console.WriteLine(" TRIPFLOW 7/7 SMOKE TEST CRITERIA VERIFICATION");
        Console.WriteLine("================================================================");

        var results = new List<(string Name, bool Ok, string Detail)>();

        // 1. GET /health
        try
        {
            var resp = await _client.GetAsync("/health");
            resp.EnsureSuccessStatusCode();
            var json = await resp.Content.ReadFromJsonAsync<JsonElement>();
            string status = json.GetProperty("status").GetString() ?? "";
            status.Should().BeOneOf("healthy", "ok");
            results.Add(("GET /health", true, $"status={status}"));
        }
        catch (Exception ex)
        {
            results.Add(("GET /health", false, ex.Message));
        }

        // 2. GET /health/ready
        try
        {
            var resp = await _client.GetAsync("/health/ready");
            resp.EnsureSuccessStatusCode();
            var json = await resp.Content.ReadFromJsonAsync<JsonElement>();
            string db = json.GetProperty("database").GetString() ?? "";
            db.Should().BeOneOf("ok", "healthy");
            results.Add(("GET /health/ready", true, $"database={db}"));
        }
        catch (Exception ex)
        {
            results.Add(("GET /health/ready", false, ex.Message));
        }

        // 3. GET /api/v1/destinations (>=100)
        try
        {
            var resp = await _client.GetAsync("/api/v1/destinations?page_size=100");
            resp.EnsureSuccessStatusCode();
            var json = await resp.Content.ReadFromJsonAsync<JsonElement>();
            int total = json.GetProperty("total").GetInt32();
            int itemsCount = json.GetProperty("items").GetArrayLength();
            total.Should().BeGreaterThanOrEqualTo(100);
            itemsCount.Should().BeGreaterThan(0);
            results.Add(("GET /destinations (>=100)", true, $"total={total}, items={itemsCount}"));
        }
        catch (Exception ex)
        {
            results.Add(("GET /destinations (>=100)", false, ex.Message));
        }

        // 4. GET /api/v1/restaurants (>=60)
        try
        {
            var resp = await _client.GetAsync("/api/v1/restaurants?page_size=100");
            resp.EnsureSuccessStatusCode();
            var json = await resp.Content.ReadFromJsonAsync<JsonElement>();
            int total = json.GetProperty("total").GetInt32();
            total.Should().BeGreaterThanOrEqualTo(60);
            results.Add(("GET /restaurants (>=60)", true, $"count={total}"));
        }
        catch (Exception ex)
        {
            results.Add(("GET /restaurants (>=60)", false, ex.Message));
        }

        // 5. GET /api/v1/places/nearby?kinds=gas
        try
        {
            var resp = await _client.GetAsync("/api/v1/places/nearby?lat=21.0288&lng=105.8525&radius_km=6&kinds=gas");
            resp.EnsureSuccessStatusCode();
            var json = await resp.Content.ReadFromJsonAsync<JsonElement>();
            int total = json.GetProperty("total").GetInt32();
            total.Should().BeGreaterThanOrEqualTo(1);
            results.Add(("GET /places/nearby?kinds=gas", true, $"gas={total}"));
        }
        catch (Exception ex)
        {
            results.Add(("GET /places/nearby?kinds=gas", false, ex.Message));
        }

        // 6. POST /api/v1/places/along-route
        try
        {
            var resp = await _client.PostAsJsonAsync("/api/v1/places/along-route", new
            {
                origin_lat = 21.0288,
                origin_lng = 105.8525,
                dest_lat = 21.0288,
                dest_lng = 105.8359,
                corridor_radius_km = 2.0,
                kinds = "rest,gas,ev,cafe"
            });
            resp.EnsureSuccessStatusCode();
            var json = await resp.Content.ReadFromJsonAsync<JsonElement>();
            int count = json.GetProperty("count").GetInt32();
            count.Should().BeGreaterThanOrEqualTo(1);
            results.Add(("POST /places/along-route", true, $"stops={count}"));
        }
        catch (Exception ex)
        {
            results.Add(("POST /places/along-route", false, ex.Message));
        }

        // 7. GET /api/v1/places/suggest?q=hoi an
        try
        {
            var resp = await _client.GetAsync("/api/v1/places/suggest?q=hoi an");
            resp.EnsureSuccessStatusCode();
            var items = await resp.Content.ReadFromJsonAsync<List<JsonElement>>();
            items.Should().NotBeNull();
            items!.Count.Should().BeGreaterThanOrEqualTo(1);
            results.Add(("GET /places/suggest?q=hoi an", true, $"items={items.Count}"));
        }
        catch (Exception ex)
        {
            results.Add(("GET /places/suggest?q=hoi an", false, ex.Message));
        }

        int failed = 0;
        foreach (var (name, ok, detail) in results)
        {
            var icon = ok ? "PASS" : "FAIL";
            Console.WriteLine($"[{icon}] {name} — {detail}");
            if (!ok) failed++;
        }

        Console.WriteLine($"\n{results.Count - failed}/{results.Count} mục PASS");
        Console.WriteLine("================================================================\n");

        failed.Should().Be(0);
    }
}
