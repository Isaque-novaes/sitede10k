import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import sharp from 'sharp';
import { gerarJson, validarEsquema, prepararImagem, ErroLimiteIA } from '../src/externo/gemini.js';
import { ErroExterno } from '../src/externo/http.js';
import { criarServicos } from '../src/externo/servicos.js';
import { criarFetchFalso, fixture } from './falsos.js';

let tmp;
beforeEach(async () => { tmp = await mkdtemp(join(tmpdir(), 'jarvis-gemini-')); });
afterEach(async () => { await rm(tmp, { recursive: true, force: true }); });

const esquema = { type: 'OBJECT', properties: { titulo: { type: 'STRING' }, notas: { type: 'ARRAY', items: { type: 'NUMBER' } } }, required: ['titulo'] };
const opcoes = (f) => ({ chave: 'K', fetch: f, modelo: 'gemini-flash-latest', reserva: 'gemini-flash-lite-latest' });

test('gerarJson manda esquema e chave e devolve o objeto', async () => {
  const f = criarFetchFalso([{ metodo: 'POST', contem: 'gemini-flash-latest:generateContent', json: fixture('gemini-ok') }]);
  const r = await gerarJson({ prompt: 'oi', esquema }, opcoes(f));
  assert.deepEqual(r, { titulo: 'Seu estilo', notas: [4.8] });
  const corpo = JSON.parse(f.chamadas[0].corpo);
  assert.equal(corpo.generationConfig.responseMimeType, 'application/json'); assert.deepEqual(corpo.generationConfig.responseSchema, esquema);
  assert.equal(corpo.contents[0].role, 'user'); assert.equal(corpo.contents[0].parts[0].text, 'oi');
  assert.equal(f.chamadas[0].cabecalhos['x-goog-api-key'], 'K');
  assert.match(f.chamadas[0].url, /^https:\/\/generativelanguage\.googleapis\.com\/v1beta\/models\/gemini-flash-latest:generateContent$/);
});

test('imagens vão como inline_data', async () => {
  const f = criarFetchFalso([{ metodo: 'POST', contem: 'generateContent', json: fixture('gemini-ok') }]);
  await gerarJson({ prompt: 'veja', esquema, imagens: [{ mime: 'image/jpeg', base64: 'AAAA' }] }, opcoes(f));
  assert.deepEqual(JSON.parse(f.chamadas[0].corpo).contents[0].parts[1], { inline_data: { mime_type: 'image/jpeg', data: 'AAAA' } });
});

test('429 no modelo principal usa a reserva', async () => {
  const f = criarFetchFalso([{ contem: 'gemini-flash-latest:', status: 429, json: {} }, { contem: 'gemini-flash-lite-latest:', json: fixture('gemini-ok') }]);
  assert.equal((await gerarJson({ prompt: 'oi', esquema }, opcoes(f))).titulo, 'Seu estilo');
});

test('404 (modelo que não existe mais) também usa a reserva', async () => {
  const f = criarFetchFalso([{ contem: 'gemini-flash-latest:', status: 404, json: {} }, { contem: 'gemini-flash-lite-latest:', json: fixture('gemini-ok') }]);
  assert.equal((await gerarJson({ prompt: 'oi', esquema }, opcoes(f))).titulo, 'Seu estilo');
});

test('429 nos dois vira ErroLimiteIA', async () => {
  const f = criarFetchFalso([{ contem: 'generateContent', status: 429, json: {} }]);
  await assert.rejects(gerarJson({ prompt: 'oi', esquema }, { chave: 'K', fetch: f, modelo: 'a', reserva: 'b' }), ErroLimiteIA);
});

test('JSON fora do esquema repete uma vez e depois falha', async () => {
  const ruim = { candidates: [{ content: { parts: [{ text: '{"notas":"x"}' }] } }] };
  const f = criarFetchFalso([{ contem: 'generateContent', json: ruim }]);
  await assert.rejects(gerarJson({ prompt: 'oi', esquema }, { chave: 'K', fetch: f, modelo: 'a', reserva: 'b' }), (e) => e instanceof ErroExterno && e.servico === 'Gemini');
  assert.equal(f.chamadas.length, 2);
});

test('texto que não é JSON também repete e falha', async () => {
  const ruim = { candidates: [{ content: { parts: [{ text: 'Claro! Aqui está:' }] } }] };
  const f = criarFetchFalso([{ contem: 'generateContent', json: ruim }]);
  await assert.rejects(gerarJson({ prompt: 'oi', esquema }, { chave: 'K', fetch: f, modelo: 'a', reserva: 'b' }), ErroExterno);
});

test('resposta bloqueada sem candidatos falha sem travar', async () => {
  const f = criarFetchFalso([{ contem: 'generateContent', json: { promptFeedback: { blockReason: 'SAFETY' } } }]);
  await assert.rejects(gerarJson({ prompt: 'oi', esquema }, { chave: 'K', fetch: f, modelo: 'a', reserva: 'b' }), ErroExterno);
});

test('validarEsquema confere enum, required e maxItems', () => {
  const e = { type: 'OBJECT', properties: { t: { type: 'STRING', enum: ['a', 'b'] }, l: { type: 'ARRAY', maxItems: 2, items: { type: 'STRING' } } }, required: ['t'] };
  assert.equal(validarEsquema({ t: 'a', l: ['x'] }, e), true);
  assert.equal(validarEsquema({ t: 'c' }, e), false); assert.equal(validarEsquema({ l: [] }, e), false);
  assert.equal(validarEsquema({ t: 'a', l: ['1', '2', '3'] }, e), false);
  assert.equal(validarEsquema({ n: 1.5 }, { type: 'OBJECT', properties: { n: { type: 'INTEGER' } } }), false);
  assert.equal(validarEsquema([1, 2], { type: 'ARRAY', minItems: 3, items: { type: 'INTEGER' } }), false);
  assert.equal(validarEsquema(null, e), false);
});

test('prepararImagem reduz para 512 px em JPEG', async () => {
  const arq = join(tmp, 'g.png'); await sharp({ create: { width: 2000, height: 1000, channels: 3, background: '#123456' } }).png().toFile(arq);
  const img = await prepararImagem(arq);
  assert.equal(img.mime, 'image/jpeg');
  assert.equal((await sharp(Buffer.from(img.base64, 'base64')).metadata()).width, 512);
});

test('servicos.gemini.gerarJson usa modelo e reserva da config', async () => {
  const f = criarFetchFalso([{ metodo: 'POST', contem: 'meu-modelo:generateContent', json: fixture('gemini-ok') }]);
  const s = criarServicos({ chaves: { gemini: 'G' }, geminiModelo: 'meu-modelo', geminiReserva: 'reserva' }, { fetch: f });
  assert.equal((await s.gemini.gerarJson({ prompt: 'oi', esquema })).titulo, 'Seu estilo');
});
