import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buscarLugares } from '../src/externo/google-places.js';
import { classificarPresenca, usuarioDoInstagramNoSite, calcularPrioridade, lugarParaRegistro } from '../src/prospeccao/classificar.js';
import { criarServicos } from '../src/externo/servicos.js';
import { criarFetchFalso, fixture } from './falsos.js';

test('buscarLugares manda máscara, corpo e chave e converte', async () => {
  const f = criarFetchFalso([{ metodo: 'POST', contem: 'places:searchText', json: fixture('places-busca') }]);
  const lugares = await buscarLugares('barbearias em Campinas', { chave: 'K', fetch: f });
  const { cabecalhos, corpo } = f.chamadas[0];
  assert.equal(cabecalhos['X-Goog-Api-Key'], 'K');
  assert.match(cabecalhos['X-Goog-FieldMask'], /places\.websiteUri/);
  assert.deepEqual(JSON.parse(corpo), { textQuery: 'barbearias em Campinas', languageCode: 'pt-BR', regionCode: 'BR', pageSize: 20 });
  assert.equal(lugares.length, 6); assert.equal(lugares[0].bairro, 'Cambuí'); assert.equal(lugares[0].cidade, 'Campinas');
  assert.deepEqual(lugares[0].local, { lat: -22.8953, lng: -47.0523 });
  assert.equal(lugares[0].nome, 'Barbearia Navalha de Ouro'); assert.equal(lugares[0].telefone, '(19) 99876-5432');
  assert.equal(lugares[0].tipoPrincipal, 'Barbearia'); assert.equal(lugares[0].situacao, 'OPERATIONAL');
  assert.equal(lugares[1].site, 'https://www.instagram.com/cortefino.studio/');
});

test('resposta sem lugares devolve lista vazia', async () => {
  const f = criarFetchFalso([{ metodo: 'POST', contem: 'places:searchText', json: {} }]);
  assert.deepEqual(await buscarLugares('nada', { chave: 'K', fetch: f }), []);
});

test('concorrentes mandam locationBias de 2 km', async () => {
  const f = criarFetchFalso([{ metodo: 'POST', contem: 'places:searchText', json: { places: [] } }]);
  await buscarLugares('barbearia', { chave: 'K', fetch: f, local: { lat: -22.9, lng: -47.06 }, quantidade: 10 });
  const corpo = JSON.parse(f.chamadas[0].corpo);
  assert.deepEqual(corpo.locationBias, { circle: { center: { latitude: -22.9, longitude: -47.06 }, radius: 2000 } });
  assert.equal(corpo.pageSize, 10);
});

test('classificarPresenca', () => {
  assert.equal(classificarPresenca(undefined), 'sem_site');
  for (const s of ['https://instagram.com/x', 'https://linktr.ee/x', 'https://wa.me/5519', 'http://facebook.com/x', 'https://api.whatsapp.com/send?phone=1', 'https://beacons.ai/x', 'https://bio.link/x', 'https://linkbio.co/x', 'https://m.facebook.com/x']) {
    assert.equal(classificarPresenca(s), 'so_rede_social', s);
  }
  assert.equal(classificarPresenca('https://x.com.br', { desempenho: 35, lcpMs: 9000, https: true }), 'site_fraco');
  assert.equal(classificarPresenca('http://x.com.br', { desempenho: 90, lcpMs: 1000, https: false }), 'site_fraco');
  assert.equal(classificarPresenca('https://x.com.br', { desempenho: 90, lcpMs: 1000, https: true }), 'site_ok');
  assert.equal(classificarPresenca('https://x.com.br'), 'site_ok');
});

test('usuarioDoInstagramNoSite', () => {
  assert.equal(usuarioDoInstagramNoSite('https://www.instagram.com/barbeariax/?hl=pt'), 'barbeariax');
  assert.equal(usuarioDoInstagramNoSite('instagram.com/barbearia.x'), 'barbearia.x');
  assert.equal(usuarioDoInstagramNoSite('https://www.instagram.com/p/Cxyz123/'), null);
  assert.equal(usuarioDoInstagramNoSite('https://linktr.ee/x'), null);
  assert.equal(usuarioDoInstagramNoSite(undefined), null);
});

test('prioridade: sem site e muitas avaliações vem primeiro', () => {
  const a = calcularPrioridade({ presenca: 'sem_site', nota: 4.8, totalAvaliacoes: 230 });
  const b = calcularPrioridade({ presenca: 'site_fraco', nota: 4.9, totalAvaliacoes: 500 });
  const c = calcularPrioridade({ presenca: 'sem_site' });
  assert.ok(a > b && a > c); assert.equal(a, 378);
  assert.equal(calcularPrioridade({ presenca: 'site_ok', nota: 3, totalAvaliacoes: 0 }), -40);
});

test('lugarParaRegistro marca WhatsApp provável e etapa inicial', () => {
  const r = lugarParaRegistro({ id: 'p1', nome: 'X', telefone: '(19) 99876-5432', tipos: [], situacao: 'OPERATIONAL' }, { nicho: 'Barbearia' }, new Date('2026-11-21T10:00:00Z'));
  assert.equal(r.whatsappProvavel, true); assert.equal(r.etapa, 'encontrado'); assert.equal(r.nicho, 'barbearia');
  assert.equal(r.datas.encontrado, '2026-11-21T10:00:00.000Z');
  assert.equal(r.presenca, 'sem_site'); assert.equal(r.acompanhamentos, 0); assert.equal(r.naoContatar, false);
  assert.deepEqual(r.historico, []); assert.equal(r.notas, '');
});

test('fixo não é WhatsApp provável', () => {
  const r = lugarParaRegistro({ id: 'p2', nome: 'Y', telefone: '(19) 3232-1010', tipos: [], situacao: 'OPERATIONAL' }, { nicho: 'barbearia' });
  assert.equal(r.whatsappProvavel, false);
});

test('servicos.places.buscar usa a chave da config', async () => {
  const f = criarFetchFalso([{ metodo: 'POST', contem: 'places:searchText', json: fixture('places-busca') }]);
  const s = criarServicos({ chaves: { google: 'G' } }, { fetch: f });
  assert.equal((await s.places.buscar('x')).length, 6); assert.equal(f.chamadas[0].cabecalhos['X-Goog-Api-Key'], 'G');
});
