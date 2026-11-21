import { mkdir, writeFile } from 'node:fs/promises';
import { dirname } from 'node:path';
import { requisitarBinario } from './http.js';

/** Baixa uma URL para um arquivo, criando a pasta. */
export async function baixarArquivo(url, destino, opcoes) {
  const bytes = await requisitarBinario(url, opcoes);
  await mkdir(dirname(destino), { recursive: true });
  await writeFile(destino, bytes);
  return destino;
}
