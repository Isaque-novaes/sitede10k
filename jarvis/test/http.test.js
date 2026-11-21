import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { requisitarJson, requisitarBinario, ErroExterno, criarRegistroLocal } from '../src/externo/http.js';
import { baixarArquivo } from '../src/externo/baixar.js';
import { criarServicos } from '../src/externo/servicos.js';
import { criarFetchFalso } from './falsos.js';

let tmp;
beforeEach(async () => { tmp = await mkdtemp(join(tmpdir(), 'jarvis-http-')); });
afterEach(async () => { await rm(tmp, { recursive: true, force: true }); });

test('requisitarJson devolve o JSON e manda os cabeçalhos', async () => {
  const f = criarFetchFalso([{ contem: '/ok', json: { a: 1 } }]);
  assert.deepEqual(await requisitarJson('https://x/ok', { servico: 'Teste', cabecalhos: { 'X-K': '1' }, fetch: f }), { a: 1 });
  assert.equal(f.chamadas[0].cabecalhos['X-K'], '1');
});

test('POST manda o corpo como JSON', async () => {
  const f = criarFetchFalso([{ metodo: 'POST', contem: '/p', json: {} }]);
  await requisitarJson('https://x/p', { servico: 'Teste', metodo: 'POST', corpo: { a: 1 }, fetch: f });
  assert.equal(f.chamadas[0].corpo, '{"a":1}');
  assert.equal(f.chamadas[0].cabecalhos['Content-Type'], 'application/json');
});

test('5xx repete e depois funciona', async () => {
  let n = 0; const f = async () => (++n < 2 ? new Response('x', { status: 503 }) : Response.json({ ok: true }));
  assert.deepEqual(await requisitarJson('https://x/y', { servico: 'Teste', fetch: f }), { ok: true });
});

test('falha de rede repete e depois vira erro em português', async () => {
  let n = 0; const f = async () => { n++; throw new TypeError('fetch failed'); };
  await assert.rejects(requisitarJson('https://x/y', { servico: 'Teste', fetch: f }), (e) => e instanceof ErroExterno && e.temporario && /Teste/.test(e.message));
  assert.equal(n, 3);
});

test('chave recusada vira erro em português sem a chave', async () => {
  const f = criarFetchFalso([{ contem: 'key=SEGREDO', status: 403, json: { error: { message: 'API key not valid' } } }]);
  await assert.rejects(requisitarJson('https://x/y?key=SEGREDO', { servico: 'Google Maps', fetch: f }), (e) =>
    e instanceof ErroExterno && e.message.includes('Google Maps') && !e.message.includes('SEGREDO') && e.status === 403);
});

test('4xx não repete', async () => {
  const f = criarFetchFalso([{ contem: '/', status: 400, json: { error: { code: 110 } } }]);
  await assert.rejects(requisitarJson('https://x/', { servico: 'Instagram', fetch: f }), (e) => e.status === 400 && e.corpo?.error?.code === 110);
  assert.equal(f.chamadas.length, 1);
});

test('429 é temporário', async () => {
  const f = criarFetchFalso([{ contem: '/', status: 429, json: {} }]);
  await assert.rejects(requisitarJson('https://x/', { servico: 'Gemini', fetch: f }), (e) => e.temporario === true);
});

test('requisitarBinario devolve os bytes', async () => {
  const f = criarFetchFalso([{ contem: '/img', bytes: Buffer.from([7, 8]) }]);
  assert.deepEqual([...await requisitarBinario('https://x/img', { servico: 'Teste', fetch: f })], [7, 8]);
});

test('baixarArquivo grava os bytes', async () => {
  const f = criarFetchFalso([{ contem: '/img', bytes: Buffer.from([1, 2, 3]) }]);
  const destino = await baixarArquivo('https://x/img', join(tmp, 'a', 'b.jpg'), { servico: 'Teste', fetch: f });
  assert.deepEqual([...await readFile(destino)], [1, 2, 3]);
});

test('o log registra serviço e status, nunca a chave', async () => {
  const eventos = []; const f = criarFetchFalso([{ contem: '/ok', json: {} }]);
  await requisitarJson('https://x/ok?key=SEGREDO', { servico: 'Google Maps', fetch: f, registrar: (e) => eventos.push(e) });
  assert.equal(eventos[0].servico, 'Google Maps'); assert.equal(eventos[0].status, 200);
  assert.ok(!JSON.stringify(eventos).includes('SEGREDO'));
});

test('criarRegistroLocal grava uma linha JSON por evento', async () => {
  const registrar = criarRegistroLocal(tmp);
  await registrar({ servico: 'A', status: 200 }); await registrar({ servico: 'B', status: 500 });
  const linhas = (await readFile(join(tmp, 'log.txt'), 'utf8')).trim().split('\n').map(JSON.parse);
  assert.deepEqual(linhas.map((l) => l.servico), ['A', 'B']);
});

test('criarServicos deixa nulo o serviço sem chave', () => {
  const s = criarServicos({ chaves: { google: 'g' } }, { fetch: criarFetchFalso([]) });
  assert.ok(s.places); assert.ok(s.pagespeed); assert.equal(s.gemini, null); assert.equal(s.github, null);
  assert.equal(s.instagram, null); assert.equal(s.pexels, null); assert.equal(typeof s.baixar, 'function');
});
