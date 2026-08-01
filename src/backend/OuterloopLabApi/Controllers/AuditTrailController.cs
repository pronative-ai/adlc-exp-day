using Microsoft.AspNetCore.Mvc;
using OuterloopLabApi.Models;
using OuterloopLabApi.Repositories;

namespace OuterloopLabApi.Controllers;

[ApiController]
[Route("api")]
public sealed class AuditTrailController : ControllerBase
{
    private readonly IAuditTrailRepository _repository;

    public AuditTrailController(IAuditTrailRepository repository)
    {
        _repository = repository;
    }

    [HttpGet("audits/{conversionId}")]
    [ProducesResponseType(typeof(CurrencyConversionResult), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetAudit([FromRoute] string conversionId, CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(conversionId, out _))
        {
            return Problem(detail: "conversionId must be a GUID.", statusCode: StatusCodes.Status400BadRequest);
        }

        var record = await _repository.GetByIdAsync(conversionId, cancellationToken);
        if (record is null)
        {
            return Problem(title: "Audit record not found", statusCode: StatusCodes.Status404NotFound);
        }

        return Ok(new CurrencyConversionResult
        {
            ConversionId = record.Id,
            SourceAmount = record.SourceAmount,
            SourceCurrency = record.SourceCurrency,
            TargetCurrency = record.TargetCurrency,
            Rate = record.Rate,
            ConvertedAmount = record.ConvertedAmount,
            ProviderDateOrSequenceMarker = record.ProviderDateOrSequenceMarker,
            ExecutedAtUtc = record.ExecutedAtUtc
        });
    }

    [HttpDelete("audits/{conversionId}")]
    public async Task<IActionResult> DeleteAudit([FromRoute] string conversionId, CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(conversionId, out _))
        {
            return Problem(detail: "conversionId must be a GUID.", statusCode: StatusCodes.Status400BadRequest);
        }

        await _repository.DeleteAsync(conversionId, cancellationToken);
        return NoContent();
    }
}
