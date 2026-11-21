import { prepararImagem } from '../externo/gemini.js';
import { tentarIA } from './comum.js';

const MAX_ENVIADAS = 20;
const ORDEM_ORIGEM = { instagram: 0, google: 1, pexels: 2 };

function alternativa(fotos, video, maxFotos) {
  const ordenadas = [...fotos].sort((a, b) => (ORDEM_ORIGEM[a.origem] ?? 3) - (ORDEM_ORIGEM[b.origem] ?? 3));
  return [...ordenadas.slice(0, maxFotos), ...(video ? [video] : [])];
}

/**
 * Escolhe as melhores fotos do negócio (mantém o primeiro vídeo).
 * @param {import('../previa/tipos.js').Midia[]} midias
 */
export async function escolherMaterial(midias, { gemini, maxFotos = 10 }) {
  const fotos = midias.filter((m) => m.tipo === 'foto');
  const video = midias.find((m) => m.tipo === 'video') ?? null;
  if (!gemini || fotos.length === 0) {
    return { midias: alternativa(fotos, video, maxFotos), porIA: false, ...(gemini ? {} : { aviso: 'Sem a chave do Gemini, usei a alternativa sem IA.' }) };
  }
  const enviadas = [];
  const imagens = [];
  for (const foto of fotos.slice(0, MAX_ENVIADAS)) {
    try {
      imagens.push(await prepararImagem(foto.arquivo));
      enviadas.push(foto);
    } catch {
      // foto ilegível fica de fora da escolha
    }
  }
  const prompt = [
    `Estas são ${enviadas.length} fotos de um negócio local, numeradas de 0 a ${enviadas.length - 1} na ordem em que foram enviadas.`,
    `Escolha até ${maxFotos} fotos para o site, da melhor para a pior: nítidas, bem iluminadas, sem texto grande por cima,`,
    'e variadas (ambiente, serviço ou produto, equipe, fachada). Evite fotos repetidas ou parecidas demais.',
    'Responda só com os números escolhidos.',
  ].join(' ');
  const esquema = { type: 'OBJECT', properties: { indices: { type: 'ARRAY', maxItems: maxFotos, items: { type: 'INTEGER' } } }, required: ['indices'] };
  const r = await tentarIA(gemini, { prompt, esquema, imagens, temperatura: 0.2 });
  if (r.ok) {
    const escolhidas = [...new Set(r.valor.indices ?? [])]
      .filter((i) => Number.isInteger(i) && i >= 0 && i < enviadas.length)
      .slice(0, maxFotos)
      .map((i) => enviadas[i]);
    if (escolhidas.length) return { midias: [...escolhidas, ...(video ? [video] : [])], porIA: true };
  }
  return { midias: alternativa(fotos, video, maxFotos), porIA: false, aviso: r.ok ? 'A IA não escolheu fotos válidas. Usei as do Instagram e do Google.' : r.aviso };
}
