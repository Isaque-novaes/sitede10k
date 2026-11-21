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

/** Perfil do Instagram com `fotos` fotos e `videos` vídeos (curtidas e datas diferentes). */
export function perfilComMidias(fotos, videos) {
  const midias = [];
  for (let i = 0; i < fotos; i++) midias.push({ tipo: 'foto', url: `https://scontent.cdninstagram.com/v/f${i}.jpg`, legenda: `Foto ${i}`, data: new Date(Date.UTC(2026, 10, 1 + i)).toISOString(), curtidas: i * 10, link: `https://www.instagram.com/p/F${i}/` });
  for (let i = 0; i < videos; i++) midias.push({ tipo: 'video', url: `https://scontent.cdninstagram.com/v/v${i}.mp4`, legenda: `Vídeo ${i}`, data: new Date(Date.UTC(2026, 9, 1 + i)).toISOString(), curtidas: 5, link: `https://www.instagram.com/reel/V${i}/` });
  return { usuario: 'navalhadeouro', nome: 'Navalha de Ouro', bio: 'Barbearia em Campinas', seguidores: 4200, totalPosts: fotos + videos, midias };
}

// ---------- IA: dublês e dados ----------
import { mkdtempSync, writeFileSync } from 'node:fs';

const JPEG_PEQUENO = Buffer.from('/9j/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAAwAEADASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAb/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCbARF8AAAAAAAAAAAAAAAAAAAAAB//2Q==', 'base64');

/** Gemini falso que sempre devolve o objeto. */
export const geminiQueDevolve = (obj) => ({ chamadas: [], async gerarJson(pedido) { this.chamadas.push(pedido); return structuredClone(obj); } });
/** Gemini falso que sempre lança o erro. */
export const geminiQueLanca = (erro) => ({ async gerarJson() { throw erro; } });

/** n mídias de foto com arquivos JPEG reais (pequenos). */
export function fotosFalsasMidia(n, origem) {
  const pasta = mkdtempSync(join(tmpdir(), 'jarvis-midia-'));
  return Array.from({ length: n }, (_, i) => {
    const arquivo = join(pasta, `${origem}-${i}.jpg`);
    writeFileSync(arquivo, JPEG_PEQUENO);
    return { arquivo, tipo: 'foto', origem, credito: origem === 'instagram' ? '@navalhadeouro' : 'Foto: Google Maps' };
  });
}
export const videoMidia = { arquivo: join(tmpdir(), 'reel-falso.mp4'), tipo: 'video', origem: 'instagram', credito: '@navalhadeouro' };

export const registro = {
  ...registroSemSite,
  horarios: ['segunda-feira: 09:00–19:00'],
  avaliacoes: [{ autor: 'Rafael M.', nota: 5, texto: 'Corte impecável e atendimento sem pressa.' }, { autor: 'Lucas A.', nota: 5, texto: 'Melhor barba de Campinas.' }],
};
export const diagnostico = {
  data: '2026-11-21T12:00:00.000Z', temSite: false, nota: 4.8, totalAvaliacoes: 230,
  concorrentes: { total: 4, comSite: 2, melhorComSite: 'Barber Club' },
  achadoPrincipal: 'Barber Club, aqui perto, já tem site e aparece melhor no Google.',
  resumo: 'Barber Club, aqui perto, já tem site e aparece melhor no Google. Com nota 4,8 e 230 avaliações, vocês já têm o que mostrar.',
};
export const textosIA = {
  titulo: 'Seu corte, do seu jeito', subtitulo: 'Barbearia no Cambuí com hora marcada',
  servicos: [{ nome: 'Corte', descricao: 'Tesoura e máquina.' }, { nome: 'Barba', descricao: 'Toalha quente.' }, { nome: 'Combo', descricao: 'Corte e barba.' }],
  sobre: 'Atendimento sem pressa no Cambuí.',
  perguntas: [{ pergunta: 'Precisa agendar?', resposta: 'Sim, pelo WhatsApp.' }, { pergunta: 'Atendem crianças?', resposta: 'Sim.' }],
  chamada: 'Agende seu horário',
};
export const contexto = {
  fotos: Array.from({ length: 6 }, () => ({ largura: 2000, altura: 1333 })), video: null,
  negocio: { ...registro, clima: ['urbano', 'classico'], midias: [] }, textos: textosIA,
};

// ---------- GitHub falso ----------
import { mkdir as mkdirP, writeFile as writeFileP } from 'node:fs/promises';

/** Rotas da Git Data API. `arvore` = caminhos que já existem no repositório. */
export function rotasGitHub({ arvore = [], status = 200 } = {}) {
  let blobs = 0;
  return [
    { metodo: 'GET', contem: '/git/ref/heads/', status, json: { ref: 'refs/heads/main', object: { sha: 'commit-atual', type: 'commit' } } },
    { metodo: 'GET', contem: '/git/commits/commit-atual', json: { sha: 'commit-atual', tree: { sha: 'arvore-base' } } },
    { metodo: 'GET', contem: '/git/trees/arvore-base', json: { sha: 'arvore-base', truncated: false, tree: arvore.map((path) => ({ path, mode: '100644', type: 'blob', sha: `s-${path}` })) } },
    { metodo: 'POST', contem: '/git/blobs', responder: () => Response.json({ sha: `blob-${++blobs}` }, { status: 201 }) },
    { metodo: 'POST', contem: '/git/trees', json: { sha: 'arvore-nova' } },
    { metodo: 'POST', contem: '/git/commits', json: { sha: 'commit-novo' } },
    { metodo: 'PATCH', contem: '/git/refs/heads/', json: { ref: 'refs/heads/main', object: { sha: 'commit-novo' } } },
  ];
}
export const fetchGitHubFalso = (opcoes) => criarFetchFalso(rotasGitHub(opcoes));

/** Escreve uma prévia mínima: index.html, 2 mídias e uma captura de conferência. */
export async function escreverPrevia(pasta) {
  await mkdirP(join(pasta, 'midias'), { recursive: true });
  await mkdirP(join(pasta, 'conferencia'), { recursive: true });
  await writeFileP(join(pasta, 'index.html'), '<!doctype html><title>x</title>');
  await writeFileP(join(pasta, 'midias', 'a.webp'), Buffer.from([1, 2]));
  await writeFileP(join(pasta, 'midias', 'b.webp'), Buffer.from([3, 4]));
  await writeFileP(join(pasta, 'conferencia', 'pc.png'), Buffer.from([5]));
}

export const URL_PREVIA = 'https://isaque.github.io/previas/x-1a2b/';
export const abordagemIA = {
  primeira: `Oi, tudo bem? Sou o Isaque, do Estúdio Dez. Vi que a Barber Club, aqui perto, já tem site. Montei uma amostra de como poderia ficar o de vocês: ${URL_PREVIA} Posso te mostrar como funciona? Isaque`,
  acompanhamento1: `Oi! Conseguiu ver a amostra do site? ${URL_PREVIA} Isaque`,
  acompanhamento2: `Oi! Não quero incomodar. Se um dia quiserem o site, a amostra continua aqui: ${URL_PREVIA} Isaque`,
  objecoes: {
    caro: 'Entendo. O site se paga com poucos clientes novos por mês.', tenho_instagram: 'O Instagram é ótimo, e o site ajuda quem procura no Google.',
    vou_pensar: 'Claro, fique à vontade.', sem_tempo: 'Eu cuido de tudo, você só aprova.', sobrinho_faz: 'Que bom ter ajuda em casa.',
    ja_tenho_site: 'Posso mostrar o que dá para melhorar.', ja_tenho_clientes: 'Ótimo, o site ajuda a manter a agenda cheia.',
  },
};
