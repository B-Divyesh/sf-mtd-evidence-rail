const base = 'https://mtd-evidence-rail.sociobot.in';
const headersFor = key => ({ 'content-type': 'application/json', 'x-workspace-key': key, 'x-forwarded-for': '198.18.41.8' });
const output = { base, generated_at: new Date().toISOString(), cases: [] };

async function untilOwned(path, options, accepted, max = 9) {
  const attempts = [];
  for (let i = 0; i < max; i++) {
    const response = await fetch(base + path, options);
    const bytes = new Uint8Array(await response.arrayBuffer());
    const text = new TextDecoder().decode(bytes);
    attempts.push({ status: response.status, text: text.slice(0, 300) });
    if (accepted.includes(response.status)) return { response, bytes, text, attempts };
  }
  return { response: null, bytes: new Uint8Array(), text: '', attempts };
}

const created = await fetch(base + '/api/workspace', { method: 'POST', headers: { 'x-forwarded-for': '198.18.41.8' } });
const creation = await created.json();
const key = creation.workspace_id;
output.create = { status: created.status, keyLength: key?.length };

const validCases = [
  ['minimum-boundary', { kind: 'expense', record_date: '2026-04-05', description: 'Quarter boundary penny', amount_pence: 1, category: 'Office', source: 'manual' }],
  ['maximum-amount', { kind: 'income', record_date: '2026-04-05', description: 'Maximum accepted amount', amount_pence: 100000000, category: 'Tutoring', source: 'manual' }],
];
for (const [name, data] of validCases) {
  const result = await untilOwned('/api/records', { method: 'POST', headers: headersFor(key), body: JSON.stringify(data) }, [201]);
  output.cases.push({ name, expected: 201, attempts: result.attempts });
}

const invalidCases = [
  ['zero-amount', { kind: 'expense', record_date: '2026-04-05', description: 'Zero', amount_pence: 0, category: 'Office' }],
  ['negative-amount', { kind: 'expense', record_date: '2026-04-05', description: 'Negative', amount_pence: -1, category: 'Office' }],
  ['over-maximum', { kind: 'expense', record_date: '2026-04-05', description: 'Too large', amount_pence: 100000001, category: 'Office' }],
  ['impossible-date', { kind: 'expense', record_date: '2026-99-99', description: 'Bad date', amount_pence: 1, category: 'Office' }],
  ['unknown-kind', { kind: 'gift', record_date: '2026-04-05', description: 'Bad kind', amount_pence: 1, category: 'Office' }],
  ['long-description', { kind: 'expense', record_date: '2026-04-05', description: 'x'.repeat(121), amount_pence: 1, category: 'Office' }],
  ['long-category', { kind: 'expense', record_date: '2026-04-05', description: 'Bad category', amount_pence: 1, category: 'x'.repeat(41) }],
];
for (const [name, data] of invalidCases) {
  const result = await untilOwned('/api/records', { method: 'POST', headers: headersFor(key), body: JSON.stringify(data) }, [400]);
  output.cases.push({ name, expected: 400, attempts: result.attempts });
}

const workspace = await untilOwned('/api/workspace?from=2026-01-06&to=2026-04-05', { headers: headersFor(key) }, [200]);
const body = JSON.parse(workspace.text);
const recordId = body.records[0].id;
output.workspaceBeforeFiles = { attempts: workspace.attempts, total: body.summary.total };

const unsupported = await untilOwned(`/api/records/${recordId}/evidence`, { method: 'POST', headers: headersFor(key), body: JSON.stringify({ name: 'unsafe.exe', mime: 'application/octet-stream', data_base64: 'bm8=' }) }, [415]);
output.cases.push({ name: 'unsupported-evidence', expected: 415, attempts: unsupported.attempts });
const linked = await untilOwned(`/api/records/${recordId}/evidence`, { method: 'POST', headers: headersFor(key), body: JSON.stringify({ name: 'receipt.txt', mime: 'text/plain', data_base64: 'cmVjZWlwdA==' }) }, [200]);
output.cases.push({ name: 'supported-evidence-recovery', expected: 200, attempts: linked.attempts });

const exported = await untilOwned('/api/export?from=2026-01-06&to=2026-04-05', { headers: headersFor(key) }, [200]);
output.export = { attempts: exported.attempts, signature: new TextDecoder().decode(exported.bytes.slice(0, 2)), contentType: exported.response?.headers.get('content-type') };

const writes = await Promise.all(Array.from({ length: 20 }, (_, i) => fetch(base + '/api/records', {
  method: 'POST', headers: headersFor(key), body: JSON.stringify({ kind: 'expense', record_date: '2026-03-01', description: `Concurrent ${i + 1}`, amount_pence: 100 + i, category: 'Office', source: 'manual' }),
}).then(r => r.status)));
output.concurrentWrites = { requested: 20, counts: Object.fromEntries([...new Set(writes)].sort().map(status => [status, writes.filter(x => x === status).length])), statuses: writes };

const finalWorkspace = await untilOwned('/api/workspace?from=2026-01-06&to=2026-04-05', { headers: headersFor(key) }, [200]);
output.workspaceAfterConcurrency = { attempts: finalWorkspace.attempts, total: JSON.parse(finalWorkspace.text).summary.total };
const deleted = await untilOwned('/api/workspace', { method: 'DELETE', headers: { ...headersFor(key), 'x-confirm-delete': 'delete' } }, [204]);
output.delete = { attempts: deleted.attempts };
output.readAfterDelete = [];
for (let i = 0; i < 6; i++) output.readAfterDelete.push((await fetch(base + '/api/workspace', { headers: headersFor(key) })).status);

console.log(JSON.stringify(output, null, 2));
