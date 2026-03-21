# ============================================================================
# SCRIPT DE CONFIGURACAO AUTOMATICA - Trade Risk API
# Versao: 2.1 (Sem caracteres especiais)
# ============================================================================

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  CONFIGURACAO AUTOMATICA - TRADE RISK API" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

$rootPath = "C:\Dev\TradeRiskApi"

if (-not (Test-Path $rootPath)) {
    Write-Host "ERRO: Pasta $rootPath nao encontrada!" -ForegroundColor Red
    exit 1
}

Set-Location $rootPath

Write-Host "[1/6] Criando arquivos da camada Application..." -ForegroundColor Yellow

# ============================================================================
# APPLICATION LAYER - RiskAnalysisService
# ============================================================================

$riskAnalysisServicePath = "src\TradeRiskApi.Application\Services"
New-Item -Path $riskAnalysisServicePath -ItemType Directory -Force | Out-Null

$riskAnalysisServiceContent = @'
using System.Diagnostics;
using TradeRiskApi.Domain.Entities;
using TradeRiskApi.Domain.Enums;
using TradeRiskApi.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace TradeRiskApi.Application.Services;

public interface IRiskAnalysisService
{
    Task<(IEnumerable<RiskLevel> Categories, Dictionary<RiskLevel, RiskCategory> Summary, long ProcessingTimeMs)> 
        AnalyzeTradesAsync(IEnumerable<Trade> trades, CancellationToken cancellationToken = default);
}

public sealed class RiskAnalysisService : IRiskAnalysisService
{
    private readonly IRiskClassificationService _classificationService;
    private readonly ILogger<RiskAnalysisService> _logger;

    public RiskAnalysisService(
        IRiskClassificationService classificationService,
        ILogger<RiskAnalysisService> logger)
    {
        _classificationService = classificationService ?? throw new ArgumentNullException(nameof(classificationService));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    public async Task<(IEnumerable<RiskLevel> Categories, Dictionary<RiskLevel, RiskCategory> Summary, long ProcessingTimeMs)> 
        AnalyzeTradesAsync(IEnumerable<Trade> trades, CancellationToken cancellationToken = default)
    {
        if (trades == null)
            throw new ArgumentNullException(nameof(trades));

        var stopwatch = Stopwatch.StartNew();
        var tradeList = trades.ToList();
        _logger.LogInformation("Iniciando análise de {Count} trades", tradeList.Count);

        var summary = new Dictionary<RiskLevel, RiskCategory>
        {
            [RiskLevel.LOWRISK] = new RiskCategory(RiskLevel.LOWRISK),
            [RiskLevel.MEDIUMRISK] = new RiskCategory(RiskLevel.MEDIUMRISK),
            [RiskLevel.HIGHRISK] = new RiskCategory(RiskLevel.HIGHRISK)
        };

        var categories = new List<RiskLevel>(tradeList.Count);

        await Task.Run(() =>
        {
            foreach (var trade in tradeList)
            {
                cancellationToken.ThrowIfCancellationRequested();
                var riskLevel = _classificationService.ClassifyTrade(trade);
                categories.Add(riskLevel);
                summary[riskLevel].AddTrade(trade);
            }
        }, cancellationToken);

        stopwatch.Stop();

        _logger.LogInformation(
            "Análise concluída em {ElapsedMs}ms. LOWRISK={Low}, MEDIUMRISK={Medium}, HIGHRISK={High}",
            stopwatch.ElapsedMilliseconds,
            summary[RiskLevel.LOWRISK].Count,
            summary[RiskLevel.MEDIUMRISK].Count,
            summary[RiskLevel.HIGHRISK].Count
        );

        return (categories, summary, stopwatch.ElapsedMilliseconds);
    }
}
'@

Set-Content -Path "$riskAnalysisServicePath\RiskAnalysisService.cs" -Value $riskAnalysisServiceContent -Encoding UTF8
Write-Host "  [OK] RiskAnalysisService.cs criado" -ForegroundColor Green

# ============================================================================
# APPLICATION LAYER - TradeRequestValidator
# ============================================================================

$validatorsPath = "src\TradeRiskApi.Application\Validators"
New-Item -Path $validatorsPath -ItemType Directory -Force | Out-Null

$validatorContent = @'
using FluentValidation;
using TradeRiskApi.Application.DTOs;

namespace TradeRiskApi.Application.Validators;

public sealed class TradeRequestValidator : AbstractValidator<TradeRequestDto>
{
    public TradeRequestValidator()
    {
        RuleFor(x => x.Value)
            .GreaterThanOrEqualTo(0)
            .WithMessage("O valor da trade deve ser maior ou igual a zero");

        RuleFor(x => x.ClientSector)
            .NotEmpty()
            .WithMessage("O setor do cliente é obrigatório")
            .Must(sector => sector == "Public" || sector == "Private")
            .WithMessage("Setor deve ser Public ou Private");

        RuleFor(x => x.ClientId)
            .MaximumLength(50)
            .When(x => !string.IsNullOrEmpty(x.ClientId))
            .WithMessage("ClientId nao pode exceder 50 caracteres");
    }
}
'@

Set-Content -Path "$validatorsPath\TradeRequestValidator.cs" -Value $validatorContent -Encoding UTF8
Write-Host "  [OK] TradeRequestValidator.cs criado" -ForegroundColor Green

# ============================================================================
# APPLICATION LAYER - HealthCheck
# ============================================================================

$healthChecksPath = "src\TradeRiskApi.Application\HealthChecks"
New-Item -Path $healthChecksPath -ItemType Directory -Force | Out-Null

$healthCheckContent = @'
using Microsoft.Extensions.Diagnostics.HealthChecks;
using TradeRiskApi.Domain.Entities;
using TradeRiskApi.Domain.Enums;
using TradeRiskApi.Domain.Interfaces;

namespace TradeRiskApi.Application.HealthChecks;

public sealed class RiskClassificationHealthCheck : IHealthCheck
{
    private readonly IRiskClassificationService _classificationService;

    public RiskClassificationHealthCheck(IRiskClassificationService classificationService)
    {
        _classificationService = classificationService ?? throw new ArgumentNullException(nameof(classificationService));
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context, 
        CancellationToken cancellationToken = default)
    {
        try
        {
            var testTrade = new Trade(500000m, ClientSector.Public, "HEALTH_CHECK");
            var result = _classificationService.ClassifyTrade(testTrade);

            if (result == RiskLevel.LOWRISK)
            {
                return HealthCheckResult.Healthy("Servico de classificacao operacional");
            }

            return HealthCheckResult.Degraded("Servico retornou resultado inesperado");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Servico de classificacao falhou", ex);
        }
    }
}
'@

Set-Content -Path "$healthChecksPath\RiskClassificationHealthCheck.cs" -Value $healthCheckContent -Encoding UTF8
Write-Host "  [OK] RiskClassificationHealthCheck.cs criado" -ForegroundColor Green

Write-Host ""
Write-Host "[2/6] Criando arquivos da camada Web..." -ForegroundColor Yellow

# ============================================================================
# WEB LAYER - Middleware
# ============================================================================

$middlewarePath = "src\TradeRiskApi.Web\Middleware"
New-Item -Path $middlewarePath -ItemType Directory -Force | Out-Null

$middlewareContent = @'
using System.Net;
using System.Text.Json;

namespace TradeRiskApi.Web.Middleware;

public sealed class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception occurred");
            await HandleExceptionAsync(context, ex);
        }
    }

    private static Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;

        var response = new
        {
            error = "Internal Server Error",
            message = exception.Message,
            timestamp = DateTime.UtcNow
        };

        return context.Response.WriteAsync(JsonSerializer.Serialize(response));
    }
}
'@

Set-Content -Path "$middlewarePath\ExceptionHandlingMiddleware.cs" -Value $middlewareContent -Encoding UTF8
Write-Host "  [OK] ExceptionHandlingMiddleware.cs criado" -ForegroundColor Green

# ============================================================================
# WEB LAYER - Program.cs
# ============================================================================

$programContent = @'
using TradeRiskApi.Application.HealthChecks;
using TradeRiskApi.Application.Services;
using TradeRiskApi.Application.Validators;
using TradeRiskApi.Domain.Interfaces;
using TradeRiskApi.Web.Middleware;
using FluentValidation;
using FluentValidation.AspNetCore;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Trade Risk Classification API",
        Version = "v2.0",
        Description = "API REST para classificacao automatica de risco de operacoes financeiras",
        Contact = new OpenApiContact
        {
            Name = "UBS Technology Team",
            Email = "dev@ubs.com"
        }
    });

    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        c.IncludeXmlComments(xmlPath);
    }
});

builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssemblyContaining<TradeRequestValidator>();

builder.Services.AddScoped<IRiskClassificationService, RiskClassificationService>();
builder.Services.AddScoped<IRiskAnalysisService, RiskAnalysisService>();

builder.Services.AddHealthChecks()
    .AddCheck<RiskClassificationHealthCheck>("risk-classification");

builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Trade Risk API v2.0");
        c.RoutePrefix = string.Empty;
    });
}

app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseHttpsRedirection();
app.UseCors("AllowAll");
app.UseAuthorization();
app.MapControllers();
app.MapHealthChecks("/health");

app.Run();

public partial class Program { }
'@

Set-Content -Path "src\TradeRiskApi.Web\Program.cs" -Value $programContent -Encoding UTF8 -Force
Write-Host "  [OK] Program.cs atualizado" -ForegroundColor Green

Write-Host ""
Write-Host "[3/6] Atualizando arquivos .csproj..." -ForegroundColor Yellow

$webCsprojPath = "src\TradeRiskApi.Web\TradeRiskApi.Web.csproj"
if (Test-Path $webCsprojPath) {
    $webCsprojContent = Get-Content $webCsprojPath -Raw
    if ($webCsprojContent -notmatch "GenerateDocumentationFile") {
        $webCsprojContent = $webCsprojContent -replace '</PropertyGroup>', "    <GenerateDocumentationFile>true</GenerateDocumentationFile>`r`n    <NoWarn>1591</NoWarn>`r`n  </PropertyGroup>"
        Set-Content -Path $webCsprojPath -Value $webCsprojContent -Encoding UTF8
        Write-Host "  [OK] TradeRiskApi.Web.csproj atualizado" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] TradeRiskApi.Web.csproj ja possui XML documentation" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "[4/6] Criando testes unitarios..." -ForegroundColor Yellow

$domainTestsPath = "tests\TradeRiskApi.UnitTests\Domain"
New-Item -Path $domainTestsPath -ItemType Directory -Force | Out-Null

$tradeTestsContent = @'
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
'@

Set-Content -Path "$domainTestsPath\TradeTests.cs" -Value $tradeTestsContent -Encoding UTF8
Write-Host "  [OK] TradeTests.cs criado" -ForegroundColor Green

$applicationTestsPath = "tests\TradeRiskApi.UnitTests\Application"
New-Item -Path $applicationTestsPath -ItemType Directory -Force | Out-Null

$serviceTestsContent = @'
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
'@

Set-Content -Path "$applicationTestsPath\RiskClassificationServiceTests.cs" -Value $serviceTestsContent -Encoding UTF8
Write-Host "  [OK] RiskClassificationServiceTests.cs criado" -ForegroundColor Green

Write-Host ""
Write-Host "[5/6] Criando testes de integracao..." -ForegroundColor Yellow

$integrationTestsPath = "tests\TradeRiskApi.IntegrationTests\Controllers"
New-Item -Path $integrationTestsPath -ItemType Directory -Force | Out-Null

$integrationTestsContent = @'
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
'@

Set-Content -Path "$integrationTestsPath\TradesControllerTests.cs" -Value $integrationTestsContent -Encoding UTF8
Write-Host "  [OK] TradesControllerTests.cs criado" -ForegroundColor Green

Write-Host ""
Write-Host "[6/6] Criando arquivos de documentacao..." -ForegroundColor Yellow

$readmeContent = @'
# Trade Risk Classification API

API REST para classificacao de risco de operacoes financeiras.

## Executar
```bash
cd src/TradeRiskApi.Web
dotnet run
```

Acesse: https://localhost:5001

## Testes
```bash
dotnet test
```
'@

Set-Content -Path "README.md" -Value $readmeContent -Encoding UTF8
Write-Host "  [OK] README.md criado" -ForegroundColor Green

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  CONFIGURACAO CONCLUIDA COM SUCESSO!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Proximos passos:" -ForegroundColor Cyan
Write-Host "1. Abra: TradeRiskApi.sln no Visual Studio" -ForegroundColor White
Write-Host "2. Compile: Ctrl+Shift+B" -ForegroundColor White
Write-Host "3. Execute: F5" -ForegroundColor White
Write-Host "4. Acesse: https://localhost:5001" -ForegroundColor White
Write-Host ""