import { acoes, nota, CSS_COMUM } from './_comum.js';

// Topo de mosaico: o título no centro e cinco fotos ao redor, cada uma rolando numa velocidade.
export function render(ctx) {
  const { negocio, textos, fotos, util } = ctx;
  const { esc } = util;
  const fatores = ['0.08', '0.16', '0.05', '0.14', '0.1'];
  const pecas = fotos.slice(0, 5).map((f, i) => `<figure class="t-mosaico-movel__foto t-mosaico-movel__foto--${i + 1}" data-anim="paralaxe" data-fator="${fatores[i]}">${util.img(f, { prioridade: i === 0, alt: `Foto ${i + 1} de ${negocio.nome}`, sizes: '(min-width: 900px) 22vw, 45vw' })}</figure>`).join('\n    ');
  const html = `<header class="topo t-mosaico-movel">
  <div class="t-mosaico-movel__fotos" aria-hidden="false">
    ${pecas}
  </div>
  <div class="container t-mosaico-movel__texto">
    <h1 class="t-mosaico-movel__titulo" data-titulo-principal data-anim="texto-partes">${esc(textos.titulo)}</h1>
    <p class="t-mosaico-movel__sub" data-anim="subir" style="--ordem:2">${esc(textos.subtitulo)}</p>
    ${acoes(ctx, 't-mosaico-movel__acoes', 3)}
    ${nota(ctx, 't-mosaico-movel__nota', 4)}
  </div>
</header>`;
  const css = `${CSS_COMUM}
.t-mosaico-movel{position:relative;overflow:clip;padding-block:6rem calc(2.5rem + var(--altura-faixa,3.6rem));display:grid;gap:2.5rem}
.t-mosaico-movel__texto{display:grid;gap:1.1rem;order:-1}
.t-mosaico-movel__titulo{font-size:clamp(2.6rem,1.4rem + 5.6vw,6.4rem);line-height:.98;max-width:12ch}
.t-mosaico-movel__sub{font-size:clamp(1.05rem,1rem + .4vw,1.3rem);color:var(--cor-texto-suave);max-width:36ch}
.t-mosaico-movel__fotos{display:grid;grid-template-columns:repeat(2,1fr);gap:.6rem;padding-inline:1.25rem}
.t-mosaico-movel__foto{overflow:hidden;border-radius:10px}
.t-mosaico-movel__foto img{width:100%;height:100%;object-fit:cover;aspect-ratio:4/5}
.t-mosaico-movel__foto--1{grid-column:1 / -1}
.t-mosaico-movel__foto--1 img{aspect-ratio:16/9}
.t-mosaico-movel__foto--5{display:none}
@media (min-width:900px){
  .t-mosaico-movel{min-height:100vh;min-height:100svh;place-items:center;padding-block:7rem calc(3rem + var(--altura-faixa,2.4rem))}
  .t-mosaico-movel__fotos{position:absolute;inset:0;display:block;padding:0;z-index:0}
  .t-mosaico-movel__foto{position:absolute;width:clamp(10rem,17vw,16rem);opacity:.9}
  .t-mosaico-movel__foto img,.t-mosaico-movel__foto--1 img{aspect-ratio:4/5}
  .t-mosaico-movel__foto--1{left:4%;top:12%}
  .t-mosaico-movel__foto--2{right:5%;top:8%;width:clamp(9rem,14vw,13rem)}
  .t-mosaico-movel__foto--3{left:10%;bottom:6%;width:clamp(8rem,12vw,11rem)}
  .t-mosaico-movel__foto--4{right:9%;bottom:10%}
  .t-mosaico-movel__foto--5{display:block;left:42%;top:4%;width:clamp(6rem,9vw,8rem);opacity:.6}
  .t-mosaico-movel__texto{position:relative;z-index:1;order:0;justify-items:center;text-align:center;max-width:44rem;padding:2rem;background:radial-gradient(closest-side,color-mix(in srgb,var(--cor-fundo) 92%,transparent),transparent)}
  .t-mosaico-movel__titulo{max-width:14ch}
  .t-mosaico-movel__acoes{justify-content:center}
}`;
  return { html, css };
}
