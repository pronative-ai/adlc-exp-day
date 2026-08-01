using Microsoft.Azure.Cosmos;
using OuterloopLabApi.Models;

namespace OuterloopLabApi.Repositories;

public sealed class AuditTrailRepository : IAuditTrailRepository
{
    private readonly Container _container;

    public AuditTrailRepository(CosmosClient cosmosClient, OuterloopLabApi.CosmosEnvironmentConfig cfg)
    {
        _container = cosmosClient.GetContainer(cfg.CosmosDbDatabase, cfg.CosmosDbContainer);
    }

    public async Task AddAsync(AuditTrailRecord record, CancellationToken cancellationToken)
    {
        await _container.CreateItemAsync(record, new PartitionKey(record.PartitionKey), cancellationToken: cancellationToken);
    }

    public async Task<AuditTrailRecord?> GetByIdAsync(string conversionId, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _container.ReadItemAsync<AuditTrailRecord>(conversionId, new PartitionKey(conversionId), cancellationToken: cancellationToken);
            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    public async Task DeleteAsync(string conversionId, CancellationToken cancellationToken)
    {
        await _container.DeleteItemAsync<AuditTrailRecord>(conversionId, new PartitionKey(conversionId), cancellationToken: cancellationToken);
    }
}
