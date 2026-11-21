import { mkdir, readdir, rm, writeFile, rename } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { dataEmSaoPaulo, diasEntre } from '../funil/funil.js';

const DIAS_PARA_EXPIRAR = 45;
const COPIAS_GUARDADAS = 8;

/** Prévias publicadas que devem sair do ar. */
export function previasParaRemover(registros, agora = new Date()) {
  return registros.filter((r) => {
    if (!r.previa?.url) return false;
    if (r.naoContatar || r.etapa === 'perdido' || r.etapa === 'descartado') return true;
    if ((r.etapa === 'preparado' || r.etapa === 'abordado') && r.previa.publicadaEm) {
      return diasEntre(r.previa.publicadaEm, agora) >= DIAS_PARA_EXPIRAR;
    }
    return false;
  });
}

/** Remove do GitHub as prévias vencidas e limpa o endereço delas no registro. */
export async function limparPreviasVencidas({ loja, servicos, agora = new Date() }) {
  const registros = await loja.ler('negocios', []);
  const alvos = previasParaRemover(registros, agora);
  if (!alvos.length) return { removidas: [], avisos: [] };
  if (!servicos?.github) return { removidas: [], avisos: [`Configure o GitHub para tirar do ar ${alvos.length} prévia(s) vencida(s).`] };
  const removidas = [];
  const avisos = [];
  for (const alvo of alvos) {
    try {
      await servicos.github.remover(alvo.previa.slug, `Remove a prévia ${alvo.previa.slug}`);
      removidas.push(alvo.previa.slug);
    } catch (erro) {
      avisos.push(`Não consegui tirar do ar a prévia de ${alvo.nome}: ${erro.message}`);
    }
  }
  const data = agora.toISOString();
  await loja.atualizar('negocios', (atual) => atual.map((r) => {
    if (!removidas.includes(r.previa?.slug)) return r;
    const { url: _url, publicadaEm: _publicadaEm, ...previa } = r.previa;
    return { ...r, previa, historico: [...(r.historico ?? []), { tipo: 'previa_removida', data, detalhe: r.previa.slug }] };
  }), []);
  return { removidas, avisos };
}

async function gravarJson(destino, valor) {
  await mkdir(dirname(destino), { recursive: true });
  const temporario = `${destino}.${process.pid}.tmp`;
  await writeFile(temporario, JSON.stringify(valor, null, 2), 'utf8');
  await rename(temporario, destino);
  return destino;
}

/** Um arquivo único com todos os dados, para o usuário guardar. */
export async function exportarDados({ loja, destino, agora = new Date() }) {
  return gravarJson(destino, { exportadoEm: agora.toISOString(), negocios: await loja.ler('negocios', []), buscas: await loja.ler('buscas', []) });
}

/** Semana ISO ("AAAA-SS") da data em São Paulo. */
function semanaIso(agora) {
  const [a, m, d] = dataEmSaoPaulo(agora).split('-').map(Number);
  const data = new Date(Date.UTC(a, m - 1, d));
  const diaSemana = data.getUTCDay() || 7;
  data.setUTCDate(data.getUTCDate() + 4 - diaSemana);
  const inicioAno = new Date(Date.UTC(data.getUTCFullYear(), 0, 1));
  const semana = Math.ceil(((data - inicioAno) / 86400000 + 1) / 7);
  return `${data.getUTCFullYear()}-${String(semana).padStart(2, '0')}`;
}

/** Cópia automática semanal em {pasta}/copias, guardando as 8 mais recentes. */
export async function copiaSemanal({ loja, pasta, agora = new Date() }) {
  const destino = join(pasta, 'copias', `${semanaIso(agora)}.json`);
  if (existsSync(destino)) return null;
  await exportarDados({ loja, destino, agora });
  const copias = (await readdir(join(pasta, 'copias'))).filter((f) => /^\d{4}-\d{2}\.json$/.test(f)).sort();
  for (const antiga of copias.slice(0, Math.max(0, copias.length - COPIAS_GUARDADAS))) await rm(join(pasta, 'copias', antiga), { force: true });
  return destino;
}
