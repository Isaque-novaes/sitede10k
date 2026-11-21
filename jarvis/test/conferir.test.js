import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { montarPrevia, gravarPrevia } from '../src/previa/montar.js';
import { conferirPrevia } from '../src/previa/conferir.js';
import { abrirNavegador } from '../src/util/navegador.js';
import { prepararMontagemExemplo } from './ajudantes.js';

let tmp; let boa; let ruim; let montagemExemplo; let navegador;
before(async () => {
  tmp = await mkdtemp(join(tmpdir(), 'jarvis-conferir-'));
  boa = join(tmp, 'boa'); ruim = join(tmp, 'ruim');
  await mkdir(ruim, { recursive: true });
  montagemExemplo = await prepararMontagemExemplo(join(tmp, 'trabalho'));
  navegador = await abrirNavegador();
});
after(async () => { await navegador?.close(); await rm(tmp, { recursive: true, force: true }); });

test('abrirNavegador abre um navegador que funciona', async () => {
  const pagina = await navegador.newPage();
  await pagina.setContent('<p>ok</p>');
  assert.equal(await pagina.textContent('p'), 'ok');
  await pagina.close();
});

test('prévia boa passa', async () => {
  await gravarPrevia(boa, montarPrevia(montagemExemplo));
  const r = await conferirPrevia(boa, { navegador, bloquearRede: true });
  assert.deepEqual(r.problemas, []); assert.ok(r.ok);
  assert.ok(existsSync(r.capturas.celular) && existsSync(r.capturas.pc));
  assert.equal(r.capturas.celular, join(boa, 'conferencia', 'celular.png'));
});

test('página quebrada é reprovada com os motivos', async () => {
  await writeFile(join(ruim, 'index.html'), `<!doctype html><meta name=viewport content="width=device-width"><body>
    <div style="width:2000px">largo</div><img src="nao-existe.jpg"><script>throw new Error('x')</script>`);
  const r = await conferirPrevia(ruim, { navegador, bloquearRede: true });
  assert.equal(r.ok, false);
  for (const trecho of ['vaza para os lados', 'imagem quebrada', 'erro', 'título principal']) assert.ok(r.problemas.some((p) => p.includes(trecho)), trecho);
  assert.ok(r.problemas.some((p) => p.startsWith('celular:')));
  assert.ok(r.problemas.some((p) => p.startsWith('pc:')));
});

test('título abaixo da primeira tela é reprovado', async () => {
  const pasta = join(tmp, 'titulo-baixo'); await mkdir(pasta, { recursive: true });
  await writeFile(join(pasta, 'index.html'), `<!doctype html><meta name=viewport content="width=device-width"><body style="margin:0">
    <div style="height:3000px"></div><h1 data-titulo-principal>Lá embaixo</h1>`);
  const r = await conferirPrevia(pasta, { navegador, bloquearRede: true });
  assert.ok(r.problemas.some((p) => p.includes('título principal fora da primeira tela')));
});

test('falha de fonte do Google não conta como erro', async () => {
  const pasta = join(tmp, 'fonte'); await mkdir(pasta, { recursive: true });
  await writeFile(join(pasta, 'index.html'), `<!doctype html><meta name=viewport content="width=device-width">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inexistente">
    <body><h1 data-titulo-principal>Olá</h1>`);
  const r = await conferirPrevia(pasta, { navegador, bloquearRede: true });
  assert.deepEqual(r.problemas, []);
});

test('abre e fecha o próprio navegador quando não recebe um', async () => {
  const r = await conferirPrevia(boa, { bloquearRede: true });
  assert.ok(r.ok, r.problemas.join('; '));
});
