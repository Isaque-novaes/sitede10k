// Onde estamos: endereço e botão de mapa de um lado, horários do outro.
export function render(ctx) {
  const { negocio, util } = ctx;
  const { esc } = util;
  const horarios = (negocio.horarios ?? []).map((h) => {
    const [dia, ...resto] = h.split(':');
    return resto.length
      ? `<div class="s-localizacao-a__linha"><dt>${esc(dia.trim())}</dt><dd>${esc(resto.join(':').trim())}</dd></div>`
      : `<div class="s-localizacao-a__linha"><dt>${esc(h)}</dt><dd></dd></div>`;
  }).join('\n        ');
  const html = `<section class="secao s-localizacao s-localizacao-a" id="localizacao">
  <div class="container s-localizacao-a__grade">
    <div class="s-localizacao-a__onde" data-anim="subir">
      <h2 class="titulo-secao">Onde estamos</h2>
      ${negocio.endereco ? `<p class="s-localizacao-a__endereco">${esc(negocio.endereco)}</p>` : ''}
      ${negocio.mapsUrl ? `<a class="link-sutil" href="${esc(negocio.mapsUrl)}" rel="noopener">Ver no mapa</a>` : ''}
    </div>
    ${horarios ? `<div class="s-localizacao-a__horarios" data-anim="subir" style="--ordem:1">
      <h3 class="s-localizacao-a__subtitulo">Horários</h3>
      <dl>
        ${horarios}
      </dl>
    </div>` : ''}
  </div>
</section>`;
  const css = `.s-localizacao-a__grade{display:grid;gap:3rem}
.s-localizacao-a__onde{display:grid;gap:1.25rem;align-content:start}
.s-localizacao-a__endereco{font-size:clamp(1.15rem,1rem + .5vw,1.4rem);max-width:30ch}
.s-localizacao-a__subtitulo{font-size:1.5rem;margin-bottom:1rem}
.s-localizacao-a__linha{display:flex;justify-content:space-between;gap:1rem;padding-block:.85rem;border-bottom:1px solid color-mix(in srgb,var(--cor-texto) 14%,transparent)}
.s-localizacao-a__linha dt{font-weight:600}
.s-localizacao-a__linha dd{color:var(--cor-texto-suave);text-align:right}
@media (min-width:900px){.s-localizacao-a__grade{grid-template-columns:1fr 1fr;gap:5rem}}`;
  return { html, css };
}
