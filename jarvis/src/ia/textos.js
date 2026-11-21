import { textosBase } from '../previa/textos-base.js';
import { limparTextos } from '../util/texto.js';
import { tentarIA, REGRAS_DE_ESCRITA } from './comum.js';

const ESQUEMA = {
  type: 'OBJECT',
  properties: {
    titulo: { type: 'STRING' },
    subtitulo: { type: 'STRING' },
    servicos: { type: 'ARRAY', minItems: 3, maxItems: 6, items: { type: 'OBJECT', properties: { nome: { type: 'STRING' }, descricao: { type: 'STRING' } }, required: ['nome', 'descricao'] } },
    sobre: { type: 'STRING' },
    perguntas: { type: 'ARRAY', minItems: 2, maxItems: 5, items: { type: 'OBJECT', properties: { pergunta: { type: 'STRING' }, resposta: { type: 'STRING' } }, required: ['pergunta', 'resposta'] } },
    chamada: { type: 'STRING' },
  },
  required: ['titulo', 'subtitulo', 'servicos', 'sobre', 'perguntas', 'chamada'],
};

const serve = (t) => t?.titulo && t.titulo.length <= 60 && (t.servicos?.length ?? 0) >= 3 && (t.perguntas?.length ?? 0) >= 2
  && t.subtitulo && t.sobre && t.chamada;

/**
 * Textos da prévia na voz do negócio, com as palavras dos clientes.
 * @returns {Promise<{textos: import('../previa/tipos.js').TextosPrevia, porIA:boolean, aviso?:string}>}
 */
export async function escreverTextosPrevia(registro, diagnostico, { gemini }) {
  const avaliacoes = (registro.avaliacoes ?? []).map((a) => `"${a.texto}" (${a.nota} estrelas)`);
  const prompt = [
    'Escreva os textos do site de um negócio local, na voz do próprio negócio, confiante e acolhedora.',
    `Negócio: ${registro.nome}, ${registro.nicho}, em ${registro.bairro ? `${registro.bairro}, ` : ''}${registro.cidade ?? ''}.`,
    registro.instagram?.bio ? `Bio do Instagram: ${registro.instagram.bio}` : '',
    avaliacoes.length ? `Avaliações reais de clientes (use as palavras deles): ${avaliacoes.join(' ')}` : '',
    `Situação online: ${diagnostico?.resumo ?? ''}`,
    'Título com até 60 caracteres. De 3 a 6 serviços típicos desse tipo de negócio, com descrição curta.',
    'De 2 a 5 perguntas frequentes com respostas que não prometem nada que não está nos dados (na dúvida, oriente a chamar o negócio).',
    'Uma chamada final curta, com verbo no começo.',
    REGRAS_DE_ESCRITA,
  ].filter(Boolean).join('\n');
  const r = await tentarIA(gemini, { prompt, esquema: ESQUEMA, temperatura: 0.8 });
  if (r.ok) {
    const textos = limparTextos(r.valor);
    if (serve(textos)) return { textos, porIA: true };
  }
  return { textos: textosBase(registro), porIA: false, aviso: r.ok ? 'Os textos da IA não serviram. Usei os textos prontos do nicho.' : r.aviso };
}
