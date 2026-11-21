import { mensagensPadrao, ROTEIRO_OBJECOES, temPressao } from '../vendas/mensagens.js';
import { limparTextos } from '../util/texto.js';
import { tentarIA, REGRAS_DE_ESCRITA } from './comum.js';

const CHAVES = Object.keys(ROTEIRO_OBJECOES);
const ESQUEMA = {
  type: 'OBJECT',
  properties: {
    primeira: { type: 'STRING' },
    acompanhamento1: { type: 'STRING' },
    acompanhamento2: { type: 'STRING' },
    objecoes: { type: 'OBJECT', properties: Object.fromEntries(CHAVES.map((k) => [k, { type: 'STRING' }])), required: CHAVES },
  },
  required: ['primeira', 'acompanhamento1', 'acompanhamento2', 'objecoes'],
};

function serve(a, { url, nomeUsuario }) {
  if (!a?.primeira || a.primeira.length > 400) return false;
  if (!a.primeira.includes(url) || !a.primeira.includes(nomeUsuario)) return false;
  if ([a.primeira, a.acompanhamento1, a.acompanhamento2].some(temPressao)) return false;
  return CHAVES.every((k) => typeof a.objecoes?.[k] === 'string' && a.objecoes[k].trim());
}

/**
 * Mensagens de abordagem adaptadas pela IA, com a padrão como alternativa.
 * @returns {Promise<import('../prospeccao/tipos.js').Abordagem & {porIA:boolean, aviso?:string}>}
 */
export async function escreverAbordagem(registro, diagnostico, { url, nomeUsuario, estudio, gemini }) {
  const prompt = [
    `Você é ${nomeUsuario}, do ${estudio}, e faz sites para negócios locais.`,
    `Escreva mensagens de WhatsApp para o dono de ${registro.nome} (${registro.nicho}, ${registro.cidade ?? ''}).`,
    `Diagnóstico: ${diagnostico?.resumo ?? ''}`,
    `Achado principal: ${diagnostico?.achadoPrincipal ?? ''}`,
    `Link da amostra do site que você fez para eles: ${url}`,
    'A primeira mensagem tem até 400 caracteres, se apresenta, cita um achado concreto do diagnóstico, traz o link exatamente como está e termina assinada com o seu nome.',
    'Os dois acompanhamentos são curtos, gentis, lembram a amostra e trazem o link.',
    'Sem pressão: nada de urgência, última chance, só hoje ou pontos de exclamação repetidos.',
    `Adapte ao nicho estas respostas para objeções: ${JSON.stringify(ROTEIRO_OBJECOES)}`,
    REGRAS_DE_ESCRITA,
  ].join('\n');
  const r = await tentarIA(gemini, { prompt, esquema: ESQUEMA, temperatura: 0.7 });
  if (r.ok) {
    const a = limparTextos(r.valor);
    if (serve(a, { url, nomeUsuario })) return { ...a, porIA: true };
  }
  const aviso = r.ok ? 'As mensagens da IA não serviram. Usei as mensagens prontas.' : r.aviso;
  return { ...mensagensPadrao(registro, diagnostico, { url, nomeUsuario, estudio }), porIA: false, aviso };
}
