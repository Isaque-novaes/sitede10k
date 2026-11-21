// Serviços em colunas com um traço grosso na cor de destaque em cima de cada um.
export function render(ctx) {
  const { textos, util } = ctx;
  const { esc } = util;
  const itens = textos.servicos.map((s, i) => `<li class="s-servicos-c__coluna" data-anim="subir" style="--ordem:${i}">
        <h3 class="s-servicos-c__nome">${esc(s.nome)}</h3>
        <p class="s-servicos-c__desc">${esc(s.descricao)}</p>
      </li>`).join('\n      ');
  const html = `<section class="secao s-servicos s-servicos-c" id="servicos">
  <div class="container">
    <div class="s-servicos-c__cabeca">
      <h2 class="titulo-secao" data-anim="subir">Como podemos ajudar</h2>
      <p class="texto-largo" data-anim="subir" style="--ordem:1">${esc(textos.subtitulo)}</p>
    </div>
    <ul class="s-servicos-c__colunas">
      ${itens}
    </ul>
  </div>
</section>`;
  const css = `.s-servicos-c__cabeca{display:grid;gap:1rem;margin-bottom:3rem}
.s-servicos-c__colunas{display:grid;gap:2.25rem}
.s-servicos-c__coluna{display:grid;gap:.6rem;align-content:start;padding-top:1.25rem;border-top:5px solid var(--cor-destaque)}
.s-servicos-c__coluna:nth-child(even){border-top-color:var(--cor-destaque2)}
.s-servicos-c__nome{font-size:clamp(1.35rem,1.15rem + .8vw,1.75rem)}
.s-servicos-c__desc{color:var(--cor-texto-suave)}
@media (min-width:700px){.s-servicos-c__colunas{grid-template-columns:repeat(2,1fr);column-gap:2rem}}
@media (min-width:1000px){.s-servicos-c__colunas{grid-template-columns:repeat(auto-fit,minmax(14rem,1fr));column-gap:2.5rem}}`;
  return { html, css };
}
