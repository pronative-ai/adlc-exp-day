namespace OuterloopLabApi;

public sealed record CosmosEnvironmentConfig(
    string CosmosDbUri,
    string CosmosDbDatabase,
    string CosmosDbContainer,
    string CosmosDbAccountName,
    string CosmosDbResourceGroup,
    string CosmosDbRegion,
    string AzureManagedIdentityClientId)
{
    public static CosmosEnvironmentConfig FromEnvironment()
    {
        string GetRequired(string key)
        {
            var value = Environment.GetEnvironmentVariable(key);
            if (string.IsNullOrWhiteSpace(value))
            {
                throw new InvalidOperationException($"Missing required environment variable '{key}'.");
            }
            return value;
        }

        return new CosmosEnvironmentConfig(
            CosmosDbUri: GetRequired("COSMOS_DB_URI"),
            CosmosDbDatabase: GetRequired("COSMOS_DB_DATABASE"),
            CosmosDbContainer: GetRequired("COSMOS_DB_CONTAINER"),
            CosmosDbAccountName: GetRequired("COSMOS_DB_ACCOUNT_NAME"),
            CosmosDbResourceGroup: GetRequired("COSMOS_DB_RESOURCE_GROUP"),
            CosmosDbRegion: GetRequired("COSMOS_DB_REGION"),
            AzureManagedIdentityClientId: GetRequired("AZURE_MANAGED_IDENTITY_CLIENT_ID")
        );
    }
}
