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
            .WithMessage("O setor do cliente Ã© obrigatÃ³rio")
            .Must(sector => sector == "Public" || sector == "Private")
            .WithMessage("Setor deve ser Public ou Private");

        RuleFor(x => x.ClientId)
            .MaximumLength(50)
            .When(x => !string.IsNullOrEmpty(x.ClientId))
            .WithMessage("ClientId nao pode exceder 50 caracteres");
    }
}
