import { ErroLimiteIA } from '../externo/gemini.js';
import { ErroExterno } from '../externo/http.js';

/**
 * Roda uma chamada à IA e transforma qualquer falha em aviso.
 * @returns {Promise<{ok:true, valor:any} | {ok:false, aviso:string}>}
 */
export async function tentarIA(gemini, pedido) {
  if (!gemini) return { ok: false, aviso: 'Sem a chave do Gemini, usei a alternativa sem IA.' };
  try {
    return { ok: true, valor: await gemini.gerarJson(pedido) };
  } catch (erro) {
    if (erro instanceof ErroLimiteIA || erro instanceof ErroExterno) return { ok: false, aviso: erro.message };
    return { ok: false, aviso: `A IA falhou (${erro.message}). Usei a alternativa sem IA.` };
  }
}

export const REGRAS_DE_ESCRITA = 'Escreva em português do Brasil, simples e direto. Nunca use travessão nem meia-risca. '
  + 'Não invente fatos que não estão nos dados: nada de preços, horários, endereços, anos de experiência, prêmios ou promoções.';
