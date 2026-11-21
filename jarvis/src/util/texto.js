// Limpeza de textos que vêm de fora (Google, Instagram, IA) antes de irem para a prévia.

/** Troca travessão e meia-risca: entre horários vira "às", no resto vira vírgula. */
export function limparTracos(texto) {
  return String(texto)
    .replace(/(\d)\s*[–—]\s*(\d)/g, '$1 às $2')
    .replace(/\s*[–—]+\s*/g, ', ')
    .replace(/^,\s*|,\s*$/g, '')
    .replace(/,\s*,/g, ',');
}

const NAO_MEXER = new Set(['mapsUrl', 'midias', 'arquivo', 'whatsapp', 'telefone', 'id', 'usuario']);

/** Aplica limparTracos em todos os textos de um objeto, sem mexer em links, arquivos e telefones. */
export function limparTextos(valor, chave = '') {
  if (NAO_MEXER.has(chave)) return valor;
  if (typeof valor === 'string') return limparTracos(valor);
  if (Array.isArray(valor)) return valor.map((v) => limparTextos(v));
  if (valor && typeof valor === 'object') {
    return Object.fromEntries(Object.entries(valor).map(([k, v]) => [k, limparTextos(v, k)]));
  }
  return valor;
}
