// Testes das correções pedidas na revisão final do plano 1.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, rm, writeFile, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import sharp from 'sharp';
import { tratarFoto } from '../src/previa/midia.js';
import { derivarPaleta } from '../src/previa/cores.js';
import { montarPrevia, gravarPrevia } from '../src/previa/montar.js';
import { conferirPrevia } from '../src/previa/conferir.js';
import { gerarPrevia } from '../src/previa/gerar.js';
import { textosBase, identificarNicho } from '../src/previa/textos-base.js';
import { abrirNavegador } from '../src/util/navegador.js';
import { TOPOS, VARIANTES } from '../kit/catalogo.js';
import { negocioCompleto, textosCompletos, TODAS_AS_SECOES_A, PALETA_TESTE, criarFotosTratadas } from './ajudantes.js';

let tmp; let navegador;
before(async () => { tmp = await mkdtemp(join(tmpdir(), 'jarvis-revisao-')); navegador = await abrirNavegador(); });
after(async () => { await navegador?.close(); await rm(tmp, { recursive: true, force: true }); });

async function foto(nome, largura, altura, cor = '#8a5a3a') {
  const pasta = join(tmp, 'orig'); await mkdir(pasta, { recursive: true });
  const arq = join(pasta, `${nome}.jpg`);
  await sharp({ create: { width: largura, height: altura, channels: 3, background: cor } }).jpeg().toFile(arq);
  return tratarFoto({ arquivo: arq, tipo: 'foto', origem: 'google', credito: 'Google Maps' }, join(tmp, 'tratadas'), nome);
}
const assinatura = (extra) => ({ topo: 'foto-cheia', fontes: 'playfair-dmsans', movimento: 'suave', secoes: TODAS_AS_SECOES_A, paleta: PALETA_TESTE, ...extra });
async function conferirMontagem(nome, montagem) {
  const pasta = join(tmp, nome);
  await gravarPrevia(pasta, montarPrevia(montagem));
  return conferirPrevia(pasta, { navegador, bloquearRede: true });
}

// 1. Foto pequena não vira topo de tela cheia
test('revisão 1: o topo usa só fotos que atendem a largura mínima dele', async () => {
  const pequena = await foto('pequena', 320, 568);
  const grande = await foto('grande', 2000, 1333);
  const { html } = montarPrevia({ negocio: negocioCompleto, textos: textosCompletos, fotos: [pequena, grande], video: null, assinatura: assinatura() });
  const topo = html.slice(html.indexOf('<header class="topo'), html.indexOf('</header>'));
  assert.ok(topo.includes('midias/grande-'), 'usa a foto grande');
  assert.ok(!topo.includes('midias/pequena-'), 'não usa a foto pequena');
});

// 2. Título legível sobre foto
test('revisão 2: a conferência reprova título sem contraste com o fundo', async () => {
  const pasta = join(tmp, 'sem-contraste'); await mkdir(pasta, { recursive: true });
  await writeFile(join(pasta, 'index.html'), `<!doctype html><meta name=viewport content="width=device-width"><body style="margin:0;background:#fff">
    <h1 data-titulo-principal style="color:#f4f4f4;font-size:48px;margin:40px">Título claro no branco</h1>`);
  const r = await conferirPrevia(pasta, { navegador, bloquearRede: true });
  assert.ok(r.problemas.some((p) => p.includes('pouco contraste')), r.problemas.join('; '));
});

test('revisão 2: topos com foto ficam legíveis mesmo com fotos quase brancas', async () => {
  const brancas = [await foto('branca1', 2000, 1333, '#f2f0ec'), await foto('branca2', 2000, 1333, '#f6f4ef'), await foto('branca3', 2000, 1333, '#efece6'),
    await foto('branca4', 2000, 1333, '#f4f1ea'), await foto('branca5', 2000, 1333, '#f0eee9')];
  const paleta = derivarPaleta(['#f2f0ec', '#efece6'], ['moderno']);
  for (const topo of ['foto-cheia', 'carrossel', 'moldura', 'mosaico-movel', 'tela-dividida', 'colagem']) {
    const r = await conferirMontagem(`branco-${topo}`, { negocio: negocioCompleto, textos: textosCompletos, fotos: brancas, video: null, assinatura: assinatura({ topo, paleta }) });
    assert.ok(r.ok, `${topo}: ${r.problemas.join('; ')}`);
  }
});

// 3. Palavra longa no título não é cortada
test('revisão 3: a conferência reprova título cortado nas laterais', async () => {
  const pasta = join(tmp, 'cortado'); await mkdir(pasta, { recursive: true });
  await writeFile(join(pasta, 'index.html'), `<!doctype html><meta name=viewport content="width=device-width"><body style="margin:0;background:#111;color:#fff">
    <div style="overflow:clip"><h1 data-titulo-principal style="font-size:60px;white-space:nowrap">Otorrinolaringologia avançada</h1></div>`);
  const r = await conferirPrevia(pasta, { navegador, bloquearRede: true });
  assert.ok(r.problemas.some((p) => p.includes('título principal cortado')), r.problemas.join('; '));
});

test('revisão 3: nenhum topo corta uma palavra longa no título', async () => {
  const fotos = await criarFotosTratadas(join(tmp, 'longas'), 6);
  const textos = { ...textosCompletos, titulo: 'Clínica de Otorrinolaringologia' };
  for (const { id } of TOPOS.filter((t) => t.id !== 'video-fundo')) {
    const r = await conferirMontagem(`longo-${id}`, { negocio: negocioCompleto, textos, fotos, video: null, assinatura: assinatura({ topo: id, fontes: 'anton-nunitosans' }) });
    assert.ok(r.ok, `${id}: ${r.problemas.join('; ')}`);
  }
});

// 4. Avaliações com texto difícil não vazam, em todas as variantes
test('revisão 4: as três variantes de cada seção aguentam textos difíceis no celular e no PC', async () => {
  const fotos = await criarFotosTratadas(join(tmp, 'dificeis'), 6);
  const negocio = {
    ...negocioCompleto,
    nome: 'Espaço de Beleza & Estética Maria Antônia D\'Ávila Conceição!',
    endereco: 'Avenida Doutor Heitor Penteado de Albuquerque Cavalcanti, 12345, Jardim Chapadão, Campinas',
    avaliacoes: [
      { autor: 'Cliente', nota: 5, texto: 'k'.repeat(40) },
      { autor: 'Outro', nota: 5, texto: 'https://www.exemplo.com.br/um/endereco/muito/comprido/sem/espaco/nenhum/para/quebrar/a/linha' },
      { autor: 'Mais um', nota: 4, texto: 'a'.repeat(280) },
      { autor: 'Texto longo', nota: 5, texto: 'Excelente atendimento '.repeat(45) },
    ],
  };
  const textos = { ...textosCompletos, servicos: [...textosCompletos.servicos, { nome: 'Otorrinolaringologista', descricao: 'Desparafusabilidades'.repeat(3) }] };
  for (const v of VARIANTES) {
    const secoes = TODAS_AS_SECOES_A.map((s) => ({ ...s, variante: v }));
    const r = await conferirMontagem(`dificil-${v}`, { negocio, textos, fotos, video: null, assinatura: assinatura({ topo: 'titulo-gigante', secoes, fontes: 'syne-karla' }) });
    assert.ok(r.ok, `variante ${v}: ${r.problemas.join('; ')}`);
  }
});

// 5. Uma foto só não se repete pela página
test('revisão 5: com uma foto só, ela aparece uma vez', async () => {
  const unica = await foto('unica', 640, 1136);
  const secoes = [{ tipo: 'servicos', variante: 'b' }, { tipo: 'sobre', variante: 'c' }, { tipo: 'sobre', variante: 'a' }, { tipo: 'chamada-final', variante: 'b' }];
  const { html } = montarPrevia({ negocio: negocioCompleto, textos: textosCompletos, fotos: [unica], video: null, assinatura: assinatura({ topo: 'titulo-gigante', secoes }) });
  assert.equal((html.match(/<img [^>]*midias\/unica-/g) || []).length, 1);
});

// 6. Textos base não prometem o que o negócio não tem
test('revisão 6: sem contato, endereço e horários, os textos não falam deles', () => {
  const academia = { id: 'g', nome: 'Academia Força Total', nicho: 'academia', cidade: 'Sorocaba', avaliacoes: [], midias: [], clima: [] };
  for (let s = 1; s <= 6; s++) {
    const tudo = JSON.stringify(textosBase(academia, () => (s % 7) / 7));
    assert.ok(!/WhatsApp/i.test(tudo), tudo);
    assert.ok(!/endereço completo|link do mapa|horários estão/i.test(tudo), tudo);
  }
});

test('revisão 6: com WhatsApp, os textos usam o WhatsApp', () => {
  const t = JSON.stringify(textosBase({ id: 'g', nome: 'Academia X', nicho: 'academia', cidade: 'Sorocaba', whatsapp: '(15) 99876-5432', avaliacoes: [], midias: [], clima: [] }, () => 0));
  assert.match(t, /WhatsApp/);
});

test('revisão 6: com só telefone fixo, os textos falam em telefone', () => {
  const t = JSON.stringify(textosBase({ id: 'g', nome: 'Academia X', nicho: 'academia', cidade: 'Sorocaba', telefone: '(15) 3232-1010', avaliacoes: [], midias: [], clima: [] }, () => 0));
  assert.ok(!/WhatsApp/i.test(t)); assert.match(t, /telefone/i);
});

// 7. Travessões vindos de fora são limpos
test('revisão 7: travessões de horários, bio e avaliações somem do HTML', () => {
  const negocio = {
    ...negocioCompleto,
    horarios: ['segunda-feira: 09:00–19:00', 'sábado: 09:00—13:00'],
    instagram: { ...negocioCompleto.instagram, bio: 'Barbearia — desde 2010' },
    avaliacoes: [{ autor: 'Ana', nota: 5, texto: 'Ótimo – recomendo' }, { autor: 'Bia', nota: 5, texto: 'Top — demais' }],
  };
  const { html } = montarPrevia({ negocio, textos: { ...textosCompletos, sobre: 'Desde 2010 — no Cambuí' }, fotos: [], video: null, assinatura: assinatura({ topo: 'titulo-gigante' }) });
  assert.ok(!/[—–]/.test(html));
  assert.match(html, /09:00 às 19:00/);
});

// 8. Assinatura sugerida de fora é validada
test('revisão 8: assinatura sugerida inválida vira aviso e escolha por regras', async () => {
  const negocio = { ...negocioCompleto, id: 'v', midias: [] };
  const ruins = [
    assinatura({ topo: 'titulo-gigante', secoes: [{ tipo: 'servicos', variante: 'z' }, { tipo: 'chamada-final', variante: 'a' }] }),
    assinatura({ topo: 'titulo-gigante', paleta: { ...PALETA_TESTE, fundo: '#000</style><script>alert(1)</script>' } }),
    assinatura({ topo: 'titulo-gigante', paleta: { ...PALETA_TESTE, texto: '#202428' } }),
    assinatura({ topo: 'titulo-gigante', secoes: [{ tipo: 'chamada-final', variante: 'a' }, { tipo: 'servicos', variante: 'a' }] }),
    assinatura({ topo: 'titulo-gigante', fontes: 'comic-sans' }),
  ];
  for (const sugerida of ruins) {
    const r = await gerarPrevia(negocio, { pastaSaida: tmp, usadas: [], assinatura: sugerida, conferir: false });
    assert.ok(r.avisos.some((a) => a.includes('assinatura')), JSON.stringify(sugerida));
    const html = await readFile(join(r.pasta, 'index.html'), 'utf8');
    assert.ok(!html.includes('<script>alert(1)</script>'));
  }
});

// 9. Nicho reconhecido por palavra, não por pedaço de palavra
test('revisão 9: identificarNicho não confunde pedaços de palavras', () => {
  assert.equal(identificarNicho('Restaurante de espetinhos'), 'restaurante');
  assert.equal(identificarNicho('Espaço Fitness'), 'academia');
  assert.equal(identificarNicho('Loja de tapetes'), 'generico');
  assert.equal(identificarNicho('Petshop Amigo'), 'petshop');
  assert.equal(identificarNicho('Café Central'), 'cafeteria');
  assert.equal(identificarNicho('Spa Urbano'), 'estetica');
});
