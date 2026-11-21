import { acoes, nota, CSS_COMUM } from './_comum.js';

// Topo com o reel do negócio. No celular o vídeo vertical ocupa a tela toda.
// No PC ele fica numa moldura alta à direita, sobre a capa desfocada.
export function render(ctx) {
  const { negocio, textos, video, util } = ctx;
  const { esc } = util;
  const vertical = video && video.altura >= video.largura;
  const capa = video ? util.caminho(video.capa) : '';
  const src = video ? util.caminho(video.video, video.original?.credito) : '';
  const html = `<header class="topo t-video-fundo${vertical ? ' t-video-fundo--vertical' : ''}">
  ${video ? `<div class="t-video-fundo__ambiente" aria-hidden="true" style="background-image:url('${capa}')"></div>
  <div class="t-video-fundo__moldura">
    <video class="t-video-fundo__video" src="${src}" poster="${capa}" autoplay muted loop playsinline preload="metadata" aria-label="Vídeo de ${esc(negocio.nome)}"></video>
  </div>` : ''}
  <div class="t-video-fundo__veu" aria-hidden="true"></div>
  <div class="container t-video-fundo__conteudo">
    <h1 class="t-video-fundo__titulo" data-titulo-principal data-anim="texto-partes">${esc(textos.titulo)}</h1>
    <p class="t-video-fundo__sub" data-anim="subir" style="--ordem:3">${esc(textos.subtitulo)}</p>
    ${acoes(ctx, 't-video-fundo__acoes')}
    ${nota(ctx, 't-video-fundo__nota')}
  </div>
</header>`;
  const css = `${CSS_COMUM}
.t-video-fundo{position:relative;min-height:100vh;min-height:100svh;display:flex;align-items:flex-end;overflow:clip;isolation:isolate;padding-block:7.5rem calc(2.5rem + var(--altura-faixa,3.6rem))}
.t-video-fundo__ambiente{display:none}
.t-video-fundo__moldura{position:absolute;inset:0;z-index:-2}
.t-video-fundo__video{width:100%;height:100%;object-fit:cover}
.t-video-fundo__veu{position:absolute;inset:0;z-index:-1;background:linear-gradient(to top,var(--cor-fundo) 4%,color-mix(in srgb,var(--cor-fundo) 80%,transparent) 36%,color-mix(in srgb,var(--cor-fundo) 15%,transparent) 70%,color-mix(in srgb,var(--cor-fundo) 55%,transparent) 100%)}
.t-video-fundo__conteudo{display:grid;gap:1.2rem}
.t-video-fundo__titulo{font-size:clamp(2.8rem,1.6rem + 6vw,6.5rem);line-height:.98;max-width:12ch}
.t-video-fundo__sub{font-size:clamp(1.1rem,1rem + .45vw,1.35rem);color:var(--cor-texto-suave);max-width:36ch}
@media (min-width:900px){
  .t-video-fundo--vertical{align-items:center;padding-block:8rem calc(4rem + var(--altura-faixa,2.4rem))}
  .t-video-fundo--vertical .t-video-fundo__ambiente{display:block;position:absolute;inset:-40px;z-index:-3;background-size:cover;background-position:center;filter:blur(40px) saturate(1.2);opacity:.55}
  .t-video-fundo--vertical .t-video-fundo__veu{background:linear-gradient(90deg,var(--cor-fundo) 0%,color-mix(in srgb,var(--cor-fundo) 85%,transparent) 45%,color-mix(in srgb,var(--cor-fundo) 30%,transparent) 100%)}
  .t-video-fundo--vertical .t-video-fundo__moldura{position:absolute;inset:auto calc((100vw - min(1180px,100vw - 4rem)) / 2) auto auto;top:50%;transform:translateY(-50%);z-index:1;width:min(30vw,22rem);aspect-ratio:9/16;border-radius:18px;overflow:hidden;box-shadow:0 30px 80px -20px color-mix(in srgb,var(--cor-fundo) 80%,#000 20%);outline:1px solid color-mix(in srgb,var(--cor-texto) 18%,transparent)}
  .t-video-fundo--vertical .t-video-fundo__conteudo{padding-right:calc(min(30vw,22rem) + 4rem)}
}`;
  return { html, css };
}
