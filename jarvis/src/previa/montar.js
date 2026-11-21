import { readFileSync } from 'node:fs';
import { copyFile, mkdir, writeFile } from 'node:fs/promises';
import { basename, dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { SECOES, FONTES, TOPOS } from '../../kit/catalogo.js';
import { PECAS_TOPO, PECAS_SECAO } from '../../kit/pecas.js';
import { esc } from '../util/html.js';
import { linkWhatsApp, normalizarTelefoneBR, provavelCelular } from '../util/whatsapp.js';
import { contraste } from './cores.js';
import { limparTextos } from '../util/texto.js';

const KIT = join(dirname(fileURLToPath(import.meta.url)), '..', '..', 'kit');
const lerKit = (arquivo) => readFileSync(join(KIT, arquivo), 'utf8');
const BASE_CSS = lerKit('base.css');
const MOVIMENTO_CSS = lerKit('movimento.css');
const MOVIMENTO_JS = lerKit('movimento.js');

const SERIFADAS = new Set(['Playfair Display', 'Fraunces', 'Cormorant Garamond', 'DM Serif Display', 'Abril Fatface']);
const ESTUDIO_PADRAO = 'Estúdio Dez';

const numero = (valor, casas = 0) => Number(valor).toLocaleString('pt-BR', { minimumFractionDigits: casas, maximumFractionDigits: casas });

/** Corta numa palavra inteira e põe reticências. */
function cortar(texto, limite) {
  const t = String(texto ?? '').trim();
  if (t.length <= limite) return t;
  const corte = t.slice(0, limite);
  const espaco = corte.lastIndexOf(' ');
  return `${(espaco > limite * 0.6 ? corte.slice(0, espaco) : corte).replace(/[\s,.;:!?]+$/, '')}…`;
}

const estrelas = (nota) => '★'.repeat(Math.max(0, Math.min(5, Math.round(nota ?? 5))));

/**
 * O contexto que cada peça do kit recebe.
 * @param {{negocio:any, textos:any, fotos:any[], video:any, assinatura:any, opcoes?:any}} entrada
 */
export function criarContextoPeca({ negocio: negocioBruto, textos: textosBrutos, fotos = [], video = null, assinatura, opcoes = {} }) {
  const negocio = limparTextos(negocioBruto);
  const textos = limparTextos(textosBrutos);
  const registro = new Map();
  const larguraMinTopo = TOPOS.find((t) => t.id === assinatura.topo)?.requisitos.larguraMin ?? 0;
  const fotosTopo = fotos.filter((f) => f.largura >= larguraMinTopo);
  const reservadas = new Set();
  const livres = (larguraMin = 0) => fotos.filter((f) => !reservadas.has(f.pc) && f.largura >= larguraMin);
  const creditos = new Set();
  const fontes = FONTES.find((f) => f.id === assinatura.fontes) ?? FONTES[0];
  const reqCtx = { fotos, video, negocio, textos };
  const secoes = assinatura.secoes
    .filter((s) => SECOES.find((d) => d.tipo === s.tipo)?.requisitos(reqCtx))
    .map((s) => s.tipo);
  let prioridadeUsada = false;

  const caminho = (absoluto, credito) => {
    const destino = `midias/${basename(absoluto)}`;
    registro.set(destino, absoluto);
    if (credito) creditos.add(credito);
    return destino;
  };

  const util = {
    esc,
    numero,
    cortar,
    estrelas,
    caminho,
    /** Fotos que nenhuma peça usou ainda. */
    fotosLivres: livres,
    /** Pega a próxima foto livre (ou a última, com doFim) e marca como usada. `null` se não houver. */
    reservarFoto({ larguraMin = 0, doFim = false } = {}) {
      const lista = livres(larguraMin);
      const foto = (doFim ? lista.at(-1) : lista[0]) ?? null;
      if (foto) reservadas.add(foto.pc);
      return foto;
    },
    /** `<img>` responsivo. Marca a foto como usada (menos na galeria). Só a primeira com prioridade recebe prioridade. */
    img(foto, { classe = '', prioridade = false, alt = '', sizes = '100vw', atributos = '', reservar = true } = {}) {
      if (reservar) reservadas.add(foto.pc);
      const comPrioridade = prioridade && !prioridadeUsada;
      if (comPrioridade) prioridadeUsada = true;
      const wCel = Math.min(800, foto.largura);
      const wPc = Math.min(1600, foto.largura);
      const altura = Math.round((foto.altura * wPc) / foto.largura);
      const srcCel = caminho(foto.celular, foto.original?.credito);
      const srcPc = caminho(foto.pc);
      const srcset = wCel === wPc ? `${srcPc} ${wPc}w` : `${srcCel} ${wCel}w, ${srcPc} ${wPc}w`;
      const carga = comPrioridade ? 'fetchpriority="high"' : 'loading="lazy" decoding="async"';
      return `<img${classe ? ` class="${classe}"` : ''} src="${srcCel}" srcset="${srcset}" sizes="${sizes}" width="${wPc}" height="${altura}" alt="${esc(alt)}" ${carga}${atributos ? ` ${atributos}` : ''}>`;
    },
    /** Melhor forma de contato do visitante com o negócio. */
    linkContato() {
      const zap = negocio.whatsapp || (provavelCelular(negocio.telefone) ? negocio.telefone : null);
      const link = zap && linkWhatsApp(zap, 'Olá! Vim pelo site e quero mais informações.');
      if (link) return { href: link, rotulo: 'Chamar no WhatsApp', tipo: 'whatsapp' };
      const tel = normalizarTelefoneBR(negocio.telefone);
      if (tel) return { href: `tel:+${tel}`, rotulo: 'Ligar agora', tipo: 'telefone' };
      if (negocio.mapsUrl) return { href: negocio.mapsUrl, rotulo: 'Ver no mapa', tipo: 'mapa' };
      return null;
    },
    /** Link do topo para a primeira seção útil. */
    ancora() {
      if (secoes.includes('servicos')) return { href: '#servicos', rotulo: 'Ver serviços' };
      if (secoes.includes('sobre')) return { href: '#sobre', rotulo: 'Saiba mais' };
      return null;
    },
  };

  return {
    negocio, textos, fotos, fotosTopo, video, paleta: assinatura.paleta, fontes, movimento: assinatura.movimento,
    secoes, opcoes, util, _registro: registro, _creditos: creditos,
  };
}

function linkFontes(f) {
  const familia = (nome, pesos) => `family=${nome.replace(/ /g, '+')}:wght@${pesos}`;
  return `https://fonts.googleapis.com/css2?${familia(f.titulo, f.pesosTitulo)}&${familia(f.texto, f.pesosTexto)}&display=swap`;
}

function variaveis(paleta, fontes) {
  const sobreDestaque = contraste(paleta.fundo, paleta.destaque) >= contraste(paleta.texto, paleta.destaque) ? paleta.fundo : paleta.texto;
  const generico = (nome) => (SERIFADAS.has(nome) ? 'Georgia, serif' : 'system-ui, sans-serif');
  const pesoTitulo = fontes.pesosTitulo.split(';').at(-1);
  return `:root{--cor-fundo:${paleta.fundo};--cor-superficie:${paleta.superficie};--cor-texto:${paleta.texto};`
    + `--cor-texto-suave:${paleta.textoSuave};--cor-destaque:${paleta.destaque};--cor-destaque2:${paleta.destaque2};`
    + `--cor-sobre-destaque:${sobreDestaque};--fonte-titulo:'${fontes.titulo}', ${generico(fontes.titulo)};`
    + `--fonte-texto:'${fontes.texto}', ${generico(fontes.texto)};--peso-titulo:${pesoTitulo}}`;
}

/**
 * Monta a página da prévia.
 * @returns {{html:string, arquivos:{destino:string, origem:string}[]}}
 */
export function montarPrevia({ negocio: negocioBruto, textos: textosBrutos, assinatura, fotos = [], video = null, opcoes = {} }) {
  const estudio = opcoes.estudio ?? ESTUDIO_PADRAO;
  const ctx = criarContextoPeca({ negocio: negocioBruto, textos: textosBrutos, fotos, video, assinatura, opcoes });
  const { util, negocio, textos } = ctx;

  const topo = PECAS_TOPO[assinatura.topo];
  if (!topo) throw new Error(`Peça do kit não encontrada: topo ${assinatura.topo}`);
  const partes = [topo.render(ctx)];
  for (const s of assinatura.secoes) {
    if (!ctx.secoes.includes(s.tipo)) continue;
    const peca = PECAS_SECAO[`${s.tipo}-${s.variante}`];
    if (!peca) throw new Error(`Peça do kit não encontrada: seção ${s.tipo}-${s.variante}`);
    partes.push(peca.render(ctx));
  }
  const css = [...new Set(partes.map((p) => p.css))].join('\n');
  const contato = util.linkContato();

  const insta = negocio.instagram?.usuario
    ? `<a href="https://www.instagram.com/${esc(negocio.instagram.usuario)}/" rel="noopener">@${esc(negocio.instagram.usuario)}</a>`
    : '';
  const creditos = [...ctx._creditos];
  const rodape = `<footer class="rodape"><div class="container rodape__grade">
  <p class="rodape__nome">${esc(negocio.nome)}</p>
  <div class="rodape__info">
    ${negocio.endereco ? `<p>${esc(negocio.endereco)}</p>` : `<p>${esc(negocio.bairro ? `${negocio.bairro}, ${negocio.cidade}` : negocio.cidade)}</p>`}
    ${insta ? `<p>${insta}</p>` : ''}
  </div>
  ${creditos.length ? `<p class="rodape__creditos">Fotos: ${creditos.map(esc).join(', ')}.</p>` : ''}
</div></footer>`;

  const html = `<!doctype html>
<html lang="pt-BR" class="sem-js">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title>${esc(negocio.nome)} | Prévia</title>
<meta name="description" content="${esc(textos.subtitulo)}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="${linkFontes(ctx.fontes)}">
<script>document.documentElement.className='js'</script>
<style>
${variaveis(assinatura.paleta, ctx.fontes)}
${BASE_CSS}
${MOVIMENTO_CSS}
${css}
</style>
</head>
<body data-movimento="${esc(assinatura.movimento)}">
<a class="pular" href="#conteudo">Pular para o conteúdo</a>
<nav class="barra" aria-label="${esc(negocio.nome)}"><div class="container barra__linha">
  <a class="barra__nome" href="#conteudo">${esc(negocio.nome)}</a>
  ${contato ? `<a class="botao barra__acao" href="${esc(contato.href)}">${esc(contato.rotulo)}</a>` : ''}
</div></nav>
<main id="conteudo">
${partes.map((p) => p.html).join('\n')}
</main>
${rodape}
<p class="faixa-demo" role="note">${opcoes.ficticio
    ? `Exemplo criado pelo ${esc(estudio)} com um negócio fictício. Nome, avaliações e números são inventados.`
    : `Demonstração criada pelo ${esc(estudio)}. Este não é o site oficial de ${esc(negocio.nome)}.`}</p>
<script>
${MOVIMENTO_JS}
</script>
</body>
</html>
`;

  const arquivos = [...ctx._registro.entries()].map(([destino, origem]) => ({ destino, origem }));
  return { html, arquivos };
}

/** Escreve `index.html` e copia as mídias para a pasta da prévia. */
export async function gravarPrevia(pasta, montagem) {
  await mkdir(join(pasta, 'midias'), { recursive: true });
  await writeFile(join(pasta, 'index.html'), montagem.html, 'utf8');
  for (const { destino, origem } of montagem.arquivos) {
    const alvo = join(pasta, destino);
    if (resolve(origem) === resolve(alvo)) continue;
    await copyFile(origem, alvo);
  }
}
