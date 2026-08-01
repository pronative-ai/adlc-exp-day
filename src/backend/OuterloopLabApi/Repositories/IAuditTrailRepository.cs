using OuterloopLabApi.Models;

namespace OuterloopLabApi.Repositories;

public interface IAuditTrailRepository
{
    Task AddAsync(AuditTrailRecord record, CancellationToken cancellationToken);
    Task<AuditTrailRecord?> GetByIdAsync(string conversionId, CancellationToken cancellationToken);
    Task DeleteAsync(string conversionId, CancellationToken cancellationToken);
}
