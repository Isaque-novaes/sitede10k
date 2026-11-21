// Avaliações em faixa contínua: os cartões passam devagar e param quando o mouse passa por cima.
export function render(ctx) {
  const { negocio, util } = ctx;
  const { esc } = util;
  const avaliacoes = negocio.avaliacoes.filter((a) => a.texto?.trim()).slice(0, 8);
  const cartao = (a, oculto) => `<li class="s-avaliacoes-b__cartao"${oculto ? ' aria-hidden="true"' : ''}>
          <p class="s-avaliacoes-b__estrelas"><span class="estrelas" aria-label="${a.nota} de 5 estrelas">${util.estrelas(a.nota)}</span></p>
          <p class="s-avaliacoes-b__texto">${esc(util.cortar(a.texto, 280))}</p>
          <p class="s-avaliacoes-b__autor">${esc(a.autor)}</p>
        </li>`;
  const html = `<section class="secao s-avaliacoes s-avaliacoes-b" id="avaliacoes">
  <div class="container s-avaliacoes-b__cabeca">
    <h2 class="titulo-secao" data-anim="subir">O que dizem no Google</h2>
    ${negocio.nota != null ? `<p class="s-avaliacoes-b__media" data-anim="subir" style="--ordem:1"><span class="estrelas" aria-hidden="true">★</span> ${util.numero(negocio.nota, 1)}${negocio.totalAvaliacoes ? ` de média em ${util.numero(negocio.totalAvaliacoes)} avaliações` : ' de média'}</p>` : ''}
  </div>
  <div class="s-avaliacoes-b__faixa" data-anim="faixa">
    <ul class="faixa__trilho">
        ${avaliacoes.map((a) => cartao(a, false)).join('\n        ')}
        ${avaliacoes.map((a) => cartao(a, true)).join('\n        ')}
    </ul>
  </div>
</section>`;
  const css = `.s-avaliacoes-b__cabeca{display:grid;gap:.75rem;margin-bottom:2.5rem}
.s-avaliacoes-b__media{color:var(--cor-texto-suave);font-size:1.05rem}
.s-avaliacoes-b__faixa{mask-image:linear-gradient(90deg,transparent,#000 6%,#000 94%,transparent);-webkit-mask-image:linear-gradient(90deg,transparent,#000 6%,#000 94%,transparent)}
.s-avaliacoes-b__faixa .faixa__trilho{gap:1rem;padding-inline:.5rem}
.s-avaliacoes-b__cartao{width:min(80vw,23rem);flex:none;display:grid;gap:.9rem;align-content:start;padding:1.6rem;border-radius:16px;background:var(--cor-superficie);border:1px solid color-mix(in srgb,var(--cor-texto) 10%,transparent);margin-right:1rem}
.s-avaliacoes-b__texto{font-size:1.02rem;overflow-wrap:anywhere}
.s-avaliacoes-b__autor{font-weight:600;color:var(--cor-texto-suave)}`;
  return { html, css };
}
