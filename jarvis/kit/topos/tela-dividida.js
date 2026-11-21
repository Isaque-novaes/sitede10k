import { acoes, nota, CSS_COMUM } from './_comum.js';

// Topo dividido: texto num painel de cor de um lado, foto inteira do outro.
export function render(ctx) {
  const { negocio, textos, util } = ctx;
  const fotos = ctx.fotosTopo;
  const { esc } = util;
  const foto = fotos[0];
  const html = `<header class="topo t-tela-dividida">
  <div class="t-tela-dividida__foto" data-anim="zoom-lento">${foto ? util.img(foto, { prioridade: true, alt: `Foto de ${negocio.nome}`, sizes: '(min-width: 900px) 50vw, 100vw' }) : ''}</div>
  <div class="t-tela-dividida__painel">
    <div class="t-tela-dividida__texto">
      <h1 class="t-tela-dividida__titulo" data-titulo-principal data-anim="texto-partes">${esc(textos.titulo)}</h1>
      <p class="t-tela-dividida__sub" data-anim="subir" style="--ordem:2">${esc(textos.subtitulo)}</p>
      ${acoes(ctx, 't-tela-dividida__acoes', 3)}
      ${nota(ctx, 't-tela-dividida__nota', 4)}
    </div>
  </div>
</header>`;
  const css = `${CSS_COMUM}
.t-tela-dividida{display:grid;background:var(--cor-superficie);overflow:clip}
.t-tela-dividida__foto{height:52vh;height:52svh;overflow:hidden}
.t-tela-dividida__foto img{width:100%;height:100%;object-fit:cover}
.t-tela-dividida__painel{display:flex;align-items:center;padding:2.5rem 1.25rem calc(2.5rem + var(--altura-faixa,3.6rem));border-top:4px solid var(--cor-destaque)}
.t-tela-dividida__texto{display:grid;gap:1.1rem;max-width:36rem}
.t-tela-dividida__titulo{font-size:clamp(2.4rem,1.5rem + 4.2vw,5.4rem);line-height:1}
.t-tela-dividida__sub{font-size:clamp(1.05rem,1rem + .4vw,1.3rem);color:var(--cor-texto-suave)}
@media (min-width:900px){.t-tela-dividida{grid-template-columns:1fr 1fr;min-height:100vh;min-height:100svh}.t-tela-dividida__foto{order:2;height:auto}.t-tela-dividida__painel{padding:8rem clamp(2rem,5vw,5rem) calc(3rem + var(--altura-faixa,2.4rem)) max(2rem,(100vw - 1180px) / 2);border-top:0;border-right:4px solid var(--cor-destaque)}}`;
  return { html, css };
}
