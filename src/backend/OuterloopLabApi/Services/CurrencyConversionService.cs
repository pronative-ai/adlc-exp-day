using OuterloopLabApi.Models;
using OuterloopLabApi.Repositories;

namespace OuterloopLabApi.Services;

public sealed class CurrencyConversionService
{
    private readonly ICurrencyProviderClient _providerClient;
    private readonly IAuditTrailRepository _auditRepository;

    public CurrencyConversionService(ICurrencyProviderClient providerClient, IAuditTrailRepository auditRepository)
    {
        _providerClient = providerClient;
        _auditRepository = auditRepository;
    }

    public async Task<CurrencyConversionResult> ConvertAsync(CurrencyConversionRequest request, CancellationToken cancellationToken)
    {
        var from = request.SourceCurrency.Trim().ToUpperInvariant();
        var to = request.TargetCurrency.Trim().ToUpperInvariant();
        var amount = request.Amount;

        var providerRate = await _providerClient.GetRateAsync(from, to, cancellationToken);

        var convertedAmount = amount * providerRate.Rate;
        var conversionId = Guid.NewGuid().ToString();
        var executedAtUtc = DateTimeOffset.UtcNow;

        var record = new AuditTrailRecord
        {
            Id = conversionId,
            PartitionKey = conversionId,
            SourceAmount = amount,
            SourceCurrency = from,
            TargetCurrency = to,
            Rate = providerRate.Rate,
            ConvertedAmount = convertedAmount,
            ProviderDateOrSequenceMarker = providerRate.ProviderDateOrSequenceMarker,
            ExecutedAtUtc = executedAtUtc
        };

        await _auditRepository.AddAsync(record, cancellationToken);

        return new CurrencyConversionResult
        {
            ConversionId = record.Id,
            SourceAmount = record.SourceAmount,
            SourceCurrency = record.SourceCurrency,
            TargetCurrency = record.TargetCurrency,
            Rate = record.Rate,
            ConvertedAmount = record.ConvertedAmount,
            ProviderDateOrSequenceMarker = record.ProviderDateOrSequenceMarker,
            ExecutedAtUtc = record.ExecutedAtUtc
        };
    }
}
