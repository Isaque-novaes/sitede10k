import sharp from 'sharp';

/** Climas que pedem fundo escuro. */
const CLIMAS_ESCUROS = ['noturno', 'moderno', 'sofisticado', 'forte', 'urbano'];
/** Cores usadas quando o negócio não tem nenhuma foto. */
const CORES_PADRAO = ['#6b5e51', '#c8962e', '#3f8f8a'];
/** Abaixo disso, a cor é considerada cinza e não serve de destaque. */
const SATURACAO_MINIMA_DESTAQUE = 0.15;

/** @param {string} hex @returns {[number, number, number]} */
export function hexParaRgb(hex) {
  const h = String(hex).replace('#', '').trim();
  const cheio = h.length === 3 ? h.split('').map((c) => c + c).join('') : h;
  return [0, 2, 4].map((i) => parseInt(cheio.slice(i, i + 2), 16));
}

/** @param {[number, number, number]} rgb @returns {string} */
export function rgbParaHex([r, g, b]) {
  const canal = (v) => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, '0');
  return `#${canal(r)}${canal(g)}${canal(b)}`;
}

/** Distância euclidiana entre duas cores em RGB. */
export function distanciaRgb(a, b) {
  const [r1, g1, b1] = hexParaRgb(a);
  const [r2, g2, b2] = hexParaRgb(b);
  return Math.hypot(r1 - r2, g1 - g2, b1 - b2);
}

/** Luminância relativa WCAG 2 (0 a 1). */
export function luminancia(hex) {
  const [r, g, b] = hexParaRgb(hex).map((v) => {
    const c = v / 255;
    return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/** Razão de contraste WCAG 2 (1 a 21). */
export function contraste(a, b) {
  const la = luminancia(a);
  const lb = luminancia(b);
  return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
}

/** @returns {[number, number, number]} matiz 0-360, saturação 0-1, luminosidade 0-1 */
export function hexParaHsl(hex) {
  const [r, g, b] = hexParaRgb(hex).map((v) => v / 255);
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const l = (max + min) / 2;
  if (max === min) return [0, 0, l];
  const d = max - min;
  const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  let h;
  if (max === r) h = (g - b) / d + (g < b ? 6 : 0);
  else if (max === g) h = (b - r) / d + 2;
  else h = (r - g) / d + 4;
  return [h * 60, s, l];
}

export function hslParaHex([h, s, l]) {
  const sat = Math.max(0, Math.min(1, s));
  const lum = Math.max(0, Math.min(1, l));
  const c = (1 - Math.abs(2 * lum - 1)) * sat;
  const hh = (((h % 360) + 360) % 360) / 60;
  const x = c * (1 - Math.abs((hh % 2) - 1));
  let rgb = [0, 0, 0];
  if (hh < 1) rgb = [c, x, 0];
  else if (hh < 2) rgb = [x, c, 0];
  else if (hh < 3) rgb = [0, c, x];
  else if (hh < 4) rgb = [0, x, c];
  else if (hh < 5) rgb = [x, 0, c];
  else rgb = [c, 0, x];
  const m = lum - c / 2;
  return rgbParaHex(rgb.map((v) => (v + m) * 255));
}

/**
 * Mexe só na luminosidade HSL, em passos de 2%, até atingir o contraste mínimo com o fundo.
 * @param {string} cor
 * @param {string} fundo
 * @param {number} minimo
 */
export function ajustarContraste(cor, fundo, minimo) {
  if (contraste(cor, fundo) >= minimo) return cor;
  const [h, s, l] = hexParaHsl(cor);
  const clarear = luminancia(fundo) < 0.4;
  let atual = l;
  let melhor = cor;
  for (let i = 0; i < 50; i++) {
    atual = clarear ? Math.min(1, atual + 0.02) : Math.max(0, atual - 0.02);
    melhor = hslParaHex([h, s, atual]);
    if (contraste(melhor, fundo) >= minimo) return melhor;
    if (atual === 0 || atual === 1) break;
  }
  return melhor;
}

/**
 * Cores principais da imagem, da mais presente para a menos.
 * Sempre devolve `quantidade` cores (repete as existentes se a imagem tiver menos).
 * @param {Buffer|string} imagem
 * @param {number} [quantidade]
 * @returns {Promise<string[]>}
 */
export async function extrairCores(imagem, quantidade = 5) {
  const { data } = await sharp(imagem)
    .rotate()
    .resize(64, 64, { fit: 'cover' })
    .removeAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  // Histograma com 5 bits por canal: menos pontos para o k-means, mesmo resultado prático.
  const baldes = new Map();
  for (let i = 0; i < data.length; i += 3) {
    const chave = ((data[i] >> 3) << 10) | ((data[i + 1] >> 3) << 5) | (data[i + 2] >> 3);
    const b = baldes.get(chave);
    if (b) {
      b.n++; b.r += data[i]; b.g += data[i + 1]; b.b += data[i + 2];
    } else {
      baldes.set(chave, { n: 1, r: data[i], g: data[i + 1], b: data[i + 2] });
    }
  }
  const pontos = [...baldes.values()].map((b) => ({ n: b.n, c: [b.r / b.n, b.g / b.n, b.b / b.n] }));
  const dist2 = (a, b) => (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2;

  // Início determinístico: o ponto mais frequente, depois o que maximiza peso x distância².
  pontos.sort((a, b) => b.n - a.n);
  const centros = [pontos[0].c];
  while (centros.length < quantidade) {
    let melhor = null;
    let valor = 0;
    for (const p of pontos) {
      const d = Math.min(...centros.map((c) => dist2(p.c, c)));
      if (p.n * d > valor) { valor = p.n * d; melhor = p; }
    }
    if (!melhor) break;
    centros.push(melhor.c);
  }

  let pesos = new Array(centros.length).fill(0);
  for (let iter = 0; iter < 10; iter++) {
    const somas = centros.map(() => [0, 0, 0]);
    pesos = new Array(centros.length).fill(0);
    for (const p of pontos) {
      let k = 0;
      let menor = Infinity;
      centros.forEach((c, j) => { const d = dist2(p.c, c); if (d < menor) { menor = d; k = j; } });
      pesos[k] += p.n;
      somas[k][0] += p.c[0] * p.n; somas[k][1] += p.c[1] * p.n; somas[k][2] += p.c[2] * p.n;
    }
    centros.forEach((c, j) => {
      if (pesos[j] > 0) centros[j] = [somas[j][0] / pesos[j], somas[j][1] / pesos[j], somas[j][2] / pesos[j]];
    });
  }

  const ordenadas = centros
    .map((c, j) => ({ hex: rgbParaHex(c), peso: pesos[j] }))
    .filter((x) => x.peso > 0)
    .sort((a, b) => b.peso - a.peso)
    .map((x) => x.hex);
  const resultado = [...ordenadas];
  for (let i = 0; resultado.length < quantidade; i++) resultado.push(ordenadas[i % ordenadas.length]);
  return resultado;
}

/** Move a luminosidade até a luminância relativa cruzar o alvo. */
function fundoComLuminancia(h, s, escuro) {
  if (escuro) {
    for (let l = 0.1; l >= 0.03; l -= 0.01) {
      const hex = hslParaHex([h, s, l]);
      if (luminancia(hex) <= 0.035) return hex;
    }
    return hslParaHex([h, s, 0.03]);
  }
  for (let l = 0.94; l <= 0.975; l += 0.005) {
    const hex = hslParaHex([h, s, l]);
    if (luminancia(hex) >= 0.85) return hex;
  }
  return hslParaHex([h, Math.min(s, 0.1), 0.975]);
}

/**
 * Paleta da prévia a partir das cores das fotos e do clima do negócio.
 * @param {string[]} cores da mais presente para a menos
 * @param {string[]} clima
 * @param {'claro'|'escuro'} [forcar] ignora o clima e a cor dominante para decidir o fundo
 * @returns {import('./tipos.js').Paleta}
 */
export function derivarPaleta(cores, clima, forcar) {
  const lista = [...new Set((cores?.length ? cores : CORES_PADRAO).map((c) => c.toLowerCase()))];
  const dominante = lista[0];
  const [hDom, sDom] = hexParaHsl(dominante);
  const escuro = forcar
    ? forcar === 'escuro'
    : (clima ?? []).some((c) => CLIMAS_ESCUROS.includes(c)) || luminancia(dominante) < 0.2;

  const sFundo = Math.min(sDom, 0.25);
  const fundo = fundoComLuminancia(hDom, sFundo, escuro);
  const [hF, sF, lF] = hexParaHsl(fundo);

  const texto = ajustarContraste(hslParaHex([hDom, Math.min(sDom, 0.15), escuro ? 0.95 : 0.1]), fundo, 7);
  const textoSuave = ajustarContraste(hslParaHex([hDom, Math.min(sDom, 0.15), escuro ? 0.72 : 0.35]), fundo, 4.5);

  let superficie = fundo;
  for (let passo = 0.01; passo <= 0.3; passo += 0.01) {
    superficie = hslParaHex([hF, sF, escuro ? lF + passo : lF - passo]);
    if (distanciaRgb(superficie, fundo) >= 10) break;
  }

  const saturadas = lista
    .map((hex, i) => ({ hex, s: hexParaHsl(hex)[1], i }))
    .filter((x) => x.s >= SATURACAO_MINIMA_DESTAQUE)
    .sort((a, b) => b.s - a.s || a.i - b.i);
  const baseDestaque = saturadas[0]?.hex ?? CORES_PADRAO[1];
  let baseDestaque2 = saturadas[1]?.hex;
  if (!baseDestaque2) {
    const [h, s, l] = hexParaHsl(baseDestaque);
    baseDestaque2 = saturadas.length ? hslParaHex([h + 150, s, l]) : CORES_PADRAO[2];
  }

  return {
    fundo,
    superficie,
    texto,
    textoSuave,
    destaque: ajustarContraste(baseDestaque, fundo, 3),
    destaque2: ajustarContraste(baseDestaque2, fundo, 3),
  };
}
