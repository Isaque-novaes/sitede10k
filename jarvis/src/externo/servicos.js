import { baixarArquivo } from './baixar.js';
import { buscarLugares, detalharLugar, baixarFotoLugar } from './google-places.js';
import { testarSite } from './pagespeed.js';
import { gerarJson } from './gemini.js';
import { descobrirPerfil, baixarMidiasInstagram } from './instagram.js';
import { completarComPexels } from './pexels.js';

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
      return {
        ...c,
        buscar: (texto, opcoes = {}) => buscarLugares(texto, { ...c, ...opcoes }),
        detalhar: (id) => detalharLugar(id, c),
        baixarFoto: (nome, destino) => baixarFotoLugar(nome, destino, c),
      };
    }),
    pagespeed: comChave(chaves.google, () => {
      const c = { ...base, chave: chaves.google };
      return { ...c, testar: (url) => testarSite(url, c) };
    }),
    gemini: comChave(chaves.gemini, () => {
      const c = { ...base, chave: chaves.gemini, modelo: config.geminiModelo ?? 'gemini-flash-latest', reserva: config.geminiReserva ?? 'gemini-flash-lite-latest' };
      return { ...c, gerarJson: (pedido) => gerarJson(pedido, c) };
    }),
    instagram: chaves.meta && chaves.metaIgUserId ? (() => {
      const c = { ...base, token: chaves.meta, igUserId: chaves.metaIgUserId, versao: config.metaVersao ?? 'v23.0' };
      return {
        ...c,
        descobrir: (usuario) => descobrirPerfil(usuario, c),
        baixarMidias: (perfil, pasta, opcoes = {}) => baixarMidiasInstagram(perfil, pasta, { ...c, ...opcoes }),
      };
    })() : null,
    pexels: comChave(chaves.pexels, () => {
      const c = { ...base, chave: chaves.pexels };
      return { ...c, completar: (midias, nicho, pasta, opcoes = {}) => completarComPexels(midias, nicho, pasta, { ...c, ...opcoes }) };
    }),
    github: chaves.github && config.githubRepo ? { ...base, token: chaves.github, repo: config.githubRepo } : null,
    baixar: (url, destino, servico = 'download') => baixarArquivo(url, destino, { servico, fetch, registrar }),
  };
}
