namespace OuterloopLabApi.Services;

public interface ICurrencyProviderClient
{
    Task<ProviderRateInfo> GetRateAsync(string fromCurrency, string toCurrency, CancellationToken cancellationToken);
}
