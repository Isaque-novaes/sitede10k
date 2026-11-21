// Faixas iniciais em reais, a partir de pesquisa de mercado (2026). O usuário edita em config.precos.
export const TABELA_PRECOS = {
  basico: [900, 1800],
  profissional: [1800, 4000],
  premium: [5000, 10000],
  manutencao: [60, 200],
};

/** Nichos com ticket mais alto. Os outros ficam em 1.0. */
export const MULTIPLICADOR_NICHO = { clinica: 1.3, odontologia: 1.3, estetica: 1.2, imobiliaria: 1.3 };

const dezena = (v) => Math.round(v / 10) * 10;

/**
 * Faixas sugeridas para o nicho. `sobrescrever` (de config.precos) troca faixas inteiras, sem multiplicador.
 * @returns {{basico:number[], profissional:number[], premium:number[], manutencao:number[]}}
 */
export function sugerirPreco(nicho, sobrescrever = {}) {
  const m = MULTIPLICADOR_NICHO[nicho] ?? 1;
  const resultado = {};
  for (const [pacote, [min, max]] of Object.entries(TABELA_PRECOS)) {
    resultado[pacote] = sobrescrever[pacote] ? [...sobrescrever[pacote]] : (pacote === 'manutencao' ? [min, max] : [dezena(min * m), dezena(max * m)]);
  }
  return resultado;
}
