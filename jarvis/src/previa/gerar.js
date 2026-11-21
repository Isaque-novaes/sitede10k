import { readdir, rm } from 'node:fs/promises';
import { join } from 'node:path';
import { criarSlug } from '../util/slug.js';
import { tratarMidias } from './midia.js';
import { derivarPaleta, distanciaRgb, hexParaHsl } from './cores.js';
import { textosBase } from './textos-base.js';
import { ehUnica, escolherAssinaturaPorRegras, validarAssinatura } from './assinatura.js';
import { montarPrevia, gravarPrevia } from './montar.js';
import { conferirPrevia } from './conferir.js';

const TENTATIVAS = 3;

/** Cores saturadas das fotos, diferentes do destaque atual, para variar a paleta. */
function coresExtras(cores, paleta) {
  return [...new Set(cores)]
    .filter((c) => hexParaHsl(c)[1] >= 0.2 && distanciaRgb(c, paleta.destaque) > 60)
    .sort((a, b) => hexParaHsl(b)[1] - hexParaHsl(a)[1])
    .slice(0, 4);
}

async function limparTentativa(pasta) {
  await rm(join(pasta, 'index.html'), { force: true });
  await rm(join(pasta, 'conferencia'), { recursive: true, force: true });
}

/** Apaga de `midias/` o que a página final não usa (a pasta vai ser publicada). */
async function limparMidiasNaoUsadas(pasta, montagem) {
  const usadas = new Set(montagem.arquivos.map((a) => a.destino.replace(/^midias\//, '')));
  for (const arquivo of await readdir(join(pasta, 'midias')).catch(() => [])) {
    if (!usadas.has(arquivo)) await rm(join(pasta, 'midias', arquivo), { force: true });
  }
}

/**
 * Pipeline completo de uma prévia: mídias, paleta, textos, assinatura única, montagem e conferência.
 * @param {import('./tipos.js').Negocio} negocio
 * @param {{pastaSaida:string, usadas?:import('./tipos.js').AssinaturaUsada[], textos?:import('./tipos.js').TextosPrevia,
 *   assinatura?:import('./tipos.js').Assinatura, estudio?:string, aleatorio?:() => number, conferir?:boolean,
 *   navegador?:import('playwright-core').Browser, bloquearRede?:boolean}} opcoes
 * @returns {Promise<import('./tipos.js').PreviaGerada & {avisos:string[]}>}
 */
export async function gerarPrevia(negocio, opcoes) {
  const {
    pastaSaida, usadas = [], textos, assinatura, estudio, aleatorio = Math.random,
    conferir = true, navegador, bloquearRede = false, ficticio = false,
  } = opcoes;
  const avisos = [];
  const slug = criarSlug(negocio.nome, aleatorio);
  const pasta = join(pastaSaida, slug);

  const tratadas = await tratarMidias(negocio.midias ?? [], join(pasta, 'midias'));
  avisos.push(...tratadas.avisos);
  const { fotos, video } = tratadas;

  const cores = fotos.flatMap((f) => f.cores.slice(0, 3));
  const paletaBase = derivarPaleta(cores, negocio.clima ?? []);
  const extras = coresExtras(cores, paletaBase);
  const textosFinais = textos ?? textosBase(negocio, aleatorio);
  const contexto = { fotos, video, negocio, textos: textosFinais };
  const alvo = { nicho: negocio.nicho, cidade: negocio.cidade };

  let sugerida = null;
  if (assinatura) {
    const { ok, motivos } = validarAssinatura(assinatura, contexto);
    if (!ok) avisos.push(`A assinatura sugerida não serve (${motivos.join('; ')}). Escolhi outra pelas regras.`);
    else if (!ehUnica(assinatura, usadas, alvo)) avisos.push('A assinatura sugerida já foi usada neste nicho e cidade. Escolhi outra pelas regras.');
    else sugerida = assinatura;
  }

  const usadasNestaChamada = [...usadas];
  let resultado = null;
  let montagemFinal = null;
  for (let tentativa = 1; tentativa <= TENTATIVAS; tentativa++) {
    const escolhida = sugerida ?? escolherAssinaturaPorRegras(contexto, paletaBase, extras, usadasNestaChamada, aleatorio);
    sugerida = null;
    await limparTentativa(pasta);
    const montagem = montarPrevia({ negocio, textos: textosFinais, assinatura: escolhida, fotos, video, opcoes: { estudio, ficticio } });
    await gravarPrevia(pasta, montagem);
    const conferencia = conferir
      ? await conferirPrevia(pasta, { navegador, bloquearRede })
      : { ok: true, problemas: [], capturas: { celular: '', pc: '' } };
    resultado = { slug, pasta, assinatura: escolhida, conferencia, avisos };
    montagemFinal = montagem;
    if (conferencia.ok) break;
    avisos.push(`Tentativa ${tentativa} reprovada na conferência: ${conferencia.problemas.join('; ')}`);
    usadasNestaChamada.push({ assinatura: escolhida, nicho: negocio.nicho, cidade: negocio.cidade });
  }

  await limparMidiasNaoUsadas(pasta, montagemFinal);
  return resultado;
}
