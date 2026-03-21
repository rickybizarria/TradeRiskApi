using TradeRiskApi.Domain.Entities;
using TradeRiskApi.Domain.Enums;
using TradeRiskApi.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace TradeRiskApi.Application.Services;

public sealed class RiskClassificationService : IRiskClassificationService
{
    private readonly ILogger<RiskClassificationService> _logger;

    public RiskClassificationService(ILogger<RiskClassificationService> logger)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    public async Task<IEnumerable<RiskLevel>> ClassifyTradesAsync(
        IEnumerable<Trade> trades,
        CancellationToken cancellationToken = default)
    {
        if (trades == null)
            throw new ArgumentNullException(nameof(trades));

        var tradeList = trades.ToList();

        if (tradeList.Count == 0)
            return Enumerable.Empty<RiskLevel>();

        _logger.LogInformation("Classificando {Count} trades de forma assíncrona", tradeList.Count);

        return await Task.Run(() =>
        {
            cancellationToken.ThrowIfCancellationRequested();
            return tradeList.Select(ClassifyTrade).ToList();
        }, cancellationToken);
    }

    public RiskLevel ClassifyTrade(Trade trade)
    {
        if (trade == null)
            throw new ArgumentNullException(nameof(trade));

        var risk = trade.ClassifyRisk();

        _logger.LogDebug(
            "Trade classificada: Valor={Value}, Setor={Sector}, Risco={Risk}",
            trade.Value.Value,
            trade.ClientSector,
            risk
        );

        return risk;
    }
}