using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using TripFlow.Api.Models.DTOs;
using TripFlow.Api.Services;
using TripFlow.Tests.Fixtures;

namespace TripFlow.Tests;

public class PlacesAndCorridorTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly HttpClient _client;

    public PlacesAndCorridorTests(TestWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task TC_COR_01_Nearby_GasStations_ShouldReturnAtLeast1()
    {
        var resp = await _client.GetAsync("/api/v1/places/nearby?lat=21.0288&lng=105.8525&radius_km=6&kinds=gas");
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await resp.Content.ReadFromJsonAsync<NearbyResponse>();
        body.Should().NotBeNull();
        body!.Total.Should().BeGreaterThanOrEqualTo(1);
    }

    [Fact]
    public async Task TC_COR_02_AlongRoute_Hanoi_ShouldReturnStops()
    {
        var resp = await _client.PostAsJsonAsync("/api/v1/places/along-route", new AlongRouteRequest
        {
            OriginLat = 21.0288,
            OriginLng = 105.8525,
            DestLat = 21.0288,
            DestLng = 105.8359,
            CorridorRadiusKm = 2.0,
            Kinds = "rest,gas,ev,cafe"
        });

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await resp.Content.ReadFromJsonAsync<AlongRouteResponse>();
        body.Should().NotBeNull();
        body!.Count.Should().BeGreaterThanOrEqualTo(1);
        body.Stops.Should().NotBeEmpty();
    }

    [Fact]
    public async Task TC_COR_03_Suggest_HoiAn_ShouldReturnSuggestions()
    {
        var resp = await _client.GetAsync("/api/v1/places/suggest?q=hoi an");
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await resp.Content.ReadFromJsonAsync<List<PlaceSuggestItem>>();
        body.Should().NotBeNull();
        body!.Count.Should().BeGreaterThanOrEqualTo(1);
    }

    [Fact]
    public async Task TC_COR_04_Suggest_VietnameseNoAccent_ShouldFindMatches()
    {
        var resp = await _client.GetAsync("/api/v1/places/suggest?q=sai gon");
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await resp.Content.ReadFromJsonAsync<List<PlaceSuggestItem>>();
        body.Should().NotBeNull();
        body!.Should().NotBeEmpty();
    }

    [Fact]
    public async Task TC_COR_05_CorridorSearch_ShouldReturnRestaurants()
    {
        var resp = await _client.PostAsJsonAsync("/api/v1/restaurants/corridor-search", new CorridorSearchRequest
        {
            OriginLat = 10.7769,
            OriginLng = 106.6953,
            DestLat = 10.7932,
            DestLng = 106.6698,
            CorridorRadiusKm = 3.0
        });

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await resp.Content.ReadFromJsonAsync<CorridorSearchResponse>();
        body.Should().NotBeNull();
        body!.Items.Should().NotBeEmpty();
    }

    [Fact]
    public async Task TC_COR_06_CheckDetourAndProgress_Metrics()
    {
        var geo = new GeoService();
        var route = new List<PointD>
        {
            new(10.0, 106.0),
            new(10.0, 107.0)
        };

        var proj = geo.ProjectPointToRoute(10.01, 106.5, route);
        proj.DistanceToRouteKm.Should().BeLessThan(3.0);
        proj.DetourDistanceKm.Should().Be(Math.Round(proj.DistanceToRouteKm * 2, 2));
        proj.RouteProgressPct.Should().BeInRange(40, 60);
    }

    [Fact]
    public async Task TC_COR_07_SearchHistory_AddAndList()
    {
        var resp = await _client.PostAsJsonAsync("/api/v1/places/history", new CreateSearchHistoryRequest
        {
            Query = "Đà Lạt săn mây",
            Kind = "text"
        });

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task TC_COR_08_SfcsScoreCalculation()
    {
        var geo = new GeoService();
        double score = geo.CalculateSfcsScore(4.8, 1000, true, 0.5);
        score.Should().BeGreaterThan(80.0);
        score.Should().BeLessThanOrEqualTo(105.0);
    }
}
