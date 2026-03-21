namespace TradeRiskApi.Application.DTOs;

public sealed class RiskCategoryDto
{
    public int Count { get; set; }
    public decimal TotalValue { get; set; }
    public string? TopClient { get; set; }
}

public sealed class RiskAnalysisResponseDto
{
    public List<string> Categories { get; set; } = new();
    public Dictionary<string, RiskCategoryDto> Summary { get; set; } = new();
    public long ProcessingTimeMs { get; set; }
    public int TotalTrades { get; set; }
}