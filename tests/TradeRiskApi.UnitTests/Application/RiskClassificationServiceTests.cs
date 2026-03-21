using Microsoft.Extensions.Logging;
using Moq;
using TradeRiskApi.Application.Services;
using TradeRiskApi.Domain.Entities;
using TradeRiskApi.Domain.Enums;
using Xunit;

namespace TradeRiskApi.UnitTests.Application;

public sealed class RiskClassificationServiceTests
{
    private readonly RiskClassificationService _sut;
    private readonly Mock<ILogger<RiskClassificationService>> _loggerMock;

    public RiskClassificationServiceTests()
    {
        _loggerMock = new Mock<ILogger<RiskClassificationService>>();
        _sut = new RiskClassificationService(_loggerMock.Object);
    }

    [Fact]
    public async Task ClassifyTradesAsync_ShouldReturnCategoriesInSameOrder()
    {
        var trades = new List<Trade>
        {
            new(2000000, ClientSector.Private),
            new(400000, ClientSector.Public),
            new(500000, ClientSector.Public),
            new(3000000, ClientSector.Public)
        };

        var results = await _sut.ClassifyTradesAsync(trades);
        var resultList = results.ToList();

        Assert.Equal(4, resultList.Count);
        Assert.Equal(RiskLevel.HIGHRISK, resultList[0]);
        Assert.Equal(RiskLevel.LOWRISK, resultList[1]);
        Assert.Equal(RiskLevel.LOWRISK, resultList[2]);
        Assert.Equal(RiskLevel.MEDIUMRISK, resultList[3]);
    }
}
