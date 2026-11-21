import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';
import sharp from 'sharp';
import { temFfmpeg, tratarFoto, tratarVideo, tratarMidias } from '../src/previa/midia.js';

let tmp;
before(async () => { tmp = await mkdtemp(join(tmpdir(), 'jarvis-midia-')); });
after(async () => { await rm(tmp, { recursive: true, force: true }); });

const ffmpegOk = await temFfmpeg();

test('tratarFoto gera duas larguras sem ampliar', async () => {
  const orig = join(tmp, 'grande.jpg');
  await sharp({ create: { width: 2400, height: 1600, channels: 3, background: '#336699' } }).jpeg().toFile(orig);
  const f = await tratarFoto({ arquivo: orig, tipo: 'foto', origem: 'google', credito: 'Google Maps' }, tmp, 'f1');
  assert.equal((await sharp(f.celular).metadata()).width, 800);
  assert.equal((await sharp(f.pc).metadata()).width, 1600);
  assert.equal((await sharp(f.pc).metadata()).format, 'webp');
  assert.equal(f.cores.length, 5);
  assert.equal(f.tipo, 'foto');
  assert.equal(f.largura, 2400); assert.equal(f.altura, 1600);
});

test('tratarFoto não amplia foto pequena', async () => {
  const orig = join(tmp, 'pequena.jpg');
  await sharp({ create: { width: 320, height: 568, channels: 3, background: '#aa3300' } }).jpeg().toFile(orig);
  const f = await tratarFoto({ arquivo: orig, tipo: 'foto', origem: 'instagram', credito: '@x' }, tmp, 'f2');
  assert.equal((await sharp(f.pc).metadata()).width, 320);
  assert.equal((await sharp(f.celular).metadata()).width, 320);
  assert.equal(f.largura, 320); assert.equal(f.altura, 568);
});

test('tratarFoto aplica a rotação EXIF nas medidas', async () => {
  const orig = join(tmp, 'girada.jpg');
  await sharp({ create: { width: 1200, height: 800, channels: 3, background: '#228844' } })
    .withMetadata({ orientation: 6 }).jpeg().toFile(orig);
  const f = await tratarFoto({ arquivo: orig, tipo: 'foto', origem: 'instagram', credito: '@x' }, tmp, 'f3');
  assert.equal(f.largura, 800); assert.equal(f.altura, 1200);
});

test('tratarVideo comprime para 720p sem áudio e gera capa', { skip: !ffmpegOk }, async () => {
  const orig = join(tmp, 'v.mp4');
  execFileSync('ffmpeg', ['-y', '-v', 'error', '-f', 'lavfi', '-i', 'testsrc=size=1080x1920:rate=30:duration=15',
    '-f', 'lavfi', '-i', 'sine=duration=15', '-shortest', orig]);
  const v = await tratarVideo({ arquivo: orig, tipo: 'video', origem: 'instagram', credito: '@x' }, tmp, 'v1');
  const info = JSON.parse(execFileSync('ffprobe', ['-v', 'error', '-show_streams', '-show_format', '-of', 'json', v.video]));
  assert.equal(info.streams.filter((s) => s.codec_type === 'audio').length, 0);
  assert.ok(info.streams[0].height <= 720);
  assert.ok(Number(info.format.duration) <= 12.1);
  assert.ok(existsSync(v.capa));
  assert.equal(v.tipo, 'video');
  assert.ok(v.duracao <= 12.1 && v.duracao > 11);
  assert.equal(v.altura, 720);
});

test('tratarMidias pula arquivo corrompido com aviso', async () => {
  const ruim = join(tmp, 'ruim.jpg');
  await writeFile(ruim, 'não é imagem');
  const r = await tratarMidias([{ arquivo: ruim, tipo: 'foto', origem: 'google', credito: 'x' }], join(tmp, 'saida'));
  assert.equal(r.fotos.length, 0);
  assert.equal(r.avisos.length, 1);
  assert.equal(r.video, null);
});

test('tratarMidias trata fotos e usa só o primeiro vídeo', { skip: !ffmpegOk }, async () => {
  const fotos = [];
  for (let i = 0; i < 3; i++) {
    const arq = join(tmp, `m${i}.jpg`);
    await sharp({ create: { width: 1000, height: 700, channels: 3, background: '#4466' + (i + 1) + '0' } }).jpeg().toFile(arq);
    fotos.push({ arquivo: arq, tipo: 'foto', origem: 'google', credito: 'Google Maps' });
  }
  const vids = [];
  for (let i = 0; i < 2; i++) {
    const arq = join(tmp, `mv${i}.mp4`);
    execFileSync('ffmpeg', ['-y', '-v', 'error', '-f', 'lavfi', '-i', 'testsrc=size=640x360:rate=24:duration=2', arq]);
    vids.push({ arquivo: arq, tipo: 'video', origem: 'instagram', credito: '@x' });
  }
  const r = await tratarMidias([...fotos, ...vids], join(tmp, 'saida2'));
  assert.equal(r.fotos.length, 3);
  assert.ok(r.video);
  assert.equal(r.video.original.arquivo, vids[0].arquivo);
});
