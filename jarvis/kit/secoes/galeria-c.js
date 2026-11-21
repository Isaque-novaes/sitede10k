// Galeria em grade com uma foto grande de destaque e as outras menores ao redor.
export function render(ctx) {
  const { negocio, fotos, util } = ctx;
  const lista = (fotos.length > 5 ? fotos.slice(1) : fotos).slice(0, 7);
  const itens = lista.map((f, i) => `<figure class="s-galeria-c__item${i === 0 ? ' s-galeria-c__item--grande' : ''}" data-anim="revelar">${util.img(f, { classe: 's-galeria-c__foto', alt: `Foto ${i + 1} de ${negocio.nome}`, sizes: i === 0 ? '(min-width: 900px) 50vw, 100vw' : '(min-width: 900px) 25vw, 50vw' })}</figure>`).join('\n    ');
  const html = `<section class="secao s-galeria s-galeria-c" id="galeria">
  <div class="container">
    <h2 class="titulo-secao s-galeria-c__titulo" data-anim="subir">Veja com os próprios olhos</h2>
    <div class="s-galeria-c__grade">
    ${itens}
    </div>
  </div>
</section>`;
  const css = `.s-galeria-c__titulo{margin-bottom:2.5rem;max-width:16ch}
.s-galeria-c__grade{display:grid;grid-template-columns:repeat(2,1fr);grid-auto-rows:9rem;gap:.6rem}
.s-galeria-c__item{overflow:hidden;border-radius:4px}
.s-galeria-c__item--grande{grid-column:1 / -1;grid-row:span 2}
.s-galeria-c__foto{width:100%;height:100%;object-fit:cover}
@media (min-width:900px){.s-galeria-c__grade{grid-template-columns:repeat(4,1fr);grid-auto-rows:13rem;gap:.8rem}.s-galeria-c__item--grande{grid-column:span 2}}`;
  return { html, css };
}
