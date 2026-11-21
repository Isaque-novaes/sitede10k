import { mkdir } from 'node:fs/promises';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { abrirNavegador } from '../util/navegador.js';

const TELAS = [
  { nome: 'celular', width: 390, height: 844 },
  { nome: 'pc', width: 1440, height: 900 },
];
const HOSTS_DE_FONTE = ['fonts.googleapis.com', 'fonts.gstatic.com'];
const ehFonte = (url) => HOSTS_DE_FONTE.some((h) => String(url ?? '').includes(h));
const CONTRASTE_MINIMO_TITULO = 3;

const luminanciaCanal = (v) => { const c = v / 255; return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4; };
const luminanciaRgb = (r, g, b) => 0.2126 * luminanciaCanal(r) + 0.7152 * luminanciaCanal(g) + 0.0722 * luminanciaCanal(b);

/**
 * Esconde o texto do título, fotografa o que está atrás dele e mede o contraste com a cor do texto.
 * Devolve o contraste que 90% dos pontos do fundo alcançam (os 10% piores ficam de fora).
 */
async function medirContrasteDoTitulo(pagina, titulo) {
  const [r, g, b] = (titulo.cor.match(/\d+(\.\d+)?/g) ?? ['0', '0', '0']).map(Number);
  const lumTexto = luminanciaRgb(r, g, b);
  const area = await pagina.evaluate(() => {
    const el = document.querySelector('[data-titulo-principal]');
    const caixa = el.getBoundingClientRect();
    const x = Math.max(0, caixa.left); const y = Math.max(0, caixa.top);
    const estilo = document.createElement('style');
    estilo.id = '__conferencia';
    estilo.textContent = '[data-titulo-principal],[data-titulo-principal] *{color:transparent!important;text-shadow:none!important;-webkit-text-stroke:0!important}';
    document.head.appendChild(estilo);
    return { x, y, width: Math.min(window.innerWidth, caixa.right) - x, height: Math.min(window.innerHeight, caixa.bottom) - y };
  });
  if (area.width < 2 || area.height < 2) return Infinity;
  const imagem = await pagina.screenshot({ clip: area });
  await pagina.evaluate(() => document.getElementById('__conferencia')?.remove());
  const sharp = (await import('sharp')).default;
  const { data, info } = await sharp(imagem).removeAlpha().raw().toBuffer({ resolveWithObject: true });
  const contrastes = [];
  for (let i = 0; i < data.length; i += info.channels * 3) {
    const lumFundo = luminanciaRgb(data[i], data[i + 1], data[i + 2]);
    contrastes.push((Math.max(lumTexto, lumFundo) + 0.05) / (Math.min(lumTexto, lumFundo) + 0.05));
  }
  contrastes.sort((a, b) => a - b);
  return contrastes[Math.floor(contrastes.length * 0.1)] ?? Infinity;
}

async function conferirTela(navegador, url, pasta, tela, bloquearRede) {
  const problemas = [];
  const contexto = await navegador.newContext({ viewport: { width: tela.width, height: tela.height } });
  try {
    if (bloquearRede) await contexto.route(/^https?:\/\//, (rota) => rota.abort());
    const pagina = await contexto.newPage();
    pagina.on('console', (msg) => {
      if (msg.type() !== 'error') return;
      if (ehFonte(msg.location()?.url) || ehFonte(msg.text())) return;
      problemas.push(`${tela.nome}: erro no console: ${msg.text().slice(0, 160)}`);
    });
    pagina.on('pageerror', (erro) => problemas.push(`${tela.nome}: erro de JavaScript: ${String(erro.message ?? erro).slice(0, 160)}`));

    await pagina.goto(url, { waitUntil: 'load', timeout: 30000 });
    const altura = await pagina.evaluate(() => document.documentElement.scrollHeight);
    for (let y = 0; y < altura; y += Math.round(tela.height * 0.7)) {
      await pagina.evaluate((v) => window.scrollTo(0, v), y);
      await pagina.waitForTimeout(80);
    }
    await pagina.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => {});

    const medidas = await pagina.evaluate(() => ({
      larguraConteudo: document.documentElement.scrollWidth,
      larguraTela: window.innerWidth,
      quebradas: [...document.images].filter((i) => i.complete && i.naturalWidth === 0).map((i) => i.getAttribute('src')),
    }));
    if (medidas.larguraConteudo > medidas.larguraTela + 1) {
      problemas.push(`${tela.nome}: conteúdo vaza para os lados (scrollWidth ${medidas.larguraConteudo} > ${medidas.larguraTela})`);
    }
    for (const src of medidas.quebradas.slice(0, 3)) problemas.push(`${tela.nome}: imagem quebrada (${src})`);

    await pagina.evaluate(() => window.scrollTo(0, 0));
    await pagina.waitForTimeout(2200);
    const titulo = await pagina.evaluate(() => {
      const el = document.querySelector('[data-titulo-principal]');
      if (!el) return { existe: false };
      const r = el.getBoundingClientRect();
      const faixaDoTexto = document.createRange();
      faixaDoTexto.selectNodeContents(el);
      const partes = [...faixaDoTexto.getClientRects()].filter((b) => b.width > 0);
      const cortado = partes.some((b) => b.right > window.innerWidth + 1 || b.left < -1);
      return { existe: true, altura: r.height, topo: r.top, base: r.bottom, tela: window.innerHeight, cortado, cor: getComputedStyle(el).color };
    });
    if (!titulo.existe) problemas.push(`${tela.nome}: título principal ausente`);
    else if (titulo.altura === 0) problemas.push(`${tela.nome}: título principal sem altura`);
    else if (titulo.topo >= titulo.tela || titulo.base <= 0) problemas.push(`${tela.nome}: título principal fora da primeira tela`);
    else {
      if (titulo.cortado) problemas.push(`${tela.nome}: título principal cortado nas laterais`);
      const contrasteTitulo = await medirContrasteDoTitulo(pagina, titulo);
      if (contrasteTitulo < CONTRASTE_MINIMO_TITULO) {
        problemas.push(`${tela.nome}: título principal com pouco contraste com o fundo (${contrasteTitulo.toFixed(1)}:1)`);
      }
    }

    const captura = join(pasta, 'conferencia', `${tela.nome}.png`);
    await pagina.screenshot({ path: captura });
    return { problemas, captura };
  } finally {
    await contexto.close();
  }
}

/**
 * Abre a prévia no celular (390 x 844) e no PC (1440 x 900), procura problemas e tira capturas.
 * @param {string} pasta pasta com o index.html
 * @param {{navegador?: import('playwright-core').Browser, bloquearRede?: boolean}} [opcoes]
 * @returns {Promise<import('./tipos.js').ResultadoConferencia>}
 */
export async function conferirPrevia(pasta, opcoes = {}) {
  const proprio = !opcoes.navegador;
  const navegador = opcoes.navegador ?? await abrirNavegador();
  try {
    await mkdir(join(pasta, 'conferencia'), { recursive: true });
    const url = pathToFileURL(join(pasta, 'index.html')).href;
    const problemas = [];
    const capturas = {};
    for (const tela of TELAS) {
      const r = await conferirTela(navegador, url, pasta, tela, !!opcoes.bloquearRede);
      problemas.push(...r.problemas);
      capturas[tela.nome] = r.captura;
    }
    return { ok: problemas.length === 0, problemas, capturas: { celular: capturas.celular, pc: capturas.pc } };
  } finally {
    if (proprio) await navegador.close();
  }
}
