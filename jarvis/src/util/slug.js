const ALFABETO = 'abcdefghijklmnopqrstuvwxyz0123456789';
const MAX_NOME = 40;

/**
 * Minúsculas, sem acento, só [a-z0-9] e hífens, sem hífens repetidos ou nas pontas.
 * @param {string} texto
 */
export function normalizar(texto) {
  return String(texto ?? '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/['’`´]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

/**
 * @param {string} nome
 * @param {() => number} [aleatorio]
 * @returns {string} `{nome-normalizado}-{4 caracteres}`
 */
export function criarSlug(nome, aleatorio = Math.random) {
  const base = normalizar(nome).slice(0, MAX_NOME).replace(/-+$/g, '') || 'negocio';
  let sufixo = '';
  for (let i = 0; i < 4; i++) sufixo += ALFABETO[Math.floor(aleatorio() * ALFABETO.length)];
  return `${base}-${sufixo}`;
}
