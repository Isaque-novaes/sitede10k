/*
 * Gera "antes-e-depois-automacoes.pptx" (6 slides) com pptxgenjs.
 * Uso:  NODE_PATH=<pasta com pptxgenjs, react-icons, react, react-dom, sharp> node gerar-slides.js <apply_theme.js>
 */
const path = require('path');
const pptxgen = require('pptxgenjs');
const React = require('react');
const ReactDOMServer = require('react-dom/server');
const sharp = require('sharp');
const fa = require('react-icons/fa');

const { applyTheme } = require(process.argv[2]);
const OUT = path.join(__dirname, 'antes-e-depois-automacoes.pptx');
const IMG_DEMO = path.join(__dirname, 'img', 'demo-intercambios.png');
const DEMO_URL = 'https://claude.ai/artifact/KPV9K8urnLch5fWNxiCC4E'; // demo publicada (abre só para quem recebeu acesso)

/* ---------- Identidade log·aí (mesmas cores da demo) ---------- */
const HEX = {
  ink: '3A4556', slate: '5B6B84', card: 'F2F4F7', navy: '1F4E8C', green: '9CCB5B',
  red: 'B42318', amber: 'F2A93B', dgreen: '2B7A44', lblue: 'E1EEFB', line: 'E2E6EC', yellow: 'FFF1C2',
};
const THEME = {
  name: 'logai Planejamento',
  headFontFace: 'Calibri',
  bodyFontFace: 'Calibri',
  colors: {
    dk1: HEX.ink, lt1: 'FFFFFF', dk2: HEX.slate, lt2: HEX.card,
    accent1: HEX.navy, accent2: HEX.green, accent3: HEX.red, accent4: HEX.amber,
    accent5: HEX.dgreen, accent6: HEX.lblue, hlink: HEX.navy, folHlink: HEX.slate,
  },
};

const pres = new pptxgen();
pres.layout = 'LAYOUT_WIDE'; // 13,33" x 7,5"
pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
pres.title = 'Antes e depois das automações';
pres.subject = 'Automações da SDA e projeto Intercâmbios';
const C = pres.SchemeColor;
const S = pres.shapes;

/* ---------- Ícones (react-icons -> PNG) ---------- */
async function icon(name, hex) {
  const Comp = fa[name];
  if (!Comp) throw new Error('Ícone inexistente: ' + name);
  const svg = ReactDOMServer.renderToStaticMarkup(React.createElement(Comp, { size: 256 })).replace(/currentColor/g, '#' + hex);
  const buf = await sharp(Buffer.from(svg)).resize(256, 256, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } }).png().toBuffer();
  return 'image/png;base64,' + buf.toString('base64');
}

/* ---------- Helpers (sempre objetos novos: pptxgenjs altera as opções) ---------- */
const shadow = () => ({ type: 'outer', color: '000000', opacity: 0.12, blur: 8, offset: 2, angle: 90 });
function text(slide, t, o) { slide.addText(t, { isTextBox: true, margin: 0, valign: 'top', ...o }); }
function card(slide, x, y, w, h, name, o = {}) {
  slide.addShape(S.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.08, fill: { color: C.background2 }, objectName: name, ...o });
}
async function iconCircle(slide, iconName, x, y, d, { fill, fillTransp = 0, iconHex = 'FFFFFF', name }) {
  slide.addShape(S.OVAL, { x, y, w: d, h: d, fill: { color: fill, transparency: fillTransp }, objectName: `${name} (fundo)` });
  const p = d * 0.26;
  slide.addImage({ data: await icon(iconName, iconHex), x: x + p, y: y + p, w: d - 2 * p, h: d - 2 * p, objectName: name, altText: name });
}
function arrow(slide, x, y, w, h, color, name) {
  slide.addShape(S.RIGHT_ARROW, { x, y, w, h, fill: { color }, objectName: name });
}

/* ---------- Layouts ---------- */
const footer = (color) => ({ text: { text: 'Planejamento · TVV — Terminal Primário', options: { x: 0.6, y: 6.98, w: 7, h: 0.3, fontSize: 10, color, margin: 0 } } });
pres.defineSlideMaster({
  title: 'CAPA',
  background: { color: C.text2 },
  objects: [
    { placeholder: { options: { name: 'title', type: 'title', x: 0.8, y: 2.25, w: 11.7, h: 1.15, fontSize: 48, bold: true, color: C.background1, align: 'left', valign: 'bottom', margin: 0 }, text: '' } },
    { placeholder: { options: { name: 'body', type: 'body', x: 0.8, y: 3.55, w: 11.2, h: 0.9, fontSize: 20, color: C.background2, align: 'left', valign: 'top', margin: 0 }, text: '' } },
  ],
});
pres.defineSlideMaster({
  title: 'CONTEUDO',
  background: { color: C.background1 },
  objects: [
    { placeholder: { options: { name: 'title', type: 'title', x: 0.6, y: 0.4, w: 12.13, h: 0.72, fontSize: 36, bold: true, color: C.text1, align: 'left', valign: 'middle', margin: 0 }, text: '' } },
    footer(C.text2),
  ],
  slideNumber: { x: 12.23, y: 6.98, w: 0.5, h: 0.3, fontSize: 10, color: HEX.slate, align: 'right' },
});
pres.defineSlideMaster({
  title: 'ESCURO',
  background: { color: C.text2 },
  objects: [
    { placeholder: { options: { name: 'title', type: 'title', x: 0.6, y: 0.4, w: 12.13, h: 0.72, fontSize: 36, bold: true, color: C.background1, align: 'left', valign: 'middle', margin: 0 }, text: '' } },
    footer(C.background2),
  ],
  slideNumber: { x: 12.23, y: 6.98, w: 0.5, h: 0.3, fontSize: 10, color: HEX.card, align: 'right' },
});

const subtitle = (slide, t) => text(slide, t, { x: 0.6, y: 1.17, w: 12.13, h: 0.4, fontSize: 16, color: C.text2 });

(async () => {
  /* =============== 1. CAPA =============== */
  pres.addSection({ title: 'Abertura' });
  let s = pres.addSlide({ masterName: 'CAPA', sectionTitle: 'Abertura' });
  // marca: grade 3x3
  for (let i = 0; i < 9; i++) {
    const r = Math.floor(i / 3), c = i % 3;
    s.addShape(S.RECTANGLE, { x: 0.8 + c * 0.2, y: 0.82 + r * 0.2, w: 0.16, h: 0.16, fill: { color: i % 2 ? 'CFE6AE' : HEX.green }, objectName: `Marca ${i + 1}` });
  }
  text(s, 'log·aí', { x: 1.55, y: 0.78, w: 1.3, h: 0.6, fontSize: 30, bold: true, color: C.background1, valign: 'middle' });
  s.addShape(S.LINE, { x: 2.85, y: 0.88, w: 0, h: 0.42, line: { color: 'FFFFFF', width: 1, transparency: 50 }, objectName: 'Separador' });
  text(s, 'Planejamento', { x: 3.03, y: 0.78, w: 3, h: 0.6, fontSize: 22, color: C.background1, valign: 'middle' });
  s.addText('Antes e depois das automações', { placeholder: 'title' });
  s.addText('Cadastro da SDA no PTVV e no Loga-AI · Projeto Intercâmbios com o Navis N4', { placeholder: 'body' });
  const chips = [['FaFileExcel', 'SDA · cadastro no PTVV'], ['FaFileExcel', 'SDA · cadastro no Loga-AI'], ['FaSyncAlt', 'Intercâmbios · projeto N4']];
  for (let i = 0; i < chips.length; i++) {
    const x = 0.8 + i * 3.8;
    s.addShape(S.ROUNDED_RECTANGLE, { x, y: 5.0, w: 3.6, h: 0.8, rectRadius: 0.4, fill: { color: C.background1, transparency: 88 }, objectName: `Item ${i + 1}` });
    await iconCircle(s, chips[i][0], x + 0.14, 5.12, 0.56, { fill: C.accent2, iconHex: HEX.ink, name: `Ícone item ${i + 1}` });
    text(s, chips[i][1], { x: x + 0.85, y: 5.0, w: 2.65, h: 0.8, fontSize: 15, bold: true, color: C.background1, valign: 'middle' });
  }
  text(s, 'TVV — Terminal Primário · Novembro de 2026', { x: 0.8, y: 6.55, w: 8, h: 0.4, fontSize: 14, color: C.background2 });
  s.addNotes('Vou mostrar o antes e o depois de duas automações que já estão funcionando no cadastro da SDA (PTVV e Loga-AI) e do projeto de Intercâmbios, que integra o Loga-AI ao Navis N4.');

  /* =============== 2. SDA ANTES =============== */
  pres.addSection({ title: 'SDA' });
  s = pres.addSlide({ masterName: 'CONTEUDO', sectionTitle: 'SDA' });
  s.addText('SDA antes: tudo digitado à mão, duas vezes', { placeholder: 'title' });
  subtitle(s, 'Cada SDA recebida precisava ser cadastrada manualmente em dois sites');
  const passos = [
    ['FaFileAlt', 'Recebe o arquivo SDA'],
    ['FaCopy', 'Copia os dados campo a campo'],
    ['FaKeyboard', 'Digita cerca de 16 campos no PTVV'],
    ['FaKeyboard', 'Digita tudo de novo no Loga-AI'],
  ];
  for (let i = 0; i < passos.length; i++) {
    const x = 0.6 + i * 2.06, y = 1.85;
    card(s, x, y, 1.84, 2.25, `Passo ${i + 1}`);
    await iconCircle(s, passos[i][0], x + 0.2, y + 0.22, 0.62, { fill: C.text2, name: `Ícone passo ${i + 1}` });
    text(s, passos[i][1], { x: x + 0.2, y: y + 1.02, w: 1.52, h: 1.1, fontSize: 15, color: C.text1 });
    if (i < passos.length - 1) arrow(s, x + 1.87, y + 1.0, 0.16, 0.26, C.text2, `Seta ${i + 1}`);
  }
  card(s, 8.95, 1.85, 3.78, 2.25, 'Tempo antes');
  text(s, '10–30 min', { x: 9.22, y: 2.05, w: 3.4, h: 0.9, fontSize: 48, bold: true, color: C.accent3, valign: 'middle' });
  text(s, 'por SDA, somando os dois sites', { x: 9.22, y: 3.0, w: 3.4, h: 0.4, fontSize: 16, color: C.text1 });
  text(s, '5 a 15 min em cada site · estimado', { x: 9.22, y: 3.45, w: 3.4, h: 0.35, fontSize: 12, color: C.text2 });
  text(s, 'Problemas do dia a dia', { x: 0.6, y: 4.4, w: 6, h: 0.4, fontSize: 18, bold: true, color: C.text1 });
  const problemas = [
    ['FaExclamationTriangle', 'Erro de digitação', 'Dados digitados errado'],
    ['FaQuestionCircle', 'Campo esquecido', 'Informação sem preencher'],
    ['FaRedo', 'Retrabalho', 'Cadastros corrigidos depois'],
    ['FaHourglassHalf', 'Fila e atraso', 'Acúmulo nos dias cheios'],
  ];
  for (let i = 0; i < problemas.length; i++) {
    const x = 0.6 + i * 3.09, y = 4.9;
    s.addShape(S.ROUNDED_RECTANGLE, { x, y, w: 2.86, h: 1.7, rectRadius: 0.08, fill: { color: C.background1 }, line: { color: HEX.line, width: 1 }, objectName: `Problema ${i + 1}` });
    await iconCircle(s, problemas[i][0], x + 0.22, y + 0.22, 0.55, { fill: C.accent3, fillTransp: 86, iconHex: HEX.red, name: `Ícone problema ${i + 1}` });
    text(s, problemas[i][1], { x: x + 0.22, y: y + 0.87, w: 2.45, h: 0.35, fontSize: 15, bold: true, color: C.text1 });
    text(s, problemas[i][2], { x: x + 0.22, y: y + 1.22, w: 2.45, h: 0.35, fontSize: 14, color: C.text2 });
  }
  s.addNotes('Antes, a equipe abria o arquivo da SDA e digitava cada informação à mão: cerca de 16 campos no PTVV e tudo de novo no Loga-AI. Eram de 5 a 15 minutos em cada site, e os erros de digitação e campos esquecidos geravam retrabalho e fila nos dias cheios.');

  /* =============== 3. SDA DEPOIS =============== */
  s = pres.addSlide({ masterName: 'CONTEUDO', sectionTitle: 'SDA' });
  s.addText('SDA depois: importar, abrir e preencher', { placeholder: 'title' });
  subtitle(s, 'Uma planilha para cada site: o Excel puxa os dados da SDA e preenche o cadastro com um clique');
  const linhasBase = [
    ['Navio', 'LOG-IN DISCOVERY'],
    ['Armador', 'LOG-IN - LOGISTICA INTERMODAL S/A'],
    ['Agência', 'MSC MEDITERRANEAN SHIPPING DO BRASIL LTDA'],
    ['Viagem', '750S'],
    ['Origem → destino', 'Rio de Janeiro → Vitoria'],
    ['ETA', '07/12/2026 06:45'],
  ];
  const planilhas = [
    { x: 0.6, titulo: 'TVV | Cadastro de navio e viagem', botoes: ['1. Importar SDA', '2. Abrir portal', '3. Preencher cadastro'],
      linhas: [...linhasBase, ['Berço / serviço', '204 / FEE']], nome: 'Planilha PTVV' },
    { x: 7.38, titulo: 'Logai TVV — Cadastro de escala', botoes: ['1. Importar SDA', '2. Abrir Logai', '3. Preencher Logai'],
      linhas: [['Visit do Portal TVV', '11765'], ...linhasBase], nome: 'Planilha Loga-AI' },
  ];
  const y0 = 1.75, W = 5.35;
  for (const p of planilhas) {
    s.addShape(S.RECTANGLE, { x: p.x, y: y0, w: W, h: 0.42, fill: { color: C.accent1 }, objectName: `${p.nome} (título)` });
    text(s, p.titulo, { x: p.x + 0.14, y: y0, w: W - 0.28, h: 0.42, fontSize: 13, bold: true, color: C.background1, valign: 'middle' });
    const bw = (W - 0.24) / 3;
    p.botoes.forEach((b, i) => {
      const destaque = i === 2;
      s.addShape(S.ROUNDED_RECTANGLE, { x: p.x + i * (bw + 0.12), y: y0 + 0.54, w: bw, h: 0.36, rectRadius: 0.06, fill: { color: destaque ? C.accent2 : C.text1 }, objectName: `${p.nome} botão ${i + 1}` });
      text(s, b, { x: p.x + i * (bw + 0.12), y: y0 + 0.54, w: bw, h: 0.36, fontSize: 11, bold: true, align: 'center', valign: 'middle', color: destaque ? C.text1 : C.background1 });
    });
    const rows = [[
      { text: 'Campo', options: { bold: true, color: C.background1, fill: { color: C.text2 } } },
      { text: 'Valor para revisão', options: { bold: true, color: C.background1, fill: { color: C.text2 } } },
    ]];
    for (const [campo, valor] of p.linhas) {
      const visit = campo.startsWith('Visit');
      rows.push([
        { text: campo, options: { color: C.text1, fill: { color: C.background1 }, bold: visit } },
        { text: valor, options: { color: C.accent1, fill: { color: visit ? HEX.yellow : C.accent6 }, bold: visit } },
      ]);
    }
    s.addTable(rows, { x: p.x, y: y0 + 1.04, w: W, colW: [1.55, W - 1.55], rowH: 0.3, fontSize: 10, valign: 'middle', margin: [0.03, 0.08, 0.03, 0.08] /* polegadas */, border: { type: 'solid', pt: 0.75, color: HEX.line }, objectName: `${p.nome} (dados)` });
    text(s, '1 a 3 min por cadastro (antes: 5 a 15 min)', { x: p.x, y: y0 + 3.52, w: W, h: 0.32, fontSize: 14, bold: true, color: C.accent5 });
  }
  text(s, 'Visit gerada no PTVV', { x: 5.98, y: 2.55, w: 1.37, h: 0.5, fontSize: 11, color: C.text2, align: 'center', valign: 'bottom' });
  arrow(s, 6.2, 3.1, 0.95, 0.5, C.accent2, 'Seta Visit');
  text(s, '11765', { x: 5.98, y: 3.68, w: 1.37, h: 0.35, fontSize: 16, bold: true, color: C.text1, align: 'center' });
  const destaques = [
    { ic: 'FaUserCheck', fill: C.accent1, iconHex: 'FFFFFF', t: 'Nada é salvo sem revisão', d: 'A planilha preenche o site; quem confere e clica em Salvar é a equipe.' },
    { ic: 'FaExclamationTriangle', fill: C.accent4, iconHex: HEX.ink, t: 'Avisos de atenção', d: 'Alerta nomes parecidos e portos duplicados antes de salvar.' },
  ];
  for (let i = 0; i < destaques.length; i++) {
    const x = 0.6 + i * 6.18, y = 5.72, d = destaques[i];
    card(s, x, y, 5.95, 1.05, d.t);
    await iconCircle(s, d.ic, x + 0.22, y + 0.25, 0.55, { fill: d.fill, iconHex: d.iconHex, name: `Ícone ${d.t}` });
    text(s, d.t, { x: x + 0.97, y: y + 0.14, w: 4.8, h: 0.35, fontSize: 15, bold: true, color: C.text1 });
    text(s, d.d, { x: x + 0.97, y: y + 0.5, w: 4.85, h: 0.45, fontSize: 14, color: C.text2 });
  }
  s.addNotes('Hoje são duas planilhas, uma para o PTVV e outra para o Loga-AI. Importamos a SDA, a planilha puxa os dados necessários, abrimos o site e clicamos em Preencher cadastro: todos os campos são preenchidos sozinhos. A Visit gerada no PTVV é usada na planilha do Loga-AI. Nada é salvo sem a conferência da equipe, e a planilha avisa quando há nomes parecidos ou portos duplicados. Cada cadastro leva de 1 a 3 minutos.');

  /* =============== 4. INTERCÂMBIOS HOJE =============== */
  pres.addSection({ title: 'Intercâmbios' });
  s = pres.addSlide({ masterName: 'CONTEUDO', sectionTitle: 'Intercâmbios' });
  s.addText('Intercâmbios hoje: três ambientes, tudo manual', { placeholder: 'title' });
  subtitle(s, 'Devolução de contêineres vazios pós-desova · área solicitante: Planejamento');
  const hoje = [
    ['FaEnvelope', 'Outlook', 'O intercâmbio chega em PDF por e-mail'],
    ['FaFolderOpen', 'Pasta de rede', 'O arquivo é salvo à mão na pasta do Planejamento'],
    ['FaKeyboard', 'Navis N4', 'O cadastro é feito à mão, olhando o PDF'],
  ];
  for (let i = 0; i < hoje.length; i++) {
    const x = 0.6 + i * 4.265, y = 1.85;
    card(s, x, y, 3.6, 2.55, `Etapa ${i + 1}`);
    await iconCircle(s, hoje[i][0], x + 0.3, y + 0.3, 0.8, { fill: C.text2, name: `Ícone etapa ${i + 1}` });
    text(s, `ETAPA ${i + 1}`, { x: x + 1.3, y: y + 0.36, w: 2.1, h: 0.3, fontSize: 12, bold: true, color: C.text2 });
    text(s, hoje[i][1], { x: x + 1.3, y: y + 0.64, w: 2.2, h: 0.45, fontSize: 22, bold: true, color: C.text1 });
    text(s, hoje[i][2], { x: x + 0.3, y: y + 1.4, w: 3.0, h: 0.95, fontSize: 16, color: C.text1 });
    if (i < hoje.length - 1) arrow(s, x + 3.8, y + 1.1, 0.27, 0.34, C.text2, `Seta etapa ${i + 1}`);
  }
  const dores = [
    ['FaRedo', 'Trabalho manual a cada documento', 'Receber, salvar e cadastrar, um intercâmbio por vez.'],
    ['FaSearch', 'Sem acompanhamento centralizado', 'Difícil saber o que chegou e ainda não foi cadastrado no N4.'],
  ];
  for (let i = 0; i < dores.length; i++) {
    const x = 0.6 + i * 6.18, y = 4.85;
    s.addShape(S.ROUNDED_RECTANGLE, { x, y, w: 5.95, h: 1.35, rectRadius: 0.08, fill: { color: C.background1 }, line: { color: HEX.line, width: 1 }, objectName: dores[i][1] });
    await iconCircle(s, dores[i][0], x + 0.25, y + 0.35, 0.65, { fill: C.accent3, fillTransp: 86, iconHex: HEX.red, name: `Ícone ${dores[i][1]}` });
    text(s, dores[i][1], { x: x + 1.15, y: y + 0.27, w: 4.6, h: 0.38, fontSize: 16, bold: true, color: C.text1 });
    text(s, dores[i][2], { x: x + 1.15, y: y + 0.67, w: 4.6, h: 0.5, fontSize: 14, color: C.text2 });
  }
  s.addNotes('Hoje o intercâmbio passa por três ambientes: chega em PDF pelo Outlook, alguém salva o arquivo na pasta de rede do Planejamento e depois cadastra tudo à mão no Navis N4. É trabalho manual a cada documento e não temos um lugar único para ver o que chegou e ainda não foi cadastrado.');

  /* =============== 5. INTERCÂMBIOS DEPOIS =============== */
  s = pres.addSlide({ masterName: 'CONTEUDO', sectionTitle: 'Intercâmbios' });
  s.addText('Intercâmbios depois: o N4 cadastra sozinho', { placeholder: 'title' });
  subtitle(s, 'Projeto no Loga-AI integrado ao Navis N4 · viabilidade confirmada pela TI');
  const iw = 7.2, ih = iw * 1760 / 2744;
  s.addShape(S.RECTANGLE, { x: 0.58, y: 1.78, w: iw + 0.04, h: ih + 0.04, fill: { color: C.background1 }, line: { color: HEX.line, width: 1 }, shadow: shadow(), objectName: 'Moldura protótipo' });
  s.addImage({ path: IMG_DEMO, x: 0.6, y: 1.8, w: iw, h: ih, objectName: 'Protótipo Intercâmbios', altText: 'Tela de Intercâmbios no Loga-AI: um PDF sendo lido, um intercâmbio aguardando o N4 e os anteriores já cadastrados no N4',
    hyperlink: { url: DEMO_URL, tooltip: 'Abrir o protótipo navegável' } });
  s.addText([
    { text: 'Protótipo navegável (clique para abrir): ', options: { color: C.text2 } },
    { text: DEMO_URL.replace('https://', ''), options: { bold: true, hyperlink: { url: DEMO_URL, tooltip: 'Abrir o protótipo navegável' } } },
  ], { x: 0.6, y: 1.8 + ih + 0.1, w: iw, h: 0.3, fontSize: 12, margin: 0, valign: 'top', isTextBox: true, objectName: 'Link do protótipo' });
  const fluxo = [
    ['Cliente envia o PDF', 'Dados e intercâmbio em PDF direto no Loga-AI'],
    ['Loga-AI registra', 'Guarda o documento e a data, e lê os dados do PDF'],
    ['N4 puxa sozinho', 'Sem digitação e sem conferência manual'],
    ['Cadastrado no N4', 'Status muda após a confirmação do N4, com histórico'],
  ];
  for (let i = 0; i < fluxo.length; i++) {
    const x = 8.25, y = 1.8 + i * 1.17, last = i === fluxo.length - 1;
    if (!last) s.addShape(S.LINE, { x: x + 0.275, y: y + 0.6, w: 0, h: 0.52, line: { color: HEX.line, width: 2 }, objectName: `Conector ${i + 1}` });
    s.addShape(S.OVAL, { x, y, w: 0.55, h: 0.55, fill: { color: last ? C.accent5 : C.accent1 }, objectName: `Número ${i + 1}` });
    text(s, String(i + 1), { x, y, w: 0.55, h: 0.55, fontSize: 18, bold: true, color: C.background1, align: 'center', valign: 'middle' });
    text(s, fluxo[i][0], { x: x + 0.75, y: y + 0.02, w: 3.7, h: 0.36, fontSize: 17, bold: true, color: C.text1 });
    text(s, fluxo[i][1], { x: x + 0.75, y: y + 0.4, w: 3.73, h: 0.6, fontSize: 14, color: C.text2 });
  }
  s.addNotes('Com o projeto, o cliente envia os dados e o PDF direto no Loga-AI. O sistema registra o documento e a data, lê os dados e o Navis N4 puxa o intercâmbio automaticamente, sem digitação e sem conferência manual. O status só muda para Cadastrado no N4 depois da confirmação do N4. A TI já confirmou a viabilidade e o protótipo navegável está pronto para demonstrar: clique na imagem ou no link abaixo dela para abrir (' + DEMO_URL + ').');

  /* =============== 6. RESUMO =============== */
  pres.addSection({ title: 'Resumo' });
  s = pres.addSlide({ masterName: 'ESCURO', sectionTitle: 'Resumo' });
  s.addText('Resumo: o que muda', { placeholder: 'title' });
  // SDA
  let x = 0.6, y = 1.5;
  s.addShape(S.ROUNDED_RECTANGLE, { x, y, w: 5.95, h: 5.15, rectRadius: 0.1, fill: { color: C.background1 }, shadow: shadow(), objectName: 'Resumo SDA' });
  text(s, 'SDA · PTVV E LOGA-AI', { x: x + 0.4, y: y + 0.32, w: 5.1, h: 0.3, fontSize: 13, bold: true, color: C.text2, charSpacing: 1 });
  text(s, 'ANTES', { x: x + 0.4, y: y + 0.8, w: 2.2, h: 0.28, fontSize: 12, bold: true, color: C.text2 });
  text(s, 'DEPOIS', { x: x + 3.25, y: y + 0.8, w: 2.2, h: 0.28, fontSize: 12, bold: true, color: C.text2 });
  text(s, '10–30 min', { x: x + 0.4, y: y + 1.08, w: 2.45, h: 0.7, fontSize: 34, bold: true, color: C.text2, valign: 'middle' });
  arrow(s, x + 2.78, y + 1.27, 0.32, 0.32, C.accent2, 'Seta resumo');
  text(s, '2–6 min', { x: x + 3.25, y: y + 1.08, w: 2.3, h: 0.7, fontSize: 34, bold: true, color: C.accent5, valign: 'middle' });
  text(s, 'por SDA, somando os dois sites · estimado', { x: x + 0.4, y: y + 1.82, w: 5.2, h: 0.32, fontSize: 14, color: C.text2 });
  text(s, '≈ 80% menos tempo', { x: x + 0.4, y: y + 2.3, w: 5.2, h: 0.6, fontSize: 30, bold: true, color: C.accent1, valign: 'middle' });
  s.addText([
    { text: 'Cerca de 32 campos por SDA preenchidos pela planilha', options: { bullet: true, breakLine: true } },
    { text: 'Menos erro de digitação e campo esquecido', options: { bullet: true, breakLine: true } },
    { text: 'Nada é salvo sem a revisão da equipe', options: { bullet: true } },
  ], { x: x + 0.4, y: y + 3.15, w: 5.2, h: 1.7, fontSize: 15, color: C.text1, paraSpaceAfter: 8, valign: 'top', margin: 0, isTextBox: true });
  // Intercâmbios
  x = 6.78;
  s.addShape(S.ROUNDED_RECTANGLE, { x, y, w: 5.95, h: 5.15, rectRadius: 0.1, fill: { color: C.background1 }, shadow: shadow(), objectName: 'Resumo Intercâmbios' });
  text(s, 'INTERCÂMBIOS · PROJETO', { x: x + 0.4, y: y + 0.32, w: 5.1, h: 0.3, fontSize: 13, bold: true, color: C.text2, charSpacing: 1 });
  text(s, 'Do PDF ao Navis N4 sem digitação', { x: x + 0.4, y: y + 0.8, w: 5.2, h: 1.0, fontSize: 28, bold: true, color: C.accent1, valign: 'middle' });
  const muda = [
    ['FaInbox', 'Recebimento, arquivo e cadastro em um só lugar'],
    ['FaSyncAlt', 'Cadastro no Navis N4 automático'],
    ['FaListUl', 'Status e histórico de cada intercâmbio'],
  ];
  for (let i = 0; i < muda.length; i++) {
    const yy = y + 2.0 + i * 0.78;
    await iconCircle(s, muda[i][0], x + 0.4, yy, 0.52, { fill: C.accent2, fillTransp: 70, iconHex: HEX.dgreen, name: `Ícone ${muda[i][1]}` });
    text(s, muda[i][1], { x: x + 1.1, y: yy, w: 4.5, h: 0.52, fontSize: 15, color: C.text1, valign: 'middle' });
  }
  s.addShape(S.ROUNDED_RECTANGLE, { x: x + 0.4, y: y + 4.42, w: 5.15, h: 0.45, rectRadius: 0.22, fill: { color: C.accent2, transparency: 75 }, objectName: 'Situação do projeto' });
  text(s, 'Viabilidade confirmada pela TI · protótipo pronto', { x: x + 0.4, y: y + 4.42, w: 5.15, h: 0.45, fontSize: 14, bold: true, color: C.accent5, align: 'center', valign: 'middle' });
  s.addNotes('Resumindo: na SDA, o cadastro nos dois sites caiu de 10 a 30 minutos para 2 a 6 minutos por SDA, cerca de 80% menos tempo pelas nossas estimativas, com menos erro e sempre com a revisão da equipe. No projeto de Intercâmbios, o PDF entra no Loga-AI e o Navis N4 cadastra sozinho, com status e histórico de cada intercâmbio. A viabilidade já foi confirmada pela TI.');

  await pres.writeFile({ fileName: OUT });
  await applyTheme(OUT, THEME);
  console.log('Gerado:', OUT);
})().catch(e => { console.error(e); process.exit(1); });
