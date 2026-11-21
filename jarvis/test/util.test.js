import { test } from 'node:test';
import assert from 'node:assert/strict';
import { criarSlug } from '../src/util/slug.js';
import { esc } from '../src/util/html.js';
import { normalizarTelefoneBR, provavelCelular, linkWhatsApp } from '../src/util/whatsapp.js';
import { criarAleatorio } from '../src/util/aleatorio.js';

test('criarSlug limpa acentos, apóstrofo, & e emoji', () => {
  const s = criarSlug("D'Ávila Barber & Co 💈", criarAleatorio(1));
  assert.match(s, /^davila-barber-co-[a-z0-9]{4}$/);
});

test('criarSlug corta o nome em 40 caracteres', () => {
  const s = criarSlug('a'.repeat(80), criarAleatorio(2));
  assert.equal(s.split('-')[0].length, 40);
});

test('criarSlug muda o sufixo entre chamadas sem semente', () => {
  assert.notEqual(criarSlug('Barbearia X'), criarSlug('Barbearia X'));
});

test('esc escapa HTML', () => {
  assert.equal(esc(`<a href="x">'&'</a>`), '&lt;a href=&quot;x&quot;&gt;&#39;&amp;&#39;&lt;/a&gt;');
  assert.equal(esc(undefined), '');
});

test('telefone brasileiro', () => {
  assert.equal(normalizarTelefoneBR('(19) 99876-5432'), '5519998765432');
  assert.equal(normalizarTelefoneBR('+55 19 3234-5678'), '551932345678');
  assert.equal(normalizarTelefoneBR('123'), null);
  assert.equal(provavelCelular('(19) 99876-5432'), true);
  assert.equal(provavelCelular('(19) 3234-5678'), false);
});

test('linkWhatsApp codifica o texto', () => {
  assert.equal(linkWhatsApp('(19) 99876-5432', 'Olá, tudo bem?'),
    'https://wa.me/5519998765432?text=Ol%C3%A1%2C%20tudo%20bem%3F');
  assert.equal(linkWhatsApp('', 'x'), null);
});

test('criarAleatorio é determinístico', () => {
  const a = criarAleatorio(42), b = criarAleatorio(42);
  assert.deepEqual([a(), a(), a()], [b(), b(), b()]);
});
