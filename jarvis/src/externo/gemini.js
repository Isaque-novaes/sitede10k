import sharp from 'sharp';
import { requisitarJson, ErroExterno } from './http.js';

const SERVICO = 'Gemini';
const URL_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';

/** O limite grátis do Gemini acabou por enquanto (nos dois modelos). */
export class ErroLimiteIA extends Error {
  constructor() {
    super('A IA grátis atingiu o limite de uso por enquanto. Usei a alternativa sem IA.');
    this.name = 'ErroLimiteIA';
  }
}

/**
 * Confere um valor contra um esquema no formato responseSchema do Gemini (subconjunto).
 * @returns {boolean}
 */
export function validarEsquema(valor, esquema) {
  switch (esquema?.type) {
    case 'OBJECT': {
      if (valor === null || typeof valor !== 'object' || Array.isArray(valor)) return false;
      for (const campo of esquema.required ?? []) if (valor[campo] === undefined) return false;
      for (const [campo, sub] of Object.entries(esquema.properties ?? {})) {
        if (valor[campo] !== undefined && !validarEsquema(valor[campo], sub)) return false;
      }
      return true;
    }
    case 'ARRAY':
      if (!Array.isArray(valor)) return false;
      if (esquema.maxItems !== undefined && valor.length > Number(esquema.maxItems)) return false;
      if (esquema.minItems !== undefined && valor.length < Number(esquema.minItems)) return false;
      return valor.every((v) => validarEsquema(v, esquema.items ?? {}));
    case 'STRING':
      return typeof valor === 'string' && (!esquema.enum || esquema.enum.includes(valor));
    case 'NUMBER':
      return typeof valor === 'number' && Number.isFinite(valor);
    case 'INTEGER':
      return Number.isInteger(valor);
    case 'BOOLEAN':
      return typeof valor === 'boolean';
    default:
      return true;
  }
}

/** Reduz a imagem antes de mandar para a IA, para gastar menos limite. */
export async function prepararImagem(caminho, larguraMax = 512) {
  const bytes = await sharp(caminho).rotate().resize({ width: larguraMax, withoutEnlargement: true }).jpeg({ quality: 75 }).toBuffer();
  return { mime: 'image/jpeg', base64: bytes.toString('base64') };
}

async function chamarModelo(modelo, corpo, { chave, fetch, registrar }) {
  return requisitarJson(`${URL_BASE}/${modelo}:generateContent`, {
    servico: SERVICO, metodo: 'POST', corpo, fetch, registrar, tempoLimiteMs: 60000,
    cabecalhos: { 'x-goog-api-key': chave },
  });
}

async function chamarComReserva(corpo, { chave, fetch, registrar, modelo, reserva }) {
  try {
    return await chamarModelo(modelo, corpo, { chave, fetch, registrar });
  } catch (erro) {
    if (!(erro instanceof ErroExterno) || ![429, 404].includes(erro.status) || !reserva) {
      if (erro instanceof ErroExterno && erro.status === 429) throw new ErroLimiteIA();
      throw erro;
    }
    try {
      return await chamarModelo(reserva, corpo, { chave, fetch, registrar });
    } catch (erroReserva) {
      if (erroReserva instanceof ErroExterno && erroReserva.status === 429) throw new ErroLimiteIA();
      throw erroReserva;
    }
  }
}

/**
 * Pede uma resposta em JSON ao Gemini e confere o formato.
 * @param {{prompt:string, esquema:object, imagens?:{mime:string, base64:string}[], temperatura?:number}} pedido
 * @param {{chave:string, fetch?:typeof fetch, registrar?:Function, modelo:string, reserva?:string}} opcoes
 */
export async function gerarJson({ prompt, esquema, imagens = [], temperatura = 0.8 }, opcoes) {
  const corpo = {
    contents: [{ role: 'user', parts: [{ text: prompt }, ...imagens.map((i) => ({ inline_data: { mime_type: i.mime, data: i.base64 } }))] }],
    generationConfig: { responseMimeType: 'application/json', responseSchema: esquema, temperature: temperatura },
  };
  for (let tentativa = 0; tentativa < 2; tentativa++) {
    const resposta = await chamarComReserva(corpo, opcoes);
    const texto = resposta?.candidates?.[0]?.content?.parts?.map((p) => p.text ?? '').join('') ?? '';
    try {
      const valor = JSON.parse(texto);
      if (validarEsquema(valor, esquema)) return valor;
    } catch {
      // tenta de novo
    }
  }
  throw new ErroExterno(SERVICO, 'A IA respondeu num formato inesperado. Usei a alternativa sem IA.');
}
