namespace TradeRiskApi.Domain.Enums;

/// <summary>
/// Níveis de risco de uma operação financeira (trade)
/// </summary>
public enum RiskLevel
{
    /// <summary>
    /// Baixo risco - Operações com valor menor que 1.000.000
    /// </summary>
    LOWRISK = 1,

    /// <summary>
    /// Médio risco - Operações com valor >= 1.000.000 e cliente do setor Público
    /// </summary>
    MEDIUMRISK = 2,

    /// <summary>
    /// Alto risco - Operações com valor >= 1.000.000 e cliente do setor Privado
    /// </summary>
    HIGHRISK = 3
}