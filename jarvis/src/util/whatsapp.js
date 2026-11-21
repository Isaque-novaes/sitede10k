/**
 * Só dígitos, com 55 na frente. `null` se não tiver 12 ou 13 dígitos.
 * @param {string} telefone
 * @returns {string|null}
 */
export function normalizarTelefoneBR(telefone) {
  let d = String(telefone ?? '').replace(/\D/g, '');
  if (!d) return null;
  if (d.startsWith('0')) d = d.replace(/^0+/, '');
  if (!(d.startsWith('55') && (d.length === 12 || d.length === 13))) d = `55${d}`;
  return d.length === 12 || d.length === 13 ? d : null;
}

/**
 * Celular brasileiro: 13 dígitos com o 9 logo depois do DDD.
 * @param {string} telefone
 */
export function provavelCelular(telefone) {
  const d = normalizarTelefoneBR(telefone);
  return !!d && d.length === 13 && d[4] === '9';
}

/**
 * @param {string} telefone
 * @param {string} texto
 * @returns {string|null}
 */
export function linkWhatsApp(telefone, texto) {
  const d = normalizarTelefoneBR(telefone);
  if (!d) return null;
  return `https://wa.me/${d}?text=${encodeURIComponent(texto ?? '')}`;
}
