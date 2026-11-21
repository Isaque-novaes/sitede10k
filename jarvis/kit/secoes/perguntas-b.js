// Perguntas em duas colunas: título e convite para chamar de um lado, respostas do outro.
export function render(ctx) {
  const { textos, util } = ctx;
  const { esc } = util;
  const contato = util.linkContato();
  const itens = textos.perguntas.map((p, i) => `<details class="s-perguntas-b__item" data-anim="subir" style="--ordem:${i}">
        <summary class="s-perguntas-b__pergunta">${esc(p.pergunta)}</summary>
        <p class="s-perguntas-b__resposta">${esc(p.resposta)}</p>
      </details>`).join('\n      ');
  const html = `<section class="secao s-perguntas s-perguntas-b" id="perguntas">
  <div class="container s-perguntas-b__grade">
    <div class="s-perguntas-b__lado" data-anim="subir">
      <h2 class="titulo-secao">Antes de vir</h2>
      ${contato ? `<p class="s-perguntas-b__convite">Ficou alguma dúvida? <a href="${esc(contato.href)}">${esc(contato.rotulo)}</a></p>` : ''}
    </div>
    <div class="s-perguntas-b__lista">
      ${itens}
    </div>
  </div>
</section>`;
  const css = `.s-perguntas-b__grade{display:grid;gap:2.5rem}
.s-perguntas-b__lado{display:grid;gap:1.25rem;align-content:start}
.s-perguntas-b__convite{color:var(--cor-texto-suave)}
.s-perguntas-b__convite a{color:var(--cor-destaque);font-weight:600}
.s-perguntas-b__lista{display:grid;gap:.75rem}
.s-perguntas-b__item{border-radius:12px;background:var(--cor-superficie);padding-inline:1.25rem}
.s-perguntas-b__pergunta{list-style:none;cursor:pointer;min-height:3.5rem;display:flex;align-items:center;gap:1rem;padding-block:1rem;font-weight:600;font-size:1.05rem}
.s-perguntas-b__pergunta::-webkit-details-marker{display:none}
.s-perguntas-b__pergunta::before{content:"";flex:none;width:.6rem;height:.6rem;border-right:2px solid var(--cor-destaque);border-bottom:2px solid var(--cor-destaque);transform:rotate(-45deg);transition:transform .3s ease}
.s-perguntas-b__item[open] .s-perguntas-b__pergunta::before{transform:rotate(45deg)}
.s-perguntas-b__resposta{padding:0 0 1.25rem 1.6rem;color:var(--cor-texto-suave)}
@media (min-width:900px){.s-perguntas-b__grade{grid-template-columns:4fr 7fr;gap:4rem}.s-perguntas-b__lado{position:sticky;top:6rem}}`;
  return { html, css };
}
