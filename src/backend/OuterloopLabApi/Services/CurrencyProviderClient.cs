using System.Globalization;
using System.Text.Json;
using OuterloopLabApi.Services;

namespace OuterloopLabApi.Services;

public sealed class CurrencyProviderClient : ICurrencyProviderClient
{
    private readonly HttpClient _httpClient;
    private readonly string _baseUrl;

    public CurrencyProviderClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
        _baseUrl = (Environment.GetEnvironmentVariable("CURRENCY_API_BASE_URL") ?? "https://frankfurter.dev").TrimEnd('/');
    }

    public async Task<ProviderRateInfo> GetRateAsync(string fromCurrency, string toCurrency, CancellationToken cancellationToken)
    {
        try
        {
            var url = $"{_baseUrl}/v2/rate/{fromCurrency}/{toCurrency}";
            using var resp = await _httpClient.GetAsync(url, cancellationToken);
            if (!resp.IsSuccessStatusCode)
            {
                throw new CurrencyProviderException($"Upstream rate provider returned status {(int)resp.StatusCode}.");
            }

            await using var stream = await resp.Content.ReadAsStreamAsync(cancellationToken);
            using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);

            var root = doc.RootElement;

            var rate = TryGetDecimal(root, new[] { "rate", "conversion_rate" }, toCurrency)
                       ?? TryGetRateFromRatesMap(root, toCurrency)
                       ?? throw new CurrencyProviderException("Upstream response did not contain a usable rate.");

            var marker = TryGetString(root, new[] { "date", "effective_date", "provider_date", "sequence" })
                          ?? string.Empty;

            return new ProviderRateInfo(rate, marker);
        }
        catch (CurrencyProviderException)
        {
            throw;
        }
        catch (JsonException jx)
        {
            throw new CurrencyProviderException("Failed to parse upstream rate provider response.", jx);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex) when (ex is HttpRequestException || ex is TaskCanceledException)
        {
            throw new CurrencyProviderException("Failed to reach upstream rate provider.", ex);
        }
    }

    private static decimal? TryGetDecimal(JsonElement root, IEnumerable<string> candidateNames, string expectedCurrencyKey)
    {
        foreach (var name in candidateNames)
        {
            if (root.TryGetProperty(name, out var prop))
            {
                var parsed = TryParseDecimal(prop);
                if (parsed is not null) return parsed;
            }
        }

        return null;
    }

    private static decimal? TryGetRateFromRatesMap(JsonElement root, string targetCurrency)
    {
        string[] mapNames = ["rates", "conversion_rates"];
        foreach (var mapName in mapNames)
        {
            if (!root.TryGetProperty(mapName, out var map) || map.ValueKind != JsonValueKind.Object)
            {
                continue;
            }

            if (map.TryGetProperty(targetCurrency, out var v))
            {
                return TryParseDecimal(v);
            }
        }
        return null;
    }

    private static string? TryGetString(JsonElement root, IEnumerable<string> candidateNames)
    {
        foreach (var name in candidateNames)
        {
            if (root.TryGetProperty(name, out var prop) && prop.ValueKind == JsonValueKind.String)
            {
                return prop.GetString();
            }
        }

        return null;
    }

    private static decimal? TryParseDecimal(JsonElement element)
    {
        try
        {
            return element.ValueKind switch
            {
                JsonValueKind.Number => element.GetDecimal(),
                JsonValueKind.String => decimal.TryParse(element.GetString(), NumberStyles.Number, CultureInfo.InvariantCulture, out var d) ? d : null,
                _ => null
            };
        }
        catch
        {
            return null;
        }
    }
}
