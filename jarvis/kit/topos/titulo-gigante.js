import { acoes, nota, CSS_COMUM } from './_comum.js';

// Topo tipográfico: o título ocupa a largura da tela. Se houver foto, ela entra num arco recortado.
export function render(ctx) {
  const { negocio, textos, fotos, util } = ctx;
  const { esc } = util;
  const foto = fotos[0];
  const html = `<header class="topo t-titulo-gigante${foto ? '' : ' t-titulo-gigante--sem-foto'}">
  <div class="container t-titulo-gigante__grade">
    <h1 class="t-titulo-gigante__titulo" data-titulo-principal data-anim="texto-partes">${esc(textos.titulo)}</h1>
    ${foto ? `<figure class="t-titulo-gigante__arco" data-anim="revelar">${util.img(foto, { prioridade: true, alt: `Foto de ${negocio.nome}`, sizes: '(min-width: 900px) 30vw, 70vw' })}</figure>` : '<div class="t-titulo-gigante__traco" aria-hidden="true"></div>'}
    <div class="t-titulo-gigante__apoio">
      <p class="t-titulo-gigante__sub" data-anim="subir" style="--ordem:2">${esc(textos.subtitulo)}</p>
      ${acoes(ctx, 't-titulo-gigante__acoes', 3)}
      ${nota(ctx, 't-titulo-gigante__nota', 4)}
    </div>
  </div>
</header>`;
  const css = `${CSS_COMUM}
.t-titulo-gigante{padding-block:6.5rem calc(2.5rem + var(--altura-faixa,3.6rem));overflow:clip}
.t-titulo-gigante__grade{display:grid;gap:2rem}
.t-titulo-gigante__titulo{font-size:clamp(3rem,.8rem + 10.5vw,11rem);line-height:.92;letter-spacing:-.03em;max-width:11ch}
.t-titulo-gigante__arco{width:min(70%,22rem);justify-self:end;margin-top:-1rem;aspect-ratio:3/4;border-radius:999px 999px 12px 12px;overflow:hidden;border:3px solid var(--cor-destaque)}
.t-titulo-gigante__arco img{width:100%;height:100%;object-fit:cover}
.t-titulo-gigante__traco{height:12px;width:min(40%,14rem);background:var(--cor-destaque);border-radius:6px}
.t-titulo-gigante__apoio{display:grid;gap:1.1rem;max-width:34rem}
.t-titulo-gigante__sub{font-size:clamp(1.1rem,1rem + .45vw,1.35rem);color:var(--cor-texto-suave)}
@media (min-width:900px){.t-titulo-gigante{min-height:100vh;min-height:100svh;display:flex;align-items:center;padding-block:7rem calc(3rem + var(--altura-faixa,2.4rem))}.t-titulo-gigante__grade{grid-template-columns:minmax(0,1fr) auto;align-items:end;column-gap:clamp(2rem,4vw,4rem);row-gap:2rem;width:min(1180px,100% - 4rem)}.t-titulo-gigante__titulo{grid-column:1;grid-row:1;font-size:clamp(3rem,1rem + 6.8vw,8.75rem);max-width:none}.t-titulo-gigante__arco{grid-column:2;grid-row:1 / span 2;align-self:center;justify-self:end;width:clamp(13rem,22vw,20rem);margin-top:0}.t-titulo-gigante__apoio,.t-titulo-gigante__traco{grid-column:1;grid-row:2}.t-titulo-gigante--sem-foto .t-titulo-gigante__grade{grid-template-columns:1fr}.t-titulo-gigante--sem-foto .t-titulo-gigante__traco{grid-row:2}.t-titulo-gigante--sem-foto .t-titulo-gigante__apoio{grid-row:3}}`;
  return { html, css };
}
