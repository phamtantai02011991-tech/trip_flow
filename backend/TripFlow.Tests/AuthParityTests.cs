using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using TripFlow.Api.Models.DTOs;
using TripFlow.Tests.Fixtures;

namespace TripFlow.Tests;

public class AuthParityTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly HttpClient _client;

    public AuthParityTests(TestWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task TC_AUTH_01_SendOtp_ValidPhone_ShouldReturnOk()
    {
        var resp = await _client.PostAsJsonAsync("/api/v1/auth/otp/send", new SendOtpRequest
        {
            Phone = "0987654321",
            FullName = "Nguyen Van A"
        });

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await resp.Content.ReadFromJsonAsync<SendOtpResponse>();
        body.Should().NotBeNull();
        body!.Phone.Should().Be("0987654321");
        body.DebugOtp.Should().NotBeNullOrEmpty();
    }

    [Fact]
    public async Task TC_AUTH_02_SendOtp_InvalidPhone_ShouldReturnBadRequest()
    {
        var resp = await _client.PostAsJsonAsync("/api/v1/auth/otp/send", new SendOtpRequest
        {
            Phone = "12345"
        });

        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        var content = await resp.Content.ReadAsStringAsync();
        content.Should().Contain("detail");
    }

    [Fact]
    public async Task TC_AUTH_03_SendOtp_TwiceWithin60s_ShouldReturn429()
    {
        var phone = "0912345678";
        await _client.PostAsJsonAsync("/api/v1/auth/otp/send", new SendOtpRequest { Phone = phone });

        var secondResp = await _client.PostAsJsonAsync("/api/v1/auth/otp/send", new SendOtpRequest { Phone = phone });
        secondResp.StatusCode.Should().Be((HttpStatusCode)429);
        var content = await secondResp.Content.ReadAsStringAsync();
        content.Should().Contain("detail");
    }

    [Fact]
    public async Task TC_AUTH_04_VerifyOtp_CorrectCode_ShouldReturnToken()
    {
        var phone = "0933334444";
        var sendResp = await _client.PostAsJsonAsync("/api/v1/auth/otp/send", new SendOtpRequest { Phone = phone, FullName = "Tester" });
        var sendBody = await sendResp.Content.ReadFromJsonAsync<SendOtpResponse>();

        var verifyResp = await _client.PostAsJsonAsync("/api/v1/auth/otp/verify", new VerifyOtpRequest
        {
            Phone = phone,
            OtpCode = sendBody!.DebugOtp!
        });

        verifyResp.StatusCode.Should().Be(HttpStatusCode.OK);
        var tokenBody = await verifyResp.Content.ReadFromJsonAsync<TokenResponse>();
        tokenBody.Should().NotBeNull();
        tokenBody!.AccessToken.Should().NotBeNullOrEmpty();
        tokenBody.User.Phone.Should().Be(phone);
    }

    [Fact]
    public async Task TC_AUTH_05_VerifyOtp_IncorrectCode_ShouldReturn400()
    {
        var phone = "0977778888";
        await _client.PostAsJsonAsync("/api/v1/auth/otp/send", new SendOtpRequest { Phone = phone });

        var verifyResp = await _client.PostAsJsonAsync("/api/v1/auth/otp/verify", new VerifyOtpRequest
        {
            Phone = phone,
            OtpCode = "000000"
        });

        verifyResp.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        var content = await verifyResp.Content.ReadAsStringAsync();
        content.Should().Contain("lần thử");
    }

    [Fact]
    public async Task TC_AUTH_06_Login_AdminCredentials_ShouldReturnToken()
    {
        var resp = await _client.PostAsJsonAsync("/api/v1/auth/login", new LoginRequest
        {
            Email = "admin@tripflow.vn",
            Password = "Admin@TripFlow2026!"
        });

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await resp.Content.ReadFromJsonAsync<TokenResponse>();
        body.Should().NotBeNull();
        body!.User.Role.Should().Be("super_admin");
        body.AccessToken.Should().NotBeNullOrEmpty();
    }

    [Fact]
    public async Task TC_AUTH_07_Login_WrongPassword5Times_ShouldLockAccount()
    {
        var email = "admin_lock_test@tripflow.vn";
        await _client.PostAsJsonAsync("/api/v1/auth/register", new RegisterRequest
        {
            Email = email,
            Password = "Password123!",
            FullName = "Lock Test User"
        });

        for (int i = 0; i < 5; i++)
        {
            await _client.PostAsJsonAsync("/api/v1/auth/login", new LoginRequest
            {
                Email = email,
                Password = "WrongPassword!"
            });
        }

        var lockedResp = await _client.PostAsJsonAsync("/api/v1/auth/login", new LoginRequest
        {
            Email = email,
            Password = "Password123!"
        });

        lockedResp.StatusCode.Should().Be((HttpStatusCode)423);
    }

    [Fact]
    public async Task TC_AUTH_08_TwoFactor_SetupAndStatus()
    {
        // Login as admin first
        var loginResp = await _client.PostAsJsonAsync("/api/v1/auth/login", new LoginRequest
        {
            Email = "admin@tripflow.vn",
            Password = "Admin@TripFlow2026!"
        });
        var tokenBody = await loginResp.Content.ReadFromJsonAsync<TokenResponse>();

        var authClient = _client;
        var request = new HttpRequestMessage(HttpMethod.Get, "/api/v1/auth/2fa/status");
        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", tokenBody!.AccessToken);

        var statusResp = await authClient.SendAsync(request);
        statusResp.StatusCode.Should().Be(HttpStatusCode.OK);
    }
}
