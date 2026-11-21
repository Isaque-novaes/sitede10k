import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { completarComPexels, CONSULTA_PEXELS } from '../src/externo/pexels.js';
import { NICHOS } from '../src/previa/textos-base.js';
import { criarServicos } from '../src/externo/servicos.js';
import { criarFetchFalso, fixture, fotosFalsasMidia } from './falsos.js';

let tmp;
beforeEach(async () => { tmp = await mkdtemp(join(tmpdir(), 'jarvis-pexels-')); });
afterEach(async () => { await rm(tmp, { recursive: true, force: true }); });

test('completa até 4 fotos com crédito do Pexels e avisa', async () => {
  const f = criarFetchFalso([{ contem: 'api.pexels.com/v1/search', json: fixture('pexels-busca') }, { contem: 'images.pexels.com', bytes: Buffer.from([1]) }]);
  const r = await completarComPexels(fotosFalsasMidia(1, 'google'), 'pizzaria', tmp, { chave: 'P', fetch: f });
  assert.equal(r.midias.length, 4); assert.ok(r.midias.slice(1).every((m) => m.origem === 'pexels' && /\(Pexels\)$/.test(m.credito)));
  assert.equal(r.midias[1].credito, 'Foto: Ana Costa (Pexels)');
  assert.ok(r.midias.slice(1).every((m) => existsSync(m.arquivo) && m.tipo === 'foto'));
  assert.match(f.chamadas[0].url, /query=wood%20fired%20pizza/); assert.equal(f.chamadas[0].cabecalhos.Authorization, 'P');
  assert.match(f.chamadas[0].url, /orientation=landscape/); assert.match(f.chamadas[0].url, /locale=pt-BR/);
  assert.match(r.aviso, /poucas fotos reais/);
});

test('com fotos suficientes não chama o Pexels', async () => {
  const f = criarFetchFalso([]);
  const r = await completarComPexels(fotosFalsasMidia(5, 'instagram'), 'pizzaria', tmp, { chave: 'P', fetch: f });
  assert.equal(r.midias.length, 5); assert.equal(f.chamadas.length, 0); assert.equal(r.aviso, undefined);
});

test('vídeo não conta como foto', async () => {
  const f = criarFetchFalso([{ contem: 'api.pexels.com/v1/search', json: fixture('pexels-busca') }, { contem: 'images.pexels.com', bytes: Buffer.from([1]) }]);
  const r = await completarComPexels([...fotosFalsasMidia(3, 'google'), { arquivo: 'v.mp4', tipo: 'video', origem: 'instagram', credito: '@x' }], 'pizzaria', tmp, { chave: 'P', fetch: f });
  assert.equal(r.midias.filter((m) => m.tipo === 'foto').length, 4);
});

test('nicho desconhecido usa a consulta genérica', async () => {
  const f = criarFetchFalso([{ contem: 'api.pexels.com/v1/search', json: { photos: [] } }]);
  const r = await completarComPexels([], 'zzz', tmp, { chave: 'P', fetch: f });
  assert.match(f.chamadas[0].url, /query=small%20business/); assert.equal(r.midias.length, 0);
});

test('toda consulta de nicho existe', () => {
  for (const n of NICHOS) assert.ok(CONSULTA_PEXELS[n], n);
});

test('servicos.pexels.completar usa a chave', async () => {
  const f = criarFetchFalso([{ contem: 'api.pexels.com', json: { photos: [] } }]);
  const s = criarServicos({ chaves: { pexels: 'PX' } }, { fetch: f });
  await s.pexels.completar([], 'barbearia', tmp);
  assert.equal(f.chamadas[0].cabecalhos.Authorization, 'PX');
});
