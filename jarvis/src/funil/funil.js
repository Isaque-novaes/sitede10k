// Funil de vendas: etapas, acompanhamento e quem cobrar hoje.

export const ETAPAS = ['encontrado', 'preparado', 'abordado', 'respondeu', 'reuniao', 'proposta', 'fechou', 'perdido', 'descartado'];
const ETAPAS_DE_CONTATO = new Set(['abordado', 'respondeu', 'reuniao', 'proposta']);
const MAX_ACOMPANHAMENTOS = 2;

/** "AAAA-MM-DD" da data no fuso de São Paulo. */
export const dataEmSaoPaulo = (data) => new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Sao_Paulo', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date(data));

/** Dias de calendário (em São Paulo) entre duas datas. */
export function diasEntre(inicio, fim) {
  const emUtc = (d) => { const [a, m, dd] = dataEmSaoPaulo(d).split('-').map(Number); return Date.UTC(a, m - 1, dd); };
  return Math.round((emUtc(fim) - emUtc(inicio)) / 86400000);
}

const comInteracao = (registro, interacao) => [...(registro.historico ?? []), interacao];

/** Muda a etapa do negócio (devolve um novo registro). */
export function mudarEtapa(registro, etapa, agora = new Date(), detalhe) {
  if (!ETAPAS.includes(etapa)) throw new Error(`Etapa desconhecida: ${etapa}.`);
  if (registro.etapa === 'fechou' && etapa !== 'fechou') throw new Error('Negócio já fechado.');
  if (registro.naoContatar && ETAPAS_DE_CONTATO.has(etapa)) throw new Error('Este negócio pediu para não ser contatado.');
  const data = agora.toISOString();
  return {
    ...registro,
    etapa,
    datas: { ...(registro.datas ?? {}), [etapa]: data },
    historico: comInteracao(registro, { tipo: 'etapa', data, detalhe: detalhe ?? etapa }),
  };
}

/** Registra que a mensagem de acompanhamento foi enviada. No máximo 2. */
export function registrarAcompanhamento(registro, agora = new Date()) {
  const feitos = registro.acompanhamentos ?? 0;
  if (feitos >= MAX_ACOMPANHAMENTOS) throw new Error('Já foram 2 acompanhamentos. O melhor agora é marcar como perdido.');
  const data = agora.toISOString();
  return {
    ...registro,
    acompanhamentos: feitos + 1,
    ultimoAcompanhamento: data,
    historico: comInteracao(registro, { tipo: 'acompanhamento', data, detalhe: String(feitos + 1) }),
  };
}

/** O negócio pediu para não ser contatado: sai do funil para sempre. */
export function marcarNaoContatar(registro, agora = new Date()) {
  const data = agora.toISOString();
  return {
    ...registro,
    naoContatar: true,
    etapa: 'descartado',
    datas: { ...(registro.datas ?? {}), descartado: data },
    historico: comInteracao(registro, { tipo: 'nao_contatar', data }),
  };
}

/**
 * Quem precisa de uma nova mensagem hoje e quem já pode ser dado como perdido.
 * @returns {{cobrar:{registro:any, qual:1|2}[], sugerirPerdido:any[]}}
 */
export function cobrarHoje(registros, agora = new Date(), dias = [3, 7]) {
  const cobrar = [];
  const sugerirPerdido = [];
  for (const r of registros) {
    if (r.etapa !== 'abordado' || r.naoContatar || !r.datas?.abordado) continue;
    const feitos = r.acompanhamentos ?? 0;
    if (feitos === 0 && diasEntre(r.datas.abordado, agora) >= dias[0]) cobrar.push({ registro: r, qual: 1 });
    else if (feitos === 1 && r.ultimoAcompanhamento && diasEntre(r.ultimoAcompanhamento, agora) >= dias[1]) cobrar.push({ registro: r, qual: 2 });
    else if (feitos >= 2 && r.ultimoAcompanhamento && diasEntre(r.ultimoAcompanhamento, agora) >= dias[1]) sugerirPerdido.push(r);
  }
  return { cobrar, sugerirPerdido };
}
