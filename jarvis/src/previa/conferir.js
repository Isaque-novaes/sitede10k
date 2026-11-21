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
    await pagina.waitForTimeout(1200);
    const titulo = await pagina.evaluate(() => {
      const el = document.querySelector('[data-titulo-principal]');
      if (!el) return { existe: false };
      const r = el.getBoundingClientRect();
      return { existe: true, altura: r.height, topo: r.top, base: r.bottom, tela: window.innerHeight };
    });
    if (!titulo.existe) problemas.push(`${tela.nome}: título principal ausente`);
    else if (titulo.altura === 0) problemas.push(`${tela.nome}: título principal sem altura`);
    else if (titulo.topo >= titulo.tela || titulo.base <= 0) problemas.push(`${tela.nome}: título principal fora da primeira tela`);

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
