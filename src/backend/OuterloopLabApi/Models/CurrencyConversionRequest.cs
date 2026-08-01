using System.ComponentModel.DataAnnotations;

namespace OuterloopLabApi.Models;

public sealed class CurrencyConversionRequest
{
    [Range(typeof(decimal), "0.0000000001", "79228162514264337593543950335")]
    public decimal Amount { get; set; }

    [Required]
    [StringLength(3, MinimumLength = 3)]
    public string SourceCurrency { get; set; } = string.Empty;

    [Required]
    [StringLength(3, MinimumLength = 3)]
    public string TargetCurrency { get; set; } = string.Empty;
}
