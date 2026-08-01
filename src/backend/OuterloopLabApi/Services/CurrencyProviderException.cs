namespace OuterloopLabApi.Services;

public sealed class CurrencyProviderException : Exception
{
    public CurrencyProviderException(string message, Exception? inner = null) : base(message, inner)
    {
    }
}
