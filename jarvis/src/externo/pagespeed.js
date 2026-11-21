import { requisitarJson } from './http.js';

/**
 * Testa a velocidade do site no celular (PageSpeed Insights).
 * @returns {Promise<import('../prospeccao/tipos.js').ResultadoSite>}
 */
export async function testarSite(url, { chave, fetch, registrar }) {
  const params = new URLSearchParams({ url, strategy: 'mobile', category: 'performance', key: chave });
  const r = await requisitarJson(`https://www.googleapis.com/pagespeedonline/v5/runPagespeed?${params}`, {
    servico: 'teste de velocidade do Google', fetch, registrar, tempoLimiteMs: 60000, tentativas: 1,
  });
  const lh = r?.lighthouseResult ?? {};
  return {
    desempenho: Math.round((lh.categories?.performance?.score ?? 0) * 100),
    lcpMs: Math.round(lh.audits?.['largest-contentful-paint']?.numericValue ?? 0),
    https: String(lh.finalUrl ?? url).startsWith('https:'),
  };
}
