using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using FluentAssertions;
using TripFlow.Api.Models.DTOs;
using TripFlow.Api.Models.Entities;
using TripFlow.Tests.Fixtures;

namespace TripFlow.Tests;

public class AdminParityTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly HttpClient _client;

    public AdminParityTests(TestWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    private async Task<string> GetAdminTokenAsync()
    {
        var loginResp = await _client.PostAsJsonAsync("/api/v1/auth/login", new LoginRequest
        {
            Email = "admin@tripflow.vn",
            Password = "Admin@TripFlow2026!"
        });
        var tokenBody = await loginResp.Content.ReadFromJsonAsync<TokenResponse>();
        return tokenBody!.AccessToken;
    }

    private async Task<string> GetNormalUserTokenAsync()
    {
        var loginResp = await _client.PostAsJsonAsync("/api/v1/auth/login", new LoginRequest
        {
            Email = "user@tripflow.vn",
            Password = "User@TripFlow2026!"
        });
        var tokenBody = await loginResp.Content.ReadFromJsonAsync<TokenResponse>();
        return tokenBody!.AccessToken;
    }

    [Fact]
    public async Task TC_ADM_01_AdminDashboard_ShouldReturnKPIs()
    {
        var token = await GetAdminTokenAsync();
        var req = new HttpRequestMessage(HttpMethod.Get, "/api/v1/admin/dashboard");
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var resp = await _client.SendAsync(req);
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var dashboard = await resp.Content.ReadFromJsonAsync<AdminDashboardResponse>();
        dashboard.Should().NotBeNull();
        dashboard!.TotalProvinces.Should().Be(10);
        dashboard.TotalDestinations.Should().BeGreaterThanOrEqualTo(100);
        dashboard.TotalRestaurants.Should().BeGreaterThanOrEqualTo(60);
    }

    [Fact]
    public async Task TC_ADM_02_NormalUser_AccessAdmin_ShouldReturn403()
    {
        var token = await GetNormalUserTokenAsync();
        var req = new HttpRequestMessage(HttpMethod.Get, "/api/v1/admin/dashboard");
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var resp = await _client.SendAsync(req);
        resp.StatusCode.Should().Be(HttpStatusCode.Forbidden);
        var content = await resp.Content.ReadAsStringAsync();
        content.Should().Contain("detail");
    }

    [Fact]
    public async Task TC_ADM_02b_Anonymous_AccessAdmin_ShouldReturn401()
    {
        var req = new HttpRequestMessage(HttpMethod.Get, "/api/v1/admin/dashboard");
        // No Authorization header

        var resp = await _client.SendAsync(req);
        resp.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        var content = await resp.Content.ReadAsStringAsync();
        content.Should().Contain("detail");
    }

    [Fact]
    public async Task TC_ADM_03_Admin_CreateDestination_ShouldSucceed()
    {
        var token = await GetAdminTokenAsync();
        var req = new HttpRequestMessage(HttpMethod.Post, "/api/v1/admin/destinations")
        {
            Content = JsonContent.Create(new Destination
            {
                ProvinceId = 1,
                CategoryId = 1,
                Name = "Địa điểm thử nghiệm Admin",
                Description = "Mô tả thử nghiệm",
                Address = "Quận 1, TP.HCM",
                Latitude = 10.7769,
                Longitude = 106.7009
            })
        };
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var resp = await _client.SendAsync(req);
        resp.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task TC_ADM_04_Admin_UpdateUserRole_ShouldSucceed()
    {
        var token = await GetAdminTokenAsync();
        var req = new HttpRequestMessage(HttpMethod.Put, "/api/v1/admin/users/2/role")
        {
            Content = JsonContent.Create(new UpdateUserRoleRequest
            {
                Role = "moderator",
                AssignedProvinceId = 1
            })
        };
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var resp = await _client.SendAsync(req);
        resp.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task TC_ADM_05_AuditLogs_ShouldBeRecorded()
    {
        var token = await GetAdminTokenAsync();
        var req = new HttpRequestMessage(HttpMethod.Get, "/api/v1/admin/audit-logs");
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var resp = await _client.SendAsync(req);
        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var logs = await resp.Content.ReadFromJsonAsync<List<AuditLogDto>>();
        logs.Should().NotBeNull();
    }

    [Fact]
    public async Task TC_ADM_06_HealthReady_ShouldReturnDatabaseOk()
    {
        var resp = await _client.GetAsync("/health/ready");
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await resp.Content.ReadFromJsonAsync<ReadyResponse>();
        body.Should().NotBeNull();
        body!.Database.Should().Be("ok");
    }

    [Fact]
    public async Task TC_ADM_07_Health_ShouldReturnOk()
    {
        var resp = await _client.GetAsync("/health");
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await resp.Content.ReadFromJsonAsync<HealthResponse>();
        body.Should().NotBeNull();
        body!.Status.Should().Be("ok");
    }

    [Fact]
    public async Task TC_ADM_08_TriggerCrawl_ShouldCreateJob()
    {
        var token = await GetAdminTokenAsync();
        var req = new HttpRequestMessage(HttpMethod.Post, "/api/v1/admin/crawl")
        {
            Content = JsonContent.Create(new TriggerCrawlRequest
            {
                Keyword = "Quán phở ngon Hà Nội",
                Lat = 21.0285,
                Lng = 105.8542
            })
        };
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var resp = await _client.SendAsync(req);
        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await resp.Content.ReadFromJsonAsync<CrawlJobDto>();
        body.Should().NotBeNull();
        body!.Keyword.Should().Be("Quán phở ngon Hà Nội");
    }
}
