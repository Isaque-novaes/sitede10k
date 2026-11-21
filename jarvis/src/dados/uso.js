// Contador mensal de chamadas pagas do Google, para nunca passar da cota grátis.

export const LIMITES = { places_busca: 800, places_detalhes: 800, places_foto: 800 };

export class ErroCota extends Error {
  constructor(servico) {
    super('Limite mensal de segurança do Google atingido. Novas buscas voltam no dia 1.');
    this.name = 'ErroCota';
    this.servico = servico;
  }
}

const mesDe = (data) => new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Sao_Paulo', year: 'numeric', month: '2-digit' })
  .format(data).slice(0, 7);

export async function registrarUso(loja, api, quantidade = 1, hoje = new Date()) {
  const mes = mesDe(hoje);
  const uso = await loja.atualizar('uso', (atual) => {
    const meses = { ...atual };
    meses[mes] = { ...(meses[mes] ?? {}), [api]: (meses[mes]?.[api] ?? 0) + quantidade };
    return meses;
  }, {});
  return uso[mes][api];
}

export async function podeUsar(loja, api, quantidade = 1, hoje = new Date()) {
  const limite = LIMITES[api];
  if (limite === undefined) return true;
  const uso = await loja.ler('uso', {});
  return (uso[mesDe(hoje)]?.[api] ?? 0) + quantidade <= limite;
}

export async function garantirCota(loja, api, quantidade = 1, hoje = new Date()) {
  if (!(await podeUsar(loja, api, quantidade, hoje))) throw new ErroCota(api);
}
