import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { descobrirPerfil, candidatosDeUsuario, encontrarInstagram, baixarMidiasInstagram } from '../src/externo/instagram.js';
import { criarServicos } from '../src/externo/servicos.js';
import { criarFetchFalso, fixture, perfilComMidias } from './falsos.js';

let tmp;
beforeEach(async () => { tmp = await mkdtemp(join(tmpdir(), 'jarvis-ig-')); });
afterEach(async () => { await rm(tmp, { recursive: true, force: true }); });
const op = (f) => ({ token: 'T', igUserId: '178', versao: 'v23.0', fetch: f });

test('descobrirPerfil monta a consulta e converte', async () => {
  const f = criarFetchFalso([{ contem: 'business_discovery.username(navalhadeouro)', json: fixture('instagram-perfil') }]);
  const p = await descobrirPerfil('navalhadeouro', op(f));
  assert.match(f.chamadas[0].url, /graph\.facebook\.com\/v23\.0\/178\?fields=/);
  assert.match(f.chamadas[0].url, /access_token=T/);
  assert.equal(p.usuario, 'navalhadeouro'); assert.equal(p.seguidores, 4200); assert.equal(p.totalPosts, 310);
  assert.equal(p.nome, 'Navalha de Ouro Barbearia'); assert.match(p.bio, /Campinas/);
  assert.ok(p.midias.some((m) => m.tipo === 'video'));
  assert.ok(p.midias.every((m) => m.url));
  assert.equal(p.midias.length, 4, 'o reel sem download é ignorado');
  assert.equal(p.midias.find((m) => m.legenda === 'Antes e depois').tipo, 'foto', 'carrossel vira foto');
  assert.deepEqual(Object.keys(p.midias[0]).sort(), ['curtidas', 'data', 'legenda', 'link', 'tipo', 'url']);
});

test('@ com caractere estranho não chama a API', async () => {
  const f = criarFetchFalso([]);
  assert.equal(await descobrirPerfil('barbearia x!', op(f)), null);
  assert.equal(f.chamadas.length, 0);
  const g = criarFetchFalso([{ contem: 'username(navalha.ouro)', json: fixture('instagram-perfil') }]);
  assert.ok(await descobrirPerfil('@Navalha.Ouro', op(g)));
});

test('conta pessoal devolve null e token vencido avisa', async () => {
  const f110 = criarFetchFalso([{ contem: 'graph.facebook.com', status: 400, json: fixture('instagram-erro-110') }]);
  assert.equal(await descobrirPerfil('pessoal', op(f110)), null);
  const f190 = criarFetchFalso([{ contem: 'graph.facebook.com', status: 400, json: fixture('instagram-erro-190') }]);
  await assert.rejects(descobrirPerfil('x', op(f190)), (e) => e.codigo === 190 && /venceu/.test(e.message));
});

test('candidatosDeUsuario', () => {
  const c = candidatosDeUsuario({ nome: 'Barbearia Navalha de Ouro', nicho: 'barbearia', cidade: 'Campinas', site: 'https://instagram.com/navalha.oficial' });
  assert.equal(c[0], 'navalha.oficial');
  for (const u of ['barbearianavalhaouro', 'barbearia.navalhaouro', 'barbearia_navalhaouro', 'navalhaouro', 'navalhaouro.campinas']) assert.ok(c.includes(u), u);
  assert.ok(c.length <= 8 && new Set(c).size === c.length);
  assert.ok(c.every((u) => /^[a-z0-9._]{1,30}$/.test(u)));
});

test('candidatos de nome só com o nicho não ficam vazios', () => {
  const c = candidatosDeUsuario({ nome: 'Barbearia', nicho: 'barbearia', cidade: 'São José dos Campos' });
  assert.ok(c.includes('barbearia')); assert.ok(c.length >= 1);
});

test('encontrarInstagram para no primeiro candidato confiável', async () => {
  const chamados = [];
  const descobrir = async (u) => { chamados.push(u); return u === 'navalhaouro' ? { usuario: u, nome: 'Navalha de Ouro Barbearia', bio: 'Barbearia em Campinas', midias: [] } : null; };
  const r = await encontrarInstagram({ nome: 'Barbearia Navalha de Ouro', nicho: 'barbearia', cidade: 'Campinas' }, { descobrir });
  assert.equal(r[0].usuario, 'navalhaouro'); assert.ok(r[0].confianca >= 0.8); assert.equal(chamados.at(-1), 'navalhaouro');
});

test('perfil de outro negócio tem confiança baixa', async () => {
  const descobrir = async (u) => (u === 'barbearianavalhaouro' ? { usuario: u, nome: 'Loja de Roupas', bio: 'Moda em Recife', midias: [] } : null);
  const r = await encontrarInstagram({ nome: 'Barbearia Navalha de Ouro', nicho: 'barbearia', cidade: 'Campinas' }, { descobrir });
  assert.ok(r[0].confianca < 0.5);
});

test('o @ que veio do Google ganha confiança extra', async () => {
  const descobrir = async (u) => (u === 'navalha.oficial' ? { usuario: u, nome: 'Navalha de Ouro', bio: 'Campinas', midias: [] } : null);
  const r = await encontrarInstagram({ nome: 'Barbearia Navalha de Ouro', nicho: 'barbearia', cidade: 'Campinas', site: 'https://instagram.com/navalha.oficial' }, { descobrir });
  assert.equal(r[0].usuario, 'navalha.oficial'); assert.equal(r[0].confianca, 1);
});

test('baixarMidiasInstagram baixa as mais curtidas e um vídeo só', async () => {
  const f = criarFetchFalso([{ contem: 'cdninstagram', bytes: Buffer.from([1]) }]);
  const ms = await baixarMidiasInstagram(perfilComMidias(15, 2), tmp, { fetch: f, maxFotos: 12 });
  assert.equal(ms.filter((m) => m.tipo === 'foto').length, 12); assert.equal(ms.filter((m) => m.tipo === 'video').length, 1);
  assert.ok(ms.every((m) => m.credito === '@navalhadeouro' && m.origem === 'instagram'));
  assert.ok(ms.every((m) => existsSync(m.arquivo)));
  const urls = f.chamadas.map((c) => c.url);
  assert.ok(!urls.some((u) => u.endsWith('/f0.jpg') || u.endsWith('/f1.jpg') || u.endsWith('/f2.jpg')), 'as 3 menos curtidas ficam de fora');
  assert.ok(urls.some((u) => u.endsWith('/v1.mp4')) && !urls.some((u) => u.endsWith('/v0.mp4')), 'o vídeo mais recente');
});

test('download que falha é pulado com aviso', async () => {
  const f = criarFetchFalso([{ contem: '/f14.jpg', status: 404, json: {} }, { contem: 'cdninstagram', bytes: Buffer.from([1]) }]);
  const avisos = [];
  const ms = await baixarMidiasInstagram(perfilComMidias(15, 0), tmp, { fetch: f, maxFotos: 12, aoAvisar: (a) => avisos.push(a) });
  assert.equal(ms.length, 11); assert.equal(avisos.length, 1);
});

test('servicos.instagram só existe com token e id da conta', () => {
  assert.equal(criarServicos({ chaves: { meta: 'T' } }, {}).instagram, null);
  const s = criarServicos({ chaves: { meta: 'T', metaIgUserId: '178' }, metaVersao: 'v23.0' }, {});
  assert.equal(typeof s.instagram.descobrir, 'function'); assert.equal(typeof s.instagram.baixarMidias, 'function');
});
