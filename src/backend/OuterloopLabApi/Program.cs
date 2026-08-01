using Azure.Core;
using Azure.Identity;
using Microsoft.Azure.Cosmos;
using OuterloopLabApi.Repositories;
using OuterloopLabApi.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers()
    .AddJsonOptions(o =>
    {
        o.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
    });

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddProblemDetails();

builder.Services.AddSingleton(OuterloopLabApi.CosmosEnvironmentConfig.FromEnvironment());

builder.Services.AddSingleton<TokenCredential>(sp =>
{
    var cfg = sp.GetRequiredService<OuterloopLabApi.CosmosEnvironmentConfig>();
    return new DefaultAzureCredential(new DefaultAzureCredentialOptions
    {
        ManagedIdentityClientId = cfg.AzureManagedIdentityClientId
    });
});

builder.Services.AddSingleton(sp =>
{
    var cfg = sp.GetRequiredService<OuterloopLabApi.CosmosEnvironmentConfig>();
    var tokenCredential = sp.GetRequiredService<TokenCredential>();
    // Token-based auth only (no connection strings / account keys).
    return new CosmosClient(cfg.CosmosDbUri, tokenCredential);
});

builder.Services.AddSingleton<IAuditTrailRepository, AuditTrailRepository>();
builder.Services.AddHttpClient<ICurrencyProviderClient, CurrencyProviderClient>();
builder.Services.AddScoped<CurrencyConversionService>();

var app = builder.Build();

// Token-authenticated data-plane provisioning must occur before the web app starts.
await CosmosProvisioning.EnsureCosmosDatabaseAndContainerAsync(app.Services, app.Logger);

app.MapControllers();
app.Run();

internal static class CosmosProvisioning
{
    private const int ThroughputRUs = 400;

    public static async Task EnsureCosmosDatabaseAndContainerAsync(IServiceProvider services, ILogger logger)
    {
        var cfg = services.GetRequiredService<OuterloopLabApi.CosmosEnvironmentConfig>();
        var tokenCredential = services.GetRequiredService<TokenCredential>();

        // Best-effort control-plane provisioning.
        await TryProvisionViaArmAsync(cfg, tokenCredential, logger);

        var cosmosClient = services.GetRequiredService<CosmosClient>();

        // Mandatory token-authenticated data-plane create-if-not-exists.
        // If this fails, startup must fail.
        await cosmosClient.CreateDatabaseIfNotExistsAsync(cfg.CosmosDbDatabase, throughput: ThroughputRUs);

        var database = cosmosClient.GetDatabase(cfg.CosmosDbDatabase);
        await database.CreateContainerIfNotExistsAsync(
            id: cfg.CosmosDbContainer,
            partitionKeyPath: "/partitionKey",
            throughput: ThroughputRUs);

        logger.LogInformation("Cosmos DB database/container are available (database='{Database}', container='{Container}').", cfg.CosmosDbDatabase, cfg.CosmosDbContainer);
    }

    private static async Task TryProvisionViaArmAsync(OuterloopLabApi.CosmosEnvironmentConfig cfg, TokenCredential credential, ILogger logger)
    {
        try
        {
            // ARM provisioning is best-effort; failures should not block startup.
            // We use the same token-based credential (Managed Identity client id).
            var armClient = new Azure.ResourceManager.ArmClient(credential);

            // Resolve a subscription dynamically if possible.
            dynamic? subscription = null;
            try
            {
                subscription = await armClient.GetDefaultSubscriptionAsync();
            }
            catch
            {
                // If we cannot resolve subscription, we just skip ARM provisioning.
            }

            if (subscription is null)
            {
                logger.LogWarning("Skipping ARM provisioning because a default subscription could not be resolved.");
                return;
            }

            // Best-effort control-plane attempt.
            // We intentionally use dynamic so the code compiles even if the SDK surface changes.
            dynamic cosmosAccount = subscription.GetCosmosDBAccountResource(cfg.CosmosDbAccountName, cfg.CosmosDbResourceGroup);

            logger.LogInformation("ARM provisioning attempt started for Cosmos account '{Account}'.", cfg.CosmosDbAccountName);

            // Attempt SQL database/container create (best-effort). Any failure is swallowed.
            try
            {
                dynamic sqlDb = cosmosAccount.GetSqlDatabaseResource(cfg.CosmosDbDatabase);
                dynamic sqlContainer = sqlDb.GetSqlContainerResource(cfg.CosmosDbContainer);

                // Use null payloads: we only need to attempt the control-plane call.
                await sqlDb.CreateOrUpdateAsync(null!, null!);
                await sqlContainer.CreateOrUpdateAsync(null!, null!);
            }
            catch (Exception armEx)
            {
                logger.LogWarning(armEx, "ARM SQL database/container create attempt failed (best-effort). Continuing.");
            }
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "ARM provisioning attempt failed (best-effort). Continuing with data-plane provisioning.");
        }
    }
}
