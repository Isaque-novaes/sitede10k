// Linha de comando do motor de prospecção: `npm run jarvis -- <comando>`.
import { resolve } from 'node:path';
import { realpathSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import { carregarConfig } from './config.js';
import { criarLoja } from './dados/loja.js';
import { criarServicos } from './externo/servicos.js';
import { criarRegistroLocal } from './externo/http.js';
import { buscarNegocios } from './prospeccao/buscar.js';
import { prepararNegocio, sugerirInstagram, confirmarInstagram } from './prospeccao/preparar.js';
import { limparPreviasVencidas, exportarDados, copiaSemanal } from './prospeccao/manutencao.js';
import { mudarEtapa, registrarAcompanhamento, marcarNaoContatar, cobrarHoje, diasEntre } from './funil/funil.js';
import { linkAbordagem } from './vendas/mensagens.js';

const AJUDA = [
  'Comandos do Jarvis:',
  '  buscar <nicho> [cidade]            procura negócios no Google Maps',
  '  instagram <id> [@usuario|nenhum]   sugere ou confirma o Instagram do negócio',
  '  preparar <id>                      monta o diagnóstico, a prévia e as mensagens',
  '  enviei <id>                        anota que você mandou a primeira mensagem',
  '  cobrei <id>                        anota que você mandou o acompanhamento',
  '  etapa <id> <etapa>                 muda a etapa: respondeu, reuniao, proposta, fechou, perdido ou descartado',
  '  nao-contatar <id>                  o negócio pediu para não receber mais mensagens',
  '  hoje                               quem cobrar hoje e como está a meta da semana',
  '  limpar                             tira do ar as prévias vencidas',
  '  exportar <arquivo>                 salva todos os seus dados num arquivo',
  'Exemplo: npm run jarvis -- buscar barbearias Campinas',
];

const PRESENCA = { sem_site: 'sem site', so_rede_social: 'só rede social', site_fraco: 'site fraco', site_ok: 'tem site' };
const numero = (n, casas = 0) => Number(n).toLocaleString('pt-BR', { minimumFractionDigits: casas, maximumFractionDigits: casas });
const reais = (n) => `R$ ${numero(n)}`;

function exigir(valor, mensagem) {
  if (!valor) throw new Error(mensagem);
  return valor;
}

const exigirId = (id) => exigir(id, 'Diga o id do negócio. Ele aparece na lista da busca.');

async function lerNegocio(loja, id) {
  const registro = (await loja.ler('negocios', [])).find((r) => r.id === id);
  if (!registro) throw new Error('Não achei esse negócio. Faça uma busca antes.');
  return registro;
}

/** Aplica `mudar` ao negócio dentro da fila da loja e devolve o registro novo. */
async function alterarNegocio(loja, id, mudar) {
  let novo;
  await loja.atualizar('negocios', (atual) => {
    const registro = atual.find((r) => r.id === id);
    if (!registro) throw new Error('Não achei esse negócio. Faça uma busca antes.');
    novo = mudar(registro);
    return atual.map((r) => (r.id === id ? novo : r));
  }, []);
  return novo;
}

function linhaDoNegocio(r, i) {
  const partes = [PRESENCA[r.presenca] ?? r.presenca];
  if (r.nota != null) partes.push(`nota ${numero(r.nota, 1)}${r.totalAvaliacoes ? ` com ${numero(r.totalAvaliacoes)} avaliações` : ''}`);
  return `${i + 1}. ${r.nome} (${partes.join(', ')}) id: ${r.id}`;
}

function comoContatar(registro, texto, saida) {
  const link = linkAbordagem(registro, texto);
  if (link) saida(`WhatsApp: ${link}`);
  else saida(registro.telefone ? `Sem WhatsApp provável. Ligue para ${registro.telefone}.` : 'Sem telefone no Google. Procure o contato no Instagram deles.');
}

const COMANDOS = {
  async buscar([nicho, ...resto], { config, loja, servicos, saida }) {
    exigir(nicho, 'Diga o nicho. Exemplo: buscar barbearias Campinas');
    const cidade = exigir(resto.join(' ').trim() || config.cidadePadrao, 'Diga a cidade ou configure a cidade padrão.');
    const r = await buscarNegocios({ nicho, cidade }, { loja, servicos });
    saida(r.resumo);
    r.novos.forEach((n, i) => saida(linhaDoNegocio(n, i)));
    const fora = [];
    if (r.ignorados.jaConhecidos) fora.push(`${r.ignorados.jaConhecidos} que você já conhecia`);
    if (r.ignorados.fechados) fora.push(`${r.ignorados.fechados} fechado(s)`);
    if (r.ignorados.naoContatar) fora.push(`${r.ignorados.naoContatar} que pediu para não ser contatado`);
    if (fora.length) saida(`Deixei de fora: ${fora.join(', ')}.`);
    r.avisos.forEach((a) => saida(`Atenção: ${a}`));
    if (r.novos.length) saida(`Próximo passo: preparar ${r.novos[0].id}`);
    return 0;
  },

  async instagram([id, usuario], { loja, servicos, saida }) {
    exigirId(id);
    if (usuario) {
      const nenhum = usuario.toLowerCase() === 'nenhum';
      const r = await confirmarInstagram(id, nenhum ? null : usuario, { loja });
      saida(nenhum ? `Anotado: ${r.nome} não tem Instagram.` : `Anotado: @${r.instagram.usuario} é o Instagram de ${r.nome}.`);
      return 0;
    }
    const registro = await lerNegocio(loja, id);
    if (!servicos.instagram) {
      saida('Configure a chave da Meta para eu procurar o Instagram.');
      saida(`Se você já sabe o @, use: instagram ${id} @usuario`);
      return 0;
    }
    const achados = await sugerirInstagram(id, { loja, servicos });
    if (!achados.length) {
      saida(`Não achei o Instagram de ${registro.nome}. Se souber, use: instagram ${id} @usuario`);
      return 0;
    }
    saida(`Possíveis Instagrams de ${registro.nome}:`);
    achados.forEach((a, i) => saida(`${i + 1}. @${a.usuario} (confiança ${Math.round(a.confianca * 100)}%)`));
    saida(`Para confirmar: instagram ${id} @${achados[0].usuario}  (ou "nenhum" se não for nenhum deles)`);
    return 0;
  },

  async preparar([id], { config, loja, servicos, saida, navegador, bloquearRede }) {
    exigirId(id);
    const { registro, url, avisos } = await prepararNegocio(id, { loja, servicos, config, navegador, bloquearRede, aoProgredir: (t) => saida(`... ${t}`) });
    avisos.forEach((a) => saida(`Atenção: ${a}`));
    if (!registro.abordagem) {
      saida('A prévia não ficou boa o bastante para mandar. Problemas encontrados:');
      (registro.previa?.problemas ?? []).forEach((p) => saida(`- ${p}`));
      saida(`Tente de novo: preparar ${id}`);
      return 1;
    }
    saida(url ? `Prévia: ${url}` : `A prévia ficou salva no computador, mas não foi publicada. Troque "[link da prévia]" pelo link antes de enviar.`);
    if (registro.preco?.profissional) {
      const [min, max] = registro.preco.profissional;
      saida(`Preço sugerido (site profissional): ${reais(min)} a ${reais(max)}`);
    }
    saida('Primeira mensagem:');
    saida(registro.abordagem.primeira);
    comoContatar(registro, registro.abordagem.primeira, saida);
    saida(`Depois de enviar: enviei ${id}`);
    return 0;
  },

  async enviei([id], { config, loja, saida }) {
    const r = await alterarNegocio(loja, exigirId(id), (reg) => mudarEtapa(reg, 'abordado'));
    saida(`Anotado: mensagem enviada para ${r.nome}. Eu te lembro de cobrar em ${config.diasAcompanhamento?.[0] ?? 3} dias.`);
    return 0;
  },

  async cobrei([id], { loja, saida }) {
    const r = await alterarNegocio(loja, exigirId(id), (reg) => registrarAcompanhamento(reg));
    saida(`Anotado: acompanhamento ${r.acompanhamentos} de 2 para ${r.nome}.`);
    return 0;
  },

  async etapa([id, etapa], { loja, saida }) {
    exigirId(id);
    exigir(etapa, 'Diga a etapa: respondeu, reuniao, proposta, fechou, perdido ou descartado.');
    const r = await alterarNegocio(loja, id, (reg) => mudarEtapa(reg, etapa));
    saida(`Anotado: ${r.nome} agora está na etapa "${etapa}".`);
    if (etapa === 'perdido' || etapa === 'descartado') saida('A prévia sai do ar no próximo "limpar".');
    return 0;
  },

  async 'nao-contatar'([id], { loja, saida }) {
    const r = await alterarNegocio(loja, exigirId(id), (reg) => marcarNaoContatar(reg));
    saida(`Anotado: ${r.nome} não vai receber mais mensagens. A prévia sai do ar no próximo "limpar".`);
    return 0;
  },

  async hoje(_args, { config, loja, saida }) {
    const agora = new Date();
    const registros = await loja.ler('negocios', []);
    const { cobrar, sugerirPerdido } = cobrarHoje(registros, agora, config.diasAcompanhamento ?? [3, 7]);
    if (cobrar.length) {
      saida(`Cobrar hoje (${cobrar.length}):`);
      for (const { registro, qual } of cobrar) {
        const texto = registro.abordagem?.[`acompanhamento${qual}`] ?? '';
        saida(`- ${registro.nome} (mensagem ${qual} de 2) id: ${registro.id}`);
        if (texto) saida(texto);
        comoContatar(registro, texto, saida);
        saida(`  Depois de enviar: cobrei ${registro.id}`);
      }
    } else {
      saida('Ninguém para cobrar hoje.');
    }
    if (sugerirPerdido.length) {
      saida(`Já receberam 2 acompanhamentos sem resposta (${sugerirPerdido.length}):`);
      sugerirPerdido.forEach((r) => saida(`- ${r.nome}: etapa ${r.id} perdido`));
    }
    const prontos = registros.filter((r) => r.etapa === 'preparado' && !r.naoContatar);
    if (prontos.length) {
      saida(`Prontos para enviar (${prontos.length}):`);
      prontos.forEach((r) => saida(`- ${r.nome} id: ${r.id}`));
    }
    const naSemana = registros.filter((r) => r.datas?.abordado && diasEntre(r.datas.abordado, agora) < 7).length;
    saida(`Meta da semana: ${naSemana} de ${config.metaSemanal ?? 10} abordagens.`);
    return 0;
  },

  async limpar(_args, { loja, servicos, saida }) {
    const { removidas, avisos } = await limparPreviasVencidas({ loja, servicos });
    saida(removidas.length ? `Tirei do ar ${removidas.length} prévia(s).` : 'Nenhuma prévia para tirar do ar agora.');
    avisos.forEach((a) => saida(`Atenção: ${a}`));
    return 0;
  },

  async exportar([arquivo], { loja, saida }) {
    exigir(arquivo, 'Diga o nome do arquivo. Exemplo: exportar meus-dados.json');
    const destino = await exportarDados({ loja, destino: resolve(arquivo) });
    saida(`Salvei seus dados em ${destino}`);
    return 0;
  },
};

/**
 * Roda um comando. Nunca lança: erros viram uma linha em português e código 1.
 * @param {string[]} argv
 * @param {{config:any, loja:any, servicos:any, saida?:(linha:string)=>void, navegador?:any, bloquearRede?:boolean}} ambiente
 * @returns {Promise<number>} código de saída
 */
export async function executar(argv, { config, loja, servicos, saida = console.log, navegador, bloquearRede }) {
  const [comando, ...args] = argv;
  if (['ajuda', 'help', '--help', '-h'].includes(comando)) {
    AJUDA.forEach((l) => saida(l));
    return 0;
  }
  const acao = Object.hasOwn(COMANDOS, comando ?? '') ? COMANDOS[comando] : null;
  if (!acao) {
    if (comando) saida(`Não conheço o comando "${comando}".`);
    AJUDA.forEach((l) => saida(l));
    return 1;
  }
  try {
    return await acao(args, { config, loja, servicos, saida, navegador, bloquearRede });
  } catch (erro) {
    saida(`Não deu certo: ${erro?.message ?? String(erro)}`);
    return 1;
  }
}

async function principal() {
  let config;
  try {
    config = await carregarConfig();
  } catch (erro) {
    console.log(`Não deu certo: ${erro.message}`);
    return 1;
  }
  const loja = criarLoja(config.pastaDados);
  const servicos = criarServicos(config, { registrar: criarRegistroLocal(config.pastaDados) });
  try {
    await copiaSemanal({ loja, pasta: config.pastaDados });
  } catch {
    // a cópia semanal é um extra: não impede o comando
  }
  return executar(process.argv.slice(2), { config, loja, servicos });
}

const rodandoDireto = (() => {
  try {
    return import.meta.url === pathToFileURL(realpathSync(process.argv[1] ?? '')).href;
  } catch {
    return false;
  }
})();

if (rodandoDireto) process.exitCode = await principal();
