import { acoes, nota, CSS_COMUM } from './_comum.js';

// Topo de colagem: título à esquerda e três fotos em alturas diferentes, sobrepostas de leve.
export function render(ctx) {
  const { negocio, textos, fotos, util } = ctx;
  const { esc } = util;
  const [a, b, c] = fotos;
  const foto = (f, classe, i, prioridade = false) => f
    ? `<figure class="t-colagem__foto ${classe}" data-anim="subir" style="--ordem:${i}">${util.img(f, { prioridade, alt: `Foto de ${negocio.nome}`, sizes: '(min-width: 900px) 30vw, 60vw' })}</figure>`
    : '';
  const html = `<header class="topo t-colagem">
  <div class="container t-colagem__grade">
    <div class="t-colagem__texto">
      <h1 class="t-colagem__titulo" data-titulo-principal data-anim="texto-partes">${esc(textos.titulo)}</h1>
      <p class="t-colagem__sub" data-anim="subir" style="--ordem:2">${esc(textos.subtitulo)}</p>
      ${acoes(ctx, 't-colagem__acoes', 3)}
      ${nota(ctx, 't-colagem__nota', 4)}
    </div>
    <div class="t-colagem__fotos">
      ${foto(a, 't-colagem__foto--a', 1, true)}
      ${foto(b, 't-colagem__foto--b', 2)}
      ${foto(c, 't-colagem__foto--c', 3)}
    </div>
  </div>
</header>`;
  const css = `${CSS_COMUM}
.t-colagem{padding-block:6.5rem calc(3rem + var(--altura-faixa,3.6rem));overflow:clip}
.t-colagem__grade{display:grid;gap:2.5rem}
.t-colagem__texto{display:grid;gap:1.15rem;align-content:center}
.t-colagem__titulo{font-size:clamp(2.6rem,1.5rem + 5.4vw,6rem);line-height:.98;max-width:12ch}
.t-colagem__sub{font-size:clamp(1.05rem,1rem + .4vw,1.3rem);color:var(--cor-texto-suave);max-width:34ch}
.t-colagem__fotos{display:grid;grid-template-columns:repeat(6,1fr);grid-template-rows:repeat(6,minmax(2.4rem,auto));gap:.6rem}
.t-colagem__foto{overflow:hidden;border-radius:8px}
.t-colagem__foto img{width:100%;height:100%;object-fit:cover}
.t-colagem__foto--a{grid-column:1 / 5;grid-row:1 / 6;aspect-ratio:4/5}
.t-colagem__foto--b{grid-column:4 / 7;grid-row:2 / 4;z-index:1;outline:6px solid var(--cor-fundo)}
.t-colagem__foto--c{grid-column:4 / 7;grid-row:4 / 7;z-index:1;outline:6px solid var(--cor-fundo)}
@media (min-width:900px){.t-colagem{min-height:100vh;min-height:100svh;display:flex;align-items:center;padding-block:7rem calc(3rem + var(--altura-faixa,2.4rem))}.t-colagem__grade{grid-template-columns:5fr 6fr;gap:4rem;align-items:center;width:min(1180px,100% - 4rem)}}`;
  return { html, css };
}
