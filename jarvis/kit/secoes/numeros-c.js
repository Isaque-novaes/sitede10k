// Números em faixa de destaque: rótulo em cima, número enorme embaixo, com contagem.
export function render(ctx) {
  const { negocio, util } = ctx;
  const { esc } = util;
  const dados = [];
  if (negocio.nota != null) dados.push({ rotulo: 'Nota no Google', valor: negocio.nota, casas: 1 });
  if (negocio.totalAvaliacoes != null) dados.push({ rotulo: 'Avaliações', valor: negocio.totalAvaliacoes, casas: 0 });
  if (negocio.instagram?.seguidores) dados.push({ rotulo: 'Seguidores', valor: negocio.instagram.seguidores, casas: 0 });
  const itens = dados.map((d, i) => `<li class="s-numeros-c__item" data-anim="subir" style="--ordem:${i}">
      <span class="s-numeros-c__rotulo">${esc(d.rotulo)}</span>
      <span class="s-numeros-c__valor" data-anim="contador" data-valor="${d.valor}" data-casas="${d.casas}">${esc(util.numero(d.valor, d.casas))}</span>
    </li>`).join('\n    ');
  const html = `<section class="secao s-numeros s-numeros-c" id="numeros" aria-label="Números">
  <ul class="container s-numeros-c__lista">
    ${itens}
  </ul>
</section>`;
  const css = `.s-numeros-c{background:var(--cor-destaque);color:var(--cor-sobre-destaque);padding-block:clamp(3rem,2rem + 4vw,5.5rem)}
.s-numeros-c__lista{display:grid;gap:1.75rem}
.s-numeros-c__item{display:grid;gap:.25rem;text-align:center}
.s-numeros-c__rotulo{font-weight:600;opacity:.85}
.s-numeros-c__valor{font-family:var(--fonte-titulo);font-weight:var(--peso-titulo);font-size:clamp(3rem,2rem + 4vw,5.5rem);line-height:1;font-variant-numeric:tabular-nums}
@media (min-width:768px){.s-numeros-c__lista{grid-template-columns:repeat(auto-fit,minmax(12rem,1fr))}.s-numeros-c__item+.s-numeros-c__item{border-left:1px solid color-mix(in srgb,var(--cor-sobre-destaque) 30%,transparent)}}`;
  return { html, css };
}
