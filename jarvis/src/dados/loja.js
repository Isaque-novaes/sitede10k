import { readFile, writeFile, rename, mkdir, rm } from 'node:fs/promises';
import { join } from 'node:path';

/**
 * Loja de dados em arquivos JSON, um por coleção, com escrita atômica.
 * @param {string} pasta
 */
export function criarLoja(pasta) {
  const filas = new Map();
  const arquivo = (colecao) => join(pasta, `${colecao}.json`);

  async function ler(colecao, padrao = undefined) {
    try {
      return JSON.parse(await readFile(arquivo(colecao), 'utf8'));
    } catch (erro) {
      if (erro.code === 'ENOENT') return structuredClone(padrao);
      throw erro;
    }
  }

  async function gravar(colecao, valor) {
    await mkdir(pasta, { recursive: true });
    const destino = arquivo(colecao);
    const temporario = `${destino}.${process.pid}.${Math.random().toString(36).slice(2)}.tmp`;
    try {
      await writeFile(temporario, JSON.stringify(valor, null, 2), 'utf8');
      await rename(temporario, destino);
    } catch (erro) {
      await rm(temporario, { force: true });
      throw erro;
    }
  }

  /** Lê, aplica fn e grava. Chamadas na mesma coleção esperam a anterior terminar. */
  function atualizar(colecao, fn, padrao = undefined) {
    const anterior = filas.get(colecao) ?? Promise.resolve();
    const proxima = anterior.catch(() => {}).then(async () => {
      const novo = await fn(await ler(colecao, padrao));
      await gravar(colecao, novo);
      return novo;
    });
    filas.set(colecao, proxima);
    return proxima;
  }

  return { pasta, ler, gravar, atualizar };
}
