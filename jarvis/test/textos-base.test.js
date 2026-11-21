import { test } from 'node:test';
import assert from 'node:assert/strict';
import { NICHOS, identificarNicho, textosBase } from '../src/previa/textos-base.js';
import { criarAleatorio } from '../src/util/aleatorio.js';

const negocioBase = {
  id: 'x', nome: 'Casa do Teste', nicho: 'generico', bairro: 'Centro', cidade: 'Jundiaí',
  avaliacoes: [], midias: [], clima: [],
};

test('identificarNicho reconhece variações', () => {
  assert.equal(identificarNicho('Barber Shop'), 'barbearia');
  assert.equal(identificarNicho('Clínica Odontológica Sorriso'), 'odontologia');
  assert.equal(identificarNicho('Pet Shop'), 'petshop');
  assert.equal(identificarNicho('Loja de parafusos'), 'generico');
  assert.equal(identificarNicho('Salão de beleza'), 'salao');
  assert.equal(identificarNicho('Clínica de Estética'), 'estetica');
  assert.equal(identificarNicho('Pizzaria'), 'pizzaria');
  assert.equal(identificarNicho('Auto Center e Mecânica'), 'oficina');
});

test('NICHOS tem os 15 nichos do plano', () => {
  assert.deepEqual(NICHOS, ['barbearia', 'salao', 'estetica', 'restaurante', 'pizzaria', 'hamburgueria', 'cafeteria', 'padaria', 'clinica', 'odontologia', 'academia', 'petshop', 'oficina', 'imobiliaria', 'generico']);
});

for (const nicho of NICHOS) {
  test(`textos base completos: ${nicho}`, () => {
    const t = textosBase({ ...negocioBase, nicho }, criarAleatorio(3));
    assert.ok(t.titulo && t.subtitulo && t.sobre && t.chamada);
    assert.ok(t.servicos.length >= 3 && t.perguntas.length >= 2);
    assert.ok(t.servicos.every((s) => s.nome && s.descricao));
    assert.ok(t.perguntas.every((p) => p.pergunta && p.resposta));
    const tudo = JSON.stringify(t);
    assert.ok(!/[—–]/.test(tudo)); assert.ok(!/\{(nome|lugar)\}/.test(tudo));
    assert.ok(tudo.includes(negocioBase.nome));
  });

  test(`textos base variam com o sorteio: ${nicho}`, () => {
    const vistos = new Set();
    for (let s = 1; s <= 12; s++) vistos.add(textosBase({ ...negocioBase, nicho }, criarAleatorio(s)).titulo);
    assert.ok(vistos.size >= 2);
  });
}

test('nicho escrito de outro jeito também funciona', () => {
  const t = textosBase({ ...negocioBase, nicho: 'Barbearia' }, criarAleatorio(1));
  assert.ok(JSON.stringify(t).toLowerCase().includes('barba'));
});

test('usa trecho de avaliação 5 estrelas', () => {
  const t = textosBase({ ...negocioBase, avaliacoes: [{ autor: 'Ana', nota: 5, texto: 'Melhor corte da cidade, atendimento impecável.' }] }, criarAleatorio(1));
  assert.ok(JSON.stringify(t).includes('Melhor corte da cidade'));
});

test('trecho de avaliação tem no máximo 120 caracteres', () => {
  const longa = 'Gostei muito do atendimento e voltarei sempre que puder porque '.repeat(5);
  const t = textosBase({ ...negocioBase, avaliacoes: [{ autor: 'Ana', nota: 5, texto: longa }] }, criarAleatorio(1));
  const trecho = JSON.stringify(t).match(/\\"([^"\\]*)\\"/);
  assert.ok(trecho && trecho[1].length <= 121);
});

test('sem bairro usa a cidade', () => {
  const t = textosBase({ ...negocioBase, bairro: undefined }, criarAleatorio(1));
  assert.ok(JSON.stringify(t).includes(negocioBase.cidade));
});
