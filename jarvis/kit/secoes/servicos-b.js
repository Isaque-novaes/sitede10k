// Serviços em mosaico de fotos: cada serviço sobre uma foto do negócio (ou na cor da superfície, sem foto).
export function render(ctx) {
  const { negocio, textos, util } = ctx;
  const { esc } = util;
  // Ou todos os serviços ganham uma foto diferente, ou nenhum ganha.
  const comFotos = util.fotosLivres().length >= textos.servicos.length;
  const itens = textos.servicos.map((s, i) => {
    const foto = comFotos ? util.reservarFoto() : null;
    return `<li class="s-servicos-b__tile${foto ? ' s-servicos-b__tile--foto' : ''}" data-anim="subir" style="--ordem:${i % 3}">
        ${foto ? util.img(foto, { classe: 's-servicos-b__foto', alt: `${s.nome} na ${negocio.nome}`, sizes: '(min-width: 900px) 33vw, 100vw' }) : ''}
        <div class="s-servicos-b__info">
          <h3 class="s-servicos-b__nome">${esc(s.nome)}</h3>
          <p class="s-servicos-b__desc">${esc(s.descricao)}</p>
        </div>
      </li>`;
  }).join('\n      ');
  const html = `<section class="secao s-servicos s-servicos-b" id="servicos">
  <div class="container">
    <h2 class="titulo-secao s-servicos-b__titulo" data-anim="subir">O que você encontra aqui</h2>
    <ul class="s-servicos-b__grade">
      ${itens}
    </ul>
  </div>
</section>`;
  const css = `.s-servicos-b__titulo{margin-bottom:2.5rem}
.s-servicos-b__grade{display:grid;gap:.9rem}
.s-servicos-b__tile{position:relative;min-height:15rem;display:flex;align-items:flex-end;border-radius:14px;overflow:hidden;background:var(--cor-superficie);isolation:isolate}
.s-servicos-b__foto{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;z-index:-2;transition:transform .9s cubic-bezier(.2,.7,.2,1)}
.s-servicos-b__tile--foto::after{content:"";position:absolute;inset:0;z-index:-1;background:linear-gradient(to top,color-mix(in srgb,var(--cor-fundo) 92%,transparent) 15%,color-mix(in srgb,var(--cor-fundo) 10%,transparent) 75%)}
.s-servicos-b__tile:hover .s-servicos-b__foto{transform:scale(1.05)}
.s-servicos-b__info{padding:1.5rem;display:grid;gap:.4rem}
.s-servicos-b__nome{font-size:clamp(1.4rem,1.2rem + .9vw,1.9rem)}
.s-servicos-b__desc{color:var(--cor-texto-suave);max-width:36ch}
.s-servicos-b__tile:not(.s-servicos-b__tile--foto){border-top:4px solid var(--cor-destaque);min-height:11rem}
@media (min-width:700px){.s-servicos-b__grade{grid-template-columns:repeat(2,1fr)}}
@media (min-width:1000px){.s-servicos-b__grade{grid-template-columns:repeat(3,1fr)}.s-servicos-b__tile{min-height:22rem}.s-servicos-b__tile:first-child{grid-row:span 2}}`;
  return { html, css };
}
