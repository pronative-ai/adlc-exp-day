export type ConversionResponse = {
  conversionId: string
  sourceAmount: number
  sourceCurrency: string
  targetCurrency: string
  rate: number
  convertedAmount: number
  providerDateOrSequenceMarker: string
  executedAtUtc: string
}

export type CreateConversionRequest = {
  amount: number
  fromCurrency: string
  toCurrency: string
}

function getApiBaseUrl(): string {
  // Runtime substitution happens in /usr/share/nginx/html/index.html (see entrypoint.sh).
  const anyWindow = window as any
  const tokenValue = anyWindow.__VITE_API_URL__
  if (typeof tokenValue === 'string') return tokenValue
  return ''
}

export async function createConversion(req: CreateConversionRequest): Promise<ConversionResponse> {
  const apiBase = getApiBaseUrl()
  const res = await fetch(`${apiBase}/api/conversions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      amount: req.amount,
      sourceCurrency: req.fromCurrency,
      targetCurrency: req.toCurrency
    })
  })
  if (!res.ok) {
    const body = await safeJson(res)
    const message = body?.title || body?.detail || `Request failed (${res.status})`
    throw new Error(message)
  }
  return (await res.json()) as ConversionResponse
}

export async function getAuditTrail(conversionId: string): Promise<ConversionResponse> {
  const apiBase = getApiBaseUrl()
  const res = await fetch(`${apiBase}/api/audits/${encodeURIComponent(conversionId)}`)
  if (!res.ok) {
    const body = await safeJson(res)
    const message = body?.title || body?.detail || `Request failed (${res.status})`
    throw new Error(message)
  }
  return (await res.json()) as ConversionResponse
}

async function safeJson(res: Response): Promise<any> {
  try {
    return await res.json()
  } catch {
    return null
  }
}
