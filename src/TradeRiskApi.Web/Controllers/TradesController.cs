using Microsoft.AspNetCore.Mvc;
using TradeRiskApi.Application.DTOs;
using TradeRiskApi.Application.Services;
using TradeRiskApi.Domain.Entities;
using TradeRiskApi.Domain.Enums;
using TradeRiskApi.Domain.Interfaces;

namespace TradeRiskApi.Web.Controllers;

/// <summary>
/// API para classificação automática de risco de operações financeiras (trades)
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public sealed class TradesController : ControllerBase
{
    private readonly IRiskClassificationService _classificationService;
    private readonly IRiskAnalysisService _analysisService;
    private readonly ILogger<TradesController> _logger;

    public TradesController(
        IRiskClassificationService classificationService,
        IRiskAnalysisService analysisService,
        ILogger<TradesController> logger)
    {
        _classificationService = classificationService ?? throw new ArgumentNullException(nameof(classificationService));
        _analysisService = analysisService ?? throw new ArgumentNullException(nameof(analysisService));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <summary>
    /// Classifica uma lista de trades retornando suas categorias de risco
    /// </summary>
    [HttpPost("classify")]
    [ProducesResponseType(typeof(TradeResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<TradeResponseDto>> ClassifyTrades(
        [FromBody] List<TradeRequestDto> trades,
        CancellationToken cancellationToken = default)
    {
        if (trades == null || trades.Count == 0)
        {
            _logger.LogWarning("Requisição de classificação recebida com lista vazia");
            return BadRequest(new { error = "A lista de trades não pode estar vazia" });
        }

        _logger.LogInformation("Recebida requisição para classificar {Count} trades", trades.Count);

        try
        {
            var domainTrades = trades.Select(MapToDomain);
            var categories = await _classificationService.ClassifyTradesAsync(domainTrades, cancellationToken);

            var response = new TradeResponseDto
            {
                Categories = categories.Select(c => c.ToString()).ToList()
            };

            _logger.LogInformation("Classificação concluída com sucesso para {Count} trades", trades.Count);
            return Ok(response);
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Operação de classificação cancelada pelo cliente");
            return StatusCode(499, new { error = "Operação cancelada" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao classificar trades");
            return StatusCode(500, new { error = "Erro interno ao processar requisição" });
        }
    }

    /// <summary>
    /// Classifica trades e retorna análise estatística completa da carteira
    /// </summary>
    [HttpPost("analyze")]
    [ProducesResponseType(typeof(RiskAnalysisResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<RiskAnalysisResponseDto>> AnalyzeTrades(
        [FromBody] List<TradeRequestDto> trades,
        CancellationToken cancellationToken = default)
    {
        if (trades == null || trades.Count == 0)
        {
            _logger.LogWarning("Requisição de análise recebida com lista vazia");
            return BadRequest(new { error = "A lista de trades não pode estar vazia" });
        }

        if (trades.Count > 100_000)
        {
            _logger.LogWarning("Requisição de análise excede limite de 100.000 trades: {Count}", trades.Count);
            return BadRequest(new { error = "Máximo de 100.000 trades por requisição" });
        }

        _logger.LogInformation("Recebida requisição para analisar {Count} trades", trades.Count);

        try
        {
            var domainTrades = trades.Select(MapToDomain);
            var (categories, summary, processingTimeMs) = await _analysisService.AnalyzeTradesAsync(domainTrades, cancellationToken);

            var response = new RiskAnalysisResponseDto
            {
                Categories = categories.Select(c => c.ToString()).ToList(),
                Summary = summary.ToDictionary(
                    kvp => kvp.Key.ToString(),
                    kvp => new RiskCategoryDto
                    {
                        Count = kvp.Value.Count,
                        TotalValue = kvp.Value.TotalValue,
                        TopClient = kvp.Value.TopClient
                    }
                ),
                ProcessingTimeMs = processingTimeMs,
                TotalTrades = trades.Count
            };

            _logger.LogInformation(
                "Análise concluída em {ElapsedMs}ms para {Count} trades",
                processingTimeMs,
                trades.Count
            );

            return Ok(response);
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Operação de análise cancelada pelo cliente");
            return StatusCode(499, new { error = "Operação cancelada" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao analisar trades");
            return StatusCode(500, new { error = "Erro interno ao processar requisição" });
        }
    }

    /// <summary>
    /// Health check endpoint
    /// </summary>
    [HttpGet("health")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public IActionResult Health()
    {
        return Ok(new
        {
            status = "healthy",
            timestamp = DateTime.UtcNow,
            version = "2.0.0"
        });
    }

    private static Trade MapToDomain(TradeRequestDto dto)
    {
        var sector = Enum.Parse<ClientSector>(dto.ClientSector, ignoreCase: true);
        return new Trade(dto.Value, sector, dto.ClientId);
    }
}