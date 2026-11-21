import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mensagensPadrao, ROTEIRO_OBJECOES, linkAbordagem } from '../src/vendas/mensagens.js';
import { escreverAbordagem } from '../src/ia/abordagem.js';
import { sugerirPreco, TABELA_PRECOS } from '../src/vendas/precos.js';
import { NICHOS } from '../src/previa/textos-base.js';
import { registro, diagnostico, geminiQueDevolve, geminiQueLanca, abordagemIA, URL_PREVIA } from './falsos.js';
import { ErroLimiteIA } from '../src/externo/gemini.js';

const op = (extra = {}) => ({ url: URL_PREVIA, nomeUsuario: 'Isaque', estudio: 'Estúdio Dez', ...extra });

test('roteiro de objeções cobre as 7 da spec', () => {
  assert.deepEqual(Object.keys(ROTEIRO_OBJECOES).sort(), ['caro', 'ja_tenho_clientes', 'ja_tenho_site', 'sem_tempo', 'sobrinho_faz', 'tenho_instagram', 'vou_pensar']);
  assert.ok(Object.values(ROTEIRO_OBJECOES).every((t) => t.length > 20 && !/[—–]/.test(t)));
});

test('mensagem padrão cabe em 400 caracteres e tem tudo que precisa', () => {
  const a = mensagensPadrao(registro, diagnostico, op());
  assert.ok(a.primeira.length <= 400); assert.match(a.primeira, /previas\/x-1a2b/); assert.match(a.primeira, /Isaque/); assert.match(a.primeira, /Estúdio Dez/);
  assert.ok(a.primeira.includes(diagnostico.achadoPrincipal)); assert.ok(!/[—–]/.test(JSON.stringify(a)));
  assert.deepEqual(Object.keys(a.objecoes).sort(), Object.keys(ROTEIRO_OBJECOES).sort());
  for (const m of [a.acompanhamento1, a.acompanhamento2]) { assert.ok(m.includes(URL_PREVIA)); assert.ok(m.length <= 400); }
  assert.ok(!/!!|urgente|última chance|só hoje/i.test(JSON.stringify(a)));
});

test('mensagem padrão continua curta com nome e achado longos', () => {
  const a = mensagensPadrao(registro, { ...diagnostico, achadoPrincipal: 'A '.repeat(120) }, op({ nomeUsuario: 'Isaque Novaes da Silva Pereira' }));
  assert.ok(a.primeira.length <= 400); assert.ok(a.primeira.includes(URL_PREVIA));
});

test('mensagem da IA com pressão ou longa demais cai na padrão', async () => {
  for (const primeira of ['x'.repeat(401), `Última chance!! Responda hoje ${URL_PREVIA} Isaque`, `Oi, sou o Isaque ${URL_PREVIA}. É urgente!`]) {
    const r = await escreverAbordagem(registro, diagnostico, { ...op(), gemini: geminiQueDevolve({ ...abordagemIA, primeira }) });
    assert.equal(r.porIA, false, primeira); assert.ok(r.aviso);
  }
});

test('mensagem da IA sem o link ou sem o nome cai na padrão', async () => {
  for (const primeira of ['Oi, sou o Isaque, do Estúdio Dez.', `Oi! Veja: ${URL_PREVIA}`]) {
    const r = await escreverAbordagem(registro, diagnostico, { ...op(), gemini: geminiQueDevolve({ ...abordagemIA, primeira }) });
    assert.equal(r.porIA, false);
  }
});

test('mensagem da IA boa é usada', async () => {
  const g = geminiQueDevolve(abordagemIA);
  const r = await escreverAbordagem(registro, diagnostico, { ...op(), gemini: g });
  assert.equal(r.porIA, true); assert.equal(r.primeira, abordagemIA.primeira);
  assert.match(g.chamadas[0].prompt, /x-1a2b/); assert.match(g.chamadas[0].prompt, /Barber Club/);
});

test('sem IA ou com limite, usa a padrão com aviso', async () => {
  const r1 = await escreverAbordagem(registro, diagnostico, { ...op(), gemini: null });
  const r2 = await escreverAbordagem(registro, diagnostico, { ...op(), gemini: geminiQueLanca(new ErroLimiteIA()) });
  for (const r of [r1, r2]) { assert.equal(r.porIA, false); assert.ok(r.primeira.includes(URL_PREVIA)); }
  assert.match(r2.aviso, /limite/);
});

test('linkAbordagem só com WhatsApp provável', () => {
  assert.match(linkAbordagem({ telefone: '(19) 99876-5432', whatsappProvavel: true }, 'Oi'), /^https:\/\/wa\.me\/5519998765432\?text=Oi$/);
  assert.equal(linkAbordagem({ telefone: '(19) 3232-1010', whatsappProvavel: false }, 'Oi'), null);
  assert.equal(linkAbordagem({ telefoneInternacional: '+55 19 99876-5432', whatsappProvavel: true }, 'Oi tudo bem'), 'https://wa.me/5519998765432?text=Oi%20tudo%20bem');
});

test('preço por nicho com multiplicador e sobrescrita', () => {
  assert.deepEqual(sugerirPreco('barbearia').basico, [900, 1800]);
  assert.deepEqual(sugerirPreco('clinica').profissional, [2340, 5200]);
  assert.deepEqual(sugerirPreco('estetica').premium, [6000, 12000]);
  assert.deepEqual(sugerirPreco('barbearia', { basico: [700, 1200] }).basico, [700, 1200]);
  assert.deepEqual(sugerirPreco('barbearia').manutencao, TABELA_PRECOS.manutencao);
  for (const n of NICHOS) assert.ok(sugerirPreco(n).basico[0] > 0);
});
