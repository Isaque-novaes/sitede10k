// Números numa frase só, em fonte de título grande, como uma manchete.
export function render(ctx) {
  const { negocio, util } = ctx;
  const { esc } = util;
  const partes = [];
  if (negocio.nota != null) partes.push(`nota <strong class="s-numeros-b__valor">${esc(util.numero(negocio.nota, 1))}</strong> no Google`);
  if (negocio.totalAvaliacoes != null) partes.push(`<strong class="s-numeros-b__valor">${esc(util.numero(negocio.totalAvaliacoes))}</strong> avaliações`);
  if (negocio.instagram?.seguidores) partes.push(`<strong class="s-numeros-b__valor">${esc(util.numero(negocio.instagram.seguidores))}</strong> seguidores no Instagram`);
  const frase = partes.length > 1 ? `${partes.slice(0, -1).join(', ')} e ${partes.at(-1)}` : partes[0];
  const html = `<section class="secao s-numeros s-numeros-b" id="numeros" aria-label="Números">
  <div class="container">
    <p class="s-numeros-b__frase" data-anim="subir">${frase.charAt(0).toUpperCase()}${frase.slice(1)}.</p>
  </div>
</section>`;
  const css = `.s-numeros-b{border-block:1px solid color-mix(in srgb,var(--cor-texto) 12%,transparent)}
.s-numeros-b__frase{font-family:var(--fonte-titulo);font-weight:var(--peso-titulo);font-size:clamp(1.8rem,1.1rem + 3.2vw,4.2rem);line-height:1.15;max-width:24ch;color:var(--cor-texto-suave)}
.s-numeros-b__valor{color:var(--cor-destaque);font-weight:inherit}`;
  return { html, css };
}
