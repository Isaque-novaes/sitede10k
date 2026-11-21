import { test } from 'node:test';
import assert from 'node:assert/strict';
import { testarSite } from '../src/externo/pagespeed.js';
import { buscarNegocios } from '../src/prospeccao/buscar.js';
import { registrarUso, ErroCota } from '../src/dados/uso.js';
import { criarFetchFalso, fixture, ambienteBusca } from './falsos.js';

test('testarSite lê nota, LCP e https', async () => {
  const f = criarFetchFalso([{ contem: 'runPagespeed', json: fixture('pagespeed-lento') }]);
  assert.deepEqual(await testarSite('https://x.com.br', { chave: 'K', fetch: f }), { desempenho: 31, lcpMs: 8400, https: true });
  assert.match(f.chamadas[0].url, /strategy=mobile/); assert.match(f.chamadas[0].url, /category=performance/);
  assert.match(f.chamadas[0].url, /url=https%3A%2F%2Fx\.com\.br/);
});

test('buscarNegocios filtra, testa sites, ordena e salva sem duplicar', async () => {
  const { loja, servicos, f } = await ambienteBusca();
  const r1 = await buscarNegocios({ nicho: 'barbearias', cidade: 'Campinas' }, { loja, servicos });
  assert.equal(JSON.parse(f.chamadas[0].corpo).textQuery, 'barbearias em Campinas');
  assert.equal(r1.novos.length, 5); assert.equal(r1.ignorados.fechados, 1);
  assert.equal(r1.novos[0].presenca, 'sem_site');
  assert.ok(r1.novos.every((n, i, a) => i === 0 || a[i - 1].prioridade >= n.prioridade));
  const prop = r1.novos.find((n) => n.site === 'https://barbeariaprop.com.br');
  assert.equal(prop.presenca, 'site_fraco'); assert.equal(prop.desempenhoSite.desempenho, 31);
  assert.equal(f.chamadas.filter((c) => c.url.includes('runPagespeed')).length, 1, 'só o site próprio é testado');
  assert.match(r1.resumo, /^Encontrei 5 barbearias\. 4 não têm site\. A melhor oportunidade é Barbearia Navalha de Ouro, nota 4,8 com 230 avaliações e sem site\.$/);
  assert.equal((await loja.ler('buscas')).length, 1);
  const r2 = await buscarNegocios({ nicho: 'barbearias', cidade: 'Campinas' }, { loja, servicos });
  assert.equal(r2.novos.length, 0); assert.equal(r2.ignorados.jaConhecidos, 5);
  assert.match(r2.resumo, /Não encontrei negócios novos de barbearias em Campinas/);
  assert.equal((await loja.ler('negocios')).length, 5);
});

test('negócio marcado não contatar nunca volta', async () => {
  const { loja, servicos } = await ambienteBusca();
  await loja.gravar('negocios', [{ id: 'sem-site-1', naoContatar: true }]);
  const r = await buscarNegocios({ nicho: 'barbearias', cidade: 'Campinas' }, { loja, servicos });
  assert.equal(r.ignorados.naoContatar, 1); assert.ok(!r.novos.some((n) => n.id === 'sem-site-1'));
  assert.equal((await loja.ler('negocios')).length, 5);
});

test('PageSpeed fora do ar não derruba a busca', async () => {
  const { loja, servicos } = await ambienteBusca({ pagespeedStatus: 500 });
  const r = await buscarNegocios({ nicho: 'barbearias', cidade: 'Campinas' }, { loja, servicos });
  assert.equal(r.novos.length, 5);
  assert.equal(r.novos.find((n) => n.id === 'site-4').presenca, 'site_ok');
  assert.ok(r.avisos.some((a) => /Barbearia Prop/.test(a)));
});

test('cota esgotada bloqueia a busca com ErroCota', async () => {
  const { loja, servicos } = await ambienteBusca();
  await registrarUso(loja, 'places_busca', 800);
  await assert.rejects(buscarNegocios({ nicho: 'barbearias', cidade: 'Campinas' }, { loja, servicos }), ErroCota);
});

test('a busca conta no limite mensal', async () => {
  const { loja, servicos } = await ambienteBusca();
  await buscarNegocios({ nicho: 'barbearias', cidade: 'Campinas' }, { loja, servicos });
  const uso = await loja.ler('uso');
  assert.equal(Object.values(uso)[0].places_busca, 1);
});

test('sem chave do Google, a busca explica o que falta', async () => {
  const { loja, servicos } = await ambienteBusca({ chaves: {} });
  await assert.rejects(buscarNegocios({ nicho: 'barbearias', cidade: 'Campinas' }, { loja, servicos }), /chave do Google/);
});
