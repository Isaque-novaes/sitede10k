// Avaliações: uma em destaque com aspas grandes, as outras numa fileira que rola para o lado.
export function render(ctx) {
  const { negocio, util } = ctx;
  const { esc } = util;
  const avaliacoes = negocio.avaliacoes.filter((a) => a.texto?.trim()).slice(0, 5);
  const [principal, ...outras] = avaliacoes;
  const cartao = (a, i) => `<li class="s-avaliacoes-a__cartao" data-anim="subir" style="--ordem:${i}">
        <p class="s-avaliacoes-a__texto">${esc(util.cortar(a.texto, 280))}</p>
        <p class="s-avaliacoes-a__autor"><span class="estrelas" aria-label="${a.nota} de 5 estrelas">${util.estrelas(a.nota)}</span> ${esc(a.autor)}</p>
      </li>`;
  const html = `<section class="secao s-avaliacoes s-avaliacoes-a" id="avaliacoes">
  <div class="container">
    <h2 class="titulo-secao" data-anim="subir">Quem já veio recomenda</h2>
    <blockquote class="s-avaliacoes-a__destaque" data-anim="subir" style="--ordem:1">
      <span class="s-avaliacoes-a__aspas" aria-hidden="true">“</span>
      <p class="s-avaliacoes-a__frase">${esc(util.cortar(principal.texto, 280))}</p>
      <footer class="s-avaliacoes-a__autor"><span class="estrelas" aria-label="${principal.nota} de 5 estrelas">${util.estrelas(principal.nota)}</span> ${esc(principal.autor)}</footer>
    </blockquote>
    ${outras.length ? `<ul class="s-avaliacoes-a__fileira">
      ${outras.map(cartao).join('\n      ')}
    </ul>` : ''}
  </div>
</section>`;
  const css = `.s-avaliacoes-a__destaque{position:relative;margin:3rem 0 2.5rem;padding-top:3.5rem;max-width:58rem}
.s-avaliacoes-a__aspas{position:absolute;top:-1.5rem;left:-.4rem;font-family:var(--fonte-titulo);font-size:9rem;line-height:1;color:var(--cor-destaque)}
.s-avaliacoes-a__frase{font-family:var(--fonte-titulo);font-size:clamp(1.5rem,1.15rem + 1.6vw,2.6rem);line-height:1.25;overflow-wrap:anywhere}
.s-avaliacoes-a__autor{margin-top:1.25rem;color:var(--cor-texto-suave);font-size:.95rem}
.s-avaliacoes-a__fileira{display:grid;grid-auto-flow:column;grid-auto-columns:min(82%,22rem);gap:1rem;overflow-x:auto;scroll-snap-type:x mandatory;padding-bottom:1rem;scrollbar-width:thin}
.s-avaliacoes-a__cartao{scroll-snap-align:start;background:var(--cor-superficie);padding:1.5rem;border-radius:10px;display:grid;gap:1rem;align-content:space-between}
.s-avaliacoes-a__texto{overflow-wrap:anywhere}
.s-avaliacoes-a__cartao .s-avaliacoes-a__autor{margin-top:0}
@media (min-width:900px){.s-avaliacoes-a__fileira{grid-auto-flow:row;grid-template-columns:repeat(auto-fit,minmax(min(16rem,100%),1fr));overflow:visible}}`;
  return { html, css };
}
