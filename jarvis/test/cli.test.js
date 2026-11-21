import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { executar } from '../src/cli.js';
import { ambienteCli, registroAbordadoHa, registroSemSite } from './falsos.js';

test('buscar imprime o resumo e a lista', async () => {
  const { amb, linhas } = await ambienteCli();
  assert.equal(await executar(['buscar', 'barbearias', 'Campinas'], amb), 0);
  assert.match(linhas[0], /^Encontrei 5 barbearias\./); assert.ok(linhas.some((l) => /^1\. /.test(l)));
  assert.ok(linhas.some((l) => l.includes('sem-site-1')));
});

test('sem cidade usa a cidade padrão', async () => {
  const { amb, linhas } = await ambienteCli();
  assert.equal(await executar(['buscar', 'barbearias'], amb), 0); assert.match(linhas[0], /^Encontrei/);
});

test('sem cidade nem cidade padrão explica o que falta', async () => {
  const { amb, linhas } = await ambienteCli({ cidadePadrao: '' });
  assert.equal(await executar(['buscar', 'barbearias'], amb), 1); assert.match(linhas.join('\n'), /Diga a cidade/);
});

test('hoje lista quem cobrar com a mensagem pronta', async () => {
  const { amb, linhas } = await ambienteCli({ registros: [registroAbordadoHa(3)] });
  assert.equal(await executar(['hoje'], amb), 0);
  const texto = linhas.join('\n');
  assert.match(texto, /Cobrar hoje/); assert.match(texto, /Conseguiu ver a amostra/); assert.match(texto, /wa\.me\/5519998765432/);
  assert.match(texto, /Meta da semana: 1 de 10/);
});

test('enviei, cobrei, etapa e não contatar mudam o funil', async () => {
  const { amb } = await ambienteCli({ registros: [{ ...registroSemSite, etapa: 'preparado' }] });
  const { loja } = amb;
  assert.equal(await executar(['enviei', 'sem-site-1'], amb), 0);
  assert.equal((await loja.ler('negocios'))[0].etapa, 'abordado');
  assert.equal(await executar(['cobrei', 'sem-site-1'], amb), 0);
  assert.equal((await loja.ler('negocios'))[0].acompanhamentos, 1);
  assert.equal(await executar(['etapa', 'sem-site-1', 'respondeu'], amb), 0);
  assert.equal((await loja.ler('negocios'))[0].etapa, 'respondeu');
  assert.equal(await executar(['nao-contatar', 'sem-site-1'], amb), 0);
  assert.equal((await loja.ler('negocios'))[0].naoContatar, true);
  assert.equal(await executar(['etapa', 'sem-site-1', 'abordado'], amb), 1);
});

test('exportar grava o arquivo', async () => {
  const { amb, pasta } = await ambienteCli({ registros: [registroSemSite] });
  assert.equal(await executar(['exportar', join(pasta, 'meus-dados.json')], amb), 0);
  assert.ok(existsSync(join(pasta, 'meus-dados.json')));
});

test('erro vira uma linha em português, sem stack', async () => {
  const { amb, linhas } = await ambienteCli({ cotaEsgotada: true });
  assert.equal(await executar(['buscar', 'barbearias', 'Campinas'], amb), 1);
  assert.match(linhas.at(-1), /^Não deu certo: Limite mensal/); assert.ok(!linhas.join('\n').includes('    at '));
});

test('id que não existe dá erro claro', async () => {
  const { amb, linhas } = await ambienteCli();
  assert.equal(await executar(['enviei', 'nao-existe'], amb), 1); assert.match(linhas.at(-1), /Não achei esse negócio/);
});

test('comando desconhecido mostra ajuda', async () => {
  const { amb, linhas } = await ambienteCli();
  assert.equal(await executar(['voar'], amb), 1); assert.match(linhas.join('\n'), /buscar <nicho>/);
  assert.equal(await executar([], amb), 1);
});

test('preparar mostra o progresso, o link, a mensagem e o WhatsApp', async () => {
  const { abrirNavegador } = await import('../src/util/navegador.js');
  const { ambientePreparo } = await import('./falsos.js');
  const navegador = await abrirNavegador();
  try {
    const a = await ambientePreparo({ navegador });
    const linhas = [];
    const codigo = await executar(['preparar', 'sem-site-1'], { ...a, saida: (l) => linhas.push(String(l)) });
    const texto = linhas.join('\n');
    assert.equal(codigo, 0, texto);
    assert.match(texto, /^\.\.\. Buscando detalhes/m); assert.match(texto, /^Prévia: https:\/\/isaque\.github\.io\/previas\//m);
    assert.match(texto, /^Primeira mensagem:/m); assert.match(texto, /^WhatsApp: https:\/\/wa\.me\/5519998765432\?text=/m);
    assert.match(texto, /Depois de enviar: enviei sem-site-1/);
  } finally {
    await navegador.close();
  }
});
