// Perguntas frequentes com <details>, funciona sem JavaScript.
export function render(ctx) {
  const { textos, util } = ctx;
  const { esc } = util;
  const itens = textos.perguntas.map((p, i) => `<details class="s-perguntas-a__item" data-anim="subir" style="--ordem:${i}">
      <summary class="s-perguntas-a__pergunta">${esc(p.pergunta)}</summary>
      <p class="s-perguntas-a__resposta">${esc(p.resposta)}</p>
    </details>`).join('\n    ');
  const html = `<section class="secao s-perguntas s-perguntas-a" id="perguntas">
  <div class="container"><div class="s-perguntas-a__caixa">
    <h2 class="titulo-secao" data-anim="subir">Dúvidas frequentes</h2>
    <div class="s-perguntas-a__lista">
    ${itens}
    </div>
  </div></div>
</section>`;
  const css = `.s-perguntas-a__caixa{max-width:52rem}
.s-perguntas-a__lista{margin-top:2.5rem;border-top:1px solid color-mix(in srgb,var(--cor-texto) 16%,transparent)}
.s-perguntas-a__item{border-bottom:1px solid color-mix(in srgb,var(--cor-texto) 16%,transparent)}
.s-perguntas-a__pergunta{list-style:none;cursor:pointer;display:flex;justify-content:space-between;align-items:center;gap:1rem;min-height:3.5rem;padding-block:1.1rem;font-size:clamp(1.05rem,1rem + .3vw,1.25rem);font-weight:600}
.s-perguntas-a__pergunta::-webkit-details-marker{display:none}
.s-perguntas-a__pergunta::after{content:"+";flex:none;font-size:1.6rem;line-height:1;color:var(--cor-destaque);transition:transform .3s ease}
.s-perguntas-a__item[open] .s-perguntas-a__pergunta::after{transform:rotate(45deg)}
.s-perguntas-a__resposta{padding-bottom:1.25rem;color:var(--cor-texto-suave);max-width:60ch}`;
  return { html, css };
}
