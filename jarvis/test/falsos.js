// Fetch falso e fábricas compartilhadas pelos testes do plano 2. Só para testes.
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const PASTA_FIXTURES = join(dirname(fileURLToPath(import.meta.url)), 'fixtures', 'apis');

/** Lê test/fixtures/apis/{nome}.json */
export function fixture(nome) {
  return JSON.parse(readFileSync(join(PASTA_FIXTURES, `${nome}.json`), 'utf8'));
}

function cabecalhosComoObjeto(cabecalhos) {
  if (!cabecalhos) return {};
  if (cabecalhos instanceof Headers) return Object.fromEntries(cabecalhos.entries());
  return { ...cabecalhos };
}

/**
 * Fetch falso: a primeira rota cuja `contem` está na URL (e cujo método bate) responde.
 * Guarda as chamadas em `fetch.chamadas`.
 */
export function criarFetchFalso(rotas) {
  const chamadas = [];
  const falso = async (entrada, init = {}) => {
    const url = String(entrada);
    const metodo = (init.method ?? 'GET').toUpperCase();
    chamadas.push({ metodo, url, cabecalhos: cabecalhosComoObjeto(init.headers), corpo: init.body });
    const rota = rotas.find((r) => url.includes(r.contem) && (!r.metodo || r.metodo.toUpperCase() === metodo));
    if (!rota) throw new Error(`rota não gravada: ${metodo} ${url}`);
    if (typeof rota.responder === 'function') return rota.responder({ url, metodo, corpo: init.body });
    const status = rota.status ?? 200;
    if (rota.bytes) return new Response(rota.bytes, { status, headers: { 'content-type': 'application/octet-stream' } });
    const json = rota.arquivo ? fixture(rota.arquivo) : (rota.json ?? {});
    return new Response(JSON.stringify(json), { status, headers: { 'content-type': 'application/json' } });
  };
  falso.chamadas = chamadas;
  return falso;
}

// ---------- Ambientes de teste do plano 2 ----------
import { mkdtemp } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { criarLoja } from '../src/dados/loja.js';
import { criarServicos } from '../src/externo/servicos.js';

/** Loja temporária + serviços com o Google respondendo as fixtures de busca e PageSpeed. */
export async function ambienteBusca({ pagespeedStatus = 200, chaves = { google: 'K' }, rotasExtras = [] } = {}) {
  const pasta = await mkdtemp(join(tmpdir(), 'jarvis-amb-'));
  const loja = criarLoja(join(pasta, 'dados'));
  const f = criarFetchFalso([
    ...rotasExtras,
    { metodo: 'POST', contem: 'places:searchText', arquivo: 'places-busca' },
    { contem: 'runPagespeed', status: pagespeedStatus, arquivo: 'pagespeed-lento' },
  ]);
  const servicos = criarServicos({ chaves }, { fetch: f });
  return { pasta, loja, servicos, f };
}

/** Registro de um negócio sem site, como sai da busca. */
export const registroSemSite = {
  id: 'sem-site-1', nome: 'Barbearia Navalha de Ouro', endereco: 'R. Maria Monteiro, 820 - Cambuí, Campinas - SP', bairro: 'Cambuí', cidade: 'Campinas',
  local: { lat: -22.8953, lng: -47.0523 }, tipos: ['barber_shop'], tipoPrincipal: 'Barbearia', situacao: 'OPERATIONAL',
  mapsUrl: 'https://maps.google.com/?cid=1', telefone: '(19) 99876-5432', telefoneInternacional: '+55 19 99876-5432',
  nota: 4.8, totalAvaliacoes: 230, nicho: 'barbearia', presenca: 'sem_site', prioridade: 378, whatsappProvavel: true,
  etapa: 'encontrado', datas: { encontrado: '2026-11-20T12:00:00.000Z' }, acompanhamentos: 0, naoContatar: false, notas: '', historico: [],
};

/** Loja + serviços com as fixtures de detalhes e concorrentes. */
export async function ambienteDiagnostico({ concorrentes } = {}) {
  const rotas = [
    { metodo: 'POST', contem: 'places:searchText', json: concorrentes ? { places: concorrentes } : fixture('places-concorrentes') },
    { contem: '/v1/places/sem-site-1', arquivo: 'places-detalhes' },
  ];
  return ambienteBusca({ rotasExtras: rotas });
}
