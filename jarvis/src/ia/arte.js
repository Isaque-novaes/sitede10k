import { TOPOS, SECOES, VARIANTES, MOVIMENTOS, FONTES } from '../../kit/catalogo.js';
import { opcoesPossiveis, validarAssinatura } from '../previa/assinatura.js';
import { tentarIA } from './comum.js';

/** Paleta válida só para conferir o resto da sugestão (a paleta de verdade vem das fotos). */
const PALETA_DE_CONFERENCIA = { fundo: '#101418', superficie: '#1c232a', texto: '#f2f4f5', textoSuave: '#b8c0c7', destaque: '#e0a030', destaque2: '#3fa7a0' };

/**
 * Sugere topo, fontes, movimento e seções do kit. A paleta não entra: ela vem das fotos.
 * @param {{fotos:{largura:number,altura:number}[], video:any, negocio:any, textos:any}} contexto
 * @param {{assinatura:any, nicho:string, cidade:string}[]} usadas
 */
export async function sugerirAssinatura(contexto, usadas, { gemini }) {
  if (!gemini) return { assinatura: null, porIA: false };
  const { topos, secoes } = opcoesPossiveis(contexto);
  const negocio = contexto.negocio;
  const vizinhas = usadas
    .filter((u) => u.nicho === negocio.nicho && u.cidade === negocio.cidade)
    .map((u) => `${u.assinatura.topo} + ${u.assinatura.fontes} + ${u.assinatura.movimento}`);
  const esquema = {
    type: 'OBJECT',
    properties: {
      topo: { type: 'STRING', enum: topos },
      fontes: { type: 'STRING', enum: FONTES.map((f) => f.id) },
      movimento: { type: 'STRING', enum: MOVIMENTOS.map((m) => m.id) },
      secoes: {
        type: 'ARRAY',
        minItems: 2,
        items: { type: 'OBJECT', properties: { tipo: { type: 'STRING', enum: secoes }, variante: { type: 'STRING', enum: [...VARIANTES] } }, required: ['tipo', 'variante'] },
      },
    },
    required: ['topo', 'fontes', 'movimento', 'secoes'],
  };
  const prompt = [
    'Você é diretor de arte e vai montar o site de um negócio local a partir de um kit de peças prontas.',
    `Negócio: ${negocio.nome} (${negocio.nicho}). Clima: ${(negocio.clima ?? []).join(', ')}.`,
    `Topos possíveis: ${TOPOS.filter((t) => topos.includes(t.id)).map((t) => `${t.id} (${t.etiquetas.join(', ')})`).join('; ')}.`,
    `Fontes: ${FONTES.map((f) => `${f.id} (${f.etiquetas.join(', ')})`).join('; ')}.`,
    `Movimentos: ${MOVIMENTOS.map((m) => `${m.id} (${m.etiquetas.join(', ')})`).join('; ')}.`,
    `Seções possíveis: ${secoes.join(', ')}. Use todas, cada uma uma vez, com variante a, b ou c.`,
    'A primeira seção é servicos ou sobre, e a última é chamada-final.',
    vizinhas.length ? `Outros sites do mesmo nicho nesta cidade já usam: ${vizinhas.join('; ')}. Escolha algo bem diferente deles.` : '',
    'Escolha o que combina com o clima do negócio.',
  ].filter(Boolean).join('\n');
  const r = await tentarIA(gemini, { prompt, esquema, temperatura: 0.9 });
  if (!r.ok) return { assinatura: null, porIA: false, aviso: r.aviso };
  const sugestao = { topo: r.valor.topo, fontes: r.valor.fontes, movimento: r.valor.movimento, secoes: (r.valor.secoes ?? []).map((s) => ({ tipo: s?.tipo, variante: s?.variante })) };
  const { ok } = validarAssinatura({ ...sugestao, paleta: PALETA_DE_CONFERENCIA }, contexto);
  if (!ok) return { assinatura: null, porIA: false, aviso: 'A IA sugeriu uma assinatura de design que não serve. O Jarvis escolhe pelas regras.' };
  return { assinatura: sugestao, porIA: true };
}
