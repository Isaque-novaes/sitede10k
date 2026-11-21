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
