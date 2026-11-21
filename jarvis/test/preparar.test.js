import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { prepararNegocio, sugerirInstagram, confirmarInstagram, registroParaNegocio } from '../src/prospeccao/preparar.js';
import { abrirNavegador } from '../src/util/navegador.js';
import { ambientePreparo, registroSemSite } from './falsos.js';

let navegador;
before(async () => { navegador = await abrirNavegador(); });
after(async () => { await navegador?.close(); });
const amb = (opcoes = {}) => ambientePreparo({ navegador, ...opcoes });

test('registroParaNegocio monta o Negocio do plano 1', () => {
  const n = registroParaNegocio({ ...registroSemSite, instagram: { usuario: 'x', confirmado: true, bio: 'b', seguidores: 3 }, avaliacoes: [] }, [], ['urbano']);
  assert.equal(n.id, 'sem-site-1'); assert.deepEqual(n.instagram, { usuario: 'x', bio: 'b', seguidores: 3 });
  assert.deepEqual(n.clima, ['urbano']); assert.deepEqual(n.midias, []); assert.equal(n.telefone, '(19) 99876-5432');
});

test('preparo completo publica a prévia e deixa a mensagem pronta', async () => {
  const a = await amb();
  const passos = [];
  const r = await prepararNegocio('sem-site-1', { ...a, aoProgredir: (p) => passos.push(p) });
  assert.match(r.url, /^https:\/\/isaque\.github\.io\/previas\/[a-z0-9-]+\/$/);
  assert.equal(r.registro.etapa, 'preparado'); assert.equal(r.registro.previa.versao, 1); assert.equal(r.registro.previa.podeMostrar, false);
  assert.ok(r.registro.abordagem.primeira.includes(r.url)); assert.ok(r.registro.preco.basico);
  assert.ok(a.f.chamadas.some((c) => c.metodo === 'PATCH' && c.url.includes('/git/refs/heads/main')));
  assert.ok(r.registro.horarios.length && r.registro.diagnostico && r.registro.clima.length);
  assert.equal(r.registro.instagram.seguidores, 4200);
  assert.ok(passos.length >= 6);
  const salvo = (await a.loja.ler('negocios'))[0];
  assert.equal(salvo.previa.url, r.url); assert.equal(salvo.etapa, 'preparado');
  assert.ok(existsSync(join(a.config.pastaDados, 'previas', r.registro.previa.slug, 'index.html')));
});

test('sem Gemini, Pexels e GitHub, prepara com alternativas e avisa', async () => {
  const a = await amb({ sem: ['gemini', 'pexels', 'github'] });
  const r = await prepararNegocio('sem-site-1', a);
  assert.equal(r.url, undefined); assert.ok(r.registro.previa.slug);
  assert.ok(r.avisos.some((x) => /GitHub/.test(x)));
  assert.ok(r.registro.abordagem.primeira.length > 0);
});

test('limite da IA no meio não perde o que já foi feito', async () => {
  const a = await amb({ geminiStatus: 429 });
  const r = await prepararNegocio('sem-site-1', a);
  const salvo = (await a.loja.ler('negocios'))[0];
  assert.ok(salvo.horarios.length > 0 && salvo.diagnostico && salvo.previa.slug);
  assert.ok(r.avisos.some((x) => /limite/i.test(x)));
});

test('preparar de novo remove a prévia antiga e sobe a versão', async () => {
  const a = await amb();
  const r1 = await prepararNegocio('sem-site-1', a);
  const r2 = await prepararNegocio('sem-site-1', a);
  assert.equal(r2.registro.previa.versao, 2); assert.notEqual(r1.registro.previa.slug, r2.registro.previa.slug);
  assert.equal((await a.loja.ler('negocios')).length, 1);
  const arvores = a.f.chamadas.filter((c) => c.url.endsWith('/git/trees') && c.metodo === 'POST').map((c) => JSON.parse(c.corpo));
  assert.ok(arvores.some((t) => t.tree.every((e) => e.sha === null) && t.tree[0].path.startsWith(r1.registro.previa.slug)));
  assert.ok(!existsSync(join(a.config.pastaDados, 'previas', r1.registro.previa.slug)));
});

test('publicação que falha deixa a prévia local e avisa', async () => {
  const a = await amb({ githubStatus: 500 });
  const r = await prepararNegocio('sem-site-1', a);
  assert.equal(r.url, undefined); assert.ok(r.avisos.some((x) => x.includes('ficou salva no computador')));
  assert.ok(r.registro.previa.slug);
});

test('Instagram pessoal vira aviso e usa o Google', async () => {
  const a = await amb({ instagram: 'pessoal' });
  const r = await prepararNegocio('sem-site-1', a);
  assert.ok(r.avisos.some((x) => x.includes('Instagram deles é pessoal')));
  assert.ok(r.registro.previa.slug);
});

test('sugerirInstagram usa o site do Google e confirmarInstagram grava', async () => {
  const a = await amb({ registro: { site: 'https://instagram.com/semsite.oficial', instagram: undefined } });
  const s = await sugerirInstagram('sem-site-1', a);
  assert.equal(s[0].usuario, 'semsite.oficial'); assert.ok(s[0].confianca > 0.8);
  const reg = await confirmarInstagram('sem-site-1', '@SemSite.Oficial', a);
  assert.deepEqual(reg.instagram, { usuario: 'semsite.oficial', confirmado: true });
  const nenhum = await confirmarInstagram('sem-site-1', null, a);
  assert.deepEqual(nenhum.instagram, { usuario: '', confirmado: true });
});

test('negócio que não existe dá erro claro', async () => {
  const a = await amb();
  await assert.rejects(prepararNegocio('nao-existe', a), /Não achei esse negócio/);
});
