import { useState } from 'react';
import { useServerFn } from '@tanstack/react-start';
import { RefreshCw, ShieldCheck, AlertTriangle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { checkSetup } from '@/lib/setup.functions';

export function SetupAdmin() {
  const run = useServerFn(checkSetup);
  const [result, setResult] = useState<Awaited<ReturnType<typeof checkSetup>> | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  async function check() {
    setBusy(true); setError(''); setResult(null);
    try { setResult(await run()); }
    catch (e) { setError(e instanceof Error ? e.message : 'Setup check unavailable.'); }
    finally { setBusy(false); }
  }
  const errors = result?.findings.filter(f => f.severity === 'error').length ?? 0;
  return <section className="mt-8 min-w-0">
    <div className="flex flex-wrap items-center justify-between gap-4 border-b border-border pb-5">
      <h2 className="flex items-center gap-2 text-2xl font-black uppercase"><ShieldCheck size={24} /> Setup check <span className="text-xs font-medium text-muted-foreground">Read only</span></h2>
      <Button onClick={() => void check()} disabled={busy}><RefreshCw size={16} className={busy ? 'animate-spin' : ''} />{busy ? 'Checking…' : 'Run setup check'}</Button>
    </div>
    {error && <p role="alert" className="mt-5 text-destructive">{error}</p>}
    {result && <div className="mt-6">
      <p role="status" className="font-semibold">{errors ? `${errors} mismatches found` : 'No mismatches in the application baseline'} · {result.findings.length - errors} warnings</p>
      <p className="mt-2 text-sm text-muted-foreground">{result.tableCount} database tables · {result.expectedCount} expected tables · {new Date(result.checkedAt).toLocaleString()}</p>
      <p className="mt-2 text-sm text-muted-foreground">Scope: columns, types, nullability, row security, required function names and private storage. Defaults, indexes, constraints, function bodies and policy rules are not compared.</p>
      <div className="mt-5 overflow-x-auto"><table className="w-full text-left text-sm"><thead className="border-b border-border"><tr>{['Status','Object','Expected','Database / finding'].map(h => <th key={h} className="px-3 py-3 font-semibold">{h}</th>)}</tr></thead><tbody>{result.findings.map((f,i) => <tr key={`${f.object}-${i}`} className="border-b border-border"><td className="px-3 py-4 align-top"><span className={f.severity === 'error' ? 'text-destructive' : 'text-muted-foreground'}><AlertTriangle size={14} className="mr-1 inline" />{f.severity}</span></td><td className="break-words px-3 py-4 align-top font-mono">{f.object}</td><td className="px-3 py-4 align-top">{f.expected}</td><td className="min-w-48 px-3 py-4 align-top">{f.actual}</td></tr>)}</tbody></table></div>
    </div>}
  </section>;
}
