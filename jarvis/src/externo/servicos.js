import { baixarArquivo } from './baixar.js';
import { buscarLugares } from './google-places.js';

/**
 * Monta os serviços externos com a configuração e o fetch já aplicados.
 * Cada serviço é `null` quando falta a chave dele.
 * @param {any} config
 * @param {{fetch?: typeof fetch, registrar?: (evento: object) => void}} [opcoes]
 */
export function criarServicos(config, { fetch = globalThis.fetch, registrar } = {}) {
  const chaves = config.chaves ?? {};
  const base = { fetch, registrar };
  const comChave = (chave, criar) => (chave ? criar() : null);
  return {
    places: comChave(chaves.google, () => {
      const c = { ...base, chave: chaves.google };
      return { ...c, buscar: (texto, opcoes = {}) => buscarLugares(texto, { ...c, ...opcoes }) };
    }),
    pagespeed: comChave(chaves.google, () => ({ ...base, chave: chaves.google })),
    gemini: comChave(chaves.gemini, () => ({ ...base, chave: chaves.gemini })),
    instagram: chaves.meta && chaves.metaIgUserId ? { ...base, token: chaves.meta, igUserId: chaves.metaIgUserId } : null,
    pexels: comChave(chaves.pexels, () => ({ ...base, chave: chaves.pexels })),
    github: chaves.github && config.githubRepo ? { ...base, token: chaves.github, repo: config.githubRepo } : null,
    baixar: (url, destino, servico = 'download') => baixarArquivo(url, destino, { servico, fetch, registrar }),
  };
}
