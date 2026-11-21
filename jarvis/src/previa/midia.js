import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { mkdir } from 'node:fs/promises';
import { basename, join } from 'node:path';
import sharp from 'sharp';
import { extrairCores } from './cores.js';

const exec = promisify(execFile);
const LARGURA_CELULAR = 800;
const LARGURA_PC = 1600;
const QUALIDADE_WEBP = 78;
const PARALELO = 4;

/** @returns {Promise<boolean>} */
export async function temFfmpeg() {
  try {
    await exec('ffmpeg', ['-version']);
    await exec('ffprobe', ['-version']);
    return true;
  } catch {
    return false;
  }
}

/**
 * @param {import('./tipos.js').Midia} midia
 * @param {string} pastaDestino
 * @param {string} nomeBase
 * @returns {Promise<import('./tipos.js').FotoTratada>}
 */
export async function tratarFoto(midia, pastaDestino, nomeBase) {
  await mkdir(pastaDestino, { recursive: true });
  const meta = await sharp(midia.arquivo).metadata();
  const girada = (meta.orientation ?? 1) >= 5;
  const largura = girada ? meta.height : meta.width;
  const altura = girada ? meta.width : meta.height;

  const celular = join(pastaDestino, `${nomeBase}-800.webp`);
  const pc = join(pastaDestino, `${nomeBase}-1600.webp`);
  for (const [destino, alvo] of [[celular, LARGURA_CELULAR], [pc, LARGURA_PC]]) {
    await sharp(midia.arquivo)
      .rotate()
      .resize({ width: Math.min(alvo, largura), withoutEnlargement: true })
      .webp({ quality: QUALIDADE_WEBP })
      .toFile(destino);
  }
  const cores = await extrairCores(celular, 5);
  return { original: midia, tipo: 'foto', celular, pc, largura, altura, cores };
}

async function sondarVideo(arquivo) {
  const { stdout } = await exec('ffprobe', ['-v', 'error', '-select_streams', 'v:0',
    '-show_entries', 'stream=width,height:format=duration', '-of', 'json', arquivo]);
  const info = JSON.parse(stdout);
  return {
    largura: info.streams?.[0]?.width ?? 0,
    altura: info.streams?.[0]?.height ?? 0,
    duracao: Number(info.format?.duration ?? 0),
  };
}

/**
 * Até 720 px de altura, sem áudio, H.264 +faststart, 1.500 kbit/s no máximo, até 12 s, com capa JPG.
 * @param {import('./tipos.js').Midia} midia
 * @param {string} pastaDestino
 * @param {string} nomeBase
 * @returns {Promise<import('./tipos.js').VideoTratado>}
 */
export async function tratarVideo(midia, pastaDestino, nomeBase) {
  await mkdir(pastaDestino, { recursive: true });
  const video = join(pastaDestino, `${nomeBase}.mp4`);
  const capa = join(pastaDestino, `${nomeBase}-capa.jpg`);
  await exec('ffmpeg', ['-y', '-v', 'error', '-i', midia.arquivo, '-t', '12', '-an',
    '-vf', "scale=-2:'min(720,ih)'", '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '26',
    '-maxrate', '1500k', '-bufsize', '3000k', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', video]);
  const { largura, altura, duracao } = await sondarVideo(video);
  const instante = duracao > 1 ? '1' : '0';
  await exec('ffmpeg', ['-y', '-v', 'error', '-ss', instante, '-i', video, '-frames:v', '1', '-q:v', '3', capa]);
  return { original: midia, tipo: 'video', video, capa, largura, altura, duracao };
}

/**
 * Trata todas as mídias de um negócio. Fotos com erro viram aviso. Usa só o primeiro vídeo.
 * @param {import('./tipos.js').Midia[]} midias
 * @param {string} pastaDestino
 */
export async function tratarMidias(midias, pastaDestino) {
  const avisos = [];
  const fotosEntrada = midias.filter((m) => m.tipo === 'foto');
  const primeiroVideo = midias.find((m) => m.tipo === 'video');

  /** @type {(import('./tipos.js').FotoTratada|null)[]} */
  const resultados = new Array(fotosEntrada.length).fill(null);
  let proxima = 0;
  async function trabalhador() {
    while (proxima < fotosEntrada.length) {
      const i = proxima++;
      const nome = `foto-${String(i + 1).padStart(2, '0')}`;
      try {
        resultados[i] = await tratarFoto(fotosEntrada[i], pastaDestino, nome);
      } catch (erro) {
        avisos.push(`Não consegui usar a foto ${basename(fotosEntrada[i].arquivo)}: ${erro.message}`);
      }
    }
  }
  await Promise.all(Array.from({ length: Math.min(PARALELO, fotosEntrada.length) }, trabalhador));

  let video = null;
  if (primeiroVideo) {
    if (await temFfmpeg()) {
      try {
        video = await tratarVideo(primeiroVideo, pastaDestino, 'video');
      } catch (erro) {
        avisos.push(`Não consegui usar o vídeo ${basename(primeiroVideo.arquivo)}: ${erro.message}`);
      }
    } else {
      avisos.push('ffmpeg não encontrado, vídeo ignorado');
    }
  }

  return { fotos: resultados.filter(Boolean), video, avisos };
}
