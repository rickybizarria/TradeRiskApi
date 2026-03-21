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
        _logger.LogInformation("Iniciando anÃ¡lise de {Count} trades", tradeList.Count);

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
            "AnÃ¡lise concluÃ­da em {ElapsedMs}ms. LOWRISK={Low}, MEDIUMRISK={Medium}, HIGHRISK={High}",
            stopwatch.ElapsedMilliseconds,
            summary[RiskLevel.LOWRISK].Count,
            summary[RiskLevel.MEDIUMRISK].Count,
            summary[RiskLevel.HIGHRISK].Count
        );

        return (categories, summary, stopwatch.ElapsedMilliseconds);
    }
}
