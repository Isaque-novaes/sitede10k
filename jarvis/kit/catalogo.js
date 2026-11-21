// Catálogo do kit de prévias: o que existe e do que cada peça precisa.

/**
 * Topos. `requisitos.fotos` conta só fotos com largura original >= `larguraMin`.
 * @type {{id:string, requisitos:{fotos:number, video:boolean, larguraMin:number}, etiquetas:string[]}[]}
 */
export const TOPOS = [
  { id: 'foto-cheia', requisitos: { fotos: 1, video: false, larguraMin: 1200 }, etiquetas: ['impacto', 'classico'] },
  { id: 'video-fundo', requisitos: { fotos: 0, video: true, larguraMin: 0 }, etiquetas: ['dinamico', 'moderno'] },
  { id: 'colagem', requisitos: { fotos: 3, video: false, larguraMin: 600 }, etiquetas: ['acolhedor', 'variado'] },
  { id: 'tela-dividida', requisitos: { fotos: 1, video: false, larguraMin: 800 }, etiquetas: ['profissional', 'equilibrado'] },
  { id: 'titulo-gigante', requisitos: { fotos: 0, video: false, larguraMin: 0 }, etiquetas: ['forte', 'tipografico'] },
  { id: 'carrossel', requisitos: { fotos: 3, video: false, larguraMin: 1000 }, etiquetas: ['variado', 'vitrine'] },
  { id: 'moldura', requisitos: { fotos: 1, video: false, larguraMin: 700 }, etiquetas: ['elegante', 'sofisticado'] },
  { id: 'mosaico-movel', requisitos: { fotos: 5, video: false, larguraMin: 500 }, etiquetas: ['moderno', 'criativo'] },
];

const comTexto = (avaliacoes) => (avaliacoes ?? []).filter((a) => a?.texto?.trim()).length;

/**
 * Tipos de seção. `requisitos` recebe `{fotos, video, negocio, textos}`.
 * @type {{tipo:string, requisitos:(ctx:any) => boolean, fixa?:'inicio'|'fim'}[]}
 */
export const SECOES = [
  { tipo: 'servicos', requisitos: ({ textos }) => (textos?.servicos?.length ?? 0) >= 3 },
  { tipo: 'sobre', requisitos: ({ textos }) => !!textos?.sobre?.trim() },
  { tipo: 'galeria', requisitos: ({ fotos }) => (fotos?.length ?? 0) >= 4 },
  { tipo: 'avaliacoes', requisitos: ({ negocio }) => comTexto(negocio?.avaliacoes) >= 2 },
  { tipo: 'numeros', requisitos: ({ negocio }) => negocio?.nota != null || negocio?.totalAvaliacoes != null },
  { tipo: 'localizacao', requisitos: ({ negocio }) => !!negocio?.endereco || (negocio?.horarios?.length ?? 0) > 0 },
  { tipo: 'perguntas', requisitos: ({ textos }) => (textos?.perguntas?.length ?? 0) >= 2 },
  { tipo: 'chamada-final', requisitos: () => true, fixa: 'fim' },
];

export const VARIANTES = /** @type {const} */ (['a', 'b', 'c']);

/** @type {{id:string, etiquetas:string[]}[]} */
export const MOVIMENTOS = [
  { id: 'suave', etiquetas: ['acolhedor', 'familiar'] },
  { id: 'elegante', etiquetas: ['sofisticado', 'premium'] },
  { id: 'energico', etiquetas: ['jovem', 'esportivo', 'urbano'] },
  { id: 'paralaxe', etiquetas: ['moderno', 'natureza'] },
  { id: 'cinema', etiquetas: ['premium', 'gastronomia', 'noturno'] },
  { id: 'minimo', etiquetas: ['clinico', 'profissional', 'discreto'] },
];

/** Pares de fontes do Google Fonts. Nunca Inter ou Roboto como título. */
export const FONTES = [
  { id: 'playfair-dmsans', titulo: 'Playfair Display', texto: 'DM Sans', pesosTitulo: '500;700', pesosTexto: '400;500;700', etiquetas: ['elegante', 'classico', 'sofisticado', 'premium'] },
  { id: 'bebas-manrope', titulo: 'Bebas Neue', texto: 'Manrope', pesosTitulo: '400', pesosTexto: '400;600;800', etiquetas: ['forte', 'urbano', 'moderno', 'jovem'] },
  { id: 'fraunces-worksans', titulo: 'Fraunces', texto: 'Work Sans', pesosTitulo: '500;700', pesosTexto: '400;500;600', etiquetas: ['acolhedor', 'artesanal', 'familiar', 'gastronomia'] },
  { id: 'syne-karla', titulo: 'Syne', texto: 'Karla', pesosTitulo: '600;800', pesosTexto: '400;500;700', etiquetas: ['moderno', 'criativo', 'jovem', 'divertido'] },
  { id: 'cormorant-montserrat', titulo: 'Cormorant Garamond', texto: 'Montserrat', pesosTitulo: '500;700', pesosTexto: '400;500;600', etiquetas: ['sofisticado', 'premium', 'elegante', 'discreto'] },
  { id: 'archivoblack-archivo', titulo: 'Archivo Black', texto: 'Archivo', pesosTitulo: '400', pesosTexto: '400;500;700', etiquetas: ['forte', 'esportivo', 'urbano'] },
  { id: 'dmserif-outfit', titulo: 'DM Serif Display', texto: 'Outfit', pesosTitulo: '400', pesosTexto: '400;500;600', etiquetas: ['classico', 'acolhedor', 'elegante', 'familiar'] },
  { id: 'anton-nunitosans', titulo: 'Anton', texto: 'Nunito Sans', pesosTitulo: '400', pesosTexto: '400;600;800', etiquetas: ['energico', 'jovem', 'esportivo', 'divertido'] },
  { id: 'spacegrotesk-ibmplexsans', titulo: 'Space Grotesk', texto: 'IBM Plex Sans', pesosTitulo: '500;700', pesosTexto: '400;500;600', etiquetas: ['profissional', 'clinico', 'discreto', 'moderno'] },
  { id: 'abrilfatface-lato', titulo: 'Abril Fatface', texto: 'Lato', pesosTitulo: '400', pesosTexto: '400;700', etiquetas: ['divertido', 'gastronomia', 'classico'] },
];
