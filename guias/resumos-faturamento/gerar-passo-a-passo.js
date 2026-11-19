/*
 * Gera "passo-a-passo-resumos-faturamento.pptx" (7 slides) com pptxgenjs.
 * Uso:  NODE_PATH=<pasta com pptxgenjs, react-icons, react, react-dom, sharp> node gerar-passo-a-passo.js <apply_theme.js>
 */
const path = require('path');
const pptxgen = require('pptxgenjs');
const React = require('react');
const ReactDOMServer = require('react-dom/server');
const sharp = require('sharp');
const fa = require('react-icons/fa');

const { applyTheme } = require(process.argv[2]);
const OUT = path.join(__dirname, 'passo-a-passo-resumos-faturamento.pptx');
const LOGO = path.join(__dirname, '..', '..', 'apresentacao', 'img', 'login-tvv-transparente.png'); // 128 x 60 px

/* ---------- Cores da marca Log-In ---------- */
const HEX = {
  ink: '17233B', muted: '5E6B80', grey: 'F4F6F9', line: 'DCE2EB',
  blue: '2C4F93', blueTint: 'EEF3FA', green: '4CB034', greenInk: '2E7A20', greenTint: 'EAF6E6',
  amber: 'B26A00', amberTint: 'FFF5E0', amberLine: 'F2C46B', rowHi: 'E3F2DE',
};
const THEME = {
  name: 'Log-In TVV Planejamento',
  headFontFace: 'Calibri',
  bodyFontFace: 'Calibri',
  colors: {
    dk1: HEX.ink, lt1: 'FFFFFF', dk2: HEX.muted, lt2: HEX.grey,
    accent1: HEX.blue, accent2: HEX.green, accent3: HEX.amber, accent4: HEX.amberTint,
    accent5: HEX.blueTint, accent6: HEX.greenInk, hlink: HEX.blue, folHlink: HEX.muted,
  },
};

const pres = new pptxgen();
pres.layout = 'LAYOUT_WIDE'; // 13,33" x 7,5"
pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
pres.title = 'Envio dos resumos ao Faturamento — passo a passo';
pres.subject = 'Planejamento TVV';
const C = pres.SchemeColor;
const S = pres.shapes;

/* ---------- Ícones (react-icons -> PNG) ---------- */
const iconCache = new Map();
async function icon(name, hex) {
  const key = name + hex;
  if (iconCache.has(key)) return iconCache.get(key);
  const Comp = fa[name];
  if (!Comp) throw new Error('Ícone inexistente: ' + name);
  const svg = ReactDOMServer.renderToStaticMarkup(React.createElement(Comp, { size: 256 })).replace(/currentColor/g, '#' + hex);
  const buf = await sharp(Buffer.from(svg)).resize(256, 256, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } }).png().toBuffer();
  const data = 'image/png;base64,' + buf.toString('base64');
  iconCache.set(key, data);
  return data;
}

/* ---------- Helpers (objetos novos a cada chamada: pptxgenjs altera as opções) ---------- */
const shadow = () => ({ type: 'outer', color: '000000', opacity: 0.12, blur: 8, offset: 2, angle: 90 });
function text(slide, t, o) { slide.addText(t, { isTextBox: true, margin: 0, valign: 'top', ...o }); }
function box(slide, x, y, w, h, name, o = {}) {
  slide.addShape(S.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.1, fill: { color: C.background2 }, objectName: name, ...o });
}
async function iconImg(slide, name, hex, x, y, d, label) {
  slide.addImage({ data: await icon(name, hex), x, y, w: d, h: d, objectName: label, altText: label });
}
async function iconCircle(slide, name, x, y, d, { fill, iconHex = 'FFFFFF', label }) {
  slide.addShape(S.OVAL, { x, y, w: d, h: d, fill: { color: fill }, objectName: `${label} (fundo)` });
  const p = d * 0.27;
  await iconImg(slide, name, iconHex, x + p, y + p, d - 2 * p, label);
}
function stepNum(slide, n, x, y, d = 0.62, fill = C.accent1) {
  slide.addShape(S.OVAL, { x, y, w: d, h: d, fill: { color: fill }, objectName: `Passo ${n}` });
  text(slide, String(n), { x, y, w: d, h: d, fontSize: 22, bold: true, color: C.background1, align: 'center', valign: 'middle' });
}
/* bloco de passo: número + título + descrição */
function step(slide, n, x, y, w, title, desc, { fill, descH = 0.8 } = {}) {
  stepNum(slide, n, x, y, 0.62, fill);
  text(slide, title, { x: x + 0.85, y: y + 0.02, w, h: 0.45, fontSize: 21, bold: true, color: C.text1, valign: 'middle' });
  if (desc) text(slide, desc, { x: x + 0.85, y: y + 0.52, w, h: descH, fontSize: 16, color: C.text2 });
}
/* indicador de progresso dos 8 passos */
function tracker(slide, atuais) {
  const d = 0.34, gap = 0.56, x0 = 0.6, y = 0.42, first = Math.min(...atuais);
  slide.addShape(S.LINE, { x: x0 + d / 2, y: y + d / 2, w: gap * 7, h: 0, line: { color: HEX.line, width: 2 }, objectName: 'Linha do progresso' });
  for (let i = 1; i <= 8; i++) {
    const x = x0 + (i - 1) * gap, atual = atuais.includes(i), feito = i < first;
    slide.addShape(S.OVAL, { x, y, w: d, h: d, fill: { color: atual ? C.accent1 : feito ? C.accent2 : C.background1 },
      line: atual || feito ? undefined : { color: HEX.line, width: 1.5 }, objectName: `Progresso ${i}` });
    text(slide, String(i), { x, y, w: d, h: d, fontSize: 12, bold: true, align: 'center', valign: 'middle', color: atual || feito ? C.background1 : C.text2 });
  }
  const rotulo = atuais.length > 1 ? `Passos ${atuais.join(' e ')} de 8` : `Passo ${atuais[0]} de 8`;
  text(slide, rotulo, { x: x0 + gap * 7 + d + 0.25, y, w: 2.6, h: d, fontSize: 12, color: C.text2, valign: 'middle' });
}
const eyebrow = (slide, t) => text(slide, t, { x: 0.6, y: 0.98, w: 8, h: 0.3, fontSize: 13, bold: true, color: C.accent6, charSpacing: 1.5 });

/* ---------- Layouts ---------- */
pres.defineSlideMaster({
  title: 'CAPA',
  background: { color: C.background1 },
  objects: [
    { placeholder: { options: { name: 'title', type: 'title', x: 0.6, y: 2.6, w: 6.5, h: 1.75, fontSize: 44, bold: true, color: C.text1, align: 'left', valign: 'top', margin: 0 }, text: '' } },
    { placeholder: { options: { name: 'body', type: 'body', x: 0.6, y: 4.45, w: 6.3, h: 1.0, fontSize: 18, color: C.text2, align: 'left', valign: 'top', margin: 0 }, text: '' } },
  ],
});
pres.defineSlideMaster({
  title: 'PASSO',
  background: { color: C.background1 },
  objects: [
    { placeholder: { options: { name: 'title', type: 'title', x: 0.6, y: 1.28, w: 12.13, h: 0.72, fontSize: 32, bold: true, color: C.text1, align: 'left', valign: 'middle', margin: 0 }, text: '' } },
    { text: { text: 'Envio dos resumos ao Faturamento · Planejamento TVV', options: { x: 0.6, y: 6.98, w: 7, h: 0.3, fontSize: 10, color: HEX.muted, margin: 0 } } },
  ],
  slideNumber: { x: 12.23, y: 6.98, w: 0.5, h: 0.3, fontSize: 10, color: HEX.muted, align: 'right' },
});

(async () => {
  /* =============== 1. CAPA =============== */
  pres.addSection({ title: 'Capa' });
  let s = pres.addSlide({ masterName: 'CAPA', sectionTitle: 'Capa' });
  s.addImage({ path: LOGO, x: 0.6, y: 0.55, w: 1.36, h: 0.64, objectName: 'Logo Log-In TVV', altText: 'Log-In TVV' });
  text(s, 'PASSO A PASSO · PLANEJAMENTO TVV', { x: 0.6, y: 2.15, w: 6.5, h: 0.35, fontSize: 14, bold: true, color: C.accent6, charSpacing: 1.5 });
  s.addText('Envio dos resumos ao Faturamento', { placeholder: 'title' });
  s.addText('Como enviar pelo Outlook os documentos escaneados de um navio, usando o botão Faturamento.', { placeholder: 'body' });
  text(s, '8 passos', { x: 0.6, y: 6.35, w: 3, h: 0.4, fontSize: 14, bold: true, color: C.text2 });
  s.addShape(S.RECTANGLE, { x: 7.75, y: 0, w: 5.583, h: 7.5, fill: { color: C.accent1 }, objectName: 'Painel azul' });
  const capa = [
    ['FaFileAlt', 'Escaneie e salve', 'na pasta do Planejamento'],
    ['FaMousePointer', 'Aperte Faturamento', 'e informe quantidade e navio'],
    ['FaEnvelopeOpenText', 'Confira e envie', 'o e-mail que já vem pronto'],
  ];
  for (let i = 0; i < capa.length; i++) {
    const y = 1.75 + i * 1.45;
    await iconCircle(s, capa[i][0], 8.45, y, 0.95, { fill: C.background1, iconHex: HEX.blue, label: `Ícone ${capa[i][1]}` });
    text(s, capa[i][1], { x: 9.65, y: y + 0.08, w: 3.4, h: 0.45, fontSize: 22, bold: true, color: C.background1 });
    text(s, capa[i][2], { x: 9.65, y: y + 0.52, w: 3.4, h: 0.4, fontSize: 15, color: 'D6E0F2' });
    if (i < capa.length - 1) s.addShape(S.LINE, { x: 8.925, y: y + 1.05, w: 0, h: 0.32, line: { color: 'FFFFFF', width: 2, transparency: 45 }, objectName: `Ligação ${i + 1}` });
  }
  s.addNotes('Este passo a passo mostra como enviar ao Faturamento os documentos escaneados de um navio. Você salva os arquivos na pasta, aperta o botão Faturamento, informa a quantidade de documentos e o nome do navio, e o e-mail abre pronto no Outlook para você conferir e enviar.');

  /* =============== 2. PASSOS 1 E 2 =============== */
  pres.addSection({ title: 'Passo a passo' });
  s = pres.addSlide({ masterName: 'PASSO', sectionTitle: 'Passo a passo' });
  tracker(s, [1, 2]);
  eyebrow(s, 'NA PASTA DE REDE');
  s.addText('Salve os documentos e confira a pasta', { placeholder: 'title' });
  step(s, 1, 0.6, 2.45, 4.9, 'Escaneie e salve os documentos', 'Salve os arquivos do navio na pasta:', { descH: 0.4 });
  s.addShape(S.ROUNDED_RECTANGLE, { x: 1.45, y: 3.45, w: 2.9, h: 0.5, rectRadius: 0.08, fill: { color: C.accent5 }, line: { color: 'C9D6EC', width: 1 }, objectName: 'Pasta' });
  text(s, 'S:\\PLANEJAMENTO\\', { x: 1.45, y: 3.45, w: 2.9, h: 0.5, fontSize: 17, bold: true, color: C.accent1, align: 'center', valign: 'middle' });
  step(s, 2, 0.6, 4.45, 4.9, 'Confira se são os mais recentes', 'Os documentos que você vai enviar precisam ser os últimos arquivos modificados na pasta.', { descH: 0.9 });
  // janela da pasta (exemplo)
  const jx = 6.65, jy = 2.35, jw = 6.08;
  s.addShape(S.ROUNDED_RECTANGLE, { x: jx, y: jy, w: jw, h: 4.25, rectRadius: 0.08, fill: { color: C.background1 }, line: { color: HEX.line, width: 1 }, shadow: shadow(), objectName: 'Janela da pasta' });
  s.addShape(S.RECTANGLE, { x: jx + 0.02, y: jy + 0.02, w: jw - 0.04, h: 0.55, fill: { color: C.background2 }, objectName: 'Barra da pasta' });
  await iconImg(s, 'FaFolderOpen', HEX.amber, jx + 0.25, jy + 0.13, 0.32, 'Ícone pasta');
  text(s, 'S:\\PLANEJAMENTO\\', { x: jx + 0.7, y: jy + 0.02, w: 4, h: 0.55, fontSize: 14, bold: true, color: C.text1, valign: 'middle' });
  const linhas = [
    ['Documento 3.pdf', '19/11/2026 14:32', true],
    ['Documento 2.pdf', '19/11/2026 14:31', true],
    ['Documento 1.pdf', '19/11/2026 14:30', true],
    ['Navio anterior 2.pdf', '18/11/2026 16:05', false],
    ['Navio anterior 1.pdf', '18/11/2026 16:04', false],
  ];
  const hdr = (t) => ({ text: t, options: { bold: true, color: C.text2, fill: { color: C.background1 } } });
  const rows = [[hdr('Nome'), hdr('Data de modificação ↓')]];
  for (const [nome, data, hi] of linhas) {
    const o = { color: hi ? C.text1 : C.text2, bold: hi, fill: { color: hi ? HEX.rowHi : C.background1 } };
    rows.push([{ text: nome, options: { ...o } }, { text: data, options: { ...o } }]);
  }
  s.addTable(rows, { x: jx + 0.25, y: jy + 0.75, w: jw - 0.5, colW: [3.13, jw - 0.5 - 3.13], rowH: 0.44, fontSize: 14, valign: 'middle',
    margin: [0.04, 0.12, 0.04, 0.12], border: { type: 'solid', pt: 0.75, color: HEX.line }, objectName: 'Arquivos da pasta' });
  s.addShape(S.ROUNDED_RECTANGLE, { x: jx + 0.25, y: jy + 3.55, w: jw - 0.5, h: 0.48, rectRadius: 0.24, fill: { color: C.accent2 }, objectName: 'Aviso dos mais recentes' });
  text(s, 'Com quantidade 3, vão os 3 arquivos mais recentes', { x: jx + 0.25, y: jy + 3.55, w: jw - 0.5, h: 0.48, fontSize: 14, bold: true, color: C.background1, align: 'center', valign: 'middle' });
  s.addNotes('Passo 1: escaneie os documentos do navio e salve na pasta S:\\PLANEJAMENTO\\. Passo 2: confira se os documentos que você vai enviar são os últimos arquivos modificados na pasta, porque a automação escolhe os anexos pela data de modificação.');

  /* =============== 3. PASSO 3 =============== */
  s = pres.addSlide({ masterName: 'PASSO', sectionTitle: 'Passo a passo' });
  tracker(s, [3]);
  eyebrow(s, 'NA AUTOMAÇÃO');
  s.addText('Inicie a automação', { placeholder: 'title' });
  step(s, 3, 0.6, 2.45, 4.9, 'Aperte o botão Faturamento', 'A automação começa e, em seguida, pede duas informações: a quantidade de documentos e o nome do navio.', { descH: 1.3 });
  box(s, 6.65, 2.35, 6.08, 4.25, 'Área do botão');
  s.addShape(S.ROUNDED_RECTANGLE, { x: 8.0, y: 3.75, w: 3.4, h: 1.0, rectRadius: 0.14, fill: { color: C.accent1 }, shadow: shadow(), objectName: 'Botão Faturamento' });
  text(s, 'Faturamento', { x: 8.0, y: 3.75, w: 3.4, h: 1.0, fontSize: 30, bold: true, color: C.background1, align: 'center', valign: 'middle' });
  await iconImg(s, 'FaMousePointer', HEX.ink, 10.95, 4.45, 0.62, 'Cursor clicando no botão');
  text(s, 'Clique uma vez no botão', { x: 6.65, y: 5.6, w: 6.08, h: 0.4, fontSize: 14, color: C.text2, align: 'center' });
  s.addNotes('Passo 3: aperte o botão Faturamento. A automação começa e pede duas informações: a quantidade de documentos e o nome do navio.');

  /* =============== 4. PASSOS 4 E 5 =============== */
  s = pres.addSlide({ masterName: 'PASSO', sectionTitle: 'Passo a passo' });
  tracker(s, [4, 5]);
  eyebrow(s, 'NA AUTOMAÇÃO');
  s.addText('Informe a quantidade e o nome do navio', { placeholder: 'title' });
  const dialogos = [
    { x: 0.6, n: 4, campo: 'Quantidade de documentos', valor: '3', t: 'Informe a quantidade de documentos', d: 'Para enviar três arquivos, digite 3.' },
    { x: 6.83, n: 5, campo: 'Nome do navio', valor: 'Log-In Pantanal', t: 'Informe o nome do navio', d: 'Exemplo: Log-In Pantanal. O nome vai para o assunto do e-mail.' },
  ];
  for (const g of dialogos) {
    const w = 5.9, y = 2.3;
    s.addShape(S.ROUNDED_RECTANGLE, { x: g.x, y, w, h: 2.45, rectRadius: 0.08, fill: { color: C.background1 }, line: { color: HEX.line, width: 1 }, shadow: shadow(), objectName: `Janela passo ${g.n}` });
    s.addShape(S.RECTANGLE, { x: g.x + 0.02, y: y + 0.02, w: w - 0.04, h: 0.5, fill: { color: C.background2 }, objectName: `Barra passo ${g.n}` });
    text(s, 'Faturamento', { x: g.x + 0.25, y: y + 0.02, w: 3, h: 0.5, fontSize: 14, bold: true, color: C.text1, valign: 'middle' });
    text(s, '✕', { x: g.x + w - 0.6, y: y + 0.02, w: 0.4, h: 0.5, fontSize: 14, color: C.text2, align: 'center', valign: 'middle' });
    text(s, g.campo, { x: g.x + 0.3, y: y + 0.7, w: w - 0.6, h: 0.35, fontSize: 15, color: C.text1 });
    s.addShape(S.RECTANGLE, { x: g.x + 0.3, y: y + 1.1, w: w - 0.6, h: 0.55, fill: { color: C.background1 }, line: { color: HEX.blue, width: 1.5 }, objectName: `Campo passo ${g.n}` });
    text(s, g.valor, { x: g.x + 0.45, y: y + 1.1, w: w - 0.9, h: 0.55, fontSize: 20, bold: true, color: C.text1, valign: 'middle' });
    s.addShape(S.ROUNDED_RECTANGLE, { x: g.x + w - 2.6, y: y + 1.85, w: 1.1, h: 0.42, rectRadius: 0.06, fill: { color: C.background1 }, line: { color: HEX.line, width: 1 }, objectName: `Cancelar passo ${g.n}` });
    text(s, 'Cancelar', { x: g.x + w - 2.6, y: y + 1.85, w: 1.1, h: 0.42, fontSize: 13, color: C.text1, align: 'center', valign: 'middle' });
    s.addShape(S.ROUNDED_RECTANGLE, { x: g.x + w - 1.4, y: y + 1.85, w: 1.1, h: 0.42, rectRadius: 0.06, fill: { color: C.accent1 }, objectName: `OK passo ${g.n}` });
    text(s, 'OK', { x: g.x + w - 1.4, y: y + 1.85, w: 1.1, h: 0.42, fontSize: 13, bold: true, color: C.background1, align: 'center', valign: 'middle' });
    step(s, g.n, g.x, 5.15, 5.0, g.t, g.d, { descH: 0.75 });
  }
  s.addNotes('Passo 4: informe quantos documentos quer anexar; para três arquivos, digite 3. Passo 5: informe o nome do navio, por exemplo Log-In Pantanal. O nome vai para o assunto do e-mail.');

  /* =============== 5. PASSO 6 =============== */
  s = pres.addSlide({ masterName: 'PASSO', sectionTitle: 'Passo a passo' });
  tracker(s, [6]);
  eyebrow(s, 'NO OUTLOOK');
  s.addText('O e-mail abre pronto no Outlook', { placeholder: 'title' });
  const mx = 0.6, my = 2.3, mw = 6.75;
  s.addShape(S.ROUNDED_RECTANGLE, { x: mx, y: my, w: mw, h: 4.4, rectRadius: 0.08, fill: { color: C.background1 }, line: { color: HEX.line, width: 1 }, shadow: shadow(), objectName: 'Janela do e-mail' });
  s.addShape(S.RECTANGLE, { x: mx + 0.02, y: my + 0.02, w: mw - 0.04, h: 0.55, fill: { color: C.background2 }, objectName: 'Barra do e-mail' });
  s.addShape(S.ROUNDED_RECTANGLE, { x: mx + 0.25, y: my + 0.1, w: 1.2, h: 0.38, rectRadius: 0.06, fill: { color: C.accent1 }, objectName: 'Botão Enviar' });
  text(s, 'Enviar', { x: mx + 0.25, y: my + 0.1, w: 1.2, h: 0.38, fontSize: 13, bold: true, color: C.background1, align: 'center', valign: 'middle' });
  const campos = [['Para', 'Faturamento', true], ['Cc', 'Contatos em cópia', true], ['Assunto', 'Resumo Log-In Pantanal', false]];
  for (let i = 0; i < campos.length; i++) {
    const y = my + 0.62 + i * 0.5;
    text(s, campos[i][0], { x: mx + 0.3, y, w: 1.1, h: 0.5, fontSize: 14, color: C.text2, valign: 'middle' });
    if (campos[i][2]) {
      s.addShape(S.ROUNDED_RECTANGLE, { x: mx + 1.45, y: y + 0.09, w: 2.3, h: 0.32, rectRadius: 0.16, fill: { color: C.accent5 }, objectName: `Campo ${campos[i][0]}` });
      text(s, campos[i][1], { x: mx + 1.45, y: y + 0.09, w: 2.3, h: 0.32, fontSize: 13, color: C.accent1, align: 'center', valign: 'middle' });
    } else {
      text(s, campos[i][1], { x: mx + 1.45, y, w: 4.5, h: 0.5, fontSize: 15, bold: true, color: C.text1, valign: 'middle' });
    }
    s.addShape(S.LINE, { x: mx + 0.25, y: y + 0.5, w: mw - 0.5, h: 0, line: { color: HEX.line, width: 1 }, objectName: `Divisória ${i + 1}` });
  }
  const ay = my + 2.2;
  await iconImg(s, 'FaPaperclip', HEX.muted, mx + 0.3, ay + 0.06, 0.24, 'Anexos');
  ['Documento 3.pdf', 'Documento 2.pdf', 'Documento 1.pdf'].forEach((f, i) => {
    const fx = mx + 0.7 + i * 1.95;
    s.addShape(S.ROUNDED_RECTANGLE, { x: fx, y: ay, w: 1.8, h: 0.36, rectRadius: 0.06, fill: { color: C.background2 }, line: { color: HEX.line, width: 0.75 }, objectName: `Anexo ${i + 1}` });
    text(s, f, { x: fx, y: ay, w: 1.8, h: 0.36, fontSize: 12, color: C.text1, align: 'center', valign: 'middle' });
  });
  text(s, 'Boa tarde,', { x: mx + 0.3, y: my + 2.8, w: 4, h: 0.4, fontSize: 16, bold: true, color: C.text1 });
  [5.6, 4.3, 2.8].forEach((w, i) => s.addShape(S.ROUNDED_RECTANGLE, { x: mx + 0.3, y: my + 3.3 + i * 0.25, w, h: 0.12, rectRadius: 0.06, fill: { color: 'E6EAF1' }, objectName: `Texto ${i + 1}` }));
  text(s, 'Mensagem padrão da automação', { x: mx + 0.3, y: my + 4.02, w: 4, h: 0.3, fontSize: 11, italic: true, color: C.text2 });
  step(s, 6, 7.75, 2.35, 4.2, 'Aguarde o e-mail abrir', 'A automação preenche sozinha:', { descH: 0.4 });
  const preenche = ['Destinatários e contatos em cópia', 'Assunto: Resumo [Nome do Navio]', 'Saudação de acordo com o horário', 'Corpo do e-mail', 'Anexos selecionados'];
  for (let i = 0; i < preenche.length; i++) {
    const y = 3.45 + i * 0.6;
    await iconCircle(s, 'FaCheck', 8.6, y, 0.38, { fill: C.accent2, label: `Preenchido ${i + 1}` });
    text(s, preenche[i], { x: 9.15, y, w: 3.6, h: 0.38, fontSize: 16, color: C.text1, valign: 'middle' });
  }
  s.addNotes('Passo 6: aguarde o e-mail abrir no Outlook. A automação preenche os destinatários e os contatos em cópia, o assunto Resumo seguido do nome do navio, a saudação de acordo com o horário, o corpo do e-mail e os anexos selecionados.');

  /* =============== 6. PASSOS 7 E 8 =============== */
  s = pres.addSlide({ masterName: 'PASSO', sectionTitle: 'Passo a passo' });
  tracker(s, [7, 8]);
  eyebrow(s, 'NO OUTLOOK');
  s.addText('Confira e envie', { placeholder: 'title' });
  box(s, 0.6, 2.35, 7.1, 4.25, 'Conferência');
  step(s, 7, 0.95, 2.7, 5.6, 'Confira o e-mail', 'Antes de enviar, verifique:', { descH: 0.4 });
  const confere = [['Destinatários e pessoas em cópia', ''], ['Nome do navio no assunto', ''], ['Anexos', 'abra cada documento e confirme que é o resumo certo']];
  for (let i = 0; i < confere.length; i++) {
    const y = 3.95 + i * 0.75;
    s.addShape(S.ROUNDED_RECTANGLE, { x: 1.8, y: y + 0.03, w: 0.34, h: 0.34, rectRadius: 0.05, fill: { color: C.background1 }, line: { color: HEX.blue, width: 1.75 }, objectName: `Caixa ${i + 1}` });
    const runs = [{ text: confere[i][0], options: { bold: true, color: C.text1 } }];
    if (confere[i][1]) runs.push({ text: ': ' + confere[i][1], options: { color: C.text2 } });
    s.addText(runs, { x: 2.35, y, w: 5.1, h: 0.7, fontSize: 16, margin: 0, valign: 'top', isTextBox: true, objectName: `Conferir ${i + 1}` });
  }
  box(s, 7.95, 2.35, 4.78, 4.25, 'Envio', { fill: { color: 'EAF6E6' } });
  stepNum(s, 8, 8.3, 2.7, 0.62, C.accent2);
  text(s, 'Clique em Enviar', { x: 9.15, y: 2.72, w: 3.4, h: 0.45, fontSize: 21, bold: true, color: C.text1, valign: 'middle' });
  s.addShape(S.ROUNDED_RECTANGLE, { x: 9.15, y: 3.7, w: 2.3, h: 0.75, rectRadius: 0.1, fill: { color: C.accent1 }, shadow: shadow(), objectName: 'Botão Enviar grande' });
  await iconImg(s, 'FaPaperPlane', 'FFFFFF', 9.4, 3.9, 0.36, 'Ícone enviar');
  text(s, 'Enviar', { x: 9.85, y: 3.7, w: 1.5, h: 0.75, fontSize: 20, bold: true, color: C.background1, valign: 'middle' });
  text(s, 'Só depois da conferência. O envio é sempre feito por você.', { x: 9.15, y: 4.85, w: 3.3, h: 0.9, fontSize: 16, color: C.text2 });
  s.addNotes('Passo 7: confira os destinatários e as pessoas em cópia, o nome do navio no assunto e os anexos; abra cada documento e confirme que é o resumo certo. Passo 8: depois da conferência, clique em Enviar no Outlook.');

  /* =============== 7. ATENÇÃO =============== */
  pres.addSection({ title: 'Atenção' });
  s = pres.addSlide({ masterName: 'PASSO', sectionTitle: 'Atenção' });
  eyebrow(s, 'ATENÇÃO');
  s.addText('Antes de usar, lembre', { placeholder: 'title' });
  const avisos = [
    ['FaSortAmountDown', 'Anexos pela data', 'Os anexos são selecionados pela data de modificação, do mais recente para o mais antigo.'],
    ['FaShip', 'O navio não filtra arquivos', 'O nome do navio vai para o assunto. Ele não é usado para buscar ou filtrar os arquivos.'],
    ['FaUserCheck', 'O envio é seu', 'A automação prepara o e-mail. O envio é feito manualmente, depois da sua revisão.'],
  ];
  for (let i = 0; i < avisos.length; i++) {
    const x = 0.6 + i * 4.14, y = 2.4;
    s.addShape(S.ROUNDED_RECTANGLE, { x, y, w: 3.85, h: 3.0, rectRadius: 0.1, fill: { color: C.accent4 }, line: { color: HEX.amberLine, width: 1 }, objectName: avisos[i][1] });
    await iconCircle(s, avisos[i][0], x + 0.35, y + 0.4, 0.8, { fill: C.accent3, label: `Ícone ${avisos[i][1]}` });
    text(s, avisos[i][1], { x: x + 0.35, y: y + 1.45, w: 3.2, h: 0.5, fontSize: 20, bold: true, color: C.text1 });
    text(s, avisos[i][2], { x: x + 0.35, y: y + 2.0, w: 3.2, h: 1.5, fontSize: 16, color: C.text1 });
  }
  s.addNotes('Três cuidados: os anexos são escolhidos pela data de modificação, do mais recente para o mais antigo; o nome do navio não é usado para buscar ou filtrar os arquivos; e a automação só prepara o e-mail, o envio é sempre manual, depois da sua revisão.');

  await pres.writeFile({ fileName: OUT });
  await applyTheme(OUT, THEME);
  console.log('Gerado:', OUT);
})().catch(e => { console.error(e); process.exit(1); });
