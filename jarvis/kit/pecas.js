// Registro estático das peças do kit (o montador é síncrono).
import * as fotoCheia from './topos/foto-cheia.js';
import * as videoFundo from './topos/video-fundo.js';
import * as colagem from './topos/colagem.js';
import * as telaDividida from './topos/tela-dividida.js';
import * as tituloGigante from './topos/titulo-gigante.js';
import * as carrossel from './topos/carrossel.js';
import * as moldura from './topos/moldura.js';
import * as mosaicoMovel from './topos/mosaico-movel.js';

import * as servicosA from './secoes/servicos-a.js';
import * as sobreA from './secoes/sobre-a.js';
import * as galeriaA from './secoes/galeria-a.js';
import * as avaliacoesA from './secoes/avaliacoes-a.js';
import * as numerosA from './secoes/numeros-a.js';
import * as localizacaoA from './secoes/localizacao-a.js';
import * as perguntasA from './secoes/perguntas-a.js';
import * as chamadaFinalA from './secoes/chamada-final-a.js';
import * as servicosB from './secoes/servicos-b.js';
import * as servicosC from './secoes/servicos-c.js';
import * as sobreB from './secoes/sobre-b.js';
import * as sobreC from './secoes/sobre-c.js';
import * as galeriaB from './secoes/galeria-b.js';
import * as galeriaC from './secoes/galeria-c.js';
import * as avaliacoesB from './secoes/avaliacoes-b.js';
import * as avaliacoesC from './secoes/avaliacoes-c.js';
import * as numerosB from './secoes/numeros-b.js';
import * as numerosC from './secoes/numeros-c.js';
import * as localizacaoB from './secoes/localizacao-b.js';
import * as localizacaoC from './secoes/localizacao-c.js';
import * as perguntasB from './secoes/perguntas-b.js';
import * as perguntasC from './secoes/perguntas-c.js';
import * as chamadaFinalB from './secoes/chamada-final-b.js';
import * as chamadaFinalC from './secoes/chamada-final-c.js';

export const PECAS_TOPO = {
  'foto-cheia': fotoCheia,
  'video-fundo': videoFundo,
  colagem,
  'tela-dividida': telaDividida,
  'titulo-gigante': tituloGigante,
  carrossel,
  moldura,
  'mosaico-movel': mosaicoMovel,
};

export const PECAS_SECAO = {
  'servicos-a': servicosA,
  'sobre-a': sobreA,
  'galeria-a': galeriaA,
  'avaliacoes-a': avaliacoesA,
  'numeros-a': numerosA,
  'localizacao-a': localizacaoA,
  'perguntas-a': perguntasA,
  'chamada-final-a': chamadaFinalA,
  'servicos-b': servicosB,
  'servicos-c': servicosC,
  'sobre-b': sobreB,
  'sobre-c': sobreC,
  'galeria-b': galeriaB,
  'galeria-c': galeriaC,
  'avaliacoes-b': avaliacoesB,
  'avaliacoes-c': avaliacoesC,
  'numeros-b': numerosB,
  'numeros-c': numerosC,
  'localizacao-b': localizacaoB,
  'localizacao-c': localizacaoC,
  'perguntas-b': perguntasB,
  'perguntas-c': perguntasC,
  'chamada-final-b': chamadaFinalB,
  'chamada-final-c': chamadaFinalC,
};
