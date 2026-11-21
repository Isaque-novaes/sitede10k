import { readFile, mkdir, writeFile, rename } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const RAIZ_PADRAO = join(dirname(fileURLToPath(import.meta.url)), '..');

const PREFERENCIAS_PADRAO = {
  nomeUsuario: '',
  estudio: 'Estúdio Dez',
  whatsappUsuario: '',
  cidadePadrao: '',
  metaSemanal: 10,
  diasAcompanhamento: [3, 7],
  nomeAssistente: 'Jarvis',
  precos: {},
};

/** Lê um arquivo .env simples: CHAVE=valor, ignorando linhas vazias e comentários com #. */
async function lerEnv(arquivo) {
  let texto = '';
  try { texto = await readFile(arquivo, 'utf8'); } catch { return {}; }
  const valores = {};
  for (const linha of texto.split(/\r?\n/)) {
    const limpa = linha.trim();
    if (!limpa || limpa.startsWith('#')) continue;
    const i = limpa.indexOf('=');
    if (i < 1) continue;
    const valor = limpa.slice(i + 1).trim().replace(/^["']|["']$/g, '');
    if (valor) valores[limpa.slice(0, i).trim()] = valor;
  }
  return valores;
}

async function lerJson(arquivo) {
  try { return JSON.parse(await readFile(arquivo, 'utf8')); } catch { return {}; }
}

/**
 * Configuração do Jarvis: chaves do .env (ou do ambiente), preferências do usuário e padrões.
 * @param {{raiz?: string, env?: Record<string,string>}} [opcoes]
 */
export async function carregarConfig({ raiz = RAIZ_PADRAO, env = process.env } = {}) {
  const arquivo = await lerEnv(join(raiz, '.env'));
  const v = (nome) => (env[nome] || arquivo[nome] || undefined);
  const pastaDados = join(raiz, 'dados');
  const preferencias = await lerJson(join(pastaDados, 'config.json'));
  const githubRepo = v('GITHUB_REPO');
  const [dono, repo] = githubRepo ? githubRepo.split('/') : [];
  return {
    raiz,
    pastaDados,
    chaves: {
      google: v('GOOGLE_API_KEY'),
      gemini: v('GEMINI_API_KEY'),
      meta: v('META_TOKEN'),
      metaIgUserId: v('META_IG_USER_ID'),
      pexels: v('PEXELS_API_KEY'),
      github: v('GITHUB_TOKEN'),
    },
    githubRepo,
    githubRamo: v('GITHUB_RAMO') ?? 'main',
    baseUrlPrevias: v('BASE_URL_PREVIAS') ?? (dono && repo ? `https://${dono}.github.io/${repo}` : undefined),
    geminiModelo: v('GEMINI_MODELO') ?? 'gemini-flash-latest',
    geminiReserva: 'gemini-flash-lite-latest',
    metaVersao: v('META_VERSAO') ?? 'v23.0',
    ...PREFERENCIAS_PADRAO,
    ...preferencias,
  };
}

/** Grava preferências do usuário em dados/config.json. Chaves nunca são gravadas aqui. */
export async function salvarPreferencias(config, parcial) {
  const atuais = await lerJson(join(config.pastaDados, 'config.json'));
  const permitidas = Object.fromEntries(Object.entries(parcial).filter(([k]) => k in PREFERENCIAS_PADRAO));
  const novas = { ...atuais, ...permitidas };
  await mkdir(config.pastaDados, { recursive: true });
  const destino = join(config.pastaDados, 'config.json');
  const temporario = `${destino}.${process.pid}.${Math.random().toString(36).slice(2)}.tmp`;
  await writeFile(temporario, JSON.stringify(novas, null, 2), 'utf8');
  await rename(temporario, destino);
  return { ...config, ...novas };
}
