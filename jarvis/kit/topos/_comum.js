// Pedaços repetidos entre os topos: botões de ação e nota do Google.
export function acoes(ctx, classe, ordem = 4) {
  const { util } = ctx;
  const contato = util.linkContato();
  const ancora = util.ancora();
  if (!contato && !ancora) return '';
  return `<div class="topo-acoes ${classe}" data-anim="subir" style="--ordem:${ordem}">
      ${contato ? `<a class="botao" href="${util.esc(contato.href)}">${util.esc(contato.rotulo)}</a>` : ''}
      ${ancora ? `<a class="link-sutil" href="${ancora.href}">${util.esc(ancora.rotulo)}</a>` : ''}
    </div>`;
}

export function nota(ctx, classe, ordem = 5) {
  const { negocio, util } = ctx;
  if (negocio.nota == null) return '';
  const total = negocio.totalAvaliacoes ? ` <span class="topo-nota__total">(${util.numero(negocio.totalAvaliacoes)} avaliações)</span>` : '';
  return `<p class="topo-nota ${classe}" data-anim="subir" style="--ordem:${ordem}"><span class="estrelas" aria-hidden="true">★</span> ${util.numero(negocio.nota, 1)} no Google${total}</p>`;
}

export const CSS_COMUM = `.topo-acoes{display:flex;flex-wrap:wrap;align-items:center;gap:.75rem 1.75rem}
.topo-nota{font-size:.95rem;color:var(--cor-texto-suave)}
.topo-nota__total{white-space:nowrap}`;
