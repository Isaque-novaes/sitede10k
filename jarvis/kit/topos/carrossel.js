import { acoes, nota, CSS_COMUM } from './_comum.js';

// Topo com fotos trocando sozinhas (a cada 5 s), com botões para voltar e avançar.
export function render(ctx) {
  const { negocio, textos, fotos, util } = ctx;
  const { esc } = util;
  const lista = fotos.slice(0, 5);
  const slides = lista.map((f, i) => `<div class="t-carrossel__slide${i === 0 ? ' ativo' : ''}" data-slide>${util.img(f, { prioridade: i === 0, alt: `Foto ${i + 1} de ${negocio.nome}` })}</div>`).join('\n    ');
  const html = `<header class="topo t-carrossel" data-carrossel>
  <div class="t-carrossel__slides">
    ${slides}
  </div>
  <div class="t-carrossel__veu" aria-hidden="true"></div>
  <div class="container t-carrossel__conteudo">
    <h1 class="t-carrossel__titulo" data-titulo-principal data-anim="texto-partes">${esc(textos.titulo)}</h1>
    <p class="t-carrossel__sub" data-anim="subir" style="--ordem:3">${esc(textos.subtitulo)}</p>
    ${acoes(ctx, 't-carrossel__acoes')}
    <div class="t-carrossel__rodape">
      ${nota(ctx, 't-carrossel__nota')}
      <div class="t-carrossel__controles">
        <button type="button" class="t-carrossel__botao" data-anterior aria-label="Foto anterior">&#8249;</button>
        <button type="button" class="t-carrossel__botao" data-proximo aria-label="Próxima foto">&#8250;</button>
      </div>
    </div>
  </div>
</header>`;
  const css = `${CSS_COMUM}
.t-carrossel{position:relative;min-height:100vh;min-height:100svh;display:flex;align-items:flex-end;overflow:clip;isolation:isolate;padding-block:7.5rem calc(2rem + var(--altura-faixa,3.6rem))}
.t-carrossel__slides{position:absolute;inset:0;z-index:-2}
.t-carrossel__slide{position:absolute;inset:0;opacity:0;transition:opacity 1.2s ease}
.t-carrossel__slide img{width:100%;height:100%;object-fit:cover;transform:scale(1.06);transition:transform 6s ease-out}
.t-carrossel__slide.ativo{opacity:1}
.t-carrossel__slide.ativo img{transform:scale(1)}
.t-carrossel__veu{position:absolute;inset:0;z-index:-1;background:linear-gradient(to top,var(--cor-fundo) 3%,color-mix(in srgb,var(--cor-fundo) 75%,transparent) 35%,color-mix(in srgb,var(--cor-fundo) 20%,transparent) 70%,color-mix(in srgb,var(--cor-fundo) 50%,transparent) 100%)}
.t-carrossel__conteudo{display:grid;gap:1.2rem}
.t-carrossel__titulo{font-size:clamp(2.7rem,1.6rem + 5.8vw,6.6rem);line-height:.98;max-width:13ch}
.t-carrossel__sub{font-size:clamp(1.05rem,1rem + .4vw,1.3rem);color:var(--cor-texto-suave);max-width:38ch}
.t-carrossel__rodape{display:flex;align-items:center;justify-content:space-between;gap:1rem;margin-top:.5rem}
.t-carrossel__controles{display:flex;gap:.5rem;margin-left:auto}
.t-carrossel__botao{width:2.9rem;height:2.9rem;border-radius:50%;border:1px solid color-mix(in srgb,var(--cor-texto) 35%,transparent);background:color-mix(in srgb,var(--cor-fundo) 40%,transparent);color:var(--cor-texto);font-size:1.6rem;line-height:1;cursor:pointer;transition:background .25s ease}
.t-carrossel__botao:hover{background:var(--cor-destaque);color:var(--cor-sobre-destaque)}
@media (prefers-reduced-motion: reduce){.t-carrossel__slide,.t-carrossel__slide img{transition:none;transform:none}}`;
  return { html, css };
}
