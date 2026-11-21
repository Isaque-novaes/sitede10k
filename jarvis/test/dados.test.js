import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm, writeFile, readFile, readdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { carregarConfig, salvarPreferencias } from '../src/config.js';
import { criarLoja } from '../src/dados/loja.js';
import { registrarUso, podeUsar, garantirCota, ErroCota } from '../src/dados/uso.js';

let tmp;
beforeEach(async () => { tmp = await mkdtemp(join(tmpdir(), 'jarvis-dados-')); });
afterEach(async () => { await rm(tmp, { recursive: true, force: true }); });

test('carregarConfig lê .env injetado e aplica padrões', async () => {
  const c = await carregarConfig({ raiz: tmp, env: { GOOGLE_API_KEY: 'g', GITHUB_REPO: 'isaque/previas' } });
  assert.equal(c.chaves.google, 'g'); assert.equal(c.estudio, 'Estúdio Dez');
  assert.deepEqual(c.diasAcompanhamento, [3, 7]); assert.equal(c.geminiModelo, 'gemini-flash-latest');
  assert.equal(c.geminiReserva, 'gemini-flash-lite-latest'); assert.equal(c.metaVersao, 'v23.0');
  assert.equal(c.baseUrlPrevias, 'https://isaque.github.io/previas'); assert.equal(c.githubRamo, 'main');
  assert.equal(c.pastaDados, join(tmp, 'dados')); assert.equal(c.metaSemanal, 10); assert.equal(c.nomeAssistente, 'Jarvis');
});

test('carregarConfig lê o arquivo .env da raiz', async () => {
  await writeFile(join(tmp, '.env'), '# comentário\nGEMINI_API_KEY=abc\n\nPEXELS_API_KEY = xyz\n');
  const c = await carregarConfig({ raiz: tmp, env: {} });
  assert.equal(c.chaves.gemini, 'abc'); assert.equal(c.chaves.pexels, 'xyz');
});

test('variável de ambiente ganha do arquivo .env', async () => {
  await writeFile(join(tmp, '.env'), 'GEMINI_API_KEY=do-arquivo\n');
  const c = await carregarConfig({ raiz: tmp, env: { GEMINI_API_KEY: 'do-ambiente' } });
  assert.equal(c.chaves.gemini, 'do-ambiente');
});

test('salvarPreferencias grava preferências e nunca chaves', async () => {
  const c = await carregarConfig({ raiz: tmp, env: { GOOGLE_API_KEY: 'segredo' } });
  await salvarPreferencias(c, { nomeUsuario: 'Isaque', cidadePadrao: 'Campinas', chaves: { google: 'outro-segredo' } });
  const bruto = await readFile(join(tmp, 'dados', 'config.json'), 'utf8');
  assert.ok(!bruto.includes('segredo'));
  assert.equal((await carregarConfig({ raiz: tmp, env: {} })).nomeUsuario, 'Isaque');
});

test('loja grava e lê de forma atômica, sem sobrar temporário', async () => {
  const loja = criarLoja(join(tmp, 'd')); await loja.gravar('negocios', [{ id: 'a' }]);
  assert.deepEqual(await loja.ler('negocios'), [{ id: 'a' }]);
  assert.deepEqual((await readdir(join(tmp, 'd'))).filter((f) => f.endsWith('.tmp')), []);
  assert.deepEqual(await loja.ler('inexistente', []), []);
});

test('atualizações simultâneas não se perdem', async () => {
  const loja = criarLoja(join(tmp, 'e'));
  await Promise.all(Array.from({ length: 20 }, (_, i) => loja.atualizar('n', (v) => [...v, i], [])));
  assert.equal((await loja.ler('n')).length, 20);
});

test('cota mensal bloqueia ao chegar no limite e zera no mês seguinte', async () => {
  const loja = criarLoja(join(tmp, 'f')); const nov = new Date('2026-11-20T12:00:00-03:00');
  await registrarUso(loja, 'places_busca', 800, nov);
  assert.equal(await podeUsar(loja, 'places_busca', 1, nov), false);
  await assert.rejects(garantirCota(loja, 'places_busca', 1, nov), (e) => e instanceof ErroCota && /Limite mensal/.test(e.message));
  assert.equal(await podeUsar(loja, 'places_busca', 1, new Date('2026-12-01T09:00:00-03:00')), true);
});

test('o mês é o de São Paulo, não o de Greenwich', async () => {
  const loja = criarLoja(join(tmp, 'g'));
  await registrarUso(loja, 'places_foto', 800, new Date('2026-12-01T01:00:00Z')); // ainda 30/11 em São Paulo
  assert.equal(await podeUsar(loja, 'places_foto', 1, new Date('2026-11-30T15:00:00-03:00')), false);
});

test('GITHUB_REPO aceita o endereço copiado do navegador e recusa valor sem dono', async () => {
  const c = await carregarConfig({ raiz: tmp, env: { GITHUB_REPO: 'https://github.com/Isaque/previas.git' } });
  assert.equal(c.githubRepo, 'Isaque/previas'); assert.equal(c.baseUrlPrevias, 'https://isaque.github.io/previas');
  const ruim = await carregarConfig({ raiz: tmp, env: { GITHUB_REPO: 'previas' } });
  assert.equal(ruim.githubRepo, undefined); assert.equal(ruim.baseUrlPrevias, undefined);
});
