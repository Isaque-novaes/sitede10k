import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { ETAPAS, mudarEtapa, registrarAcompanhamento, marcarNaoContatar, cobrarHoje } from '../src/funil/funil.js';
import { previasParaRemover, limparPreviasVencidas, exportarDados, copiaSemanal } from '../src/prospeccao/manutencao.js';
import { registroSemSite as base, ambienteFunil } from './falsos.js';

const dia = (s, mes = '11') => new Date(`2026-${mes}-${s}T12:00:00-03:00`);

test('etapas da spec', () => {
  assert.deepEqual(ETAPAS, ['encontrado', 'preparado', 'abordado', 'respondeu', 'reuniao', 'proposta', 'fechou', 'perdido', 'descartado']);
});

test('mudarEtapa grava data e histórico sem alterar o original', () => {
  const r = mudarEtapa(base, 'abordado', dia('10'));
  assert.equal(r.etapa, 'abordado'); assert.equal(r.datas.abordado, dia('10').toISOString());
  assert.deepEqual(r.historico.at(-1), { tipo: 'etapa', data: dia('10').toISOString(), detalhe: 'abordado' });
  assert.equal(base.etapa, 'encontrado');
  assert.throws(() => mudarEtapa(base, 'voando', dia('10')), /Etapa desconhecida/);
});

test('cobrar no dia 3 e no dia 7, depois sugerir perdido', () => {
  let r = mudarEtapa(base, 'abordado', dia('10'));
  assert.equal(cobrarHoje([r], dia('12')).cobrar.length, 0);
  assert.deepEqual(cobrarHoje([r], dia('13')).cobrar.map((c) => c.qual), [1]);
  r = registrarAcompanhamento(r, dia('13'));
  assert.equal(cobrarHoje([r], dia('19')).cobrar.length, 0);
  assert.deepEqual(cobrarHoje([r], dia('20')).cobrar.map((c) => c.qual), [2]);
  r = registrarAcompanhamento(r, dia('20'));
  assert.equal(cobrarHoje([r], dia('26')).sugerirPerdido.length, 0);
  assert.equal(cobrarHoje([r], dia('27')).sugerirPerdido.length, 1);
  assert.throws(() => registrarAcompanhamento(r, dia('27')));
});

test('os dias contam pela data de São Paulo', () => {
  const r = mudarEtapa(base, 'abordado', new Date('2026-11-10T23:30:00-03:00'));
  assert.equal(cobrarHoje([r], new Date('2026-11-13T00:30:00-03:00')).cobrar.length, 1);
});

test('dias de acompanhamento configuráveis', () => {
  const r = mudarEtapa(base, 'abordado', dia('10'));
  assert.equal(cobrarHoje([r], dia('12'), [2, 5]).cobrar.length, 1);
});

test('só quem está em abordado entra na cobrança', () => {
  const r = mudarEtapa(mudarEtapa(base, 'abordado', dia('01')), 'respondeu', dia('02'));
  assert.equal(cobrarHoje([r], dia('20')).cobrar.length, 0);
});

test('não contatar bloqueia contato e some da cobrança', () => {
  const r = marcarNaoContatar(mudarEtapa(base, 'abordado', dia('10')), dia('11'));
  assert.equal(r.etapa, 'descartado'); assert.equal(r.naoContatar, true);
  assert.throws(() => mudarEtapa(r, 'abordado', dia('12')), /não ser contatado/);
  assert.equal(cobrarHoje([{ ...r, etapa: 'abordado' }], dia('20')).cobrar.length, 0);
});

test('fechou é final', () => {
  assert.throws(() => mudarEtapa(mudarEtapa(base, 'fechou', dia('10')), 'perdido', dia('11')), /já fechado/);
});

test('prévias para remover', () => {
  const pub = (etapa, publicadaEm, extra = {}) => ({ ...base, etapa, ...extra, previa: { url: 'u', publicadaEm, slug: 's', versao: 1 } });
  const lista = [pub('abordado', '2026-10-01T12:00:00-03:00'), pub('abordado', '2026-11-01T12:00:00-03:00'), pub('perdido', '2026-11-20T12:00:00-03:00'), pub('respondeu', '2026-09-01T12:00:00-03:00'), pub('preparado', '2026-11-20T12:00:00-03:00', { naoContatar: true })];
  assert.equal(previasParaRemover(lista, dia('21')).length, 3);
  assert.equal(previasParaRemover([{ ...base, etapa: 'perdido', previa: { slug: 's', versao: 1 } }], dia('21')).length, 0, 'sem url não há o que remover');
});

test('limparPreviasVencidas chama o GitHub e limpa o registro', async () => {
  const { loja, servicos, f } = await ambienteFunil([{ ...base, etapa: 'perdido', previa: { url: 'u', slug: 'x-1a2b', publicadaEm: '2026-11-01T00:00:00Z', versao: 1 } }]);
  const r = await limparPreviasVencidas({ loja, servicos, agora: dia('21') });
  assert.deepEqual(r.removidas, ['x-1a2b']);
  const salvo = (await loja.ler('negocios'))[0];
  assert.equal(salvo.previa.url, undefined); assert.equal(salvo.previa.publicadaEm, undefined); assert.equal(salvo.previa.slug, 'x-1a2b');
  assert.equal(salvo.historico.at(-1).tipo, 'previa_removida');
  assert.ok(f.chamadas.some((c) => c.metodo === 'PATCH'));
});

test('sem GitHub, a limpeza só avisa', async () => {
  const { loja, servicos } = await ambienteFunil([{ ...base, etapa: 'perdido', previa: { url: 'u', slug: 'x-1a2b', publicadaEm: '2026-11-01T00:00:00Z', versao: 1 } }], { github: false });
  const r = await limparPreviasVencidas({ loja, servicos, agora: dia('21') });
  assert.deepEqual(r.removidas, []); assert.match(r.avisos[0], /GitHub/);
  assert.equal((await loja.ler('negocios'))[0].previa.url, 'u');
});

test('exportarDados junta negócios e buscas num arquivo', async () => {
  const { loja, pasta } = await ambienteFunil([base]);
  await loja.gravar('buscas', [{ nicho: 'barbearias', cidade: 'Campinas' }]);
  const arquivo = await exportarDados({ loja, destino: join(pasta, 'export.json') });
  const dados = JSON.parse(await readFile(arquivo, 'utf8'));
  assert.equal(dados.negocios.length, 1); assert.equal(dados.buscas.length, 1); assert.ok(dados.exportadoEm);
});

test('cópia semanal não repete na mesma semana e guarda 8', async () => {
  const { loja, pasta } = await ambienteFunil([base]);
  assert.ok(await copiaSemanal({ loja, pasta, agora: dia('21') }));
  assert.equal(await copiaSemanal({ loja, pasta, agora: dia('22') }), null);
  for (let semana = 1; semana <= 10; semana++) await copiaSemanal({ loja, pasta, agora: new Date(Date.UTC(2027, 0, semana * 7, 15)) });
  assert.equal((await readdir(join(pasta, 'copias'))).length, 8);
});

test('limpar também tira do ar a versão antiga que uma prévia não publicada substitui', async () => {
  const previa = { slug: 'nova-9z9z', versao: 2, substitui: { slug: 'x-1a2b', url: 'u', publicadaEm: '2026-11-01T00:00:00Z' } };
  assert.equal(previasParaRemover([{ ...base, etapa: 'perdido', previa }], dia('21')).length, 1);
  const { loja, servicos, f } = await ambienteFunil([{ ...base, etapa: 'perdido', previa }]);
  const r = await limparPreviasVencidas({ loja, servicos, agora: dia('21') });
  assert.deepEqual(r.removidas, ['x-1a2b']); assert.ok(f.chamadas.some((c) => c.metodo === 'PATCH'));
  const salvo = (await loja.ler('negocios'))[0];
  assert.equal(salvo.previa.substitui, undefined); assert.equal(salvo.previa.slug, 'nova-9z9z');
});
