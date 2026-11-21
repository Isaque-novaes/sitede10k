import { provavelCelular } from '../util/whatsapp.js';
import { identificarNicho } from '../previa/textos-base.js';

const REDES_SOCIAIS = ['instagram.com', 'facebook.com', 'fb.com', 'linktr.ee', 'wa.me', 'api.whatsapp.com', 'beacons.ai', 'bio.link', 'linkbio'];

function hostDe(site) {
  try {
    return new URL(/^https?:\/\//i.test(site) ? site : `https://${site}`).hostname.toLowerCase();
  } catch {
    return String(site).toLowerCase();
  }
}

/**
 * @param {string|undefined} site
 * @param {import('./tipos.js').ResultadoSite} [resultado]
 * @returns {import('./tipos.js').Presenca}
 */
export function classificarPresenca(site, resultado) {
  if (!site) return 'sem_site';
  const host = hostDe(site);
  if (REDES_SOCIAIS.some((r) => host === r || host.endsWith(`.${r}`) || host.includes(r))) return 'so_rede_social';
  if (resultado && (resultado.desempenho < 50 || !resultado.https)) return 'site_fraco';
  return 'site_ok';
}

const ROTAS_DO_INSTAGRAM = new Set(['p', 'reel', 'reels', 'stories', 'explore', 'tv', 'accounts']);

/** "https://www.instagram.com/barbeariax/?hl=pt" -> "barbeariax"; qualquer outra coisa -> null. */
export function usuarioDoInstagramNoSite(site) {
  if (!site) return null;
  const m = String(site).match(/instagram\.com\/([A-Za-z0-9._]+)/i);
  if (!m || ROTAS_DO_INSTAGRAM.has(m[1].toLowerCase())) return null;
  return m[1].toLowerCase();
}

const BASE_PRIORIDADE = { sem_site: 300, so_rede_social: 250, site_fraco: 150, site_ok: 0 };

/** Quanto maior, melhor oportunidade. */
export function calcularPrioridade({ presenca, nota, totalAvaliacoes }) {
  let p = BASE_PRIORIDADE[presenca] ?? 0;
  p += Math.min(totalAvaliacoes ?? 0, 500) / 5;
  if (typeof nota === 'number') p += (nota - 4) * 40;
  return Math.round(p);
}

/**
 * @param {import('./tipos.js').Lugar} lugar
 * @param {{nicho:string}} busca
 * @returns {import('./tipos.js').Registro}
 */
export function lugarParaRegistro(lugar, { nicho }, agora = new Date()) {
  const presenca = classificarPresenca(lugar.site);
  return {
    ...lugar,
    nicho: identificarNicho(nicho),
    presenca,
    prioridade: calcularPrioridade({ presenca, nota: lugar.nota, totalAvaliacoes: lugar.totalAvaliacoes }),
    whatsappProvavel: provavelCelular(lugar.telefone),
    etapa: 'encontrado',
    datas: { encontrado: agora.toISOString() },
    acompanhamentos: 0,
    naoContatar: false,
    notas: '',
    historico: [],
  };
}
