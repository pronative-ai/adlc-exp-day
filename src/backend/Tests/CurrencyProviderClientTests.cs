using System.Net;
using System.Text;
using System.Text.Json;
using FluentAssertions;
using OuterloopLabApi.Services;
using Xunit;

namespace Tests;

public sealed class CurrencyProviderClientTests
{
    [Fact]
    public async Task Parses_Frankfurter_V2_Rate_Response()
    {
        var handler = new StubHttpMessageHandler();
        handler.WhenRequest("https://example.test/v2/rate/EUR/USD")
            .Respond(HttpStatusCode.OK, new { date = "2026-08-01", @base = "EUR", quote = "USD", rate = 1.1498 });

        var httpClient = new System.Net.Http.HttpClient(handler);
        Environment.SetEnvironmentVariable("CURRENCY_API_BASE_URL", "https://example.test");

        var client = new CurrencyProviderClient(httpClient);

        var rate = await client.GetRateAsync("EUR", "USD", CancellationToken.None);
        rate.Rate.Should().Be(1.1498m);
        rate.ProviderDateOrSequenceMarker.Should().Be("2026-08-01");
    }

    private sealed class StubHttpMessageHandler : System.Net.Http.HttpMessageHandler
    {
        private readonly Dictionary<string, (HttpStatusCode StatusCode, string Body)> _stubs = new();
        public StubHttpMessageHandler WhenRequest(string url)
        {
            _currentUrl = url;
            return this;
        }

        private string _currentUrl = string.Empty;

        public StubHttpMessageHandler Respond(HttpStatusCode statusCode, object body)
        {
            var json = JsonSerializer.Serialize(body);
            _stubs[_currentUrl] = (statusCode, json);
            return this;
        }

        protected override Task<System.Net.Http.HttpResponseMessage> SendAsync(System.Net.Http.HttpRequestMessage request, CancellationToken cancellationToken)
        {
            if (!_stubs.TryGetValue(request.RequestUri!.ToString(), out var stub))
            {
                throw new InvalidOperationException($"No stub registered for {request.RequestUri}");
            }

            var message = new System.Net.Http.HttpResponseMessage(stub.StatusCode)
            {
                Content = new StringContent(stub.Body, Encoding.UTF8, "application/json")
            };
            return Task.FromResult(message);
        }
    }
}
