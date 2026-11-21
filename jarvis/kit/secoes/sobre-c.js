// Sobre em faixa de foto inteira com paralaxe, e o texto numa caixa sobreposta.
export function render(ctx) {
  const { negocio, textos, fotos, util } = ctx;
  const { esc } = util;
  const foto = fotos[3] ?? fotos[1] ?? fotos[0];
  const html = `<section class="secao s-sobre s-sobre-c${foto ? '' : ' s-sobre-c--sem-foto'}" id="sobre">
  ${foto ? `<div class="s-sobre-c__fundo"><div class="s-sobre-c__camada" data-anim="paralaxe" data-fator="0.1">${util.img(foto, { classe: 's-sobre-c__foto', alt: '', sizes: '100vw' })}</div></div>` : ''}
  <div class="container">
    <div class="s-sobre-c__caixa" data-anim="subir">
      <h2 class="titulo-secao">A nossa história</h2>
      <p class="s-sobre-c__texto">${esc(textos.sobre)}</p>
      ${negocio.instagram?.bio ? `<p class="s-sobre-c__bio">${esc(negocio.instagram.bio)}</p>` : ''}
    </div>
  </div>
</section>`;
  const css = `.s-sobre-c{position:relative;overflow:clip;isolation:isolate;padding-block:clamp(8rem,5rem + 10vw,14rem)}
.s-sobre-c__fundo{position:absolute;inset:0;z-index:-1}
.s-sobre-c__camada{position:absolute;inset:-12% 0}
.s-sobre-c__foto{width:100%;height:100%;object-fit:cover}
.s-sobre-c--sem-foto{padding-block:clamp(4.5rem,3rem + 6vw,8.5rem)}
.s-sobre-c__caixa{display:grid;gap:1.25rem;max-width:36rem;padding:clamp(1.75rem,1.25rem + 2vw,3rem);background:var(--cor-fundo);border-radius:4px;box-shadow:0 28px 60px -24px rgb(0 0 0 / .3)}
.s-sobre-c--sem-foto .s-sobre-c__caixa{background:var(--cor-superficie);box-shadow:none}
.s-sobre-c__texto{font-size:clamp(1.05rem,1rem + .3vw,1.2rem);line-height:1.7}
.s-sobre-c__bio{color:var(--cor-texto-suave);font-style:italic}`;
  return { html, css };
}
