// Sobre: foto com um bloco de cor deslocado atrás e o texto ao lado.
export function render(ctx) {
  const { negocio, textos, util } = ctx;
  const { esc } = util;
  const foto = util.reservarFoto();
  const bio = negocio.instagram?.bio ? `<p class="s-sobre-a__bio" data-anim="subir" style="--ordem:2">${esc(negocio.instagram.bio)}</p>` : '';
  const html = `<section class="secao s-sobre s-sobre-a" id="sobre">
  <div class="container s-sobre-a__grade${foto ? '' : ' s-sobre-a__grade--sem-foto'}">
    ${foto ? `<figure class="s-sobre-a__figura"><div class="s-sobre-a__moldura" data-anim="revelar">${util.img(foto, { classe: 's-sobre-a__foto', alt: `Foto de ${negocio.nome}`, sizes: '(min-width: 900px) 45vw, 100vw' })}</div></figure>` : ''}
    <div class="s-sobre-a__texto">
      <h2 class="titulo-secao" data-anim="subir">Quem somos</h2>
      <p class="s-sobre-a__corpo" data-anim="subir" style="--ordem:1">${esc(textos.sobre)}</p>
      ${bio}
    </div>
  </div>
</section>`;
  const css = `.s-sobre-a__grade{display:grid;gap:3rem;align-items:center}
.s-sobre-a__figura{position:relative;margin-right:1rem}
.s-sobre-a__figura::before{content:"";position:absolute;inset:1rem -1rem -1rem 1rem;background:var(--cor-destaque);opacity:.9;z-index:0}
.s-sobre-a__moldura{position:relative;z-index:1}
.s-sobre-a__foto{width:100%;aspect-ratio:4/5;object-fit:cover}
.s-sobre-a__texto{display:grid;gap:1.5rem}
.s-sobre-a__corpo{font-size:clamp(1.1rem,1rem + .4vw,1.3rem);max-width:52ch;line-height:1.65}
.s-sobre-a__bio{color:var(--cor-texto-suave);font-style:italic;max-width:46ch;padding-left:1rem;border-left:2px solid var(--cor-destaque2)}
@media (min-width:900px){.s-sobre-a__grade{grid-template-columns:5fr 6fr;gap:5rem}.s-sobre-a__grade--sem-foto{grid-template-columns:1fr}}`;
  return { html, css };
}
