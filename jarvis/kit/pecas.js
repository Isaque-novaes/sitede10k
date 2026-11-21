// Registro estático das peças do kit (o montador é síncrono).
import * as fotoCheia from './topos/foto-cheia.js';

import * as servicosA from './secoes/servicos-a.js';
import * as sobreA from './secoes/sobre-a.js';
import * as galeriaA from './secoes/galeria-a.js';
import * as avaliacoesA from './secoes/avaliacoes-a.js';
import * as numerosA from './secoes/numeros-a.js';
import * as localizacaoA from './secoes/localizacao-a.js';
import * as perguntasA from './secoes/perguntas-a.js';
import * as chamadaFinalA from './secoes/chamada-final-a.js';

export const PECAS_TOPO = {
  'foto-cheia': fotoCheia,
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
};
