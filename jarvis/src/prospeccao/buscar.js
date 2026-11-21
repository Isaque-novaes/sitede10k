import { garantirCota, registrarUso } from '../dados/uso.js';
import { lugarParaRegistro, classificarPresenca, calcularPrioridade } from './classificar.js';

const PARALELO_SITES = 3;
const DESCRICAO_PRESENCA = { sem_site: 'sem site', so_rede_social: 'só com rede social', site_fraco: 'com um site fraco', site_ok: 'com site' };
const numero = (n, casas = 0) => Number(n).toLocaleString('pt-BR', { minimumFractionDigits: casas, maximumFractionDigits: casas });

async function emLotes(itens, limite, fn) {
  let proximo = 0;
  const trabalhador = async () => {
    while (proximo < itens.length) {
      const i = proximo++;
      await fn(itens[i]);
    }
  };
  await Promise.all(Array.from({ length: Math.min(limite, itens.length) }, trabalhador));
}

function montarResumo(novos, nicho, cidade) {
  if (!novos.length) return `Não encontrei negócios novos de ${nicho} em ${cidade}. Tente outra cidade ou outro nicho.`;
  const semSite = novos.filter((n) => n.presenca === 'sem_site' || n.presenca === 'so_rede_social').length;
  const melhor = novos[0];
  const nota = melhor.nota != null
    ? `, nota ${numero(melhor.nota, 1)}${melhor.totalAvaliacoes ? ` com ${numero(melhor.totalAvaliacoes)} avaliações` : ''}`
    : '';
  const frases = [`Encontrei ${novos.length} ${nicho}.`];
  frases.push(semSite === 1 ? '1 não tem site.' : `${semSite} não têm site.`);
  frases.push(`A melhor oportunidade é ${melhor.nome}${nota} e ${DESCRICAO_PRESENCA[melhor.presenca]}.`);
  return frases.join(' ');
}

/**
 * Busca negócios no Google Maps, classifica, testa sites, ordena e salva os novos.
 * @param {{nicho:string, cidade:string}} busca
 * @param {{loja:any, servicos:any, agora?:Date}} deps
 */
export async function buscarNegocios({ nicho, cidade }, { loja, servicos, agora = new Date() }) {
  if (!servicos.places) throw new Error('Configure a chave do Google para buscar negócios.');
  await garantirCota(loja, 'places_busca', 1, agora);
  const lugares = await servicos.places.buscar(`${nicho} em ${cidade}`);
  await registrarUso(loja, 'places_busca', 1, agora);

  const conhecidos = new Map((await loja.ler('negocios', [])).map((n) => [n.id, n]));
  const ignorados = { fechados: 0, jaConhecidos: 0, naoContatar: 0 };
  const avisos = [];
  const novos = [];
  for (const lugar of lugares) {
    if (lugar.situacao !== 'OPERATIONAL') { ignorados.fechados++; continue; }
    const conhecido = conhecidos.get(lugar.id);
    if (conhecido?.naoContatar) { ignorados.naoContatar++; continue; }
    if (conhecido) { ignorados.jaConhecidos++; continue; }
    novos.push(lugarParaRegistro(lugar, { nicho }, agora));
  }

  const comSiteProprio = novos.filter((n) => n.presenca === 'site_ok');
  if (comSiteProprio.length && servicos.pagespeed) {
    await emLotes(comSiteProprio, PARALELO_SITES, async (n) => {
      try {
        n.desempenhoSite = await servicos.pagespeed.testar(n.site);
        n.presenca = classificarPresenca(n.site, n.desempenhoSite);
        n.prioridade = calcularPrioridade(n);
      } catch (erro) {
        avisos.push(`Não consegui testar o site de ${n.nome}: ${erro.message}`);
      }
    });
  }

  novos.sort((a, b) => b.prioridade - a.prioridade);
  if (novos.length) await loja.atualizar('negocios', (atual) => [...atual, ...novos], []);
  await loja.atualizar('buscas', (atual) => [...atual, { nicho, cidade, data: agora.toISOString(), total: lugares.length }], []);
  return { novos, ignorados, avisos, resumo: montarResumo(novos, nicho, cidade) };
}
