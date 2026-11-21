import { test } from 'node:test';
import assert from 'node:assert/strict';
import sharp from 'sharp';
import {
  hexParaRgb, rgbParaHex, distanciaRgb, contraste, extrairCores, derivarPaleta, ajustarContraste,
} from '../src/previa/cores.js';

test('hex e rgb vão e voltam', () => {
  assert.deepEqual(hexParaRgb('#C0392B'), [192, 57, 43]);
  assert.equal(rgbParaHex([192, 57, 43]), '#c0392b');
});

test('contraste WCAG conhecido', () => {
  assert.equal(Math.round(contraste('#000000', '#ffffff')), 21);
  assert.equal(contraste('#777777', '#777777'), 1);
});

test('extrairCores acha a cor dominante', async () => {
  const img = await sharp({ create: { width: 100, height: 100, channels: 3, background: '#c0392b' } }).png().toBuffer();
  const [principal] = await extrairCores(img, 3);
  assert.ok(distanciaRgb(principal, '#c0392b') < 20);
});

test('extrairCores ordena da cor mais presente para a menos', async () => {
  const base = sharp({ create: { width: 100, height: 100, channels: 3, background: '#1e88e5' } });
  const faixa = await sharp({ create: { width: 100, height: 20, channels: 3, background: '#fdd835' } }).png().toBuffer();
  const img = await base.composite([{ input: faixa, top: 0, left: 0 }]).png().toBuffer();
  const cores = await extrairCores(img, 2);
  assert.ok(distanciaRgb(cores[0], '#1e88e5') < 30);
  assert.ok(distanciaRgb(cores[1], '#fdd835') < 30);
});

for (const caso of [
  { nome: 'foto quase preta', cores: ['#050505', '#0a0a0a', '#111111'], clima: [] },
  { nome: 'foto quase branca', cores: ['#fafafa', '#f0f0f0', '#e8e8e8'], clima: [] },
  { nome: 'foto colorida', cores: ['#2e4057', '#d1495b', '#edae49', '#00798c', '#66a182'], clima: ['moderno'] },
  { nome: 'sem nenhuma cor', cores: [], clima: [] },
  { nome: 'sem nenhuma cor, clima noturno', cores: [], clima: ['noturno'] },
]) {
  test(`derivarPaleta tem contraste: ${caso.nome}`, () => {
    const p = derivarPaleta(caso.cores, caso.clima);
    for (const k of ['fundo', 'superficie', 'texto', 'textoSuave', 'destaque', 'destaque2']) assert.match(p[k], /^#[0-9a-f]{6}$/, k);
    assert.ok(contraste(p.texto, p.fundo) >= 7);
    assert.ok(contraste(p.textoSuave, p.fundo) >= 4.5);
    assert.ok(contraste(p.destaque, p.fundo) >= 3);
    assert.ok(contraste(p.destaque2, p.fundo) >= 3);
    assert.ok(!['#000000', '#ffffff'].includes(p.fundo));
    const d = distanciaRgb(p.superficie, p.fundo);
    assert.ok(d >= 8 && d <= 40, `superficie a ${d}`);
  });
}

test('clima moderno gera fundo escuro', () => {
  const p = derivarPaleta(['#f5e6c8', '#c97b2a'], ['moderno']);
  assert.ok(contraste(p.fundo, '#000000') < 2);
});

test('sem clima escuro e cor clara gera fundo claro', () => {
  const p = derivarPaleta(['#f5e6c8', '#c97b2a'], ['acolhedor']);
  assert.ok(contraste(p.fundo, '#ffffff') < 1.25);
});

test('destaque é a cor mais saturada', () => {
  const p = derivarPaleta(['#8a8a8a', '#e53935', '#9e9e9e'], ['moderno']);
  const [r, g, b] = hexParaRgb(p.destaque);
  assert.ok(r > g && r > b);
});

test('ajustarContraste alcança o mínimo pedido mantendo o tom', () => {
  const ajustada = ajustarContraste('#3366cc', '#0d1117', 7);
  assert.ok(contraste(ajustada, '#0d1117') >= 7);
  const [r, g, b] = hexParaRgb(ajustada);
  assert.ok(b > r && b > g);
});
