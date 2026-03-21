using TradeRiskApi.Domain.Enums;

namespace TradeRiskApi.Domain.Entities;

/// <summary>
/// Agregador de informações estatísticas sobre uma categoria de risco
/// </summary>
public sealed class RiskCategory
{
    public RiskLevel Level { get; }
    public int Count { get; private set; }
    public decimal TotalValue { get; private set; }
    public string? TopClient { get; private set; }

    private readonly Dictionary<string, decimal> _clientExposure = new();

    public RiskCategory(RiskLevel level)
    {
        Level = level;
        Count = 0;
        TotalValue = 0m;
    }

    public void AddTrade(Trade trade)
    {
        if (trade == null)
            throw new ArgumentNullException(nameof(trade));

        Count++;
        TotalValue += trade.Value.Value;

        if (!string.IsNullOrWhiteSpace(trade.ClientId))
        {
            if (!_clientExposure.ContainsKey(trade.ClientId))
                _clientExposure[trade.ClientId] = 0m;

            _clientExposure[trade.ClientId] += trade.Value.Value;
            UpdateTopClient();
        }
    }

    private void UpdateTopClient()
    {
        if (_clientExposure.Count == 0)
        {
            TopClient = null;
            return;
        }

        TopClient = _clientExposure
            .OrderByDescending(kvp => kvp.Value)
            .First()
            .Key;
    }

    public decimal GetClientExposure(string clientId)
    {
        return _clientExposure.TryGetValue(clientId, out var exposure) ? exposure : 0m;
    }

    public IReadOnlyDictionary<string, decimal> GetAllClientExposures()
    {
        return _clientExposure;
    }
}