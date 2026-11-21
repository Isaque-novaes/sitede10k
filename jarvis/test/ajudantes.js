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
