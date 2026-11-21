// Onde estamos: o endereço vira o título, os horários aparecem em blocos e os botões ficam embaixo.
export function render(ctx) {
  const { negocio, util } = ctx;
  const { esc } = util;
  const contato = util.linkContato();
  const blocos = (negocio.horarios ?? []).map((h, i) => {
    const [dia, ...resto] = h.split(':');
    return `<li class="s-localizacao-b__bloco" data-anim="subir" style="--ordem:${i}"><span class="s-localizacao-b__dia">${esc(resto.length ? dia.trim() : h)}</span>${resto.length ? `<span class="s-localizacao-b__hora">${esc(resto.join(':').trim())}</span>` : ''}</li>`;
  }).join('\n      ');
  const html = `<section class="secao s-localizacao s-localizacao-b" id="localizacao">
  <div class="container s-localizacao-b__caixa">
    <h2 class="s-localizacao-b__rotulo" data-anim="subir">Onde estamos</h2>
    <p class="s-localizacao-b__endereco" data-anim="subir" style="--ordem:1">${esc(negocio.endereco ?? (negocio.bairro ? `${negocio.bairro}, ${negocio.cidade}` : negocio.cidade))}</p>
    ${blocos ? `<ul class="s-localizacao-b__horarios" aria-label="Horários">
      ${blocos}
    </ul>` : ''}
    <div class="s-localizacao-b__acoes" data-anim="subir" style="--ordem:2">
      ${negocio.mapsUrl ? `<a class="botao" href="${esc(negocio.mapsUrl)}" rel="noopener">Ver no mapa</a>` : ''}
      ${contato && contato.tipo !== 'mapa' ? `<a class="link-sutil" href="${esc(contato.href)}">${esc(contato.rotulo)}</a>` : ''}
    </div>
  </div>
</section>`;
  const css = `.s-localizacao-b{background:var(--cor-superficie)}
.s-localizacao-b__caixa{display:grid;grid-template-columns:minmax(0,1fr);gap:1.75rem}
.s-localizacao-b__rotulo{font-family:var(--fonte-texto);font-weight:600;font-size:1.05rem;color:var(--cor-destaque);letter-spacing:0}
.s-localizacao-b__endereco{font-family:var(--fonte-titulo);font-weight:var(--peso-titulo);font-size:clamp(1.9rem,1.3rem + 2.8vw,3.8rem);line-height:1.08;max-width:20ch}
.s-localizacao-b__horarios{display:grid;grid-template-columns:repeat(auto-fit,minmax(9.5rem,1fr));gap:.75rem;max-width:48rem}
.s-localizacao-b__bloco{display:grid;gap:.2rem;padding:1rem 1.1rem;border-radius:12px;background:var(--cor-fundo)}
.s-localizacao-b__dia{font-weight:600}
.s-localizacao-b__hora{color:var(--cor-texto-suave)}
.s-localizacao-b__acoes{display:flex;flex-wrap:wrap;align-items:center;gap:1rem 1.75rem}`;
  return { html, css };
}
