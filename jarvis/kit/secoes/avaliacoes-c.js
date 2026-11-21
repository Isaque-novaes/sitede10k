// Avaliações com um resumo da nota à esquerda e três depoimentos em grade.
export function render(ctx) {
  const { negocio, util } = ctx;
  const { esc } = util;
  const avaliacoes = negocio.avaliacoes.filter((a) => a.texto?.trim()).slice(0, 3);
  const itens = avaliacoes.map((a, i) => `<li class="s-avaliacoes-c__item" data-anim="subir" style="--ordem:${i}">
        <span class="estrelas s-avaliacoes-c__estrelas" aria-label="${a.nota} de 5 estrelas">${util.estrelas(a.nota)}</span>
        <p class="s-avaliacoes-c__texto">${esc(util.cortar(a.texto, 280))}</p>
        <p class="s-avaliacoes-c__autor">${esc(a.autor)}</p>
      </li>`).join('\n      ');
  const html = `<section class="secao s-avaliacoes s-avaliacoes-c" id="avaliacoes">
  <div class="container s-avaliacoes-c__grade">
    <div class="s-avaliacoes-c__resumo" data-anim="subir">
      <h2 class="titulo-secao">Avaliações reais</h2>
      ${negocio.nota != null ? `<p class="s-avaliacoes-c__nota">${esc(util.numero(negocio.nota, 1))}</p>
      <p class="s-avaliacoes-c__base"><span class="estrelas" aria-hidden="true">${util.estrelas(negocio.nota)}</span>${negocio.totalAvaliacoes ? ` ${esc(util.numero(negocio.totalAvaliacoes))} avaliações no Google` : ' no Google'}</p>` : ''}
    </div>
    <ul class="s-avaliacoes-c__lista">
      ${itens}
    </ul>
  </div>
</section>`;
  const css = `.s-avaliacoes-c__grade{display:grid;gap:2.5rem}
.s-avaliacoes-c__resumo{display:grid;gap:.5rem;align-content:start}
.s-avaliacoes-c__nota{font-family:var(--fonte-titulo);font-weight:var(--peso-titulo);font-size:clamp(4rem,3rem + 4vw,7rem);line-height:1;color:var(--cor-destaque);margin-top:1rem}
.s-avaliacoes-c__base{color:var(--cor-texto-suave)}
.s-avaliacoes-c__lista{display:grid;gap:1.5rem}
.s-avaliacoes-c__item{display:grid;gap:.75rem;padding-bottom:1.5rem;border-bottom:1px solid color-mix(in srgb,var(--cor-texto) 14%,transparent)}
.s-avaliacoes-c__texto{font-size:1.08rem;overflow-wrap:break-word}
.s-avaliacoes-c__autor{font-weight:600;color:var(--cor-texto-suave)}
@media (min-width:900px){.s-avaliacoes-c__grade{grid-template-columns:4fr 8fr;gap:4rem}.s-avaliacoes-c__lista{grid-template-columns:repeat(auto-fit,minmax(14rem,1fr));gap:2rem}.s-avaliacoes-c__item{border-bottom:0;padding-bottom:0;padding-top:1.25rem;border-top:1px solid color-mix(in srgb,var(--cor-texto) 14%,transparent)}}`;
  return { html, css };
}
