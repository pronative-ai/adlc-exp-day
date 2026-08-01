namespace OuterloopLabApi.Models;

public sealed class CurrencyConversionResult
{
    public string ConversionId { get; set; } = string.Empty;

    public decimal SourceAmount { get; set; }
    public string SourceCurrency { get; set; } = string.Empty;

    public string TargetCurrency { get; set; } = string.Empty;

    public decimal Rate { get; set; }
    public decimal ConvertedAmount { get; set; }

    public string ProviderDateOrSequenceMarker { get; set; } = string.Empty;

    public DateTimeOffset ExecutedAtUtc { get; set; }
}
