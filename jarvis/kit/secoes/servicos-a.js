// Serviços como um cardápio: nomes grandes, descrição ao lado, título fixo à esquerda no PC.
export function render(ctx) {
  const { textos, util } = ctx;
  const { esc } = util;
  const itens = textos.servicos.map((s, i) => `<li class="s-servicos-a__item" data-anim="subir" style="--ordem:${i}">
      <h3 class="s-servicos-a__nome">${esc(s.nome)}</h3>
      <p class="s-servicos-a__desc">${esc(s.descricao)}</p>
    </li>`).join('\n    ');
  const html = `<section class="secao s-servicos s-servicos-a" id="servicos">
  <div class="container s-servicos-a__grade">
    <div class="s-servicos-a__cabeca">
      <h2 class="titulo-secao" data-anim="subir">Serviços</h2>
    </div>
    <ul class="s-servicos-a__lista">
    ${itens}
    </ul>
  </div>
</section>`;
  const css = `.s-servicos-a__grade{display:grid;gap:2.5rem}
.s-servicos-a__lista{border-top:1px solid color-mix(in srgb,var(--cor-texto) 16%,transparent)}
.s-servicos-a__item{display:grid;gap:.4rem;padding-block:1.6rem;border-bottom:1px solid color-mix(in srgb,var(--cor-texto) 16%,transparent);position:relative}
.s-servicos-a__item::before{content:"";position:absolute;left:0;top:-1px;height:2px;width:0;background:var(--cor-destaque);transition:width .5s cubic-bezier(.2,.7,.2,1)}
.s-servicos-a__item:hover::before{width:100%}
.s-servicos-a__nome{font-size:clamp(1.45rem,1.15rem + 1.3vw,2.25rem);line-height:1.1}
.s-servicos-a__desc{color:var(--cor-texto-suave);max-width:46ch}
@media (min-width:900px){.s-servicos-a__grade{grid-template-columns:5fr 7fr;gap:4rem}.s-servicos-a__cabeca{position:sticky;top:6rem;align-self:start}.s-servicos-a__item{grid-template-columns:minmax(0,1fr) minmax(0,1fr);align-items:baseline;gap:2rem}}`;
  return { html, css };
}
