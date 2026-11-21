import { requisitarJson, ErroExterno } from './http.js';

const SERVICO = 'teste de velocidade do Google';

/**
 * Testa a velocidade do site no celular (PageSpeed Insights).
 * @returns {Promise<import('../prospeccao/tipos.js').ResultadoSite>}
 */
export async function testarSite(url, { chave, fetch, registrar }) {
  const params = new URLSearchParams({ url, strategy: 'mobile', category: 'performance', key: chave });
  const r = await requisitarJson(`https://www.googleapis.com/pagespeedonline/v5/runPagespeed?${params}`, {
    servico: SERVICO, fetch, registrar, tempoLimiteMs: 60000, tentativas: 1,
  });
  const lh = r?.lighthouseResult ?? {};
  const nota = lh.categories?.performance?.score;
  // Sem nota (o Lighthouse não conseguiu carregar a página) não é "site lento": é site não testado.
  if (typeof nota !== 'number') throw new ErroExterno(SERVICO, 'O teste de velocidade não conseguiu testar o site.');
  return {
    desempenho: Math.round(nota * 100),
    lcpMs: Math.round(lh.audits?.['largest-contentful-paint']?.numericValue ?? 0),
    https: String(lh.finalUrl ?? url).startsWith('https:'),
  };
}
