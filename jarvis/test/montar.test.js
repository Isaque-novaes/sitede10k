import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { montarPrevia, gravarPrevia, criarContextoPeca } from '../src/previa/montar.js';
import { prepararMontagemExemplo } from './ajudantes.js';

let tmp; let pastaTmp; let montagemExemplo;
before(async () => {
  tmp = await mkdtemp(join(tmpdir(), 'jarvis-montar-'));
  pastaTmp = join(tmp, 'previa');
  montagemExemplo = await prepararMontagemExemplo(tmp);
});
after(async () => { await rm(tmp, { recursive: true, force: true }); });

test('página tem noindex, faixa, créditos e título principal', () => {
  const { html } = montarPrevia(montagemExemplo);
  assert.match(html, /<meta name="robots" content="noindex, nofollow">/);
  assert.match(html, /Demonstração criada pelo Estúdio Dez\. Este não é o site oficial de Barbearia do Zé\./);
  assert.match(html, /Fotos: .*@barbeariadoze/);
  assert.match(html, /data-titulo-principal/);
  assert.match(html, /data-movimento="suave"/);
  assert.match(html, /<html lang="pt-BR"/);
  assert.match(html, /<title>Barbearia do Zé \| Prévia<\/title>/);
});

test('nome do estúdio vem das opções', () => {
  const { html } = montarPrevia({ ...montagemExemplo, opcoes: { estudio: 'Estúdio Teste' } });
  assert.match(html, /Demonstração criada pelo Estúdio Teste\./);
});

test('nome perigoso sai escapado', () => {
  const { html } = montarPrevia({ ...montagemExemplo, negocio: { ...montagemExemplo.negocio, nome: `<script>alert(1)</script> D'Ávila & Co` } });
  assert.ok(!html.includes('<script>alert(1)</script>'));
  assert.ok(html.includes('&lt;script&gt;'));
});

test('sem travessão nem meia-risca no texto', () => {
  assert.ok(!/[—–]/.test(montarPrevia(montagemExemplo).html));
});

test('chamada usa o WhatsApp do negócio', () => {
  assert.match(montarPrevia(montagemExemplo).html, /href="https:\/\/wa\.me\/5519998765432\?text=/);
});

test('chamada cai para telefone e depois para o Maps', () => {
  const semZap = { ...montagemExemplo.negocio, whatsapp: undefined };
  assert.match(montarPrevia({ ...montagemExemplo, negocio: semZap }).html, /href="tel:\+?\d+"/);
  const soMaps = { ...semZap, telefone: undefined };
  assert.match(montarPrevia({ ...montagemExemplo, negocio: soMaps }).html, /href="https:\/\/maps\.google\.com/);
});

test('seção sem dados some', () => {
  const semAval = { ...montagemExemplo.negocio, avaliacoes: [] };
  assert.ok(!montarPrevia({ ...montagemExemplo, negocio: semAval }).html.includes('s-avaliacoes'));
});

test('todas as seções da assinatura aparecem quando têm dados', () => {
  const { html } = montarPrevia(montagemExemplo);
  for (const t of ['servicos', 'sobre', 'galeria', 'avaliacoes', 'numeros', 'localizacao', 'perguntas', 'chamada-final']) {
    assert.ok(html.includes(`s-${t}-a`), t);
  }
});

test('gravarPrevia copia as mídias', async () => {
  const m = montarPrevia(montagemExemplo);
  await gravarPrevia(pastaTmp, m);
  assert.ok(existsSync(join(pastaTmp, 'index.html')));
  assert.ok(m.arquivos.length > 0);
  for (const a of m.arquivos) assert.ok(existsSync(join(pastaTmp, a.destino)), a.destino);
  for (const a of m.arquivos) assert.match(a.destino, /^midias\//);
});

test('fonte de título nunca é Inter ou Roboto', () => {
  assert.ok(!/family=(Inter|Roboto)[:&]/.test(montarPrevia(montagemExemplo).html));
});

test('carrega o par de fontes escolhido com display=swap', () => {
  const { html } = montarPrevia(montagemExemplo);
  assert.match(html, /fonts\.googleapis\.com\/css2\?family=Playfair\+Display:wght@500;700&family=DM\+Sans:wght@400;500;700&display=swap/);
});

test('respeita reduzir movimento', () => {
  assert.match(montarPrevia(montagemExemplo).html, /prefers-reduced-motion:\s*reduce/);
});

test('imagens têm srcset, medidas e só a primeira tem prioridade', () => {
  const { html } = montarPrevia(montagemExemplo);
  const imgs = html.match(/<img [^>]*>/g);
  assert.ok(imgs.length >= 6);
  assert.ok(imgs.every((i) => / width="\d+"/.test(i) && / height="\d+"/.test(i) && / alt="/.test(i)));
  assert.equal(imgs.filter((i) => i.includes('fetchpriority="high"')).length, 1);
  assert.ok(imgs.filter((i) => i.includes('srcset=')).length >= 6);
});

test('criarContextoPeca entrega util para as peças', () => {
  const ctx = criarContextoPeca(montagemExemplo);
  assert.equal(typeof ctx.util.esc, 'function');
  assert.equal(typeof ctx.util.img, 'function');
  assert.deepEqual(ctx.util.linkContato().rotulo.length > 0, true);
  assert.equal(ctx.fontes.id, 'playfair-dmsans');
  assert.equal(ctx.movimento, 'suave');
});
