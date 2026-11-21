// Onde estamos com um mapa desenhado (sem carregar mapa de verdade) que leva ao Google Maps.
export function render(ctx) {
  const { negocio, util } = ctx;
  const { esc } = util;
  const horarios = (negocio.horarios ?? []).map((h) => `<li>${esc(h)}</li>`).join('');
  const mapa = `<span class="s-localizacao-c__mapa" aria-hidden="true"><span class="s-localizacao-c__pino"></span></span>`;
  const html = `<section class="secao s-localizacao s-localizacao-c" id="localizacao">
  <div class="container s-localizacao-c__grade">
    ${negocio.mapsUrl ? `<a class="s-localizacao-c__cartao" href="${esc(negocio.mapsUrl)}" rel="noopener" data-anim="revelar">${mapa}<span class="s-localizacao-c__ver">Ver no mapa</span></a>` : `<div class="s-localizacao-c__cartao" data-anim="revelar">${mapa}</div>`}
    <div class="s-localizacao-c__info" data-anim="subir">
      <h2 class="titulo-secao">Venha nos visitar</h2>
      <p class="s-localizacao-c__endereco">${esc(negocio.endereco ?? (negocio.bairro ? `${negocio.bairro}, ${negocio.cidade}` : negocio.cidade))}</p>
      ${horarios ? `<ul class="s-localizacao-c__horarios">${horarios}</ul>` : ''}
    </div>
  </div>
</section>`;
  const css = `.s-localizacao-c__grade{display:grid;gap:2.5rem;align-items:center}
.s-localizacao-c__cartao{position:relative;display:block;aspect-ratio:4/3;border-radius:18px;overflow:hidden;text-decoration:none;background:var(--cor-superficie)}
.s-localizacao-c__mapa{position:absolute;inset:0;background-color:var(--cor-superficie);background-image:linear-gradient(color-mix(in srgb,var(--cor-texto) 9%,transparent) 2px,transparent 2px),linear-gradient(90deg,color-mix(in srgb,var(--cor-texto) 9%,transparent) 2px,transparent 2px),linear-gradient(35deg,transparent 46%,color-mix(in srgb,var(--cor-destaque2) 45%,transparent) 46%,color-mix(in srgb,var(--cor-destaque2) 45%,transparent) 50%,transparent 50%);background-size:44px 44px,44px 44px,100% 100%}
.s-localizacao-c__pino{position:absolute;left:50%;top:46%;width:2.4rem;height:2.4rem;margin:-1.2rem 0 0 -1.2rem;border-radius:50% 50% 50% 0;transform:rotate(-45deg);background:var(--cor-destaque);box-shadow:0 0 0 10px color-mix(in srgb,var(--cor-destaque) 25%,transparent)}
.s-localizacao-c__ver{position:absolute;left:1rem;bottom:1rem;padding:.6rem 1rem;border-radius:999px;background:var(--cor-fundo);font-weight:600;font-size:.95rem}
.s-localizacao-c__info{display:grid;gap:1.1rem}
.s-localizacao-c__endereco{font-size:clamp(1.1rem,1rem + .4vw,1.3rem)}
.s-localizacao-c__horarios{display:grid;gap:.35rem;color:var(--cor-texto-suave)}
@media (min-width:900px){.s-localizacao-c__grade{grid-template-columns:6fr 5fr;gap:4.5rem}}`;
  return { html, css };
}
