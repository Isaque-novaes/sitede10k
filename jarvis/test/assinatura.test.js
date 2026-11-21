import { test } from 'node:test';
import assert from 'node:assert/strict';
import { TOPOS, SECOES, VARIANTES, MOVIMENTOS, FONTES } from '../kit/catalogo.js';
import {
  partesAssinatura, paletasIguais, contarDiferencas, ehUnica, opcoesPossiveis, escolherAssinaturaPorRegras,
} from '../src/previa/assinatura.js';
import { contraste } from '../src/previa/cores.js';
import { criarAleatorio } from '../src/util/aleatorio.js';
import { PALETA_TESTE as P, negocioMinimo, textosMinimos, contextoCompleto } from './ajudantes.js';

const A = {
  topo: 'foto-cheia', fontes: 'playfair-dmsans', movimento: 'suave',
  secoes: [{ tipo: 'servicos', variante: 'a' }, { tipo: 'chamada-final', variante: 'a' }], paleta: P,
};

test('catálogo tem o tamanho mínimo', () => {
  assert.equal(TOPOS.length, 8); assert.equal(SECOES.length, 8); assert.equal(MOVIMENTOS.length, 6); assert.equal(FONTES.length, 10);
  assert.deepEqual(VARIANTES, ['a', 'b', 'c']);
  assert.ok(FONTES.every((f) => !/^(Inter|Roboto)$/.test(f.titulo)));
});

test('partesAssinatura junta as seções em texto', () => {
  assert.equal(partesAssinatura(A).secoes, 'servicos:a|chamada-final:a');
});

test('paletas próximas contam como iguais', () => {
  assert.equal(paletasIguais(P, { ...P, fundo: '#141a1e' }), true);
  assert.equal(paletasIguais(P, { ...P, destaque: '#2060e0' }), false);
});

test('assinatura idêntica nunca é única', () => {
  assert.equal(ehUnica(A, [{ assinatura: A, nicho: 'pizzaria', cidade: 'Recife' }], { nicho: 'barbearia', cidade: 'Campinas' }), false);
});

test('mesmo nicho e cidade exige 3 diferenças', () => {
  const duas = { ...A, topo: 'colagem', fontes: 'syne-karla' };
  const tres = { ...duas, movimento: 'elegante' };
  const usadas = [{ assinatura: A, nicho: 'barbearia', cidade: 'Campinas' }];
  assert.equal(contarDiferencas(A, duas), 2);
  assert.equal(ehUnica(duas, usadas, { nicho: 'barbearia', cidade: 'Campinas' }), false);
  assert.equal(ehUnica(tres, usadas, { nicho: 'barbearia', cidade: 'Campinas' }), true);
  assert.equal(ehUnica(duas, usadas, { nicho: 'barbearia', cidade: 'Sorocaba' }), true);
});

test('uma foto pequena só libera topos possíveis', () => {
  const fotos = [{ largura: 640, altura: 1136 }];
  const { topos, secoes } = opcoesPossiveis({ fotos, video: null, negocio: negocioMinimo, textos: textosMinimos });
  assert.ok(!topos.includes('foto-cheia') && !topos.includes('colagem') && !topos.includes('video-fundo'));
  assert.ok(topos.includes('titulo-gigante'));
  assert.ok(!secoes.includes('galeria') && !secoes.includes('avaliacoes') && !secoes.includes('localizacao'));
  assert.ok(!secoes.includes('numeros') && !secoes.includes('perguntas'));
  assert.ok(secoes.includes('chamada-final'));
});

test('sem nenhuma mídia, o único topo é titulo-gigante', () => {
  const { topos } = opcoesPossiveis({ fotos: [], video: null, negocio: negocioMinimo, textos: textosMinimos });
  assert.deepEqual(topos, ['titulo-gigante']);
});

test('contexto completo libera tudo', () => {
  const { topos, secoes } = opcoesPossiveis(contextoCompleto);
  assert.equal(topos.length, 8); assert.equal(secoes.length, 8);
});

test('dez assinaturas seguidas no mesmo nicho e cidade são todas únicas', () => {
  const usadas = []; const rnd = criarAleatorio(7);
  for (let i = 0; i < 10; i++) {
    const a = escolherAssinaturaPorRegras(contextoCompleto, P, ['#c0392b', '#2e86de', '#27ae60'], usadas, rnd);
    assert.ok(ehUnica(a, usadas, { nicho: 'barbearia', cidade: 'Campinas' }));
    assert.equal(a.secoes.at(-1).tipo, 'chamada-final');
    assert.ok(['servicos', 'sobre'].includes(a.secoes[0].tipo));
    usadas.push({ assinatura: a, nicho: 'barbearia', cidade: 'Campinas' });
  }
});

test('com um só topo possível, a paleta e o resto variam até ficar única', () => {
  const ctx = { fotos: [], video: null, negocio: negocioMinimo, textos: textosMinimos };
  const usadas = []; const rnd = criarAleatorio(11);
  for (let i = 0; i < 6; i++) {
    const a = escolherAssinaturaPorRegras(ctx, P, ['#c0392b', '#2e86de'], usadas, rnd);
    assert.equal(a.topo, 'titulo-gigante');
    assert.ok(ehUnica(a, usadas, { nicho: 'barbearia', cidade: 'Campinas' }));
    assert.ok(contraste(a.paleta.texto, a.paleta.fundo) >= 7);
    assert.ok(contraste(a.paleta.destaque, a.paleta.fundo) >= 3);
    usadas.push({ assinatura: a, nicho: 'barbearia', cidade: 'Campinas' });
  }
});

test('quando não há combinação única, lança SEM_COMBINACAO_UNICA', () => {
  const ctx = { fotos: [], video: null, negocio: negocioMinimo, textos: textosMinimos };
  const usadas = [];
  // Ocupa todas as combinações possíveis desta cidade com variações mínimas.
  const rnd = criarAleatorio(3);
  assert.throws(() => {
    for (let i = 0; i < 2000; i++) {
      const a = escolherAssinaturaPorRegras(ctx, P, [], usadas, rnd);
      usadas.push({ assinatura: a, nicho: 'barbearia', cidade: 'Campinas' });
    }
  }, (erro) => erro.code === 'SEM_COMBINACAO_UNICA');
});
