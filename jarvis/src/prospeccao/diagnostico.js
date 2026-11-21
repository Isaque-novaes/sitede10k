import { garantirCota, registrarUso } from '../dados/uso.js';
import { classificarPresenca } from './classificar.js';

const numero = (n, casas = 0) => Number(n).toLocaleString('pt-BR', { minimumFractionDigits: casas, maximumFractionDigits: casas });
const TRINTA_DIAS = 30 * 24 * 60 * 60 * 1000;

async function buscarConcorrentes(registro, { loja, servicos, agora }) {
  const vazio = { total: 0, comSite: 0 };
  if (!servicos?.places || !registro.local) return vazio;
  await garantirCota(loja, 'places_busca', 1, agora);
  const lugares = await servicos.places.buscar(registro.tipoPrincipal ?? registro.nicho, { local: registro.local, quantidade: 10 });
  await registrarUso(loja, 'places_busca', 1, agora);
  const outros = lugares.filter((l) => l.id !== registro.id);
  const comSite = outros.filter((l) => classificarPresenca(l.site) === 'site_ok');
  const melhor = [...comSite].sort((a, b) => (b.nota ?? 0) - (a.nota ?? 0))[0];
  return { total: outros.length, comSite: comSite.length, ...(melhor ? { melhorComSite: melhor.nome } : {}) };
}

function escolherAchado(registro, temSite, concorrentes) {
  const site = registro.desempenhoSite;
  if (!temSite && concorrentes.melhorComSite) return `${concorrentes.melhorComSite}, aqui perto, já tem site e aparece melhor no Google.`;
  if (!temSite && registro.presenca === 'so_rede_social') return 'Vocês não têm site, e quem procura no Google acaba só no Instagram.';
  if (!temSite) return 'Vocês ainda não têm site, e quem procura no Google não encontra muito sobre vocês.';
  if (site && site.desempenho < 50) return `O site de vocês leva ${numero(site.lcpMs / 1000, 1)} segundos para abrir no celular.`;
  if (site && !site.https) return 'O site de vocês aparece como não seguro no navegador.';
  if (registro.nota != null) return `Vocês têm nota ${numero(registro.nota, 1)} no Google, e um site pode mostrar isso para quem ainda não conhece.`;
  return 'Um site próprio pode mostrar o trabalho de vocês para quem ainda não conhece.';
}

/**
 * Diagnóstico online do negócio em linguagem de dono de negócio.
 * @param {import('./tipos.js').Registro} registro
 * @param {{loja:any, servicos:any, perfil?:any, agora?:Date}} deps
 * @returns {Promise<import('./tipos.js').Diagnostico>}
 */
export async function diagnosticar(registro, { loja, servicos, perfil, agora = new Date() }) {
  const temSite = registro.presenca === 'site_fraco' || registro.presenca === 'site_ok';
  const concorrentes = await buscarConcorrentes(registro, { loja, servicos, agora });
  const achadoPrincipal = escolherAchado(registro, temSite, concorrentes);
  const frases = [achadoPrincipal];
  if (registro.nota != null && registro.totalAvaliacoes) {
    frases.push(`Com nota ${numero(registro.nota, 1)} e ${numero(registro.totalAvaliacoes)} avaliações, vocês já têm o que mostrar.`);
  }
  if (concorrentes.total) {
    frases.push(`Por perto, ${concorrentes.comSite} de ${concorrentes.total} concorrentes já têm site.`);
  }
  const diagnostico = {
    data: agora.toISOString(),
    temSite,
    concorrentes,
    resumo: frases.slice(0, 3).join(' '),
    achadoPrincipal,
  };
  if (registro.desempenhoSite) { diagnostico.desempenho = registro.desempenhoSite; diagnostico.https = registro.desempenhoSite.https; }
  if (registro.nota != null) diagnostico.nota = registro.nota;
  if (registro.totalAvaliacoes != null) diagnostico.totalAvaliacoes = registro.totalAvaliacoes;
  if (perfil) {
    diagnostico.instagram = {
      seguidores: perfil.seguidores ?? 0,
      postsUltimos30Dias: (perfil.midias ?? []).filter((m) => m.data && agora - new Date(m.data) <= TRINTA_DIAS).length,
    };
  }
  return diagnostico;
}
