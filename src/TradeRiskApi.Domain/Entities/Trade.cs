using TradeRiskApi.Domain.Enums;
using TradeRiskApi.Domain.ValueObjects;

namespace TradeRiskApi.Domain.Entities;

/// <summary>
/// Representa uma operação financeira (trade) no mercado
/// Entidade rica com comportamento de classificação de risco
/// </summary>
public sealed class Trade
{
    public Money Value { get; }
    public ClientSector ClientSector { get; }
    public string? ClientId { get; }

    public Trade(decimal value, ClientSector clientSector, string? clientId = null)
    {
        Value = new Money(value);
        ClientSector = clientSector;
        ClientId = clientId;
    }

    /// <summary>
    /// Classifica o risco da trade baseado nas regras de negócio
    /// </summary>
    public RiskLevel ClassifyRisk()
    {
        if (!Value.IsAboveThreshold())
            return RiskLevel.LOWRISK;

        return ClientSector == ClientSector.Public
            ? RiskLevel.MEDIUMRISK
            : RiskLevel.HIGHRISK;
    }

    public override string ToString()
        => $"Trade(Value={Value}, Sector={ClientSector}, ClientId={ClientId ?? "N/A"})";
}