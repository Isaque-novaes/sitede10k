import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { detalharLugar, baixarFotoLugar } from '../src/externo/google-places.js';
import { diagnosticar } from '../src/prospeccao/diagnostico.js';
import { criarFetchFalso, fixture, ambienteDiagnostico, registroSemSite } from './falsos.js';

let tmp;
beforeEach(async () => { tmp = await mkdtemp(join(tmpdir(), 'jarvis-diag-')); });
afterEach(async () => { await rm(tmp, { recursive: true, force: true }); });

test('detalharLugar traz horários, até 5 avaliações e até 10 fotos', async () => {
  const f = criarFetchFalso([{ contem: '/v1/places/sem-site-1', json: fixture('places-detalhes') }]);
  const d = await detalharLugar('sem-site-1', { chave: 'K', fetch: f });
  assert.equal(d.horarios[0], 'segunda-feira: 09:00–19:00');
  assert.equal(d.avaliacoes.length, 5); assert.ok(d.avaliacoes.every((a) => a.texto));
  assert.deepEqual(d.avaliacoes[0], { autor: 'Rafael M.', nota: 5, texto: 'Corte impecável e atendimento sem pressa.' });
  assert.equal(d.fotos.length, 10); assert.match(d.fotos[0].credito, /Google Maps/);
  assert.equal(d.fotos[1].credito, 'Foto: Cliente 1 (Google Maps)'); assert.equal(d.fotos[0].credito, 'Foto: Google Maps');
  assert.deepEqual([d.fotos[0].largura, d.fotos[0].altura], [4032, 3024]);
  assert.equal(f.chamadas[0].cabecalhos['X-Goog-FieldMask'], 'id,regularOpeningHours,reviews,photos');
  assert.match(f.chamadas[0].url, /languageCode=pt-BR/);
});

test('baixarFotoLugar pede 1600 px', async () => {
  const f = criarFetchFalso([{ contem: '/media?maxWidthPx=1600', bytes: Buffer.from([9]) }]);
  await baixarFotoLugar('places/x/photos/y', join(tmp, 'f.jpg'), { chave: 'K', fetch: f });
  assert.ok(existsSync(join(tmp, 'f.jpg'))); assert.match(f.chamadas[0].url, /places\.googleapis\.com\/v1\/places\/x\/photos\/y\/media/);
});

test('diagnóstico de negócio sem site com concorrente com site', async () => {
  const { loja, servicos, f } = await ambienteDiagnostico();
  const d = await diagnosticar(registroSemSite, { loja, servicos });
  assert.equal(d.temSite, false); assert.equal(d.concorrentes.total, 4); assert.equal(d.concorrentes.comSite, 2);
  assert.equal(d.concorrentes.melhorComSite, 'Barber Club');
  assert.match(d.achadoPrincipal, /Barber Club, aqui perto, já tem site/); assert.ok(!/[—–]/.test(d.resumo));
  assert.ok(d.resumo.includes(d.achadoPrincipal));
  const corpo = JSON.parse(f.chamadas[0].corpo);
  assert.ok(corpo.locationBias); assert.equal(corpo.pageSize, 10);
  assert.equal(Object.values(await loja.ler('uso'))[0].places_busca, 1);
});

test('diagnóstico de site lento cita os segundos', async () => {
  const { loja, servicos } = await ambienteDiagnostico({ concorrentes: [] });
  const d = await diagnosticar({ ...registroSemSite, site: 'https://x.com.br', presenca: 'site_fraco', desempenhoSite: { desempenho: 30, lcpMs: 8400, https: true } }, { loja, servicos });
  assert.equal(d.temSite, true); assert.match(d.achadoPrincipal, /8,4 segundos/);
});

test('site sem https', async () => {
  const { loja, servicos } = await ambienteDiagnostico({ concorrentes: [] });
  const d = await diagnosticar({ ...registroSemSite, site: 'http://x.com.br', presenca: 'site_fraco', desempenhoSite: { desempenho: 80, lcpMs: 1500, https: false } }, { loja, servicos });
  assert.match(d.achadoPrincipal, /não seguro/);
});

test('sem site e sem concorrentes com site', async () => {
  const { loja, servicos } = await ambienteDiagnostico({ concorrentes: [] });
  const d = await diagnosticar(registroSemSite, { loja, servicos });
  assert.match(d.achadoPrincipal, /não têm site/);
});

test('só rede social fala do Instagram', async () => {
  const { loja, servicos } = await ambienteDiagnostico({ concorrentes: [] });
  const d = await diagnosticar({ ...registroSemSite, site: 'https://instagram.com/x', presenca: 'so_rede_social' }, { loja, servicos });
  assert.match(d.achadoPrincipal, /Instagram/);
});

test('posts dos últimos 30 dias vêm do perfil', async () => {
  const { loja, servicos } = await ambienteDiagnostico({ concorrentes: [] });
  const agora = new Date('2026-11-21T12:00:00Z');
  const perfil = { seguidores: 4200, midias: [{ data: '2026-11-10T10:00:00Z' }, { data: '2026-11-01T10:00:00Z' }, { data: '2026-09-01T10:00:00Z' }] };
  const d = await diagnosticar(registroSemSite, { loja, servicos, perfil, agora });
  assert.deepEqual(d.instagram, { seguidores: 4200, postsUltimos30Dias: 2 });
});

test('sem chave do Google, o diagnóstico sai sem concorrentes', async () => {
  const { loja } = await ambienteDiagnostico();
  const d = await diagnosticar(registroSemSite, { loja, servicos: { places: null } });
  assert.equal(d.concorrentes.total, 0); assert.ok(d.achadoPrincipal);
});
