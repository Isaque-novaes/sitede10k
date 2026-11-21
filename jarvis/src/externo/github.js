import { readFile, readdir } from 'node:fs/promises';
import { join } from 'node:path';
import { requisitarJson } from './http.js';

const SERVICO = 'GitHub';

function cliente({ token, repo, fetch, registrar }) {
  const base = `https://api.github.com/repos/${repo}`;
  const cabecalhos = { Authorization: `Bearer ${token}`, Accept: 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28' };
  return (caminho, opcoes = {}) => requisitarJson(`${base}${caminho}`, { servico: SERVICO, fetch, registrar, cabecalhos, ...opcoes });
}

async function estadoAtual(api, ramo) {
  const ref = await api(`/git/ref/heads/${ramo}`);
  const commit = await api(`/git/commits/${ref.object.sha}`);
  return { commitAtual: ref.object.sha, arvoreBase: commit.tree.sha };
}

async function gravarCommit(api, ramo, { commitAtual, arvoreBase }, entradas, mensagem) {
  const arvore = await api('/git/trees', { metodo: 'POST', corpo: { base_tree: arvoreBase, tree: entradas } });
  const commit = await api('/git/commits', { metodo: 'POST', corpo: { message: mensagem, tree: arvore.sha, parents: [commitAtual] } });
  await api(`/git/refs/heads/${ramo}`, { metodo: 'PATCH', corpo: { sha: commit.sha } });
  return commit.sha;
}

/** Arquivos que vão para a internet: index.html e tudo em midias/ (as capturas de conferência ficam locais). */
async function arquivosParaPublicar(pastaLocal) {
  const midias = await readdir(join(pastaLocal, 'midias'), { withFileTypes: true }).catch(() => []);
  return ['index.html', ...midias.filter((d) => d.isFile()).map((d) => `midias/${d.name}`)];
}

/**
 * Publica a prévia em `{destinoRemoto}/` no repositório, num commit só.
 * @returns {Promise<{commit:string, arquivos:number}>}
 */
export async function publicarPasta(pastaLocal, destinoRemoto, { token, repo, ramo = 'main', fetch, registrar, mensagem }) {
  const api = cliente({ token, repo, fetch, registrar });
  const estado = await estadoAtual(api, ramo);
  const entradas = [];
  for (const relativo of await arquivosParaPublicar(pastaLocal)) {
    const conteudo = (await readFile(join(pastaLocal, relativo))).toString('base64');
    const blob = await api('/git/blobs', { metodo: 'POST', corpo: { content: conteudo, encoding: 'base64' } });
    entradas.push({ path: `${destinoRemoto}/${relativo}`, mode: '100644', type: 'blob', sha: blob.sha });
  }
  const commit = await gravarCommit(api, ramo, estado, entradas, mensagem);
  return { commit, arquivos: entradas.length };
}

/**
 * Remove a pasta `{destinoRemoto}/` do repositório. Sem arquivos, não faz commit.
 * @returns {Promise<{commit:string|null, removidos:number}>}
 */
export async function removerPasta(destinoRemoto, { token, repo, ramo = 'main', fetch, registrar, mensagem }) {
  const api = cliente({ token, repo, fetch, registrar });
  const estado = await estadoAtual(api, ramo);
  const arvore = await api(`/git/trees/${estado.arvoreBase}?recursive=1`);
  const prefixo = `${destinoRemoto}/`;
  const entradas = (arvore.tree ?? [])
    .filter((e) => e.type === 'blob' && e.path.startsWith(prefixo))
    .map((e) => ({ path: e.path, mode: '100644', type: 'blob', sha: null }));
  if (!entradas.length) return { commit: null, removidos: 0 };
  const commit = await gravarCommit(api, ramo, estado, entradas, mensagem);
  return { commit, removidos: entradas.length };
}

/** Endereço público da prévia. */
export function urlDaPrevia(baseUrlPrevias, slug) {
  return `${String(baseUrlPrevias).replace(/\/+$/, '')}/${slug}/`;
}
