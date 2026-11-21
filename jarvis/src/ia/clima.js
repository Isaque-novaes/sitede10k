import { tentarIA } from './comum.js';

export const VOCABULARIO_CLIMA = ['acolhedor', 'familiar', 'classico', 'elegante', 'sofisticado', 'premium', 'moderno', 'jovem', 'urbano',
  'forte', 'esportivo', 'energico', 'divertido', 'criativo', 'artesanal', 'gastronomia', 'natureza', 'discreto', 'profissional', 'clinico', 'noturno'];

export const CLIMA_POR_NICHO = {
  barbearia: ['urbano', 'classico'], salao: ['elegante', 'acolhedor'], estetica: ['sofisticado', 'discreto'],
  restaurante: ['acolhedor', 'gastronomia'], pizzaria: ['familiar', 'gastronomia'], hamburgueria: ['jovem', 'urbano'],
  cafeteria: ['acolhedor', 'artesanal'], padaria: ['familiar', 'artesanal'], clinica: ['profissional', 'clinico'],
  odontologia: ['profissional', 'discreto'], academia: ['energico', 'esportivo'], petshop: ['divertido', 'familiar'],
  oficina: ['forte', 'profissional'], imobiliaria: ['sofisticado', 'profissional'], generico: ['acolhedor', 'profissional'],
};

const ESQUEMA = {
  type: 'OBJECT',
  properties: { clima: { type: 'ARRAY', minItems: 2, maxItems: 4, items: { type: 'STRING', enum: VOCABULARIO_CLIMA } } },
  required: ['clima'],
};

/** De 2 a 4 palavras que descrevem o clima do negócio. */
export async function extrairClima(registro, perfil, { gemini }) {
  const legendas = (perfil?.midias ?? []).map((m) => m.legenda).filter(Boolean).slice(0, 10);
  const avaliacoes = (registro.avaliacoes ?? []).map((a) => a.texto).slice(0, 5);
  const prompt = [
    'Você ajuda a escolher o estilo visual do site de um negócio local brasileiro.',
    `Negócio: ${registro.nome} (${registro.nicho}), em ${registro.bairro ? `${registro.bairro}, ` : ''}${registro.cidade ?? ''}.`,
    perfil?.bio ? `Bio do Instagram: ${perfil.bio}` : '',
    legendas.length ? `Legendas recentes: ${legendas.join(' | ')}` : '',
    avaliacoes.length ? `O que os clientes dizem: ${avaliacoes.join(' | ')}` : '',
    'Escolha de 2 a 4 palavras da lista permitida que descrevem o clima desse negócio.',
  ].filter(Boolean).join('\n');
  const r = await tentarIA(gemini, { prompt, esquema: ESQUEMA, temperatura: 0.4 });
  if (r.ok) {
    const clima = [...new Set((r.valor.clima ?? []).filter((c) => VOCABULARIO_CLIMA.includes(c)))].slice(0, 4);
    if (clima.length >= 2) return { clima, porIA: true };
  }
  return { clima: [...(CLIMA_POR_NICHO[registro.nicho] ?? CLIMA_POR_NICHO.generico)], porIA: false, aviso: r.ok ? 'A IA não sugeriu um clima válido. Usei o padrão do nicho.' : r.aviso };
}
