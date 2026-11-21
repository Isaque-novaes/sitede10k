import { appendFile, mkdir } from 'node:fs/promises';
import { join } from 'node:path';

/** Erro de um serviço externo, com mensagem curta em português que nunca contém chave nem URL. */
export class ErroExterno extends Error {
  constructor(servico, mensagem, { status = 0, codigo, temporario = false, corpo } = {}) {
    super(mensagem);
    this.name = 'ErroExterno';
    this.servico = servico;
    this.status = status;
    this.codigo = codigo;
    this.temporario = temporario;
    this.corpo = corpo;
  }
}

const ESPERAS_PADRAO = [500, 1500];
const esperar = (ms) => new Promise((r) => setTimeout(r, ms));

function erroPorStatus(servico, status, corpo) {
  const codigo = corpo?.error?.code;
  // O Google responde chave inválida ou vencida com 400 (INVALID_ARGUMENT), não 401/403.
  const motivos = Array.isArray(corpo?.error?.details) ? corpo.error.details.map((d) => String(d?.reason ?? '')) : [];
  const chaveRuim = status === 400 && (motivos.some((m) => m.startsWith('API_KEY_')) || /API key/i.test(String(corpo?.error?.message ?? '')));
  if (status === 401 || status === 403 || chaveRuim) {
    return new ErroExterno(servico, `O ${servico} recusou a chave. Confira a chave do ${servico} nas configurações.`, { status, codigo, corpo });
  }
  if (status === 429) {
    return new ErroExterno(servico, `O ${servico} atingiu o limite de uso por enquanto. Tente de novo mais tarde.`, { status, codigo, temporario: true, corpo });
  }
  if (status >= 500) {
    return new ErroExterno(servico, `O ${servico} está fora do ar agora. Tente de novo em alguns minutos.`, { status, codigo, temporario: true, corpo });
  }
  return new ErroExterno(servico, `O ${servico} recusou o pedido (erro ${status}).`, { status, codigo, corpo });
}

async function lerCorpo(resposta) {
  const texto = await resposta.text().catch(() => '');
  try { return JSON.parse(texto); } catch { return texto || undefined; }
}

/**
 * Faz a requisição com tentativas (5xx e falha de rede), tempo limite e log.
 * @returns {Promise<Response>}
 */
async function requisitar(url, { servico, metodo = 'GET', cabecalhos = {}, corpo, fetch = globalThis.fetch, tentativas = 2, tempoLimiteMs = 20000, registrar, esperas = ESPERAS_PADRAO }) {
  const headers = { ...cabecalhos };
  let body = corpo;
  if (corpo !== undefined && !(corpo instanceof Uint8Array) && typeof corpo !== 'string') {
    body = JSON.stringify(corpo);
    headers['Content-Type'] = headers['Content-Type'] ?? 'application/json';
  }
  let ultimoErro;
  for (let tentativa = 0; tentativa <= tentativas; tentativa++) {
    if (tentativa > 0) await esperar(esperas[Math.min(tentativa - 1, esperas.length - 1)]);
    const inicio = Date.now();
    try {
      const resposta = await fetch(url, { method: metodo, headers, body, signal: AbortSignal.timeout(tempoLimiteMs) });
      registrar?.({ data: new Date().toISOString(), servico, metodo, status: resposta.status, ms: Date.now() - inicio });
      if (resposta.ok) return resposta;
      const erro = erroPorStatus(servico, resposta.status, await lerCorpo(resposta));
      if (resposta.status >= 500) { ultimoErro = erro; continue; }
      throw erro;
    } catch (erro) {
      if (erro instanceof ErroExterno) throw erro;
      registrar?.({ data: new Date().toISOString(), servico, metodo, status: 0, ms: Date.now() - inicio, erro: erro.name });
      ultimoErro = new ErroExterno(servico, `Não consegui falar com o ${servico}. Confira a internet.`, { temporario: true });
    }
  }
  throw ultimoErro;
}

/** GET/POST que devolve JSON. */
export async function requisitarJson(url, opcoes) {
  const resposta = await requisitar(url, opcoes);
  const corpo = await lerCorpo(resposta);
  return corpo;
}

/** GET que devolve os bytes. */
export async function requisitarBinario(url, opcoes) {
  const resposta = await requisitar(url, opcoes);
  return Buffer.from(await resposta.arrayBuffer());
}

/** Log local: uma linha JSON por evento em {pasta}/log.txt. */
export function criarRegistroLocal(pasta) {
  return async (evento) => {
    await mkdir(pasta, { recursive: true });
    await appendFile(join(pasta, 'log.txt'), `${JSON.stringify(evento)}\n`, 'utf8');
  };
}
