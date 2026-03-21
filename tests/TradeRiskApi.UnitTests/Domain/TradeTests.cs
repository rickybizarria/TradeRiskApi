using TradeRiskApi.Domain.Entities;
using TradeRiskApi.Domain.Enums;
using Xunit;

namespace TradeRiskApi.UnitTests.Domain;

public sealed class TradeTests
{
    [Theory]
    [InlineData(500000, ClientSector.Public, RiskLevel.LOWRISK)]
    [InlineData(999999, ClientSector.Private, RiskLevel.LOWRISK)]
    [InlineData(1000000, ClientSector.Public, RiskLevel.MEDIUMRISK)]
    [InlineData(2000000, ClientSector.Public, RiskLevel.MEDIUMRISK)]
    [InlineData(1000000, ClientSector.Private, RiskLevel.HIGHRISK)]
    [InlineData(5000000, ClientSector.Private, RiskLevel.HIGHRISK)]
    public void ClassifyRisk_ShouldReturnCorrectLevel(decimal value, ClientSector sector, RiskLevel expected)
    {
        var trade = new Trade(value, sector);
        var result = trade.ClassifyRisk();
        Assert.Equal(expected, result);
    }

    [Fact]
    public void Constructor_WithNegativeValue_ShouldThrowArgumentException()
    {
        Assert.Throws<ArgumentException>(() => new Trade(-100, ClientSector.Public));
    }
}
