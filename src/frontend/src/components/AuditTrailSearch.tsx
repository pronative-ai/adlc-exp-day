import { useEffect, useState, type FormEvent } from 'react'
import { getAuditTrail, type ConversionResponse } from '../api/currencyApi'

export default function AuditTrailSearch({ initialConversionId }: { initialConversionId: string | null }) {
  const [conversionId, setConversionId] = useState<string>(initialConversionId ?? '')
  const [result, setResult] = useState<ConversionResponse | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    if (!initialConversionId) return
    setConversionId(initialConversionId)
  }, [initialConversionId])

  async function onSearch(e: FormEvent) {
    e.preventDefault()
    setError(null)
    setBusy(true)
    try {
      const res = await getAuditTrail(conversionId)
      setResult(res)
    } catch (err) {
      if (err instanceof Error) setError(err.message)
      else setError('Audit lookup failed')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div style={{ padding: 14, borderRadius: 12, border: '1px solid #e5e7eb' }}>
      <h2 style={{ fontSize: 16, marginTop: 0, marginBottom: 10 }}>Audit Trail Lookup</h2>

      <form onSubmit={onSearch} style={{ display: 'flex', gap: 10, alignItems: 'center', flexWrap: 'wrap' }}>
        <label style={{ display: 'grid', gap: 6, flex: '1 1 420px' }}>
          <span style={{ fontSize: 12, color: '#6b7280' }}>Conversion / Audit ID</span>
          <input
            value={conversionId}
            onChange={(e) => setConversionId(e.target.value)}
            placeholder="e.g. 6f1f3d5b-..."
            style={{ padding: 10, borderRadius: 8, border: '1px solid #ccc', width: '100%' }}
          />
        </label>
        <button
          type="submit"
          disabled={busy || conversionId.trim().length === 0}
          style={{ padding: '10px 16px', borderRadius: 8, border: 'none', background: busy ? '#999' : '#0b7285', color: '#fff', cursor: busy ? 'not-allowed' : 'pointer' }}
        >
          {busy ? 'Looking up…' : 'Lookup'}
        </button>
      </form>

      {error ? (
        <div style={{ marginTop: 12, padding: 12, borderRadius: 10, background: '#ffecec', color: '#a40000' }}>{error}</div>
      ) : null}

      {result ? (
        <div style={{ marginTop: 12 }}>
          <div style={{ fontSize: 12, color: '#6b7280' }}>Found Record</div>
          <div style={{ marginTop: 8, padding: 12, borderRadius: 10, background: '#f9fafb' }}>
            <div style={{ fontFamily: 'ui-monospace, SFMono-Regular, Menlo, monospace' }}>ID: {result.conversionId}</div>
            <div>Executed At (UTC): {new Date(result.executedAtUtc).toISOString()}</div>
            <div>Provider Marker: {result.providerDateOrSequenceMarker}</div>
            <div>Pair: {result.sourceCurrency} → {result.targetCurrency}</div>
            <div>Rate: {result.rate}</div>
            <div>Converted Amount: {result.convertedAmount}</div>
          </div>
        </div>
      ) : null}
    </div>
  )
}
