using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using OuterloopLabApi.Controllers;
using OuterloopLabApi.Models;
using OuterloopLabApi.Repositories;
using OuterloopLabApi.Services;
using Xunit;

namespace Tests;

public sealed class CurrencyConversionsControllerTests
{
    [Fact]
    public async Task Returns_503_ProblemDetails_When_Provider_Fails()
    {
        var provider = new FailingProviderClient();
        var repo = new InMemoryAuditRepository();
        var svc = new CurrencyConversionService(provider, repo);
        var controller = new CurrencyConversionsController(svc);

        var result = await controller.ConvertAsync(new CurrencyConversionRequest
        {
            Amount = 10m,
            SourceCurrency = "USD",
            TargetCurrency = "EUR"
        }, CancellationToken.None);

        result.Should().BeOfType<ObjectResult>();
        var obj = (ObjectResult)result;
        obj.StatusCode.Should().Be(503);

        var problem = obj.Value.Should().BeOfType<ProblemDetails>().Subject;
        problem.Title.Should().Be("Rate provider unavailable");
        problem.Status.Should().Be(503);
    }

    private sealed class FailingProviderClient : ICurrencyProviderClient
    {
        public Task<ProviderRateInfo> GetRateAsync(string fromCurrency, string toCurrency, CancellationToken cancellationToken)
            => throw new CurrencyProviderException("boom");
    }

    private sealed class InMemoryAuditRepository : IAuditTrailRepository
    {
        public Task AddAsync(AuditTrailRecord record, CancellationToken cancellationToken) => Task.CompletedTask;
        public Task<AuditTrailRecord?> GetByIdAsync(string conversionId, CancellationToken cancellationToken) => Task.FromResult<AuditTrailRecord?>(null);
        public Task DeleteAsync(string conversionId, CancellationToken cancellationToken) => Task.CompletedTask;
    }
}
