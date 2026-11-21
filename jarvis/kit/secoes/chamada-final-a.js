// Chamada final: faixa na cor de destaque, frase grande e o botão de contato.
export function render(ctx) {
  const { negocio, textos, util } = ctx;
  const { esc } = util;
  const contato = util.linkContato();
  const lugar = negocio.bairro ? `${negocio.bairro}, ${negocio.cidade}` : negocio.cidade;
  const html = `<section class="secao s-chamada-final s-chamada-final-a" id="contato">
  <div class="container s-chamada-final-a__caixa">
    <h2 class="s-chamada-final-a__titulo" data-anim="subir">${esc(textos.chamada)}</h2>
    <p class="s-chamada-final-a__lugar" data-anim="subir" style="--ordem:1">${esc(negocio.nome)}, ${esc(lugar)}</p>
    ${contato ? `<a class="botao s-chamada-final-a__botao" href="${esc(contato.href)}" data-anim="subir" style="--ordem:2">${esc(contato.rotulo)}</a>` : ''}
  </div>
</section>`;
  const css = `.s-chamada-final-a{background:var(--cor-destaque);color:var(--cor-sobre-destaque)}
.s-chamada-final-a__caixa{display:grid;gap:1.5rem;justify-items:start}
.s-chamada-final-a__titulo{font-size:clamp(2.4rem,1.5rem + 4.4vw,5.5rem);max-width:14ch;line-height:1}
.s-chamada-final-a__lugar{opacity:.85}
.s-chamada-final-a__botao{background:var(--cor-sobre-destaque);color:var(--cor-destaque);margin-top:.5rem}`;
  return { html, css };
}
