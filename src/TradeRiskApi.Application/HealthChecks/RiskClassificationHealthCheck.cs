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
