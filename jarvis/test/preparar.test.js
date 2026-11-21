import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { prepararNegocio, publicarPrevia, sugerirInstagram, confirmarInstagram, registroParaNegocio } from '../src/prospeccao/preparar.js';
import { ErroExterno } from '../src/externo/http.js';
import { abrirNavegador } from '../src/util/navegador.js';
import { ambientePreparo, registroSemSite, navegadorQuebrado } from './falsos.js';

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
  const a = await amb({ sem: ['gemini', 'pexels', 'github'], registro: { instagram: undefined } });
  const r = await prepararNegocio('sem-site-1', a);
  assert.equal(r.url, undefined); assert.ok(r.registro.previa.slug); assert.equal(r.situacao, 'sem_publicar');
  assert.ok(r.avisos.some((x) => /GitHub/.test(x)));
  assert.ok(r.avisos.some((x) => /Instagram do negócio ainda não foi confirmado/.test(x)), r.avisos.join(' | '));
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
  assert.equal(r.url, undefined); assert.equal(r.situacao, 'sem_publicar');
  assert.ok(r.avisos.some((x) => x.includes('ficou salva no computador') && x.includes('GitHub está fora do ar')), r.avisos.join(' | '));
  assert.ok(r.registro.previa.slug);
  assert.equal(r.registro.etapa, 'encontrado', 'sem link não está pronto para enviar');
  assert.ok(r.registro.abordagem.primeira.includes('[link da prévia]'));
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

test('preparar de novo com conferência reprovada mantém a versão anterior no ar', async () => {
  const a = await amb();
  const r1 = await prepararNegocio('sem-site-1', a);
  const r2 = await prepararNegocio('sem-site-1', { ...a, navegador: navegadorQuebrado(navegador) });
  assert.equal(r2.situacao, 'reprovada'); assert.ok(r2.problemas.length > 0); assert.equal(r2.url, undefined);
  const salvo = (await a.loja.ler('negocios'))[0];
  assert.equal(salvo.previa.url, r1.url); assert.equal(salvo.previa.slug, r1.registro.previa.slug);
  assert.ok(salvo.abordagem.primeira.includes(r1.url));
  const remocoes = a.f.chamadas.filter((c) => c.metodo === 'POST' && c.url.endsWith('/git/trees')).map((c) => JSON.parse(c.corpo)).filter((t) => t.tree.every((e) => e.sha === null));
  assert.equal(remocoes.length, 0, 'a versão no ar não pode sair');
  assert.ok(existsSync(join(a.config.pastaDados, 'previas', r1.registro.previa.slug)));
});

test('publicação que falha mantém a anterior no ar e publicarPrevia resolve depois', async () => {
  const a = await amb();
  const r1 = await prepararNegocio('sem-site-1', a);
  const recusa = async () => { throw new ErroExterno('GitHub', 'O GitHub recusou a chave. Confira a chave do GitHub nas configurações.', { status: 401 }); };
  const semPublicar = { ...a, servicos: { ...a.servicos, github: { ...a.servicos.github, publicar: recusa } } };
  const r2 = await prepararNegocio('sem-site-1', semPublicar);
  assert.equal(r2.situacao, 'sem_publicar'); assert.equal(r2.url, undefined);
  assert.ok(r2.avisos.some((x) => x.includes('recusou a chave') && x.includes('ficou salva no computador')), r2.avisos.join(' | '));
  let salvo = (await a.loja.ler('negocios'))[0];
  assert.equal(salvo.previa.url, undefined); assert.deepEqual(salvo.previa.substitui, { slug: r1.registro.previa.slug, url: r1.url, publicadaEm: r1.registro.previa.publicadaEm });
  assert.ok(existsSync(join(a.config.pastaDados, 'previas', r1.registro.previa.slug)));
  const r3 = await publicarPrevia('sem-site-1', a);
  assert.match(r3.url, /^https:\/\/isaque\.github\.io\/previas\//); assert.notEqual(r3.url, r1.url);
  salvo = (await a.loja.ler('negocios'))[0];
  assert.equal(salvo.previa.url, r3.url); assert.equal(salvo.previa.substitui, undefined);
  assert.ok(salvo.abordagem.primeira.includes(r3.url) && !salvo.abordagem.primeira.includes('[link da prévia]'));
  const remocoes = a.f.chamadas.filter((c) => c.metodo === 'POST' && c.url.endsWith('/git/trees')).map((c) => JSON.parse(c.corpo)).filter((t) => t.tree.every((e) => e.sha === null));
  assert.ok(remocoes.some((t) => t.tree[0].path.startsWith(`${r1.registro.previa.slug}/`)));
  assert.ok(!existsSync(join(a.config.pastaDados, 'previas', r1.registro.previa.slug)));
});

test('não prepara quem pediu para não ser contatado nem quem está como perdido', async () => {
  const a = await amb({ registro: { naoContatar: true, etapa: 'descartado' } });
  await assert.rejects(prepararNegocio('sem-site-1', a), /pediu para não ser contatado/);
  await assert.rejects(publicarPrevia('sem-site-1', a), /pediu para não ser contatado/);
  assert.equal(a.f.chamadas.length, 0);
  const b = await amb({ registro: { etapa: 'perdido' } });
  await assert.rejects(prepararNegocio('sem-site-1', b), /está como perdido/);
});

test('confirmarInstagram aceita o endereço do perfil e recusa o que não é @', async () => {
  const a = await amb();
  const r = await confirmarInstagram('sem-site-1', 'https://www.instagram.com/Navalha.DeOuro/?hl=pt-br', a);
  assert.equal(r.instagram.usuario, 'navalha.deouro');
  await assert.rejects(confirmarInstagram('sem-site-1', 'não sei', a), /não parece um usuário do Instagram/);
});

test('publicarPrevia sem prévia guardada explica o que fazer', async () => {
  const a = await amb();
  await assert.rejects(publicarPrevia('sem-site-1', a), /ainda não tem prévia/);
});
