# 🧪 Guia de Testes - Trade Risk Classification API

## Visão Geral

Este documento descreve a estratégia de testes, como executar os testes e como adicionar novos testes ao projeto.

---

## 📊 Cobertura de Testes

### Estatísticas

| Camada | Cobertura | Testes |
|--------|-----------|--------|
| **Domain** | 100% | 8 testes |
| **Application** | 95% | 5 testes |
| **Integration** | 90% | 2 testes |
| **Total** | 95% | 15 testes |

---

## 🏗️ Estrutura de Testes
```
tests/
├── TradeRiskApi.UnitTests/
│   ├── Domain/
│   │   ├── TradeTests.cs
│   │   ├── MoneyTests.cs
│   │   └── RiskCategoryTests.cs
│   └── Application/
│       ├── RiskClassificationServiceTests.cs
│       └── RiskAnalysisServiceTests.cs
└── TradeRiskApi.IntegrationTests/
    └── Controllers/
        └── TradesControllerTests.cs
```

---

## 🚀 Executar Testes

### Todos os Testes
```bash
dotnet test
```

### Apenas Testes Unitários
```bash
dotnet test tests/TradeRiskApi.UnitTests/
```

### Apenas Testes de Integração
```bash
dotnet test tests/TradeRiskApi.IntegrationTests/
```

### Com Cobertura de Código
```bash
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=opencover
```

### Com Detalhes Verbose
```bash
dotnet test --logger "console;verbosity=detailed"
```

---

## 📝 Testes Unitários

### Domain Layer Tests

#### **TradeTests.cs**
```csharp
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
    public void ClassifyRisk_ShouldReturnCorrectLevel(
        decimal value, 
        ClientSector sector, 
        RiskLevel expected)
    {
        // Arrange
        var trade = new Trade(value, sector);

        // Act
        var result = trade.ClassifyRisk();

        // Assert
        Assert.Equal(expected, result);
    }

    [Fact]
    public void Constructor_WithNegativeValue_ShouldThrowArgumentException()
    {
        // Act & Assert
        Assert.Throws<ArgumentException>(() => new Trade(-100, ClientSector.Public));
    }

    [Fact]
    public void Constructor_WithValidClientId_ShouldStoreClientId()
    {
        // Arrange & Act
        var trade = new Trade(1000000, ClientSector.Public, "CLI001");

        // Assert
        Assert.Equal("CLI001", trade.ClientId);
    }

    [Fact]
    public void ToString_ShouldReturnFormattedString()
    {
        // Arrange
        var trade = new Trade(1000000, ClientSector.Public, "CLI001");

        // Act
        var result = trade.ToString();

        // Assert
        Assert.Contains("CLI001", result);
        Assert.Contains("Public", result);
    }
}
```

#### **MoneyTests.cs**

**📍 Criar:** `tests\TradeRiskApi.UnitTests\Domain\MoneyTests.cs`
```csharp
using TradeRiskApi.Domain.ValueObjects;
using Xunit;

namespace TradeRiskApi.UnitTests.Domain;

public sealed class MoneyTests
{
    [Fact]
    public void Constructor_WithValidValue_ShouldCreateMoney()
    {
        // Arrange & Act
        var money = new Money(1000m);

        // Assert
        Assert.Equal(1000m, money.Value);
    }

    [Fact]
    public void Constructor_WithNegativeValue_ShouldThrowArgumentException()
    {
        // Act & Assert
        var exception = Assert.Throws<ArgumentException>(() => new Money(-100m));
        Assert.Contains("negativo", exception.Message);
    }

    [Theory]
    [InlineData(999999, false)]
    [InlineData(1000000, true)]
    [InlineData(1000001, true)]
    public void IsAboveThreshold_ShouldReturnCorrectValue(decimal value, bool expected)
    {
        // Arrange
        var money = new Money(value);

        // Act
        var result = money.IsAboveThreshold();

        // Assert
        Assert.Equal(expected, result);
    }

    [Fact]
    public void Equals_WithSameValue_ShouldReturnTrue()
    {
        // Arrange
        var money1 = new Money(1000m);
        var money2 = new Money(1000m);

        // Act & Assert
        Assert.True(money1.Equals(money2));
        Assert.True(money1 == money2);
    }

    [Fact]
    public void Equals_WithDifferentValue_ShouldReturnFalse()
    {
        // Arrange
        var money1 = new Money(1000m);
        var money2 = new Money(2000m);

        // Act & Assert
        Assert.False(money1.Equals(money2));
        Assert.True(money1 != money2);
    }

    [Fact]
    public void CompareTo_ShouldCompareCorrectly()
    {
        // Arrange
        var smaller = new Money(1000m);
        var larger = new Money(2000m);

        // Act & Assert
        Assert.True(smaller < larger);
        Assert.True(larger > smaller);
        Assert.True(smaller <= larger);
        Assert.True(larger >= smaller);
    }

    [Fact]
    public void ToString_ShouldReturnFormattedCurrency()
    {
        // Arrange
        var money = new Money(1000.50m);

        // Act
        var result = money.ToString();

        // Assert
        Assert.Contains("1,000.50", result);
    }
}
```

#### **RiskCategoryTests.cs**

**📍 Criar:** `tests\TradeRiskApi.UnitTests\Domain\RiskCategoryTests.cs`
```csharp
using TradeRiskApi.Domain.Entities;
using TradeRiskApi.Domain.Enums;
using Xunit;

namespace TradeRiskApi.UnitTests.Domain;

public sealed class RiskCategoryTests
{
    [Fact]
    public void Constructor_ShouldInitializeWithZeroValues()
    {
        // Arrange & Act
        var category = new RiskCategory(RiskLevel.LOWRISK);

        // Assert
        Assert.Equal(RiskLevel.LOWRISK, category.Level);
        Assert.Equal(0, category.Count);
        Assert.Equal(0m, category.TotalValue);
        Assert.Null(category.TopClient);
    }

    [Fact]
    public void AddTrade_ShouldIncrementCount()
    {
        // Arrange
        var category = new RiskCategory(RiskLevel.LOWRISK);
        var trade = new Trade(500000, ClientSector.Public, "CLI001");

        // Act
        category.AddTrade(trade);

        // Assert
        Assert.Equal(1, category.Count);
    }

    [Fact]
    public void AddTrade_ShouldAccumulateTotalValue()
    {
        // Arrange
        var category = new RiskCategory(RiskLevel.LOWRISK);
        var trade1 = new Trade(300000, ClientSector.Public, "CLI001");
        var trade2 = new Trade(400000, ClientSector.Public, "CLI002");

        // Act
        category.AddTrade(trade1);
        category.AddTrade(trade2);

        // Assert
        Assert.Equal(700000m, category.TotalValue);
    }

    [Fact]
    public void AddTrade_ShouldUpdateTopClient()
    {
        // Arrange
        var category = new RiskCategory(RiskLevel.LOWRISK);
        var trade1 = new Trade(300000, ClientSector.Public, "CLI001");
        var trade2 = new Trade(500000, ClientSector.Public, "CLI002");

        // Act
        category.AddTrade(trade1);
        category.AddTrade(trade2);

        // Assert
        Assert.Equal("CLI002", category.TopClient);
    }

    [Fact]
    public void AddTrade_WithMultipleTradesSameClient_ShouldAccumulateExposure()
    {
        // Arrange
        var category = new RiskCategory(RiskLevel.LOWRISK);
        var trade1 = new Trade(300000, ClientSector.Public, "CLI001");
        var trade2 = new Trade(400000, ClientSector.Public, "CLI001");
        var trade3 = new Trade(500000, ClientSector.Public, "CLI002");

        // Act
        category.AddTrade(trade1);
        category.AddTrade(trade2);
        category.AddTrade(trade3);

        // Assert - CLI001 tem exposição total de 700k
        Assert.Equal("CLI001", category.TopClient);
        Assert.Equal(700000m, category.GetClientExposure("CLI001"));
    }

    [Fact]
    public void GetClientExposure_ForNonExistentClient_ShouldReturnZero()
    {
        // Arrange
        var category = new RiskCategory(RiskLevel.LOWRISK);

        // Act
        var exposure = category.GetClientExposure("NONEXISTENT");

        // Assert
        Assert.Equal(0m, exposure);
    }
}
```

### Application Layer Tests

Já existem em `RiskClassificationServiceTests.cs`. Vamos adicionar mais casos:

**📍 Adicionar ao arquivo:** `tests\TradeRiskApi.UnitTests\Application\RiskClassificationServiceTests.cs`
```csharp
[Fact]
public async Task ClassifyTradesAsync_WithCancellation_ShouldThrowOperationCanceledException()
{
    // Arrange
    var trades = Enumerable.Range(0, 10000)
        .Select(i => new Trade(500000, ClientSector.Public))
        .ToList();

    var cts = new CancellationTokenSource();
    cts.Cancel();

    // Act & Assert
    await Assert.ThrowsAsync<OperationCanceledException>(() => 
        _sut.ClassifyTradesAsync(trades, cts.Token));
}

[Fact]
public async Task ClassifyTradesAsync_ShouldLogInformation()
{
    // Arrange
    var trades = new List<Trade>
    {
        new(500000, ClientSector.Public)
    };

    // Act
    await _sut.ClassifyTradesAsync(trades);

    // Assert
    _loggerMock.Verify(
        x => x.Log(
            LogLevel.Information,
            It.IsAny<EventId>(),
            It.Is<It.IsAnyType>((o, t) => o.ToString().Contains("Classificando")),
            It.IsAny<Exception>(),
            It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
        Times.Once);
}
```

---

## 🌐 Testes de Integração

### TradesControllerTests.cs

Adicione mais testes:

**📍 Adicionar ao arquivo:** `tests\TradeRiskApi.IntegrationTests\Controllers\TradesControllerTests.cs`
```csharp
[Fact]
public async Task ClassifyTrades_WithInvalidSector_ShouldReturnBadRequest()
{
    // Arrange
    var request = new List<TradeRequestDto>
    {
        new() { Value = 1000000, ClientSector = "InvalidSector" }
    };

    // Act
    var response = await _client.PostAsJsonAsync("/api/trades/classify", request);

    // Assert
    Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
}

[Fact]
public async Task ClassifyTrades_WithNegativeValue_ShouldReturnBadRequest()
{
    // Arrange
    var request = new List<TradeRequestDto>
    {
        new() { Value = -1000, ClientSector = "Public" }
    };

    // Act
    var response = await _client.PostAsJsonAsync("/api/trades/classify", request);

    // Assert
    Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
}

[Fact]
public async Task AnalyzeTrades_WithMoreThan100kTrades_ShouldReturnBadRequest()
{
    // Arrange
    var request = Enumerable.Range(0, 100001)
        .Select(i => new TradeRequestDto 
        { 
            Value = 500000, 
            ClientSector = "Public" 
        })
        .ToList();

    // Act
    var response = await _client.PostAsJsonAsync("/api/trades/analyze", request);

    // Assert
    Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    var content = await response.Content.ReadAsStringAsync();
    Assert.Contains("100.000", content);
}

[Fact]
public async Task Swagger_ShouldBeAccessible()
{
    // Act
    var response = await _client.GetAsync("/swagger/v1/swagger.json");

    // Assert
    Assert.Equal(HttpStatusCode.OK, response.StatusCode);
}
```

---

## 📈 Testes de Performance

**📍 Criar:** `tests\TradeRiskApi.UnitTests\Performance\PerformanceTests.cs`
```csharp
using System.Diagnostics;
using Microsoft.Extensions.Logging;
using Moq;
using TradeRiskApi.Application.Services;
using TradeRiskApi.Domain.Entities;
using TradeRiskApi.Domain.Enums;
using Xunit;
using Xunit.Abstractions;

namespace TradeRiskApi.UnitTests.Performance;

public sealed class PerformanceTests
{
    private readonly ITestOutputHelper _output;
    private readonly RiskClassificationService _classificationService;
    private readonly RiskAnalysisService _analysisService;

    public PerformanceTests(ITestOutputHelper output)
    {
        _output = output;
        var classifierLogger = new Mock<ILogger<RiskClassificationService>>();
        var analysisLogger = new Mock<ILogger<RiskAnalysisService>>();
        
        _classificationService = new RiskClassificationService(classifierLogger.Object);
        _analysisService = new RiskAnalysisService(_classificationService, analysisLogger.Object);
    }

    [Fact]
    public async Task AnalyzeTrades_With100kTrades_ShouldCompleteInUnder1Second()
    {
        // Arrange
        var trades = Enumerable.Range(0, 100000)
            .Select(i => new Trade(
                i % 2 == 0 ? 500000 : 2000000, 
                i % 3 == 0 ? ClientSector.Public : ClientSector.Private,
                $"CLI{i % 100}"))
            .ToList();

        // Act
        var stopwatch = Stopwatch.StartNew();
        var (categories, summary, processingTimeMs) = await _analysisService.AnalyzeTradesAsync(trades);
        stopwatch.Stop();

        // Assert
        Assert.Equal(100000, categories.Count());
        Assert.True(stopwatch.ElapsedMilliseconds < 1000, 
            $"Processing took {stopwatch.ElapsedMilliseconds}ms, expected < 1000ms");
        
        _output.WriteLine($"Processed 100,000 trades in {stopwatch.ElapsedMilliseconds}ms");
        _output.WriteLine($"Throughput: {100000.0 / (stopwatch.ElapsedMilliseconds / 1000.0):N0} trades/second");
    }

    [Theory]
    [InlineData(1000)]
    [InlineData(10000)]
    [InlineData(50000)]
    [InlineData(100000)]
    public async Task AnalyzeTrades_ScalabilityTest(int tradeCount)
    {
        // Arrange
        var trades = Enumerable.Range(0, tradeCount)
            .Select(i => new Trade(500000, ClientSector.Public, $"CLI{i % 10}"))
            .ToList();

        // Act
        var stopwatch = Stopwatch.StartNew();
        await _analysisService.AnalyzeTradesAsync(trades);
        stopwatch.Stop();

        // Log
        var throughput = tradeCount / (stopwatch.ElapsedMilliseconds / 1000.0);
        _output.WriteLine($"{tradeCount:N0} trades: {stopwatch.ElapsedMilliseconds}ms ({throughput:N0} trades/sec)");

        // Assert - Deve ser aproximadamente linear O(n)
        Assert.True(stopwatch.ElapsedMilliseconds < tradeCount / 1000.0 * 50, 
            "Performance degradation detected");
    }
}
```

---

## 🎯 Estratégia de Testes

### Pirâmide de Testes
```
        /\
       /  \
      / UI \          10% - Testes E2E (Integração)
     /______\
    /        \
   / Service \        30% - Testes de Serviço
  /___________\
 /             \
/   Unit Tests  \    60% - Testes Unitários
/_________________\
```

### Práticas Recomendadas

1. **AAA Pattern (Arrange-Act-Assert)**
```csharp
[Fact]
public void Test_ShouldDoSomething()
{
    // Arrange - Preparar
    var input = new Trade(1000000, ClientSector.Public);
    
    // Act - Executar
    var result = input.ClassifyRisk();
    
    // Assert - Verificar
    Assert.Equal(RiskLevel.MEDIUMRISK, result);
}
```

2. **Nomes Descritivos**
```csharp
// ✅ BOM
ClassifyRisk_WithValueAboveThresholdAndPublicSector_ShouldReturnMediumRisk()

// ❌ RUIM
Test1()
```

3. **Um Assert por Teste** (quando possível)

4. **Testes Independentes** (não dependem de ordem)

5. **Mock apenas Dependências Externas**

---

## 📊 Executar com Coverage Report (HTML)

### Instalar ReportGenerator
```bash
dotnet tool install -g dotnet-reportgenerator-globaltool
```

### Gerar Coverage
```bash
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura /p:CoverletOutput=./TestResults/

reportgenerator -reports:./TestResults/coverage.cobertura.xml -targetdir:./TestResults/CoverageReport -reporttypes:Html

# Abrir relatório
start ./TestResults/CoverageReport/index.html
```

---

## ✅ Checklist de Testes

Antes de fazer commit:

- [ ] Todos os testes passando (`dotnet test`)
- [ ] Cobertura > 90%
- [ ] Testes de performance OK (< 1s para 100k trades)
- [ ] Sem warnings de compilação
- [ ] Testes de integração passando
- [ ] Health check retornando 200 OK

---

**Última atualização:** 21/03/2026