import { join } from 'node:path';
import { requisitarJson } from './http.js';
import { baixarArquivo } from './baixar.js';

const SERVICO = 'Pexels';

/** Consulta em inglês por nicho (dá mais resultado no Pexels). */
export const CONSULTA_PEXELS = {
  barbearia: 'barbershop interior', salao: 'hair salon', estetica: 'spa facial treatment', restaurante: 'restaurant food',
  pizzaria: 'wood fired pizza', hamburgueria: 'burger restaurant', cafeteria: 'coffee shop', padaria: 'bakery bread',
  clinica: 'medical clinic', odontologia: 'dental clinic', academia: 'gym workout', petshop: 'dog grooming',
  oficina: 'car mechanic', imobiliaria: 'modern house interior', generico: 'small business',
};

/**
 * Completa as fotos do negócio com fotos do Pexels até `minimo`.
 * @param {import('../previa/tipos.js').Midia[]} midias
 */
export async function completarComPexels(midias, nicho, pasta, { chave, fetch, registrar, minimo = 4 }) {
  const faltam = minimo - midias.filter((m) => m.tipo === 'foto').length;
  if (faltam <= 0) return { midias };
  const consulta = encodeURIComponent(CONSULTA_PEXELS[nicho] ?? CONSULTA_PEXELS.generico);
  const url = `https://api.pexels.com/v1/search?query=${consulta}&per_page=10&orientation=landscape&locale=pt-BR`;
  const r = await requisitarJson(url, { servico: SERVICO, fetch, registrar, cabecalhos: { Authorization: chave } });
  const novas = [];
  for (const foto of (r?.photos ?? []).slice(0, faltam)) {
    const arquivo = await baixarArquivo(foto.src.large2x, join(pasta, `pexels-${foto.id}.jpg`), { servico: SERVICO, fetch, registrar });
    novas.push({ arquivo, tipo: 'foto', origem: 'pexels', credito: `Foto: ${foto.photographer} (Pexels)` });
  }
  return { midias: [...midias, ...novas], aviso: 'Esta prévia tem poucas fotos reais do negócio.' };
}
