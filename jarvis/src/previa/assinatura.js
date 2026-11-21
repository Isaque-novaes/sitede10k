import { TOPOS, SECOES, VARIANTES, MOVIMENTOS, FONTES } from '../../kit/catalogo.js';
import { distanciaRgb, derivarPaleta, ajustarContraste, luminancia, contraste } from './cores.js';
import { normalizar } from '../util/slug.js';

const LIMITE_PALETA_IGUAL = 40;
const DIFERENCAS_MINIMAS_MESMO_LUGAR = 3;
const TENTATIVAS = 300;

/** @param {import('./tipos.js').Assinatura} a */
export function partesAssinatura(a) {
  return {
    topo: a.topo,
    fontes: a.fontes,
    movimento: a.movimento,
    secoes: a.secoes.map((s) => `${s.tipo}:${s.variante}`).join('|'),
    paleta: a.paleta,
  };
}

/** Iguais quando fundo, texto e destaque estão, cada um, a no máximo 40 de distância. Paleta ausente nunca é igual. */
export function paletasIguais(p1, p2) {
  if (!p1 || !p2) return false;
  return ['fundo', 'texto', 'destaque'].every((k) => distanciaRgb(p1[k], p2[k]) <= LIMITE_PALETA_IGUAL);
}

/** Quantas das 5 partes são diferentes (0 a 5). */
export function contarDiferencas(a, b) {
  const pa = partesAssinatura(a);
  const pb = partesAssinatura(b);
  let n = 0;
  for (const k of ['topo', 'fontes', 'movimento', 'secoes']) if (pa[k] !== pb[k]) n++;
  if (!paletasIguais(pa.paleta, pb.paleta)) n++;
  return n;
}

const mesmoLugar = (u, alvo) => normalizar(u.nicho) === normalizar(alvo.nicho) && normalizar(u.cidade) === normalizar(alvo.cidade);

/**
 * @param {import('./tipos.js').Assinatura} candidata
 * @param {import('./tipos.js').AssinaturaUsada[]} usadas
 * @param {{nicho:string, cidade:string}} alvo
 */
export function ehUnica(candidata, usadas, alvo) {
  for (const u of usadas) {
    const d = contarDiferencas(candidata, u.assinatura);
    if (d === 0) return false;
    if (mesmoLugar(u, alvo) && d < DIFERENCAS_MINIMAS_MESMO_LUGAR) return false;
  }
  return true;
}

/**
 * Topos e tipos de seção que o material e os dados do negócio permitem.
 * @param {{fotos:{largura:number}[], video:any, negocio:any, textos:any}} contexto
 */
export function opcoesPossiveis(contexto) {
  const fotos = contexto.fotos ?? [];
  const topos = TOPOS.filter(({ requisitos: r }) => {
    if (r.video && !contexto.video) return false;
    return fotos.filter((f) => f.largura >= r.larguraMin).length >= r.fotos;
  }).map((t) => t.id);
  const secoes = SECOES.filter((s) => s.requisitos(contexto)).map((s) => s.tipo);
  return { topos, secoes };
}

const PESO_COMPATIVEL = 8;
const PESO_REEL_NO_TOPO = 30;

function sortearComPeso(itens, clima, aleatorio, pesoExtra = () => 0) {
  const pesos = itens.map((i) => pesoExtra(i) || (i.etiquetas.some((e) => clima.includes(e)) ? PESO_COMPATIVEL : 1));
  let r = aleatorio() * pesos.reduce((a, b) => a + b, 0);
  for (let i = 0; i < itens.length; i++) {
    r -= pesos[i];
    if (r < 0) return itens[i];
  }
  return itens.at(-1);
}

const sortear = (lista, aleatorio) => lista[Math.floor(aleatorio() * lista.length)];

function embaralhar(lista, aleatorio) {
  const copia = [...lista];
  for (let i = copia.length - 1; i > 0; i--) {
    const j = Math.floor(aleatorio() * (i + 1));
    [copia[i], copia[j]] = [copia[j], copia[i]];
  }
  return copia;
}

function montarSecoes(possiveis, aleatorio) {
  const semFim = possiveis.filter((t) => t !== 'chamada-final');
  const iniciais = semFim.filter((t) => t === 'servicos' || t === 'sobre');
  const primeira = iniciais.length ? sortear(iniciais, aleatorio) : semFim[0];
  const meio = embaralhar(semFim.filter((t) => t !== primeira), aleatorio);
  const ordem = [primeira, ...meio, 'chamada-final'].filter(Boolean);
  return ordem.map((tipo) => ({ tipo, variante: sortear(VARIANTES, aleatorio) }));
}

function trocarDestaque(p, cor) {
  return { ...p, destaque: ajustarContraste(cor, p.fundo, 3), destaque2: ajustarContraste(p.destaque, p.fundo, 3) };
}

/** Paleta base, depois destaques trocados, depois o fundo oposto (claro/escuro) com as mesmas trocas. */
function variantesDePaleta(base, extras, clima) {
  const lista = [base, ...extras.map((c) => trocarDestaque(base, c))];
  const oposto = luminancia(base.fundo) < 0.4 ? 'claro' : 'escuro';
  const invertida = derivarPaleta([base.superficie, base.destaque, base.destaque2, ...extras], clima, oposto);
  lista.push(invertida, ...extras.map((c) => trocarDestaque(invertida, c)));
  return lista;
}

/**
 * Escolhe uma assinatura única por regras (sem IA).
 * @param {{fotos:import('./tipos.js').FotoTratada[], video:any, negocio:import('./tipos.js').Negocio, textos:import('./tipos.js').TextosPrevia}} contexto
 * @param {import('./tipos.js').Paleta} paletaBase
 * @param {string[]} coresExtras
 * @param {import('./tipos.js').AssinaturaUsada[]} usadas
 * @param {() => number} aleatorio
 * @returns {import('./tipos.js').Assinatura}
 */
export function escolherAssinaturaPorRegras(contexto, paletaBase, coresExtras, usadas, aleatorio) {
  const clima = contexto.negocio?.clima ?? [];
  const alvo = { nicho: contexto.negocio?.nicho ?? '', cidade: contexto.negocio?.cidade ?? '' };
  const { topos, secoes } = opcoesPossiveis(contexto);
  const paletas = variantesDePaleta(paletaBase, coresExtras ?? [], clima);

  const toposPossiveis = TOPOS.filter((t) => topos.includes(t.id));
  const reelNoTopo = (t) => (t.id === 'video-fundo' && contexto.video ? PESO_REEL_NO_TOPO : 0);
  const nova = () => ({
    topo: sortearComPeso(toposPossiveis, clima, aleatorio, reelNoTopo).id,
    fontes: sortearComPeso(FONTES, clima, aleatorio).id,
    movimento: sortearComPeso(MOVIMENTOS, clima, aleatorio).id,
    secoes: montarSecoes(secoes, aleatorio),
    paleta: paletas[0],
  });

  let indicePaleta = 0;
  let candidata = nova();
  for (let t = 0; t < TENTATIVAS; t++) {
    if (ehUnica(candidata, usadas, alvo)) return candidata;
    const falhaSoPelaPaleta = ehUnica({ ...candidata, paleta: null }, usadas, alvo);
    if (falhaSoPelaPaleta && indicePaleta < paletas.length - 1) {
      indicePaleta++;
      candidata = { ...candidata, paleta: paletas[indicePaleta] };
    } else {
      indicePaleta = 0;
      candidata = nova();
    }
  }
  const erro = new Error('Não encontrei uma combinação de design que ainda não tenha sido usada.');
  erro.code = 'SEM_COMBINACAO_UNICA';
  throw erro;
}

const HEX = /^#[0-9a-f]{6}$/i;
const CHAVES_PALETA = ['fundo', 'superficie', 'texto', 'textoSuave', 'destaque', 'destaque2'];
const CONTRASTE_MINIMO = { texto: 7, textoSuave: 4.5, destaque: 3, destaque2: 3 };

/**
 * Confere uma assinatura vinda de fora (por exemplo, sugerida pela IA) contra o catálogo e as regras do kit.
 * @returns {{ok:boolean, motivos:string[]}}
 */
export function validarAssinatura(a, contexto) {
  const motivos = [];
  if (!a || typeof a !== 'object') return { ok: false, motivos: ['assinatura vazia'] };
  const possiveis = opcoesPossiveis(contexto);
  if (!possiveis.topos.includes(a.topo)) motivos.push(`topo "${a.topo}" não serve para este material`);
  if (!FONTES.some((f) => f.id === a.fontes)) motivos.push(`fontes "${a.fontes}" não existem no kit`);
  if (!MOVIMENTOS.some((m) => m.id === a.movimento)) motivos.push(`movimento "${a.movimento}" não existe no kit`);

  const secoes = Array.isArray(a.secoes) ? a.secoes : [];
  if (!secoes.length) motivos.push('sem seções');
  for (const s of secoes) {
    if (!SECOES.some((d) => d.tipo === s?.tipo) || !VARIANTES.includes(s?.variante)) motivos.push(`seção "${s?.tipo}-${s?.variante}" não existe no kit`);
  }
  const tipos = secoes.map((s) => s?.tipo);
  if (new Set(tipos).size !== tipos.length) motivos.push('seção repetida');
  if (tipos.length && tipos.at(-1) !== 'chamada-final') motivos.push('a última seção precisa ser a chamada final');
  const iniciais = tipos.filter((t) => (t === 'servicos' || t === 'sobre') && possiveis.secoes.includes(t));
  if (iniciais.length && !['servicos', 'sobre'].includes(tipos[0])) motivos.push('a primeira seção precisa ser serviços ou sobre');

  const p = a.paleta ?? {};
  const coresValidas = CHAVES_PALETA.every((k) => typeof p[k] === 'string' && HEX.test(p[k]));
  if (!coresValidas) motivos.push('paleta com cor inválida');
  else {
    for (const [k, minimo] of Object.entries(CONTRASTE_MINIMO)) {
      if (contraste(p[k], p.fundo) < minimo) motivos.push(`contraste de ${k} abaixo de ${minimo}:1`);
    }
  }
  return { ok: motivos.length === 0, motivos };
}
