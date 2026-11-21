import { test } from 'node:test';
import assert from 'node:assert/strict';
import { extrairClima, VOCABULARIO_CLIMA, CLIMA_POR_NICHO } from '../src/ia/clima.js';
import { escolherMaterial } from '../src/ia/material.js';
import { sugerirAssinatura } from '../src/ia/arte.js';
import { escreverTextosPrevia } from '../src/ia/textos.js';
import { ErroLimiteIA } from '../src/externo/gemini.js';
import { ErroExterno } from '../src/externo/http.js';
import { NICHOS } from '../src/previa/textos-base.js';
import { geminiQueDevolve, geminiQueLanca, fotosFalsasMidia, videoMidia, registro, diagnostico, contexto, textosIA } from './falsos.js';

test('clima pela IA usa só o vocabulário', async () => {
  const g = geminiQueDevolve({ clima: ['urbano', 'classico'] });
  const r = await extrairClima(registro, null, { gemini: g });
  assert.deepEqual(r.clima, ['urbano', 'classico']); assert.equal(r.porIA, true);
  assert.deepEqual(g.chamadas[0].esquema.properties.clima.items.enum, VOCABULARIO_CLIMA);
  assert.match(g.chamadas[0].prompt, /Barbearia Navalha de Ouro/);
});

test('sem IA, o clima vem do nicho', async () => {
  const r = await extrairClima({ ...registro, nicho: 'pizzaria' }, null, { gemini: null });
  assert.deepEqual(r.clima, ['familiar', 'gastronomia']); assert.equal(r.porIA, false); assert.ok(r.aviso);
});

test('todo nicho tem clima padrão do vocabulário', () => {
  for (const n of NICHOS) assert.ok(CLIMA_POR_NICHO[n].every((c) => VOCABULARIO_CLIMA.includes(c)), n);
});

test('limite da IA vira alternativa com aviso', async () => {
  const r = await extrairClima(registro, null, { gemini: geminiQueLanca(new ErroLimiteIA()) });
  assert.equal(r.porIA, false); assert.match(r.aviso, /limite/i);
});

test('escolherMaterial respeita índices válidos e mantém o vídeo', async () => {
  const midias = [...fotosFalsasMidia(6, 'instagram'), videoMidia, ...fotosFalsasMidia(4, 'google')];
  const g = geminiQueDevolve({ indices: [2, 0, 99, 2] });
  const r = await escolherMaterial(midias, { gemini: g });
  assert.deepEqual(r.midias.filter((m) => m.tipo === 'foto').map((m) => m.arquivo), [midias[2].arquivo, midias[0].arquivo]);
  assert.ok(r.midias.some((m) => m.tipo === 'video')); assert.equal(r.porIA, true);
  assert.equal(g.chamadas[0].imagens.length, 10);
});

test('sem IA, o material prioriza o Instagram até o máximo', async () => {
  const midias = [...fotosFalsasMidia(4, 'google'), ...fotosFalsasMidia(8, 'instagram'), videoMidia];
  const r = await escolherMaterial(midias, { gemini: null, maxFotos: 10 });
  const fotos = r.midias.filter((m) => m.tipo === 'foto');
  assert.equal(fotos.length, 10); assert.ok(fotos.slice(0, 8).every((m) => m.origem === 'instagram'));
  assert.ok(r.midias.some((m) => m.tipo === 'video')); assert.equal(r.porIA, false);
});

test('IA que não escolhe nenhuma foto válida cai na alternativa', async () => {
  const midias = fotosFalsasMidia(3, 'google');
  const r = await escolherMaterial(midias, { gemini: geminiQueDevolve({ indices: [50, -1] }) });
  assert.equal(r.porIA, false); assert.equal(r.midias.length, 3);
});

test('sugestão de arte válida volta sem paleta', async () => {
  const sug = { topo: 'colagem', fontes: 'bebas-manrope', movimento: 'energico', secoes: [{ tipo: 'servicos', variante: 'b' }, { tipo: 'sobre', variante: 'a' }, { tipo: 'chamada-final', variante: 'c' }] };
  const g = geminiQueDevolve(sug);
  const r = await sugerirAssinatura(contexto, [], { gemini: g });
  assert.deepEqual(r.assinatura, sug); assert.equal(r.porIA, true); assert.equal(r.assinatura.paleta, undefined);
  const esquema = g.chamadas[0].esquema;
  assert.ok(esquema.properties.topo.enum.includes('colagem')); assert.ok(!esquema.properties.topo.enum.includes('video-fundo'), 'só topos possíveis');
});

test('sugestão de arte inválida volta nula com aviso', async () => {
  const r = await sugerirAssinatura(contexto, [], { gemini: geminiQueDevolve({ topo: 'foto-cheia', fontes: 'comic', movimento: 'suave', secoes: [] }) });
  assert.equal(r.assinatura, null); assert.match(r.aviso, /assinatura/);
});

test('sem IA, não há sugestão de arte', async () => {
  const r = await sugerirAssinatura(contexto, [], { gemini: null });
  assert.equal(r.assinatura, null); assert.equal(r.porIA, false);
});

test('textos da IA passam pela limpeza de travessões', async () => {
  const r = await escreverTextosPrevia(registro, diagnostico, { gemini: geminiQueDevolve({ ...textosIA, titulo: 'Corte — barba' }) });
  assert.ok(!/[—–]/.test(JSON.stringify(r.textos))); assert.equal(r.porIA, true);
});

test('título longo demais cai na alternativa', async () => {
  const r = await escreverTextosPrevia(registro, diagnostico, { gemini: geminiQueDevolve({ ...textosIA, titulo: 'x'.repeat(80) }) });
  assert.equal(r.porIA, false); assert.ok(r.textos.titulo.length <= 60);
});

test('poucos serviços cai na alternativa', async () => {
  const r = await escreverTextosPrevia(registro, diagnostico, { gemini: geminiQueDevolve({ ...textosIA, servicos: textosIA.servicos.slice(0, 2) }) });
  assert.equal(r.porIA, false); assert.ok(r.textos.servicos.length >= 3);
});

test('erro da IA nos textos cai na alternativa com aviso', async () => {
  const r = await escreverTextosPrevia(registro, diagnostico, { gemini: geminiQueLanca(new ErroExterno('Gemini', 'A IA respondeu num formato inesperado.')) });
  assert.equal(r.porIA, false); assert.match(r.aviso, /formato inesperado/);
  assert.ok(r.textos.titulo && r.textos.servicos.length >= 3);
});

test('o prompt dos textos leva avaliações e o diagnóstico, e pede para não inventar', async () => {
  const g = geminiQueDevolve(textosIA);
  await escreverTextosPrevia(registro, diagnostico, { gemini: g });
  assert.match(g.chamadas[0].prompt, /Melhor barba de Campinas/);
  assert.match(g.chamadas[0].prompt, /não invente/i);
});
