using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using TripFlow.Api.Models.DTOs;
using TripFlow.Tests.Fixtures;

namespace TripFlow.Tests;

public class TripsAndExpensesTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly HttpClient _client;

    public TripsAndExpensesTests(TestWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task TC_TRIP_01_CreateTrip_WithGuestToken_ShouldSucceed()
    {
        var guestClient = _client;
        var guestToken = Guid.NewGuid().ToString("N");
        var req = new HttpRequestMessage(HttpMethod.Post, "/api/v1/trips")
        {
            Content = JsonContent.Create(new CreateTripRequest
            {
                Title = "Chuyến phượt Đà Lạt 3N2Đ",
                OriginName = "TP. Hồ Chí Minh",
                OriginLat = 10.7769,
                OriginLng = 106.7009,
                DestinationName = "Đà Lạt",
                DestinationLat = 11.9404,
                DestinationLng = 108.4583,
                ProvinceId = 9,
                TotalDays = 3,
                BudgetAmount = 3000000
            })
        };
        req.Headers.Add("X-Guest-Token", guestToken);

        var resp = await guestClient.SendAsync(req);
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var trip = await resp.Content.ReadFromJsonAsync<TripDetailDto>();
        trip.Should().NotBeNull();
        trip!.TotalDays.Should().Be(3);
        trip.Days.Count.Should().Be(3);
    }

    [Fact]
    public async Task TC_TRIP_02_GetTrip_DifferentGuestToken_ShouldReturnNotFound()
    {
        var guestToken1 = Guid.NewGuid().ToString("N");
        var req1 = new HttpRequestMessage(HttpMethod.Post, "/api/v1/trips")
        {
            Content = JsonContent.Create(new CreateTripRequest
            {
                Title = "Chuyến đi riêng tư",
                OriginName = "Hà Nội",
                OriginLat = 21.0285,
                OriginLng = 105.8542
            })
        };
        req1.Headers.Add("X-Guest-Token", guestToken1);
        var createResp = await _client.SendAsync(req1);
        var created = await createResp.Content.ReadFromJsonAsync<TripDetailDto>();

        // Truy cập bằng guestToken khác
        var req2 = new HttpRequestMessage(HttpMethod.Get, $"/api/v1/trips/{created!.Id}");
        req2.Headers.Add("X-Guest-Token", Guid.NewGuid().ToString("N"));
        var getResp = await _client.SendAsync(req2);
        getResp.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task TC_TRIP_03_AddStop_ToDay1_ShouldSucceed()
    {
        var guestToken = Guid.NewGuid().ToString("N");
        var createReq = new HttpRequestMessage(HttpMethod.Post, "/api/v1/trips")
        {
            Content = JsonContent.Create(new CreateTripRequest
            {
                Title = "Phượt Sài Gòn",
                OriginName = "Sài Gòn",
                OriginLat = 10.7769,
                OriginLng = 106.7009,
                TotalDays = 2
            })
        };
        createReq.Headers.Add("X-Guest-Token", guestToken);
        var tripResp = await _client.SendAsync(createReq);
        var trip = await tripResp.Content.ReadFromJsonAsync<TripDetailDto>();

        var addStopResp = await _client.PostAsJsonAsync($"/api/v1/trips/{trip!.Id}/days/1/stops", new AddStopRequest
        {
            Kind = "destination",
            Name = "Dinh Độc Lập",
            Lat = 10.7769,
            Lng = 106.6953,
            StayMins = 90
        });

        addStopResp.StatusCode.Should().Be(HttpStatusCode.OK);
        var stop = await addStopResp.Content.ReadFromJsonAsync<TripStopDto>();
        stop.Should().NotBeNull();
        stop!.Name.Should().Be("Dinh Độc Lập");
    }

    [Fact]
    public async Task TC_TRIP_04_ReorderStops_ShouldUpdateOrder()
    {
        var tripResp = await _client.PostAsJsonAsync("/api/v1/trips", new CreateTripRequest
        {
            Title = "Trip Reorder Test",
            OriginName = "Hà Nội",
            OriginLat = 21.0285,
            OriginLng = 105.8542
        });
        var trip = await tripResp.Content.ReadFromJsonAsync<TripDetailDto>();

        var s1Resp = await _client.PostAsJsonAsync($"/api/v1/trips/{trip!.Id}/days/1/stops", new AddStopRequest { Name = "Điểm A", Lat = 21.0, Lng = 105.0 });
        var s2Resp = await _client.PostAsJsonAsync($"/api/v1/trips/{trip.Id}/days/1/stops", new AddStopRequest { Name = "Điểm B", Lat = 21.1, Lng = 105.1 });
        var s1 = await s1Resp.Content.ReadFromJsonAsync<TripStopDto>();
        var s2 = await s2Resp.Content.ReadFromJsonAsync<TripStopDto>();

        var reorderResp = await _client.PutAsJsonAsync($"/api/v1/trips/{trip.Id}/days/1/reorder", new ReorderStopsRequest
        {
            StopIds = new List<int> { s2!.Id, s1!.Id }
        });

        reorderResp.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task TC_TRIP_05_ShareTrip_ShouldReturnShareToken()
    {
        var tripResp = await _client.PostAsJsonAsync("/api/v1/trips", new CreateTripRequest
        {
            Title = "Chia sẻ chuyến đi",
            OriginName = "Đà Nẵng",
            OriginLat = 16.0544,
            OriginLng = 108.2022
        });
        var trip = await tripResp.Content.ReadFromJsonAsync<TripDetailDto>();

        var shareResp = await _client.PostAsync($"/api/v1/trips/{trip!.Id}/share", null);
        shareResp.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await shareResp.Content.ReadFromJsonAsync<ShareTripResponse>();
        body!.ShareToken.Should().NotBeNullOrEmpty();
        body.ShareUrl.Should().Contain(body.ShareToken);
    }

    [Fact]
    public async Task TC_TRIP_06_AddExpense_ShouldSucceed()
    {
        var tripResp = await _client.PostAsJsonAsync("/api/v1/trips", new CreateTripRequest
        {
            Title = "Trip Expense",
            OriginName = "Nha Trang",
            OriginLat = 12.2388,
            OriginLng = 109.1967
        });
        var trip = await tripResp.Content.ReadFromJsonAsync<TripDetailDto>();

        var expResp = await _client.PostAsJsonAsync($"/api/v1/trips/{trip!.Id}/expenses", new ExpenseCreateRequest
        {
            Category = "fuel",
            Title = "Đổ xăng xe máy",
            Amount = 100000,
            Planned = false
        });

        expResp.StatusCode.Should().Be(HttpStatusCode.OK);
        var exp = await expResp.Content.ReadFromJsonAsync<ExpenseDto>();
        exp!.Amount.Should().Be(100000);
        exp.Category.Should().Be("fuel");
    }

    [Fact]
    public async Task TC_TRIP_07_BudgetSummary_ShouldComputeSpentAndRemaining()
    {
        var tripResp = await _client.PostAsJsonAsync("/api/v1/trips", new CreateTripRequest
        {
            Title = "Trip Budget",
            OriginName = "Huế",
            OriginLat = 16.4637,
            OriginLng = 107.5909,
            BudgetAmount = 500000
        });
        var trip = await tripResp.Content.ReadFromJsonAsync<TripDetailDto>();

        await _client.PostAsJsonAsync($"/api/v1/trips/{trip!.Id}/expenses", new ExpenseCreateRequest { Category = "food", Title = "Cơm hến", Amount = 150000 });
        await _client.PostAsJsonAsync($"/api/v1/trips/{trip.Id}/expenses", new ExpenseCreateRequest { Category = "fuel", Title = "Xăng", Amount = 100000 });

        var sumResp = await _client.GetAsync($"/api/v1/trips/{trip.Id}/budget-summary");
        sumResp.StatusCode.Should().Be(HttpStatusCode.OK);

        var summary = await sumResp.Content.ReadFromJsonAsync<BudgetSummaryResponse>();
        summary!.TotalSpent.Should().Be(250000);
        summary.Remaining.Should().Be(250000);
        summary.IsOverBudget.Should().BeFalse();
    }

    [Fact]
    public async Task TC_TRIP_08_GenerateTrip_AndCheckAiStatus()
    {
        var tripResp = await _client.PostAsJsonAsync("/api/v1/trips", new CreateTripRequest
        {
            Title = "Tự động sinh lịch trình",
            OriginName = "Đà Lạt",
            OriginLat = 11.9404,
            OriginLng = 108.4583,
            ProvinceId = 9,
            TotalDays = 2
        });
        var trip = await tripResp.Content.ReadFromJsonAsync<TripDetailDto>();

        var genResp = await _client.PostAsync($"/api/v1/trips/{trip!.Id}/generate", null);
        genResp.StatusCode.Should().Be(HttpStatusCode.OK);

        var statusResp = await _client.GetAsync($"/api/v1/trips/{trip.Id}/ai-status");
        statusResp.StatusCode.Should().Be(HttpStatusCode.OK);
        var status = await statusResp.Content.ReadFromJsonAsync<AiStatusResponse>();
        status!.Status.Should().Be("ready");
    }
}
