using Microsoft.AspNetCore.Mvc;
using OuterloopLabApi.Models;
using OuterloopLabApi.Services;

namespace OuterloopLabApi.Controllers;

[ApiController]
[Route("api")]
public sealed class CurrencyConversionsController : ControllerBase
{
    private readonly CurrencyConversionService _service;

    public CurrencyConversionsController(CurrencyConversionService service)
    {
        _service = service;
    }

    [HttpPost("conversions")]
    [ProducesResponseType(typeof(CurrencyConversionResult), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status503ServiceUnavailable)]
    public async Task<IActionResult> ConvertAsync([FromBody] CurrencyConversionRequest request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        var from = request.SourceCurrency.Trim().ToUpperInvariant();
        var to = request.TargetCurrency.Trim().ToUpperInvariant();

        if (!IsIsoCurrency(from) || !IsIsoCurrency(to))
        {
            return Problem(detail: "sourceCurrency and targetCurrency must be three-letter ISO codes.", statusCode: StatusCodes.Status400BadRequest);
        }

        if (request.Amount <= 0)
        {
            return Problem(detail: "amount must be a positive number.", statusCode: StatusCodes.Status400BadRequest);
        }

        try
        {
            var result = await _service.ConvertAsync(new CurrencyConversionRequest
            {
                Amount = request.Amount,
                SourceCurrency = from,
                TargetCurrency = to
            }, cancellationToken);

            return Ok(result);
        }
        catch (CurrencyProviderException ex)
        {
            return Problem(
                title: "Rate provider unavailable",
                statusCode: StatusCodes.Status503ServiceUnavailable,
                detail: ex.Message);
        }
    }

    private static bool IsIsoCurrency(string code)
    {
        if (code.Length != 3) return false;
        for (var i = 0; i < 3; i++)
        {
            var c = code[i];
            if (c < 'A' || c > 'Z') return false;
        }
        return true;
    }
}
