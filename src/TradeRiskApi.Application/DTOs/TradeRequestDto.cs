using System.ComponentModel.DataAnnotations;

namespace TradeRiskApi.Application.DTOs;

public sealed class TradeRequestDto
{
    [Required(ErrorMessage = "O valor da trade é obrigatório")]
    [Range(0, double.MaxValue, ErrorMessage = "O valor deve ser maior ou igual a zero")]
    public decimal Value { get; set; }

    [Required(ErrorMessage = "O setor do cliente é obrigatório")]
    [RegularExpression("^(Public|Private)$", ErrorMessage = "Setor deve ser 'Public' ou 'Private'")]
    public string ClientSector { get; set; } = string.Empty;

    public string? ClientId { get; set; }
}