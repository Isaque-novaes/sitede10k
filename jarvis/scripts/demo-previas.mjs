// Gera as prévias de demonstração em saida/demo/ e uma galeria para olhar todas.
// Uso: npm run demo:midias && npm run demo
import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { gerarPrevia } from '../src/previa/gerar.js';
import { abrirNavegador } from '../src/util/navegador.js';
import { esc } from '../src/util/html.js';

const RAIZ = join(dirname(fileURLToPath(import.meta.url)), '..');
const SAIDA = join(RAIZ, 'saida', 'demo');
const { negocios } = JSON.parse(await readFile(join(RAIZ, 'fixtures', 'negocios-demo.json'), 'utf8'));

function paraNegocio(dados) {
  const pasta = join(RAIZ, 'fixtures', 'midias', dados.id);
  const midias = dados.midias
    .map((m) => ({ arquivo: join(pasta, `${m.pexels}.jpg`), tipo: 'foto', origem: 'pexels', credito: m.credito }))
    .filter((m) => existsSync(m.arquivo));
  const video = join(pasta, 'video.mp4');
  if (dados.video && existsSync(video)) midias.unshift({ arquivo: video, tipo: 'video', origem: 'pexels', credito: dados.video.credito });
  const { midias: _m, video: _v, ...resto } = dados;
  return { ...resto, midias };
}

await rm(SAIDA, { recursive: true, force: true });
await mkdir(SAIDA, { recursive: true });
const navegador = await abrirNavegador();
const usadas = [];
const resultados = [];
try {
  for (const dados of negocios) {
    const negocio = paraNegocio(dados);
    console.log(`${negocio.nome}: ${negocio.midias.length} mídias`);
    const r = await gerarPrevia(negocio, { pastaSaida: SAIDA, usadas, navegador, ficticio: true });
    usadas.push({ assinatura: r.assinatura, nicho: negocio.nicho, cidade: negocio.cidade });
    resultados.push({ negocio, r });
    console.log(`  ${r.conferencia.ok ? 'aprovada' : 'REPROVADA'}: ${r.assinatura.topo}, ${r.assinatura.fontes}, ${r.assinatura.movimento}`);
    for (const p of r.conferencia.problemas) console.log(`    ${p}`);
    for (const a of r.avisos) console.log(`    aviso: ${a}`);
  }
} finally {
  await navegador.close();
}

const cartoes = resultados.map(({ negocio, r }) => {
  const rel = (p) => relative(SAIDA, p).split('\\').join('/');
  const a = r.assinatura;
  return `<article class="cartao">
  <a class="cartao__capturas" href="${rel(join(r.pasta, 'index.html'))}">
    <img class="cartao__pc" src="${rel(r.conferencia.capturas.pc)}" alt="Prévia de ${esc(negocio.nome)} no computador" loading="lazy">
    <img class="cartao__celular" src="${rel(r.conferencia.capturas.celular)}" alt="Prévia de ${esc(negocio.nome)} no celular" loading="lazy">
  </a>
  <div class="cartao__texto">
    <h2>${esc(negocio.nome)}</h2>
    <p class="cartao__lugar">${esc(negocio.bairro)}, ${esc(negocio.cidade)}</p>
    <dl class="cartao__assinatura">
      <div><dt>Topo</dt><dd>${esc(a.topo)}</dd></div>
      <div><dt>Fontes</dt><dd>${esc(a.fontes)}</dd></div>
      <div><dt>Movimento</dt><dd>${esc(a.movimento)}</dd></div>
      <div><dt>Seções</dt><dd>${esc(a.secoes.map((s) => `${s.tipo} ${s.variante}`).join(', '))}</dd></div>
    </dl>
    <p class="cartao__status ${r.conferencia.ok ? 'ok' : 'falha'}">${r.conferencia.ok ? 'Aprovada no celular e no PC' : esc(r.conferencia.problemas.join('; '))}</p>
    <a class="cartao__abrir" href="${rel(join(r.pasta, 'index.html'))}">Abrir prévia</a>
  </div>
</article>`;
}).join('\n');

await writeFile(join(SAIDA, 'index.html'), `<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Prévias do Estúdio Dez</title>
<style>
body{margin:0;font-family:system-ui,sans-serif;background:#f3f1ee;color:#1d1b19;padding:2rem max(16px,4vw)}
h1{font-size:1.8rem;margin:0 0 .5rem}.intro{max-width:60ch;color:#5a554f;margin:0 0 2rem}
.cartao{display:grid;gap:1.25rem;background:#fff;border-radius:14px;padding:1rem;margin-bottom:1.5rem}
.cartao__capturas{position:relative;display:block}.cartao__pc{width:100%;border-radius:8px}
.cartao__celular{position:absolute;right:.75rem;bottom:-.75rem;width:22%;border-radius:10px;border:3px solid #1d1b19}
.cartao__texto{display:grid;gap:.6rem}.cartao__texto h2{margin:0}.cartao__lugar{margin:0;color:#5a554f}
.cartao__assinatura{margin:0;display:grid;gap:.3rem;font-size:.9rem}.cartao__assinatura div{display:flex;gap:.5rem}
.cartao__assinatura dt{min-width:6rem;color:#5a554f}.cartao__assinatura dd{margin:0}
.cartao__status{margin:0;font-weight:600}.ok{color:#2b6e3f}.falha{color:#a2322b}
@media(min-width:900px){.cartao{grid-template-columns:3fr 2fr;align-items:center}}
</style></head><body>
<h1>Prévias do Estúdio Dez</h1>
<p class="intro">Cinco negócios fictícios, cada um com uma prévia única gerada pelo kit. As duas barbearias são da mesma cidade e por isso diferem em pelo menos 3 das 5 partes do design.</p>
${cartoes}
</body></html>
`);
console.log(join(SAIDA, 'index.html'));
