using TradeRiskApi.Domain.Entities;
using TradeRiskApi.Domain.Enums;

namespace TradeRiskApi.Domain.Interfaces;

public interface IRiskClassificationService
{
    Task<IEnumerable<RiskLevel>> ClassifyTradesAsync(
        IEnumerable<Trade> trades,
        CancellationToken cancellationToken = default);

    RiskLevel ClassifyTrade(Trade trade);
}