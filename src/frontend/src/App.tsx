import { useState, type FormEvent } from 'react'
import { createConversion, type ConversionResponse } from './api/currencyApi'
import AuditTrailSearch from './components/AuditTrailSearch'

export default function App() {
  const [amount, setAmount] = useState<string>('100.00')
  const [fromCurrency, setFromCurrency] = useState<string>('USD')
  const [toCurrency, setToCurrency] = useState<string>('EUR')

  const [result, setResult] = useState<ConversionResponse | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    setBusy(true)
    try {
      const res = await createConversion({
        amount: Number(amount),
        fromCurrency,
        toCurrency
      })
      setResult(res)
    } catch (err) {
      if (err instanceof Error) setError(err.message)
      else setError('Conversion failed')
    } finally {
      setBusy(false)
    }
  }

  const lastConversionId = result?.conversionId ?? null

  return (
    <div style={{ maxWidth: 880, margin: '0 auto', padding: 16, fontFamily: 'system-ui, -apple-system, Segoe UI, Roboto, sans-serif' }}>
      <h1 style={{ marginTop: 8, marginBottom: 16 }}>Real-Time Currency Conversion</h1>

      <form onSubmit={onSubmit} style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr auto', gap: 10, alignItems: 'end' }}>
        <label style={{ display: 'grid', gap: 6 }}>
          <span>Amount</span>
          <input
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            inputMode="decimal"
            style={{ padding: 10, borderRadius: 8, border: '1px solid #ccc' }}
          />
        </label>
        <label style={{ display: 'grid', gap: 6 }}>
          <span>From</span>
          <input
            value={fromCurrency}
            onChange={(e) => setFromCurrency(e.target.value.toUpperCase())}
            maxLength={3}
            style={{ padding: 10, borderRadius: 8, border: '1px solid #ccc' }}
          />
        </label>
        <label style={{ display: 'grid', gap: 6 }}>
          <span>To</span>
          <input
            value={toCurrency}
            onChange={(e) => setToCurrency(e.target.value.toUpperCase())}
            maxLength={3}
            style={{ padding: 10, borderRadius: 8, border: '1px solid #ccc' }}
          />
        </label>
        <button
          type="submit"
          disabled={busy}
          style={{ padding: '10px 16px', borderRadius: 8, border: 'none', background: busy ? '#999' : '#1f6feb', color: '#fff', cursor: busy ? 'not-allowed' : 'pointer' }}
        >
          {busy ? 'Converting…' : 'Convert'}
        </button>
      </form>

      {error ? (
        <div style={{ marginTop: 12, padding: 12, borderRadius: 10, background: '#ffecec', color: '#a40000' }}>{error}</div>
      ) : null}

      {result ? (
        <div style={{ marginTop: 16, padding: 14, borderRadius: 12, border: '1px solid #e5e7eb' }}>
          <h2 style={{ fontSize: 16, marginTop: 0, marginBottom: 10 }}>Conversion Result</h2>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div>
              <div style={{ fontSize: 12, color: '#6b7280' }}>Audit ID</div>
              <div style={{ fontFamily: 'ui-monospace, SFMono-Regular, Menlo, monospace' }}>{result.conversionId}</div>
            </div>
            <div>
              <div style={{ fontSize: 12, color: '#6b7280' }}>Executed At (UTC)</div>
              <div style={{ fontFamily: 'ui-monospace, SFMono-Regular, Menlo, monospace' }}>{new Date(result.executedAtUtc).toISOString()}</div>
            </div>
            <div>
              <div style={{ fontSize: 12, color: '#6b7280' }}>Provider Marker</div>
              <div style={{ fontFamily: 'ui-monospace, SFMono-Regular, Menlo, monospace' }}>{result.providerDateOrSequenceMarker}</div>
            </div>
            <div>
              <div style={{ fontSize: 12, color: '#6b7280' }}>Rate</div>
              <div style={{ fontFamily: 'ui-monospace, SFMono-Regular, Menlo, monospace' }}>{result.rate}</div>
            </div>
            <div>
              <div style={{ fontSize: 12, color: '#6b7280' }}>Converted Amount</div>
              <div style={{ fontFamily: 'ui-monospace, SFMono-Regular, Menlo, monospace', fontSize: 18 }}>{result.convertedAmount}</div>
            </div>
            <div>
              <div style={{ fontSize: 12, color: '#6b7280' }}>Pair</div>
              <div style={{ fontFamily: 'ui-monospace, SFMono-Regular, Menlo, monospace' }}>{result.sourceCurrency} → {result.targetCurrency}</div>
            </div>
          </div>
        </div>
      ) : null}

      <div style={{ marginTop: 24 }}>
        <AuditTrailSearch initialConversionId={lastConversionId} />
      </div>
    </div>
  )
}
