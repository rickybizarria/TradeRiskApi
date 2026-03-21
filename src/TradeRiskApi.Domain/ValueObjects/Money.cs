namespace TradeRiskApi.Domain.ValueObjects;

/// <summary>
/// Value Object que representa um valor monetário
/// Garante imutabilidade e validação de regras de negócio
/// </summary>
public sealed class Money : IEquatable<Money>, IComparable<Money>
{
    private const decimal HIGH_RISK_THRESHOLD = 1_000_000m;

    public decimal Value { get; }

    public Money(decimal value)
    {
        if (value < 0)
            throw new ArgumentException("Valor monetário não pode ser negativo", nameof(value));

        Value = value;
    }

    public bool IsAboveThreshold() => Value >= HIGH_RISK_THRESHOLD;

    public static decimal GetThreshold() => HIGH_RISK_THRESHOLD;

    public bool Equals(Money? other)
    {
        if (other is null) return false;
        if (ReferenceEquals(this, other)) return true;
        return Value == other.Value;
    }

    public override bool Equals(object? obj) => Equals(obj as Money);

    public override int GetHashCode() => Value.GetHashCode();

    public int CompareTo(Money? other)
    {
        if (other is null) return 1;
        return Value.CompareTo(other.Value);
    }

    public static bool operator ==(Money? left, Money? right)
        => left?.Equals(right) ?? right is null;

    public static bool operator !=(Money? left, Money? right)
        => !(left == right);

    public static bool operator >(Money? left, Money? right)
        => left?.CompareTo(right) > 0;

    public static bool operator <(Money? left, Money? right)
        => left?.CompareTo(right) < 0;

    public static bool operator >=(Money? left, Money? right)
        => left?.CompareTo(right) >= 0;

    public static bool operator <=(Money? left, Money? right)
        => left?.CompareTo(right) <= 0;

    public override string ToString()
        => Value.ToString("C2", System.Globalization.CultureInfo.GetCultureInfo("en-US"));
}