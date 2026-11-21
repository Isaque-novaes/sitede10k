// Sobre como manifesto: o texto vira a peça principal, em fonte de título grande, com uma foto redonda pequena.
export function render(ctx) {
  const { negocio, textos, fotos, util } = ctx;
  const { esc } = util;
  const foto = fotos[2] ?? fotos[0];
  const html = `<section class="secao s-sobre s-sobre-b" id="sobre">
  <div class="container s-sobre-b__caixa">
    <h2 class="s-sobre-b__rotulo" data-anim="subir">Quem somos</h2>
    <p class="s-sobre-b__manifesto" data-anim="subir" style="--ordem:1">${foto ? `<span class="s-sobre-b__selo">${util.img(foto, { classe: 's-sobre-b__foto', alt: `Foto de ${negocio.nome}`, sizes: '6rem' })}</span>` : ''}${esc(textos.sobre)}</p>
    ${negocio.instagram?.usuario ? `<p class="s-sobre-b__assinatura" data-anim="subir" style="--ordem:2">${esc(negocio.nome)}, no Instagram <a href="https://www.instagram.com/${esc(negocio.instagram.usuario)}/" rel="noopener">@${esc(negocio.instagram.usuario)}</a></p>` : `<p class="s-sobre-b__assinatura" data-anim="subir" style="--ordem:2">${esc(negocio.nome)}</p>`}
  </div>
</section>`;
  const css = `.s-sobre-b__caixa{display:grid;gap:1.75rem}
.s-sobre-b__rotulo{font-family:var(--fonte-texto);font-weight:600;font-size:1.05rem;color:var(--cor-destaque);letter-spacing:0}
.s-sobre-b__manifesto{font-family:var(--fonte-titulo);font-weight:var(--peso-titulo);font-size:clamp(1.7rem,1.2rem + 2.4vw,3.4rem);line-height:1.18;max-width:28ch;text-wrap:pretty}
.s-sobre-b__selo{display:inline-block;width:1.6em;height:1.1em;vertical-align:-.12em;margin-right:.3em;border-radius:999px;overflow:hidden;border:2px solid var(--cor-destaque)}
.s-sobre-b__foto{width:100%;height:100%;object-fit:cover}
.s-sobre-b__assinatura{color:var(--cor-texto-suave)}
.s-sobre-b__assinatura a{color:var(--cor-texto)}`;
  return { html, css };
}
