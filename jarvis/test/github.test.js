import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { publicarPasta, removerPasta, urlDaPrevia } from '../src/externo/github.js';
import { criarServicos } from '../src/externo/servicos.js';
import { fetchGitHubFalso, escreverPrevia } from './falsos.js';

let tmp;
beforeEach(async () => { tmp = await mkdtemp(join(tmpdir(), 'jarvis-gh-')); });
afterEach(async () => { await rm(tmp, { recursive: true, force: true }); });

test('publicarPasta manda só index e mídias num commit', async () => {
  await escreverPrevia(tmp);
  const f = fetchGitHubFalso();
  const r = await publicarPasta(tmp, 'barbearia-x-1a2b', { token: 'T', repo: 'isaque/previas', fetch: f, mensagem: 'Prévia' });
  assert.equal(r.arquivos, 3); assert.equal(r.commit, 'commit-novo');
  const arvore = JSON.parse(f.chamadas.find((c) => c.url.endsWith('/git/trees') && c.metodo === 'POST').corpo);
  assert.equal(arvore.base_tree, 'arvore-base');
  assert.deepEqual(arvore.tree.map((t) => t.path).sort(), ['barbearia-x-1a2b/index.html', 'barbearia-x-1a2b/midias/a.webp', 'barbearia-x-1a2b/midias/b.webp']);
  assert.ok(arvore.tree.every((t) => t.mode === '100644' && t.type === 'blob' && /^blob-\d$/.test(t.sha)));
  const blob = JSON.parse(f.chamadas.find((c) => c.url.endsWith('/git/blobs')).corpo);
  assert.equal(blob.encoding, 'base64');
  const commit = JSON.parse(f.chamadas.find((c) => c.url.endsWith('/git/commits') && c.metodo === 'POST').corpo);
  assert.deepEqual(commit, { message: 'Prévia', tree: 'arvore-nova', parents: ['commit-atual'] });
  const patch = f.chamadas.find((c) => c.metodo === 'PATCH');
  assert.ok(patch.url.endsWith('/repos/isaque/previas/git/refs/heads/main')); assert.deepEqual(JSON.parse(patch.corpo), { sha: 'commit-novo' });
  assert.equal(f.chamadas[0].cabecalhos.Authorization, 'Bearer T');
  assert.equal(f.chamadas[0].cabecalhos['X-GitHub-Api-Version'], '2022-11-28');
  assert.equal(f.chamadas[0].cabecalhos.Accept, 'application/vnd.github+json');
});

test('removerPasta apaga só os arquivos da prévia', async () => {
  const f = fetchGitHubFalso({ arvore: ['barbearia-x-1a2b/index.html', 'barbearia-x-1a2b/midias/a.webp', 'outra-9z9z/index.html', 'barbearia-x-1a2bcd/index.html'] });
  const r = await removerPasta('barbearia-x-1a2b', { token: 'T', repo: 'isaque/previas', fetch: f, mensagem: 'Remove' });
  const arvore = JSON.parse(f.chamadas.find((c) => c.url.endsWith('/git/trees') && c.metodo === 'POST').corpo);
  assert.equal(r.removidos, 2); assert.ok(arvore.tree.every((t) => t.sha === null && t.path.startsWith('barbearia-x-1a2b/')));
  assert.match(f.chamadas.find((c) => c.url.includes('/git/trees/arvore-base')).url, /recursive=1/);
});

test('removerPasta sem arquivos não faz commit', async () => {
  const f = fetchGitHubFalso({ arvore: ['outra-9z9z/index.html'] });
  assert.deepEqual(await removerPasta('sumiu', { token: 'T', repo: 'isaque/previas', fetch: f, mensagem: 'x' }), { commit: null, removidos: 0 });
  assert.ok(!f.chamadas.some((c) => c.metodo === 'PATCH'));
});

test('urlDaPrevia', () => {
  assert.equal(urlDaPrevia('https://isaque.github.io/previas', 'abc-1234'), 'https://isaque.github.io/previas/abc-1234/');
  assert.equal(urlDaPrevia('https://isaque.github.io/previas/', 'abc-1234'), 'https://isaque.github.io/previas/abc-1234/');
});

test('servicos.github usa repo, ramo e endereço base da config', async () => {
  await escreverPrevia(tmp);
  const f = fetchGitHubFalso();
  const s = criarServicos({ chaves: { github: 'GT' }, githubRepo: 'isaque/previas', githubRamo: 'gh-pages', baseUrlPrevias: 'https://isaque.github.io/previas' }, { fetch: f });
  await s.github.publicar(tmp, 'x-1a2b', 'msg');
  assert.ok(f.chamadas.some((c) => c.metodo === 'PATCH' && c.url.endsWith('/git/refs/heads/gh-pages')));
  assert.equal(s.github.url('x-1a2b'), 'https://isaque.github.io/previas/x-1a2b/');
});
