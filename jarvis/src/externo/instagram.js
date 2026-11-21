import { extname, join } from 'node:path';
import { requisitarJson, ErroExterno } from './http.js';
import { baixarArquivo } from './baixar.js';
import { normalizar } from '../util/slug.js';
import { identificarNicho } from '../previa/textos-base.js';
import { usuarioDoInstagramNoSite } from '../prospeccao/classificar.js';

const SERVICO = 'Instagram';
const CAMPOS = 'business_discovery.username({usuario}){username,name,biography,followers_count,media_count,profile_picture_url,media.limit(30){media_type,media_url,thumbnail_url,caption,permalink,timestamp,like_count}}';
const PALAVRAS_VAZIAS = new Set(['de', 'da', 'do', 'das', 'dos', 'e']);
const PARALELO = 4;

/**
 * Lê um perfil comercial de outro negócio pelo Business Discovery (Graph API oficial).
 * Devolve null para conta pessoal ou inexistente.
 */
export async function descobrirPerfil(usuario, { token, igUserId, versao = 'v23.0', fetch, registrar }) {
  const limpo = String(usuario ?? '').trim().replace(/^@/, '').toLowerCase();
  if (!/^[a-z0-9._]{1,30}$/.test(limpo)) return null;
  const campos = encodeURIComponent(CAMPOS.replace('{usuario}', limpo));
  const url = `https://graph.facebook.com/${versao}/${encodeURIComponent(igUserId)}?fields=${campos}&access_token=${encodeURIComponent(token)}`;
  let resposta;
  try {
    resposta = await requisitarJson(url, { servico: SERVICO, fetch, registrar });
  } catch (erro) {
    if (erro instanceof ErroExterno && erro.codigo === 110) return null;
    if (erro instanceof ErroExterno && erro.codigo === 190) {
      throw new ErroExterno(SERVICO, 'A chave da Meta venceu. Renove nas configurações.', { status: erro.status, codigo: 190 });
    }
    throw erro;
  }
  const bd = resposta?.business_discovery;
  if (!bd) return null;
  const midias = (bd.media?.data ?? [])
    .filter((m) => m.media_url)
    .map((m) => ({
      tipo: m.media_type === 'VIDEO' ? 'video' : 'foto',
      url: m.media_url,
      legenda: m.caption ?? '',
      data: m.timestamp ? new Date(m.timestamp).toISOString() : undefined,
      curtidas: m.like_count ?? 0,
      link: m.permalink,
    }));
  return { usuario: bd.username, nome: bd.name ?? '', bio: bd.biography ?? '', seguidores: bd.followers_count ?? 0, totalPosts: bd.media_count ?? 0, midias };
}

const palavrasDe = (texto) => normalizar(texto).split('-').filter((p) => p && !PALAVRAS_VAZIAS.has(p));

function palavrasSemNicho(registro) {
  const palavras = palavrasDe(registro.nome);
  const nicho = registro.nicho && registro.nicho !== 'generico' ? registro.nicho : null;
  return { palavras, semNicho: nicho ? palavras.filter((p) => identificarNicho(p) !== nicho) : palavras };
}

/** Nomes de usuário prováveis do Instagram do negócio (até 8). */
export function candidatosDeUsuario(registro) {
  const { palavras, semNicho } = palavrasSemNicho(registro);
  const cidade = normalizar(registro.cidade ?? '').replace(/-/g, '');
  const lista = [];
  const doSite = usuarioDoInstagramNoSite(registro.site);
  if (doSite) lista.push(doSite);
  if (palavras.length) {
    lista.push(palavras.join(''));
    if (palavras.length > 1) {
      lista.push(`${palavras[0]}.${palavras.slice(1).join('')}`, `${palavras[0]}_${palavras.slice(1).join('')}`);
    }
  }
  if (semNicho.length && semNicho.length < palavras.length) lista.push(semNicho.join(''));
  const base = (semNicho.length ? semNicho : palavras).join('');
  if (base && cidade) lista.push(`${base}.${cidade}`, `${base}${cidade}`);
  if (base) lista.push(`${base}oficial`);
  return [...new Set(lista)].filter((u) => /^[a-z0-9._]{1,30}$/.test(u)).slice(0, 8);
}

function confiancaDoPerfil(registro, perfil, doSite) {
  const { palavras, semNicho } = palavrasSemNicho(registro);
  const alvo = (semNicho.length ? semNicho : palavras).filter((p) => p.length > 2);
  // O @ não entra na conta: ele foi gerado a partir do próprio nome do negócio.
  const nomePerfil = new Set(palavrasDe(perfil.nome ?? ''));
  const emComum = alvo.filter((p) => nomePerfil.has(p)).length;
  let c = alvo.length ? 0.5 * (emComum / alvo.length) : 0;
  const texto = normalizar(`${perfil.bio ?? ''} ${perfil.nome ?? ''}`);
  const lugares = [registro.cidade, registro.bairro].filter(Boolean).map((l) => normalizar(l));
  if (lugares.some((l) => texto.includes(l))) c += 0.3;
  if (doSite) c += 0.2;
  return Math.min(1, Math.round(c * 100) / 100);
}

/**
 * Testa os candidatos no Business Discovery e devolve os perfis achados, do mais provável ao menos.
 * @param {any} registro
 * @param {{descobrir:(usuario:string) => Promise<any>}} deps
 */
export async function encontrarInstagram(registro, { descobrir }) {
  const doSite = usuarioDoInstagramNoSite(registro.site);
  const achados = [];
  for (const usuario of candidatosDeUsuario(registro)) {
    const perfil = await descobrir(usuario);
    if (!perfil) continue;
    const confianca = confiancaDoPerfil(registro, perfil, usuario === doSite);
    achados.push({ usuario, confianca, perfil });
    if (confianca >= 0.8) break;
  }
  return achados.sort((a, b) => b.confianca - a.confianca);
}

/**
 * Baixa as fotos mais curtidas e o vídeo mais recente do perfil.
 * @returns {Promise<import('../previa/tipos.js').Midia[]>}
 */
export async function baixarMidiasInstagram(perfil, pasta, { fetch, registrar, maxFotos = 12, aoAvisar } = {}) {
  const fotos = perfil.midias.filter((m) => m.tipo === 'foto').sort((a, b) => b.curtidas - a.curtidas).slice(0, maxFotos);
  const video = perfil.midias.filter((m) => m.tipo === 'video').sort((a, b) => String(b.data).localeCompare(String(a.data)))[0];
  const tarefas = [
    ...fotos.map((m, i) => ({ m, nome: `ig-foto-${String(i + 1).padStart(2, '0')}${extname(new URL(m.url).pathname) || '.jpg'}` })),
    ...(video ? [{ m: video, nome: `ig-video${extname(new URL(video.url).pathname) || '.mp4'}` }] : []),
  ];
  const resultados = new Array(tarefas.length).fill(null);
  let proxima = 0;
  const trabalhador = async () => {
    while (proxima < tarefas.length) {
      const i = proxima++;
      const { m, nome } = tarefas[i];
      try {
        const arquivo = await baixarArquivo(m.url, join(pasta, nome), { servico: SERVICO, fetch, registrar });
        resultados[i] = { arquivo, tipo: m.tipo, origem: 'instagram', credito: `@${perfil.usuario}` };
      } catch (erro) {
        aoAvisar?.(`Não consegui baixar uma mídia do Instagram: ${erro.message}`);
      }
    }
  };
  await Promise.all(Array.from({ length: Math.min(PARALELO, tarefas.length) }, trabalhador));
  return resultados.filter(Boolean);
}
