import { acoes, nota, CSS_COMUM } from './_comum.js';

// Topo elegante: a foto fica dentro de um passe-partout e o título invade a borda da moldura.
export function render(ctx) {
  const { negocio, textos, util } = ctx;
  const fotos = ctx.fotosTopo;
  const { esc } = util;
  const foto = fotos[0];
  const html = `<header class="topo t-moldura">
  <div class="container t-moldura__grade">
    <figure class="t-moldura__quadro" data-anim="revelar">${foto ? util.img(foto, { prioridade: true, alt: `Foto de ${negocio.nome}`, sizes: '(min-width: 900px) 58vw, 100vw' }) : ''}</figure>
    <div class="t-moldura__texto">
      <h1 class="t-moldura__titulo" data-titulo-principal data-anim="texto-partes">${esc(textos.titulo)}</h1>
      <p class="t-moldura__sub" data-anim="subir" style="--ordem:2">${esc(textos.subtitulo)}</p>
      ${acoes(ctx, 't-moldura__acoes', 3)}
      ${nota(ctx, 't-moldura__nota', 4)}
    </div>
  </div>
</header>`;
  const css = `${CSS_COMUM}
.t-moldura{padding-block:5.5rem calc(2.5rem + var(--altura-faixa,3.6rem));overflow:clip}
.t-moldura__grade{display:grid}
.t-moldura__quadro{padding:.75rem;border:1px solid color-mix(in srgb,var(--cor-destaque) 70%,transparent);background:var(--cor-superficie)}
.t-moldura__quadro img{width:100%;aspect-ratio:4/3;object-fit:cover}
.t-moldura__texto{display:grid;gap:1.1rem;margin-top:-.7rem;position:relative;z-index:1;padding-inline:.5rem}
.t-moldura__titulo{font-size:clamp(2.6rem,1.5rem + 5vw,6.2rem);line-height:.98;max-width:12ch;text-shadow:0 2px 30px var(--cor-fundo)}
.t-moldura__sub{font-size:clamp(1.05rem,1rem + .4vw,1.3rem);color:var(--cor-texto-suave);max-width:36ch}
@media (min-width:900px){.t-moldura{min-height:100vh;min-height:100svh;display:flex;align-items:center;padding-block:7rem calc(3rem + var(--altura-faixa,2.4rem))}.t-moldura__grade{grid-template-columns:repeat(12,minmax(0,1fr));align-items:center;width:min(1180px,100% - 4rem)}.t-moldura__quadro{grid-column:7 / 13;grid-row:1;padding:1.1rem}.t-moldura__quadro img{aspect-ratio:auto;height:min(64vh,40rem)}.t-moldura__texto{grid-column:1 / 7;grid-row:1;margin-top:0;padding-inline:0 2.5rem}}`;
  return { html, css };
}
