// Chamada final sobre foto: a última foto do negócio com véu, frase centralizada e o botão.
export function render(ctx) {
  const { negocio, textos, fotos, util } = ctx;
  const { esc } = util;
  const contato = util.linkContato();
  const foto = fotos.at(-1);
  const html = `<section class="secao s-chamada-final s-chamada-final-b${foto ? '' : ' s-chamada-final-b--sem-foto'}" id="contato">
  ${foto ? `<div class="s-chamada-final-b__fundo" data-anim="zoom-lento">${util.img(foto, { classe: 's-chamada-final-b__foto', alt: '', sizes: '100vw' })}</div>` : ''}
  <div class="container s-chamada-final-b__caixa">
    <h2 class="s-chamada-final-b__titulo" data-anim="subir">${esc(textos.chamada)}</h2>
    ${negocio.horarios?.length ? `<p class="s-chamada-final-b__horario" data-anim="subir" style="--ordem:1">${esc(negocio.horarios[0])}</p>` : ''}
    ${contato ? `<a class="botao" href="${esc(contato.href)}" data-anim="subir" style="--ordem:2">${esc(contato.rotulo)}</a>` : ''}
  </div>
</section>`;
  const css = `.s-chamada-final-b{position:relative;overflow:clip;isolation:isolate;text-align:center;padding-block:clamp(6rem,4rem + 8vw,11rem)}
.s-chamada-final-b__fundo{position:absolute;inset:0;z-index:-2}
.s-chamada-final-b__foto{width:100%;height:100%;object-fit:cover}
.s-chamada-final-b::after{content:"";position:absolute;inset:0;z-index:-1;background:color-mix(in srgb,var(--cor-fundo) 72%,transparent)}
.s-chamada-final-b--sem-foto{background:radial-gradient(circle at 50% 0%,color-mix(in srgb,var(--cor-destaque) 35%,var(--cor-fundo)),var(--cor-fundo) 70%)}
.s-chamada-final-b--sem-foto::after{display:none}
.s-chamada-final-b__caixa{display:grid;gap:1.5rem;justify-items:center}
.s-chamada-final-b__titulo{font-size:clamp(2.4rem,1.5rem + 4.4vw,5.6rem);max-width:16ch;line-height:1}
.s-chamada-final-b__horario{color:var(--cor-texto-suave)}`;
  return { html, css };
}
