const MAPA = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };

/**
 * Escapa texto para uso em HTML (conteúdo e atributos).
 * @param {unknown} texto
 * @returns {string}
 */
export function esc(texto) {
  if (texto === null || texto === undefined) return '';
  return String(texto).replace(/[&<>"']/g, (c) => MAPA[c]);
}
