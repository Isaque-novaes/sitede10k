// Dados e fábricas compartilhados pelos testes. Só para testes.

/** Paleta escura válida usada em vários testes. */
export const PALETA_TESTE = {
  fundo: '#101418', superficie: '#1c232a', texto: '#f2f4f5', textoSuave: '#b8c0c7', destaque: '#e0a030', destaque2: '#3fa7a0',
};

/** Negócio sem avaliações, endereço, horários, nota nem telefone. */
export const negocioMinimo = {
  id: 'minimo', nome: 'Barbearia Mínima', nicho: 'barbearia', cidade: 'Campinas',
  avaliacoes: [], midias: [], clima: [],
};

/** 3 serviços, sobre e nenhuma pergunta. */
export const textosMinimos = {
  titulo: 'Corte na medida', subtitulo: 'Barbearia no centro de Campinas',
  servicos: [
    { nome: 'Corte', descricao: 'Tesoura e máquina' },
    { nome: 'Barba', descricao: 'Toalha quente' },
    { nome: 'Sobrancelha', descricao: 'Navalha' },
  ],
  sobre: 'Atendimento sem pressa.', perguntas: [], chamada: 'Agende seu horário',
};

const AVALIACOES = [
  { autor: 'Ana Paula', nota: 5, texto: 'Melhor corte da cidade, atendimento impecável e ambiente muito bom.' },
  { autor: 'Rodrigo', nota: 5, texto: 'Pontuais e caprichosos. Saio sempre satisfeito.' },
  { autor: 'Marcos', nota: 4, texto: 'Bom preço e café de cortesia.' },
  { autor: 'Juliana', nota: 5, texto: 'Levei meu filho e ele amou o corte.' },
  { autor: 'Pedro', nota: 5, texto: 'Barba perfeita, recomendo demais.' },
];

/** Negócio com todos os dados opcionais preenchidos. */
export const negocioCompleto = {
  id: 'completo', nome: 'Barbearia do Zé', nicho: 'barbearia', bairro: 'Cambuí', cidade: 'Campinas',
  endereco: 'Rua Coronel Quirino, 1200, Cambuí, Campinas', telefone: '(19) 3234-5678', whatsapp: '(19) 99876-5432',
  mapsUrl: 'https://maps.google.com/?cid=1',
  horarios: ['Seg a Sex: 9h às 20h', 'Sáb: 9h às 17h', 'Dom: fechado'],
  nota: 4.8, totalAvaliacoes: 230, avaliacoes: AVALIACOES,
  instagram: { usuario: 'barbeariadoze', bio: 'Corte clássico e barba desde 2010', seguidores: 4200 },
  midias: [], clima: ['urbano', 'forte'],
};

/** Textos completos com 4 perguntas. */
export const textosCompletos = {
  titulo: 'Seu estilo, no detalhe', subtitulo: 'Corte e barba no coração do Cambuí',
  servicos: [
    { nome: 'Corte masculino', descricao: 'Tesoura, máquina e acabamento na navalha.' },
    { nome: 'Barba completa', descricao: 'Toalha quente, óleo e navalha.' },
    { nome: 'Corte infantil', descricao: 'Paciência e capricho com os pequenos.' },
    { nome: 'Pigmentação', descricao: 'Disfarça falhas na barba e no cabelo.' },
  ],
  sobre: 'Desde 2010 cuidando do visual de quem passa pelo Cambuí. Sem pressa, com café e boa conversa.',
  perguntas: [
    { pergunta: 'Precisa agendar?', resposta: 'Recomendamos agendar pelo WhatsApp para não esperar.' },
    { pergunta: 'Aceitam cartão?', resposta: 'Sim, cartão, Pix e dinheiro.' },
    { pergunta: 'Tem estacionamento?', resposta: 'Tem vagas na rua e um estacionamento a 50 metros.' },
    { pergunta: 'Atendem crianças?', resposta: 'Sim, a partir de 2 anos.' },
  ],
  chamada: 'Agende seu horário agora',
};

/** Fotos "tratadas" só com medidas (para regras que não leem arquivos). */
export function fotosFalsas(n, largura = 2000, altura = 1333) {
  return Array.from({ length: n }, (_, i) => ({
    original: { arquivo: `foto${i}.jpg`, tipo: 'foto', origem: 'google', credito: 'Google Maps' },
    tipo: 'foto', celular: `foto${i}-800.webp`, pc: `foto${i}-1600.webp`, largura, altura,
    cores: ['#334455', '#c0392b', '#2e86de', '#27ae60', '#f1c40f'],
  }));
}

export const videoFalso = {
  original: { arquivo: 'v.mp4', tipo: 'video', origem: 'instagram', credito: '@barbeariadoze' },
  tipo: 'video', video: 'v.mp4', capa: 'v-capa.jpg', largura: 406, altura: 720, duracao: 10,
};

/** Contexto com 8 fotos de 2000 x 1333, um vídeo, 5 avaliações, endereço, horários, nota e 4 perguntas. */
export const contextoCompleto = {
  fotos: fotosFalsas(8), video: videoFalso, negocio: negocioCompleto, textos: textosCompletos,
};

// ---------- Fotos reais (arquivos) para testes de montagem ----------
import sharp from 'sharp';
import { join } from 'node:path';
import { mkdir } from 'node:fs/promises';
import { tratarFoto } from '../src/previa/midia.js';
import { derivarPaleta } from '../src/previa/cores.js';

const DEGRADES = [
  ['#2b1d14', '#b5713a'], ['#1d2b3a', '#6fa3c7'], ['#3a1d1d', '#d0574b'],
  ['#1f2a1d', '#8fbf6a'], ['#2a2a2a', '#c9c9c9'], ['#33261a', '#e0b070'],
  ['#1d1d33', '#8f7fd9'], ['#2e1f2a', '#d48fb7'],
];

/** Cria uma foto JPG com degradê e formas, para parecer uma foto de verdade nas capturas. */
export async function criarFotoArquivo(arquivo, largura, altura, i = 0) {
  const [a, b] = DEGRADES[i % DEGRADES.length];
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${largura}" height="${altura}">
    <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${a}"/><stop offset="1" stop-color="${b}"/></linearGradient></defs>
    <rect width="100%" height="100%" fill="url(#g)"/>
    <circle cx="${largura * 0.7}" cy="${altura * 0.35}" r="${Math.min(largura, altura) * 0.22}" fill="${b}" opacity="0.55"/>
    <rect x="${largura * 0.1}" y="${altura * 0.6}" width="${largura * 0.35}" height="${altura * 0.25}" fill="${a}" opacity="0.6"/>
  </svg>`;
  await sharp(Buffer.from(svg)).jpeg({ quality: 85 }).toFile(arquivo);
  return arquivo;
}

/** Gera e trata `n` fotos numa pasta. */
export async function criarFotosTratadas(pasta, n, { largura = 2000, altura = 1333, credito = '@barbeariadoze', origem = 'instagram' } = {}) {
  await mkdir(join(pasta, 'originais'), { recursive: true });
  const fotos = [];
  for (let i = 0; i < n; i++) {
    const arq = await criarFotoArquivo(join(pasta, 'originais', `f${i}.jpg`), largura, altura, i);
    fotos.push(await tratarFoto({ arquivo: arq, tipo: 'foto', origem, credito }, join(pasta, 'tratadas'), `foto-${i + 1}`));
  }
  return fotos;
}

export const TODAS_AS_SECOES_A = ['servicos', 'sobre', 'galeria', 'avaliacoes', 'numeros', 'localizacao', 'perguntas', 'chamada-final']
  .map((tipo) => ({ tipo, variante: 'a' }));

/** Montagem completa da Barbearia do Zé com 6 fotos tratadas de verdade. */
export async function prepararMontagemExemplo(pasta) {
  const fotos = await criarFotosTratadas(pasta, 6);
  const paleta = derivarPaleta(fotos.flatMap((f) => f.cores.slice(0, 3)), negocioCompleto.clima);
  return {
    negocio: negocioCompleto,
    textos: textosCompletos,
    assinatura: { topo: 'foto-cheia', fontes: 'playfair-dmsans', movimento: 'suave', secoes: TODAS_AS_SECOES_A, paleta },
    fotos,
    video: null,
    opcoes: {},
  };
}

// ---------- Contexto completo com arquivos reais (fotos e vídeo) ----------
import { execFileSync } from 'node:child_process';
import { tratarVideo } from '../src/previa/midia.js';
import { criarContextoPeca } from '../src/previa/montar.js';

/** Gera um vídeo vertical de teste e trata. */
export async function criarVideoTratado(pasta, { largura = 1080, altura = 1920, duracao = 4 } = {}) {
  await mkdir(join(pasta, 'originais'), { recursive: true });
  const orig = join(pasta, 'originais', 'video.mp4');
  execFileSync('ffmpeg', ['-y', '-v', 'error', '-f', 'lavfi', '-i', `testsrc=size=${largura}x${altura}:rate=24:duration=${duracao}`, orig]);
  return tratarVideo({ arquivo: orig, tipo: 'video', origem: 'instagram', credito: '@barbeariadoze' }, join(pasta, 'tratadas'), 'video');
}

/** Montagem e contexto de peça com 8 fotos, vídeo e todos os dados (para testar peças sozinhas). */
export async function prepararCtxCompleto(pasta) {
  const fotos = await criarFotosTratadas(pasta, 8);
  const video = await criarVideoTratado(pasta);
  const paleta = derivarPaleta(fotos.flatMap((f) => f.cores.slice(0, 3)), negocioCompleto.clima);
  const montagem = {
    negocio: negocioCompleto, textos: textosCompletos, fotos, video, opcoes: {},
    assinatura: { topo: 'foto-cheia', fontes: 'bebas-manrope', movimento: 'energico', secoes: TODAS_AS_SECOES_A, paleta },
  };
  return { montagem, ctx: criarContextoPeca(montagem) };
}
