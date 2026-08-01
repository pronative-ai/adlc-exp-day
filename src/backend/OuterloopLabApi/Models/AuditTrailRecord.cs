namespace OuterloopLabApi.Models;

public sealed class AuditTrailRecord
{
    // Cosmos item id.
    public string Id { get; set; } = string.Empty;

    // Cosmos partition key.
    public string PartitionKey { get; set; } = string.Empty;

    public decimal SourceAmount { get; set; }
    public string SourceCurrency { get; set; } = string.Empty;
    public string TargetCurrency { get; set; } = string.Empty;

    public decimal Rate { get; set; }
    public decimal ConvertedAmount { get; set; }

    public string ProviderDateOrSequenceMarker { get; set; } = string.Empty;

    // Must be exact server-side timestamp.
    public DateTimeOffset ExecutedAtUtc { get; set; }
}
