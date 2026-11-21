// Chamada final dividida: frase enorme de um lado, todas as formas de contato do outro.
export function render(ctx) {
  const { negocio, textos, util } = ctx;
  const { esc } = util;
  const contato = util.linkContato();
  const linhas = [];
  if (negocio.telefone) linhas.push(`<li><span class="s-chamada-final-c__rotulo">Telefone</span> ${esc(negocio.telefone)}</li>`);
  if (negocio.instagram?.usuario) linhas.push(`<li><span class="s-chamada-final-c__rotulo">Instagram</span> <a href="https://www.instagram.com/${esc(negocio.instagram.usuario)}/" rel="noopener">@${esc(negocio.instagram.usuario)}</a></li>`);
  if (negocio.endereco) linhas.push(`<li><span class="s-chamada-final-c__rotulo">Endereço</span> ${esc(negocio.endereco)}</li>`);
  const html = `<section class="secao s-chamada-final s-chamada-final-c" id="contato">
  <div class="container s-chamada-final-c__grade">
    <h2 class="s-chamada-final-c__titulo" data-anim="texto-partes">${esc(textos.chamada)}</h2>
    <div class="s-chamada-final-c__contatos" data-anim="subir" style="--ordem:2">
      ${contato ? `<a class="botao" href="${esc(contato.href)}">${esc(contato.rotulo)}</a>` : ''}
      ${linhas.length ? `<ul class="s-chamada-final-c__lista">${linhas.join('')}</ul>` : ''}
    </div>
  </div>
</section>`;
  const css = `.s-chamada-final-c{background:var(--cor-superficie);border-top:6px solid var(--cor-destaque)}
.s-chamada-final-c__grade{display:grid;gap:2.5rem}
.s-chamada-final-c__titulo{font-size:clamp(2.6rem,1.6rem + 5vw,6.2rem);line-height:.98;max-width:12ch}
.s-chamada-final-c__contatos{display:grid;gap:1.75rem;align-content:start;justify-items:start}
.s-chamada-final-c__lista{display:grid;gap:.9rem}
.s-chamada-final-c__lista li{display:grid;gap:.1rem}
.s-chamada-final-c__rotulo{font-size:.85rem;color:var(--cor-texto-suave)}
@media (min-width:900px){.s-chamada-final-c__grade{grid-template-columns:7fr 4fr;gap:4rem;align-items:end}}`;
  return { html, css };
}
