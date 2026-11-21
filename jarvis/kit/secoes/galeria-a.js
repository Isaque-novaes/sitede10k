// Galeria em colunas, com alturas naturais das fotos.
export function render(ctx) {
  const { negocio, fotos, util } = ctx;
  const lista = fotos.length > 4 ? fotos.slice(1, 9) : fotos.slice(0, 8);
  const itens = lista.map((f, i) => `<figure class="s-galeria-a__item" data-anim="subir" style="--ordem:${i % 3}">${util.img(f, { reservar: false, classe: 's-galeria-a__foto', alt: `Foto ${i + 1} de ${negocio.nome}`, sizes: '(min-width: 900px) 33vw, 50vw' })}</figure>`).join('\n    ');
  const html = `<section class="secao s-galeria s-galeria-a" id="galeria">
  <div class="container">
    <h2 class="titulo-secao s-galeria-a__titulo" data-anim="subir">Um pouco do nosso dia a dia</h2>
    <div class="s-galeria-a__colunas">
    ${itens}
    </div>
  </div>
</section>`;
  const css = `.s-galeria-a__titulo{margin-bottom:2.5rem;max-width:18ch}
.s-galeria-a__colunas{columns:2;column-gap:.75rem}
.s-galeria-a__item{break-inside:avoid;margin-bottom:.75rem;overflow:hidden;border-radius:6px}
.s-galeria-a__foto{width:100%;transition:transform .8s cubic-bezier(.2,.7,.2,1)}
.s-galeria-a__item:hover .s-galeria-a__foto{transform:scale(1.04)}
@media (min-width:900px){.s-galeria-a__colunas{columns:3;column-gap:1rem}.s-galeria-a__item{margin-bottom:1rem}}`;
  return { html, css };
}
