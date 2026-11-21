import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { TOPOS } from '../kit/catalogo.js';
import { PECAS_TOPO } from '../kit/pecas.js';
import { criarContextoPeca } from '../src/previa/montar.js';
import { prepararCtxCompleto } from './ajudantes.js';

let tmp; let ctxCompleto; let montagem;
before(async () => {
  tmp = await mkdtemp(join(tmpdir(), 'jarvis-topos-'));
  ({ ctx: ctxCompleto, montagem } = await prepararCtxCompleto(tmp));
});
after(async () => { await rm(tmp, { recursive: true, force: true }); });

for (const { id } of TOPOS) {
  test(`topo ${id} existe e segue o contrato`, async () => {
    const { render } = await import(`../kit/topos/${id}.js`);
    const { html, css } = render(ctxCompleto);
    assert.equal((html.match(/data-titulo-principal/g) || []).length, 1);
    assert.ok(css.includes(`.t-${id}`));
    assert.ok(html.includes(`t-${id}`));
    assert.ok(!/[—–]/.test(html));
    assert.equal(PECAS_TOPO[id]?.render, render, 'registrado em kit/pecas.js');
  });

  test(`topo ${id} dá prioridade a no máximo uma imagem`, async () => {
    const ctx = criarContextoPeca(montagem);
    const { html } = (await import(`../kit/topos/${id}.js`)).render(ctx);
    assert.ok((html.match(/fetchpriority="high"/g) || []).length <= 1);
  });
}

test('video-fundo tem os atributos de vídeo leve', async () => {
  const { html } = (await import('../kit/topos/video-fundo.js')).render(ctxCompleto);
  for (const attr of ['autoplay', 'muted', 'loop', 'playsinline', 'poster=']) assert.ok(html.includes(attr), attr);
  assert.match(html, /src="midias\/video\.mp4"/);
});

test('carrossel tem botões com aria-label em português e marca os slides', async () => {
  const { html } = (await import('../kit/topos/carrossel.js')).render(ctxCompleto);
  assert.match(html, /data-carrossel/);
  assert.ok((html.match(/data-slide/g) || []).length >= 3);
  assert.match(html, /aria-label="Foto anterior"/);
  assert.match(html, /aria-label="Próxima foto"/);
});

test('mosaico-movel usa paralaxe', async () => {
  const { html } = (await import('../kit/topos/mosaico-movel.js')).render(ctxCompleto);
  assert.match(html, /data-anim="paralaxe"/);
});

test('titulo-gigante funciona sem nenhuma foto', async () => {
  const ctx = criarContextoPeca({ ...montagem, fotos: [], video: null });
  const { html } = (await import('../kit/topos/titulo-gigante.js')).render(ctx);
  assert.equal((html.match(/data-titulo-principal/g) || []).length, 1);
  assert.ok(!html.includes('<img'));
});
