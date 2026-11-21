// Galeria em faixa de filme: fotos altas lado a lado, rolando para o lado com encaixe.
export function render(ctx) {
  const { negocio, fotos, util } = ctx;
  const lista = fotos.slice(0, 10);
  const itens = lista.map((f, i) => `<li class="s-galeria-b__item">${util.img(f, { reservar: false, classe: 's-galeria-b__foto', alt: `Foto ${i + 1} de ${negocio.nome}`, sizes: '(min-width: 900px) 28vw, 78vw' })}</li>`).join('\n      ');
  const html = `<section class="secao s-galeria s-galeria-b" id="galeria">
  <div class="container s-galeria-b__cabeca">
    <h2 class="titulo-secao" data-anim="subir">Por dentro</h2>
    <p class="s-galeria-b__dica" data-anim="subir" style="--ordem:1">Arraste para ver as ${lista.length} fotos</p>
  </div>
  <ul class="s-galeria-b__faixa" data-anim="subir" style="--ordem:2" tabindex="0" aria-label="Fotos de ${util.esc(negocio.nome)}">
      ${itens}
  </ul>
</section>`;
  const css = `.s-galeria-b__cabeca{display:flex;flex-wrap:wrap;align-items:baseline;justify-content:space-between;gap:1rem;margin-bottom:2rem}
.s-galeria-b__dica{color:var(--cor-texto-suave);font-size:.95rem}
.s-galeria-b__faixa{display:grid;grid-auto-flow:column;grid-auto-columns:min(78vw,26rem);gap:.9rem;overflow-x:auto;scroll-snap-type:x mandatory;padding-inline:max(1.25rem,(100vw - 1180px) / 2);padding-bottom:1rem;scrollbar-width:thin;scroll-padding-inline:max(1.25rem,(100vw - 1180px) / 2)}
.s-galeria-b__item{scroll-snap-align:start;border-radius:12px;overflow:hidden}
.s-galeria-b__foto{width:100%;height:100%;aspect-ratio:3/4;object-fit:cover}
@media (min-width:768px){.s-galeria-b__faixa{padding-inline:max(2rem,(100vw - 1180px) / 2);scroll-padding-inline:max(2rem,(100vw - 1180px) / 2)}}`;
  return { html, css };
}
