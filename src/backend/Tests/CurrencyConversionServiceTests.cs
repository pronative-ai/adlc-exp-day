using FluentAssertions;
using OuterloopLabApi.Models;
using OuterloopLabApi.Repositories;
using OuterloopLabApi.Services;
using Xunit;

namespace Tests;

public sealed class CurrencyConversionServiceTests
{
    [Fact]
    public async Task Persists_Audit_Record_And_Returns_Converted_Amount()
    {
        var provider = new FakeProviderClient(rate: 0.92m, marker: "2026-08-01");
        var repo = new InMemoryAuditRepository();
        var svc = new CurrencyConversionService(provider, repo);

        var result = await svc.ConvertAsync(new CurrencyConversionRequest
        {
            Amount = 100.00m,
            SourceCurrency = "USD",
            TargetCurrency = "EUR"
        }, CancellationToken.None);

        result.ConversionId.Should().NotBeNullOrWhiteSpace();
        result.SourceAmount.Should().Be(100.00m);
        result.SourceCurrency.Should().Be("USD");
        result.TargetCurrency.Should().Be("EUR");
        result.Rate.Should().Be(0.92m);
        result.ConvertedAmount.Should().Be(92.00m);
        result.ProviderDateOrSequenceMarker.Should().Be("2026-08-01");
        result.ExecutedAtUtc.Should().BeCloseTo(DateTimeOffset.UtcNow, precision: TimeSpan.FromSeconds(5));

        var saved = await repo.GetByIdAsync(result.ConversionId, CancellationToken.None);
        saved.Should().NotBeNull();
        saved!.ConvertedAmount.Should().Be(92.00m);
    }

    private sealed class FakeProviderClient : ICurrencyProviderClient
    {
        private readonly decimal _rate;
        private readonly string _marker;

        public FakeProviderClient(decimal rate, string marker)
        {
            _rate = rate;
            _marker = marker;
        }

        public Task<ProviderRateInfo> GetRateAsync(string fromCurrency, string toCurrency, CancellationToken cancellationToken)
            => Task.FromResult(new ProviderRateInfo(_rate, _marker));
    }

    private sealed class InMemoryAuditRepository : IAuditTrailRepository
    {
        private readonly Dictionary<string, AuditTrailRecord> _records = new();

        public Task AddAsync(AuditTrailRecord record, CancellationToken cancellationToken)
        {
            _records[record.Id] = record;
            return Task.CompletedTask;
        }

        public Task<AuditTrailRecord?> GetByIdAsync(string conversionId, CancellationToken cancellationToken)
        {
            _records.TryGetValue(conversionId, out var rec);
            return Task.FromResult<AuditTrailRecord?>(rec);
        }

        public Task DeleteAsync(string conversionId, CancellationToken cancellationToken)
        {
            _records.Remove(conversionId);
            return Task.CompletedTask;
        }
    }
}
