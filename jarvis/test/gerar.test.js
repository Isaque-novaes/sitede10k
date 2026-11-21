import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm, readdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { gerarPrevia } from '../src/previa/gerar.js';
import { contarDiferencas } from '../src/previa/assinatura.js';
import { abrirNavegador } from '../src/util/navegador.js';
import { criarAleatorio } from '../src/util/aleatorio.js';
import { criarMidiasArquivo, criarVideoArquivo, PALETA_TESTE } from './ajudantes.js';

let tmp; let navegador;
let barbeariaA; let barbeariaB; let negocioDificil; let pizzariaComVideo;
const assinaturaComVideo = {
  topo: 'video-fundo', fontes: 'abrilfatface-lato', movimento: 'cinema',
  secoes: [{ tipo: 'servicos', variante: 'b' }, { tipo: 'chamada-final', variante: 'c' }], paleta: PALETA_TESTE,
};

before(async () => {
  tmp = await mkdtemp(join(tmpdir(), 'jarvis-gerar-'));
  navegador = await abrirNavegador();
  const base = { nicho: 'barbearia', cidade: 'Campinas', clima: ['urbano'], avaliacoes: [
    { autor: 'Ana', nota: 5, texto: 'Melhor corte da cidade.' }, { autor: 'Bia', nota: 5, texto: 'Atendimento impecável.' }] };
  barbeariaA = { ...base, id: 'a', nome: 'Barbearia Navalha de Ouro', bairro: 'Cambuí', whatsapp: '(19) 99876-5432', nota: 4.9, totalAvaliacoes: 310,
    midias: await criarMidiasArquivo(join(tmp, 'orig-a'), 6, { credito: '@navalhadeouro' }) };
  barbeariaB = { ...base, id: 'b', nome: 'Studio Corte Fino', bairro: 'Taquaral', telefone: '(19) 3232-1010',
    midias: await criarMidiasArquivo(join(tmp, 'orig-b'), 5, { credito: '@cortefino', inicio: 3 }) };
  negocioDificil = {
    id: 'd', nome: 'Espaço de Beleza & Estética Maria Antônia D\'Ávila Conceição!', nicho: 'estetica', cidade: 'São José dos Campos', clima: [],
    avaliacoes: [{ autor: 'Cliente', nota: 5, texto: 'Excelente atendimento '.repeat(45) }],
    midias: await criarMidiasArquivo(join(tmp, 'orig-d'), 1, { largura: 640, altura: 1136 }),
  };
  pizzariaComVideo = { id: 'p', nome: 'Forno da Nonna', nicho: 'pizzaria', cidade: 'Campinas', clima: ['gastronomia'], avaliacoes: [], whatsapp: '(19) 98888-7777',
    midias: [...await criarMidiasArquivo(join(tmp, 'orig-p'), 3), await criarVideoArquivo(join(tmp, 'orig-p'))] };
});
after(async () => { await navegador?.close(); await rm(tmp, { recursive: true, force: true }); });

const op = (extra = {}) => ({ pastaSaida: tmp, usadas: [], navegador, bloquearRede: true, ...extra });

test('duas barbearias na mesma cidade saem únicas e aprovadas', async () => {
  assert.equal(negocioDificil.nome.length, 60);
  const usadas = [];
  const a = await gerarPrevia(barbeariaA, op({ usadas, aleatorio: criarAleatorio(1) }));
  usadas.push({ assinatura: a.assinatura, nicho: 'barbearia', cidade: 'Campinas' });
  const b = await gerarPrevia(barbeariaB, op({ usadas, aleatorio: criarAleatorio(1) }));
  assert.ok(a.conferencia.ok, a.conferencia.problemas.join('; '));
  assert.ok(b.conferencia.ok, b.conferencia.problemas.join('; '));
  assert.ok(contarDiferencas(a.assinatura, b.assinatura) >= 3);
  assert.notEqual(a.slug, b.slug);
  assert.ok(existsSync(join(a.pasta, 'index.html')));
});

test('negócio com nome longo, avaliação enorme e uma foto só passa no celular', async () => {
  const r = await gerarPrevia(negocioDificil, op());
  assert.ok(r.conferencia.ok, r.conferencia.problemas.join('; '));
});

test('negócio sem nenhuma mídia ainda gera prévia', async () => {
  const r = await gerarPrevia({ ...barbeariaA, id: 'sem-midia', midias: [] }, op());
  assert.ok(r.conferencia.ok, r.conferencia.problemas.join('; '));
  assert.equal(r.assinatura.topo, 'titulo-gigante');
});

test('vídeo do negócio vira topo possível', async () => {
  const r = await gerarPrevia(pizzariaComVideo, op({ assinatura: assinaturaComVideo }));
  assert.equal(r.assinatura.topo, 'video-fundo');
  assert.ok(existsSync(join(r.pasta, 'midias')));
  assert.ok(r.conferencia.ok, r.conferencia.problemas.join('; '));
});

test('assinatura sugerida que já foi usada é trocada, com aviso', async () => {
  const usadas = [{ assinatura: assinaturaComVideo, nicho: 'pizzaria', cidade: 'Campinas' }];
  const r = await gerarPrevia(pizzariaComVideo, op({ usadas, assinatura: assinaturaComVideo, conferir: false }));
  assert.ok(contarDiferencas(r.assinatura, assinaturaComVideo) >= 3);
  assert.ok(r.avisos.some((a) => a.includes('assinatura')));
});

test('textos vindos de fora são usados', async () => {
  const textos = { titulo: 'Título vindo da IA', subtitulo: 'Sub', servicos: [{ nome: 'A', descricao: 'a' }, { nome: 'B', descricao: 'b' }, { nome: 'C', descricao: 'c' }], sobre: 'Sobre', perguntas: [], chamada: 'Chame' };
  const r = await gerarPrevia(barbeariaB, op({ textos, conferir: false }));
  const { readFile } = await import('node:fs/promises');
  assert.match(await readFile(join(r.pasta, 'index.html'), 'utf8'), /Título vindo da IA/);
});

test('a pasta da prévia só leva as mídias usadas na página', async () => {
  const r = await gerarPrevia(barbeariaA, op({ conferir: false }));
  const { readFile } = await import('node:fs/promises');
  const html = await readFile(join(r.pasta, 'index.html'), 'utf8');
  for (const arquivo of await readdir(join(r.pasta, 'midias'))) assert.ok(html.includes(`midias/${arquivo}`), arquivo);
});
