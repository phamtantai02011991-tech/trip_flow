using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using TripFlow.Api.Models.DTOs;
using TripFlow.Tests.Fixtures;

namespace TripFlow.Tests;

public class CatalogParityTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly HttpClient _client;

    public CatalogParityTests(TestWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task TC_CAT_01_ListDestinations_PageSize100_ShouldReturnAtLeast100()
    {
        var resp = await _client.GetAsync("/api/v1/destinations?page_size=100");
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await resp.Content.ReadFromJsonAsync<PaginatedResponse<DestinationDto>>();
        body.Should().NotBeNull();
        body!.Total.Should().BeGreaterThanOrEqualTo(100);
        body.Items.Should().NotBeEmpty();
    }

    [Fact]
    public async Task TC_CAT_02_GetDestinationDetail_ShouldIncludeRelated()
    {
        var resp = await _client.GetAsync("/api/v1/destinations/1");
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await resp.Content.ReadFromJsonAsync<DestinationDetailDto>();
        body.Should().NotBeNull();
        body!.Id.Should().Be(1);
        body.Name.Should().NotBeNullOrEmpty();
    }

    [Fact]
    public async Task TC_CAT_03_ListRestaurants_PageSize100_ShouldReturnAtLeast60()
    {
        var resp = await _client.GetAsync("/api/v1/restaurants?page_size=100");
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await resp.Content.ReadFromJsonAsync<PaginatedResponse<RestaurantDto>>();
        body.Should().NotBeNull();
        body!.Total.Should().BeGreaterThanOrEqualTo(60);
        body.Items.Should().NotBeEmpty();
    }

    [Fact]
    public async Task TC_CAT_04_FilterRestaurants_ByCuisineType()
    {
        var resp = await _client.GetAsync("/api/v1/restaurants?cuisine_type=Phở");
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await resp.Content.ReadFromJsonAsync<PaginatedResponse<RestaurantDto>>();
        body.Should().NotBeNull();
    }

    [Fact]
    public async Task TC_CAT_05_ListProvinces_ShouldReturn10Provinces()
    {
        var resp = await _client.GetAsync("/api/v1/provinces");
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await resp.Content.ReadFromJsonAsync<List<ProvinceDto>>();
        body.Should().NotBeNull();
        body!.Count.Should().Be(10);
    }

    [Fact]
    public async Task TC_CAT_06_ListLocalFoods_ShouldReturnFoods()
    {
        var resp = await _client.GetAsync("/api/v1/local-foods");
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await resp.Content.ReadFromJsonAsync<List<LocalFoodDto>>();
        body.Should().NotBeNull();
        body!.Should().NotBeEmpty();
    }

    [Fact]
    public async Task TC_CAT_07_ReportDestination_ShouldReturnOk()
    {
        var resp = await _client.PostAsJsonAsync("/api/v1/destinations/1/report", new ReportRequest
        {
            IssueType = "wrong_hours",
            Description = "Giờ mở cửa thực tế là 08:00 sáng.",
            Rating = 5
        });

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await resp.Content.ReadFromJsonAsync<StatusResponse>();
        body!.Status.Should().Be("ok");
    }

    [Fact]
    public async Task TC_CAT_08_Pagination_Page2()
    {
        var resp = await _client.GetAsync("/api/v1/destinations?page=2&page_size=10");
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await resp.Content.ReadFromJsonAsync<PaginatedResponse<DestinationDto>>();
        body!.Page.Should().Be(2);
        body.PageSize.Should().Be(10);
        body.Items.Count.Should().BeLessThanOrEqualTo(10);
    }
}
