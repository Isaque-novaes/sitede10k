// Baixa as fotos do Pexels da demonstração e monta o vídeo da pizzaria a partir das fotos.
// Uso: npm run demo:midias
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const exec = promisify(execFile);
const RAIZ = join(dirname(fileURLToPath(import.meta.url)), '..');
const PASTA = join(RAIZ, 'fixtures', 'midias');
const { negocios } = JSON.parse(await readFile(join(RAIZ, 'fixtures', 'negocios-demo.json'), 'utf8'));

async function baixar(id, destino) {
  if (existsSync(destino)) return true;
  const url = `https://images.pexels.com/photos/${id}/pexels-photo-${id}.jpeg?auto=compress&cs=tinysrgb&w=2000`;
  const resposta = await fetch(url);
  if (!resposta.ok) { console.log(`  não baixou ${id} (${resposta.status})`); return false; }
  await writeFile(destino, Buffer.from(await resposta.arrayBuffer()));
  return true;
}

async function videoDasFotos(fotos, destino) {
  if (existsSync(destino)) return true;
  const entradas = fotos.flatMap((f) => ['-i', f]);
  const filtros = fotos.map((_, i) => `[${i}:v]scale=1350:2400:force_original_aspect_ratio=increase,crop=1350:2400,`
    + `zoompan=z='min(zoom+0.0014,1.12)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=72:s=1080x1920:fps=24,setsar=1[v${i}]`).join(';');
  const juntar = `${fotos.map((_, i) => `[v${i}]`).join('')}concat=n=${fotos.length}:v=1:a=0[saida]`;
  try {
    await exec('ffmpeg', ['-y', '-v', 'error', ...entradas, '-filter_complex', `${filtros};${juntar}`, '-map', '[saida]', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', destino]);
    return true;
  } catch (erro) {
    console.log(`  não montei o vídeo: ${erro.message.split('\n')[0]}`);
    return false;
  }
}

for (const negocio of negocios) {
  const pasta = join(PASTA, negocio.id);
  await mkdir(pasta, { recursive: true });
  console.log(negocio.nome);
  const baixadas = [];
  for (const m of negocio.midias) {
    const destino = join(pasta, `${m.pexels}.jpg`);
    if (await baixar(m.pexels, destino)) baixadas.push(destino);
  }
  if (negocio.video?.gerarDasFotos) {
    await videoDasFotos(baixadas.slice(0, negocio.video.gerarDasFotos), join(pasta, 'video.mp4'));
  }
  console.log(`  ${baixadas.length} de ${negocio.midias.length} fotos`);
}
