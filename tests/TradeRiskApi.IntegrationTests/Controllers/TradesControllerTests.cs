using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using TradeRiskApi.Application.DTOs;
using Xunit;

namespace TradeRiskApi.IntegrationTests.Controllers;

public sealed class TradesControllerTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public TradesControllerTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task ClassifyTrades_WithValidRequest_ShouldReturnOk()
    {
        var request = new List<TradeRequestDto>
        {
            new() { Value = 2000000, ClientSector = "Private" },
            new() { Value = 400000, ClientSector = "Public" }
        };

        var response = await _client.PostAsJsonAsync("/api/trades/classify", request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task HealthEndpoint_ShouldReturnOk()
    {
        var response = await _client.GetAsync("/api/trades/health");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
