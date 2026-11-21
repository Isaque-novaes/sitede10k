// Perguntas em grade de cartões abertos por clique, com a pergunta na fonte de título.
export function render(ctx) {
  const { textos, util } = ctx;
  const { esc } = util;
  const itens = textos.perguntas.map((p, i) => `<details class="s-perguntas-c__cartao" data-anim="subir" style="--ordem:${i % 2}">
      <summary class="s-perguntas-c__pergunta">${esc(p.pergunta)}</summary>
      <p class="s-perguntas-c__resposta">${esc(p.resposta)}</p>
    </details>`).join('\n    ');
  const html = `<section class="secao s-perguntas s-perguntas-c" id="perguntas">
  <div class="container">
    <h2 class="titulo-secao s-perguntas-c__titulo" data-anim="subir">Perguntas que sempre ouvimos</h2>
    <div class="s-perguntas-c__grade">
    ${itens}
    </div>
  </div>
</section>`;
  const css = `.s-perguntas-c__titulo{margin-bottom:2.5rem;max-width:18ch}
.s-perguntas-c__grade{display:grid;gap:1rem;align-items:start}
.s-perguntas-c__cartao{border:1px solid color-mix(in srgb,var(--cor-texto) 16%,transparent);border-radius:16px;padding:1.4rem 1.5rem;transition:border-color .3s ease,background .3s ease}
.s-perguntas-c__cartao[open]{border-color:var(--cor-destaque);background:var(--cor-superficie)}
.s-perguntas-c__pergunta{list-style:none;cursor:pointer;font-family:var(--fonte-titulo);font-weight:var(--peso-titulo);font-size:clamp(1.2rem,1.05rem + .6vw,1.55rem);line-height:1.2;min-height:2.75rem;display:flex;align-items:center}
.s-perguntas-c__pergunta::-webkit-details-marker{display:none}
.s-perguntas-c__resposta{margin-top:.9rem;color:var(--cor-texto-suave)}
@media (min-width:800px){.s-perguntas-c__grade{grid-template-columns:repeat(2,1fr)}}`;
  return { html, css };
}
