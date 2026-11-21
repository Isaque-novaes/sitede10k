// Números reais do negócio, grandes, com contagem ao aparecer.
export function render(ctx) {
  const { negocio, util } = ctx;
  const { esc } = util;
  const dados = [];
  if (negocio.nota != null) dados.push({ valor: negocio.nota, casas: 1, rotulo: 'de nota no Google' });
  if (negocio.totalAvaliacoes != null) dados.push({ valor: negocio.totalAvaliacoes, casas: 0, rotulo: 'avaliações de clientes' });
  if (negocio.instagram?.seguidores) dados.push({ valor: negocio.instagram.seguidores, casas: 0, rotulo: 'seguidores no Instagram' });
  const itens = dados.map((d, i) => `<li class="s-numeros-a__item" data-anim="subir" style="--ordem:${i}">
      <span class="s-numeros-a__valor" data-anim="contador" data-valor="${d.valor}" data-casas="${d.casas}">${esc(util.numero(d.valor, d.casas))}</span>
      <span class="s-numeros-a__rotulo">${esc(d.rotulo)}</span>
    </li>`).join('\n    ');
  const html = `<section class="secao s-numeros s-numeros-a" id="numeros" aria-label="Números">
  <ul class="container s-numeros-a__lista">
    ${itens}
  </ul>
</section>`;
  const css = `.s-numeros-a{background:var(--cor-superficie);padding-block:clamp(3.5rem,2.5rem + 4vw,6rem)}
.s-numeros-a__lista{display:grid;gap:2rem}
.s-numeros-a__item{display:grid;gap:.25rem;padding-left:1.25rem;border-left:3px solid var(--cor-destaque)}
.s-numeros-a__valor{font-family:var(--fonte-titulo);font-weight:var(--peso-titulo);font-size:clamp(3rem,2rem + 4.5vw,5.5rem);line-height:1;font-variant-numeric:tabular-nums}
.s-numeros-a__rotulo{color:var(--cor-texto-suave)}
@media (min-width:768px){.s-numeros-a__lista{grid-template-columns:repeat(auto-fit,minmax(12rem,1fr))}}`;
  return { html, css };
}
