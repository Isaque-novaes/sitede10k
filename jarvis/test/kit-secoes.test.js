import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { SECOES, VARIANTES } from '../kit/catalogo.js';
import { PECAS_SECAO } from '../kit/pecas.js';
import { criarContextoPeca } from '../src/previa/montar.js';
import { prepararCtxCompleto } from './ajudantes.js';

let tmp; let ctxCompleto; let montagem;
before(async () => {
  tmp = await mkdtemp(join(tmpdir(), 'jarvis-secoes-'));
  ({ ctx: ctxCompleto, montagem } = await prepararCtxCompleto(tmp));
});
after(async () => { await rm(tmp, { recursive: true, force: true }); });

for (const { tipo } of SECOES) for (const v of VARIANTES) {
  test(`seção ${tipo}-${v} existe e segue o contrato`, async () => {
    const { render } = await import(`../kit/secoes/${tipo}-${v}.js`);
    const { html, css } = render(ctxCompleto);
    assert.ok(html.includes(`s-${tipo}`)); assert.ok(css.length > 0); assert.ok(!/[—–]/.test(html));
    assert.ok(css.includes(`.s-${tipo}-${v}`));
    assert.equal(PECAS_SECAO[`${tipo}-${v}`]?.render, render, 'registrada em kit/pecas.js');
  });
}

test('avaliação longa é cortada em 280 caracteres', async () => {
  const longa = { autor: 'Ana', nota: 5, texto: 'ótimo '.repeat(200) };
  const ctx = criarContextoPeca({ ...montagem, negocio: { ...montagem.negocio, avaliacoes: [longa, longa] } });
  for (const v of VARIANTES) {
    const { html } = (await import(`../kit/secoes/avaliacoes-${v}.js`)).render(ctx);
    assert.ok(!html.includes('ótimo '.repeat(60)), v);
  }
});

test('variantes de avaliações e números usam faixa e contador', async () => {
  const htmls = async (t) => Promise.all(VARIANTES.map(async (v) => (await import(`../kit/secoes/${t}-${v}.js`)).render(ctxCompleto).html));
  assert.ok((await htmls('avaliacoes')).some((h) => h.includes('data-anim="faixa"')));
  assert.ok((await htmls('numeros')).some((h) => h.includes('data-anim="contador"')));
});

test('perguntas usam details e summary', async () => {
  for (const v of VARIANTES) {
    const { html } = (await import(`../kit/secoes/perguntas-${v}.js`)).render(ctxCompleto);
    assert.match(html, /<details/); assert.match(html, /<summary/);
  }
});

test('localização tem Ver no mapa e nenhum iframe', async () => {
  for (const v of VARIANTES) {
    const { html } = (await import(`../kit/secoes/localizacao-${v}.js`)).render(ctxCompleto);
    assert.match(html, /Ver no mapa/); assert.ok(!html.includes('<iframe'));
  }
});

test('chamada final sem contato não tem botão', async () => {
  const semContato = { ...montagem.negocio, whatsapp: undefined, telefone: undefined, mapsUrl: undefined };
  const ctx = criarContextoPeca({ ...montagem, negocio: semContato });
  for (const v of VARIANTES) {
    const { html } = (await import(`../kit/secoes/chamada-final-${v}.js`)).render(ctx);
    assert.ok(!html.includes('class="botao'), v);
  }
});

test('seções com foto funcionam sem fotos', async () => {
  const ctx = criarContextoPeca({ ...montagem, fotos: [] });
  for (const tipo of ['servicos', 'sobre', 'chamada-final']) for (const v of VARIANTES) {
    const { html } = (await import(`../kit/secoes/${tipo}-${v}.js`)).render(ctx);
    assert.ok(!html.includes('<img'), `${tipo}-${v}`);
  }
});

test('as três variantes de cada tipo têm HTML diferente', async () => {
  for (const { tipo } of SECOES) {
    const estrutura = await Promise.all(VARIANTES.map(async (v) => (await import(`../kit/secoes/${tipo}-${v}.js`)).render(ctxCompleto).html
      .replace(/s-[a-z-]+-[abc]/g, 'X').replace(/>[^<]*</g, '><')));
    assert.equal(new Set(estrutura).size, 3, tipo);
  }
});
