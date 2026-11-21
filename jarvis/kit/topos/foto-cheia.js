// Topo: foto do negócio em tela cheia, título grande ancorado embaixo, a foto se funde com a cor da página.
export function render(ctx) {
  const { negocio, textos, util } = ctx;
  const fotos = ctx.fotosTopo;
  const { esc } = util;
  const foto = fotos[0];
  const contato = util.linkContato();
  const ancora = util.ancora();
  const nota = negocio.nota != null
    ? `<p class="t-foto-cheia__nota" data-anim="subir" style="--ordem:4"><span class="estrelas" aria-hidden="true">★</span> ${util.numero(negocio.nota, 1)} no Google${negocio.totalAvaliacoes ? ` <span>(${util.numero(negocio.totalAvaliacoes)} avaliações)</span>` : ''}</p>`
    : '';
  const html = `<header class="topo t-foto-cheia">
  ${foto ? `<div class="t-foto-cheia__midia" data-anim="zoom-lento">${util.img(foto, { classe: 't-foto-cheia__foto', prioridade: true, alt: `Foto de ${negocio.nome}` })}</div>` : ''}
  <div class="t-foto-cheia__veu" aria-hidden="true"></div>
  <div class="container t-foto-cheia__conteudo">
    <h1 class="t-foto-cheia__titulo" data-titulo-principal data-anim="texto-partes">${esc(textos.titulo)}</h1>
    <p class="t-foto-cheia__sub" data-anim="subir" style="--ordem:3">${esc(textos.subtitulo)}</p>
    <div class="t-foto-cheia__acoes" data-anim="subir" style="--ordem:4">
      ${contato ? `<a class="botao" href="${esc(contato.href)}">${esc(contato.rotulo)}</a>` : ''}
      ${ancora ? `<a class="link-sutil" href="${ancora.href}">${esc(ancora.rotulo)}</a>` : ''}
    </div>
    ${nota}
  </div>
</header>`;
  const css = `.t-foto-cheia{position:relative;min-height:100vh;min-height:100svh;display:flex;align-items:flex-end;overflow:clip;isolation:isolate;padding-block:7.5rem calc(2.5rem + var(--altura-faixa,3.6rem))}
.t-foto-cheia__midia{position:absolute;inset:0;z-index:-2;transform-origin:60% 40%}
.t-foto-cheia__foto{width:100%;height:100%;object-fit:cover}
.t-foto-cheia__veu{position:absolute;inset:0;z-index:-1;background:linear-gradient(to top,var(--cor-fundo) 0%,color-mix(in srgb,var(--cor-fundo) 92%,transparent) 30%,color-mix(in srgb,var(--cor-fundo) 82%,transparent) 54%,color-mix(in srgb,var(--cor-fundo) 45%,transparent) 76%,color-mix(in srgb,var(--cor-fundo) 25%,transparent) 88%,color-mix(in srgb,var(--cor-fundo) 55%,transparent) 100%)}
.t-foto-cheia__conteudo{display:grid;gap:1.25rem}
.t-foto-cheia__titulo{font-size:clamp(2.8rem,1.6rem + 6.4vw,7.25rem);line-height:.97;max-width:13ch}
.t-foto-cheia__sub{font-size:clamp(1.1rem,1rem + .45vw,1.4rem);max-width:38ch;color:var(--cor-texto-suave)}
.t-foto-cheia__acoes{display:flex;flex-wrap:wrap;align-items:center;gap:.75rem 1.75rem;margin-top:.5rem}
.t-foto-cheia__nota{font-size:.95rem;color:var(--cor-texto-suave)}
@media (min-width:900px){.t-foto-cheia{padding-block:9rem calc(4rem + var(--altura-faixa,2.4rem))}.t-foto-cheia__conteudo{grid-template-columns:minmax(0,1fr) auto;column-gap:3rem}.t-foto-cheia__conteudo>*{grid-column:1}.t-foto-cheia__nota{grid-column:2;grid-row:1 / span 3;align-self:end;text-align:right;max-width:18rem}.t-foto-cheia__nota span{white-space:nowrap}}`;
  return { html, css };
}
