import { join } from 'node:path';
import { rm } from 'node:fs/promises';
import sharp from 'sharp';
import { garantirCota, registrarUso, podeUsar, ErroCota } from '../dados/uso.js';
import { encontrarInstagram } from '../externo/instagram.js';
import { diagnosticar } from './diagnostico.js';
import { extrairClima } from '../ia/clima.js';
import { escolherMaterial } from '../ia/material.js';
import { sugerirAssinatura } from '../ia/arte.js';
import { escreverTextosPrevia } from '../ia/textos.js';
import { escreverAbordagem } from '../ia/abordagem.js';
import { sugerirPreco } from '../vendas/precos.js';
import { mudarEtapa } from '../funil/funil.js';
import { gerarPrevia } from '../previa/gerar.js';

const LINK_PENDENTE = '[link da prévia]';

/** O Negocio que o gerador de prévias (plano 1) espera, a partir do registro guardado. */
export function registroParaNegocio(registro, midias, clima) {
  const { instagram } = registro;
  return {
    id: registro.id,
    nome: registro.nome,
    nicho: registro.nicho,
    bairro: registro.bairro,
    cidade: registro.cidade,
    endereco: registro.endereco,
    telefone: registro.telefone,
    mapsUrl: registro.mapsUrl,
    horarios: registro.horarios,
    nota: registro.nota,
    totalAvaliacoes: registro.totalAvaliacoes,
    avaliacoes: registro.avaliacoes ?? [],
    ...(instagram?.usuario ? { instagram: { usuario: instagram.usuario, bio: instagram.bio, seguidores: instagram.seguidores } } : {}),
    midias,
    clima,
  };
}

const usadasDaLoja = (registros) => registros
  .filter((r) => r.previa?.assinatura)
  .map((r) => ({ assinatura: r.previa.assinatura, nicho: r.nicho, cidade: r.cidade }));

async function medidasDasFotos(midias) {
  const medidas = [];
  for (const m of midias.filter((x) => x.tipo === 'foto')) {
    try {
      const meta = await sharp(m.arquivo).metadata();
      const girada = (meta.orientation ?? 1) >= 5;
      medidas.push({ largura: girada ? meta.height : meta.width, altura: girada ? meta.width : meta.height });
    } catch {
      // foto ilegível não conta
    }
  }
  return medidas;
}

async function lerRegistro(loja, id) {
  const registro = (await loja.ler('negocios', [])).find((r) => r.id === id);
  if (!registro) throw new Error('Não achei esse negócio. Faça uma busca antes.');
  return registro;
}

async function gravarRegistro(loja, registro) {
  await loja.atualizar('negocios', (atual) => atual.map((r) => (r.id === registro.id ? registro : r)), []);
}

/** Possíveis @ do Instagram do negócio, do mais provável ao menos. */
export async function sugerirInstagram(id, { loja, servicos }) {
  const registro = await lerRegistro(loja, id);
  if (!servicos.instagram) return [];
  const achados = await encontrarInstagram(registro, { descobrir: (u) => servicos.instagram.descobrir(u) });
  return achados.map(({ usuario, confianca }) => ({ usuario, confianca }));
}

/** Confirma o @ do Instagram do negócio. `null` quer dizer que o negócio não tem Instagram. */
export async function confirmarInstagram(id, usuario, { loja }) {
  const registro = await lerRegistro(loja, id);
  const limpo = usuario ? String(usuario).trim().replace(/^@/, '').toLowerCase() : '';
  const atualizado = { ...registro, instagram: { usuario: limpo, confirmado: true } };
  await gravarRegistro(loja, atualizado);
  return atualizado;
}

/**
 * Prepara um negócio de ponta a ponta: detalhes, Instagram, material, diagnóstico, textos, design,
 * prévia conferida e publicada, mensagens e preço. Cada passo grava o registro ao terminar.
 * @returns {Promise<{registro:any, url?:string, avisos:string[]}>}
 */
export async function prepararNegocio(id, { loja, servicos, config, agora = new Date(), navegador, bloquearRede, aoProgredir }) {
  let registro = await lerRegistro(loja, id);
  const avisos = [];
  const avisar = (texto) => { if (texto) avisos.push(texto); };
  const progresso = (texto) => aoProgredir?.(texto);
  const salvar = async (mudancas) => { registro = { ...registro, ...mudancas }; await gravarRegistro(loja, registro); };
  const pastaMidias = join(config.pastaDados, 'midias', id);
  const gemini = servicos.gemini ?? null;

  // 1. Detalhes e fotos do Google
  progresso('Buscando detalhes e fotos no Google Maps');
  const fotosGoogle = [];
  if (!servicos.places) {
    avisar('Sem a chave do Google, a prévia usa só o Instagram.');
  } else {
    try {
      await garantirCota(loja, 'places_detalhes', 1, agora);
      const detalhes = await servicos.places.detalhar(id);
      await registrarUso(loja, 'places_detalhes', 1, agora);
      await salvar({ horarios: detalhes.horarios, avaliacoes: detalhes.avaliacoes, fotosGoogle: detalhes.fotos });
      if (await podeUsar(loja, 'places_foto', detalhes.fotos.length, agora)) {
        for (const [i, foto] of detalhes.fotos.entries()) {
          try {
            const arquivo = await servicos.places.baixarFoto(foto.nome, join(pastaMidias, 'google', `g-${String(i + 1).padStart(2, '0')}.jpg`));
            fotosGoogle.push({ arquivo, tipo: 'foto', origem: 'google', credito: foto.credito });
          } catch (erro) {
            avisar(`Não consegui baixar uma foto do Google: ${erro.message}`);
          }
        }
        if (fotosGoogle.length) await registrarUso(loja, 'places_foto', fotosGoogle.length, agora);
      } else {
        avisar('Limite mensal de fotos do Google atingido. Usei só as outras fotos.');
      }
    } catch (erro) {
      avisar(erro instanceof ErroCota ? erro.message : `Não consegui os detalhes do Google: ${erro.message}`);
    }
  }

  // 2. Instagram (só com @ confirmado)
  progresso('Lendo o Instagram do negócio');
  let perfil = null;
  let midiasInstagram = [];
  if (registro.instagram?.confirmado && registro.instagram.usuario) {
    if (!servicos.instagram) {
      avisar('Configure a chave da Meta para usar o Instagram do negócio.');
    } else {
      try {
        perfil = await servicos.instagram.descobrir(registro.instagram.usuario);
        if (!perfil) {
          avisar('O Instagram deles é pessoal, vou usar as fotos do Google.');
        } else {
          midiasInstagram = await servicos.instagram.baixarMidias(perfil, join(pastaMidias, 'instagram'), { aoAvisar: avisar });
          await salvar({ instagram: { ...registro.instagram, bio: perfil.bio, seguidores: perfil.seguidores } });
        }
      } catch (erro) {
        avisar(erro.message);
      }
    }
  }

  // 3. Material
  progresso('Escolhendo as melhores fotos');
  const escolha = await escolherMaterial([...midiasInstagram, ...fotosGoogle], { gemini });
  avisar(escolha.aviso);
  let midias = escolha.midias;
  if (servicos.pexels) {
    try {
      const completado = await servicos.pexels.completar(midias, registro.nicho, join(pastaMidias, 'pexels'));
      midias = completado.midias;
      avisar(completado.aviso);
    } catch (erro) {
      avisar(`Não consegui fotos do Pexels: ${erro.message}`);
    }
  } else if (midias.filter((m) => m.tipo === 'foto').length < 4) {
    avisar('Esta prévia tem poucas fotos reais do negócio. Configure o Pexels para completar.');
  }

  // 4. Diagnóstico, clima e textos
  progresso('Fazendo o diagnóstico online');
  let diagnostico;
  try {
    diagnostico = await diagnosticar(registro, { loja, servicos, perfil, agora });
  } catch (erro) {
    avisar(erro instanceof ErroCota ? erro.message : `Não consegui comparar com os concorrentes: ${erro.message}`);
    diagnostico = await diagnosticar(registro, { loja, servicos: { places: null }, perfil, agora });
  }
  await salvar({ diagnostico });
  const clima = await extrairClima(registro, perfil, { gemini });
  avisar(clima.aviso);
  await salvar({ clima: clima.clima });
  progresso('Escrevendo os textos do site');
  const textos = await escreverTextosPrevia(registro, diagnostico, { gemini });
  avisar(textos.aviso);

  // 5. Direção de arte
  progresso('Escolhendo o design');
  const negocio = registroParaNegocio(registro, midias, clima.clima);
  const contexto = { fotos: await medidasDasFotos(midias), video: midias.find((m) => m.tipo === 'video') ?? null, negocio, textos: textos.textos };
  const usadas = usadasDaLoja(await loja.ler('negocios', []));
  const arte = await sugerirAssinatura(contexto, usadas, { gemini });
  avisar(arte.aviso);

  // 6. Prévia (a anterior sai do ar)
  progresso('Montando e conferindo a prévia');
  const anterior = registro.previa;
  const previa = await gerarPrevia(negocio, {
    pastaSaida: join(config.pastaDados, 'previas'), usadas, textos: textos.textos,
    assinatura: arte.assinatura ?? undefined, estudio: config.estudio, navegador, bloquearRede,
  });
  previa.avisos.forEach(avisar);
  if (anterior?.slug && anterior.slug !== previa.slug) {
    if (anterior.url && servicos.github) {
      try {
        await servicos.github.remover(anterior.slug, `Remove a versão anterior da prévia de ${registro.nome}`);
      } catch (erro) {
        avisar(`Não consegui tirar do ar a versão anterior: ${erro.message}`);
      }
    }
    await rm(join(config.pastaDados, 'previas', anterior.slug), { recursive: true, force: true });
  }
  const novaPrevia = { slug: previa.slug, assinatura: previa.assinatura, versao: (anterior?.versao ?? 0) + 1, podeMostrar: false };

  // 7. Conferência reprovada: não publica
  if (!previa.conferencia.ok) {
    await salvar({ previa: { ...novaPrevia, problemas: previa.conferencia.problemas } });
    avisar('A prévia não passou na conferência automática e não foi publicada.');
    return { registro, avisos };
  }

  // 8. Publicação
  let url;
  if (!servicos.github) {
    avisar('Configure o GitHub para publicar as prévias.');
  } else {
    progresso('Publicando a prévia');
    try {
      await servicos.github.publicar(previa.pasta, previa.slug, `Prévia de ${registro.nome}`);
      url = servicos.github.url(previa.slug);
      novaPrevia.url = url;
      novaPrevia.publicadaEm = agora.toISOString();
    } catch {
      avisar('Não consegui publicar a prévia agora. Ela ficou salva no computador.');
    }
  }
  await salvar({ previa: novaPrevia });

  // 9. Mensagens, preço e etapa
  progresso('Escrevendo as mensagens');
  if (!config.nomeUsuario) avisar('Configure seu nome para assinar as mensagens.');
  const { porIA: _porIA, aviso, ...abordagem } = await escreverAbordagem(registro, diagnostico, {
    url: url ?? LINK_PENDENTE, nomeUsuario: config.nomeUsuario || config.estudio, estudio: config.estudio, gemini,
  });
  avisar(aviso);
  const etapa = registro.etapa === 'encontrado' ? mudarEtapa(registro, 'preparado', agora) : registro;
  await salvar({ ...etapa, abordagem, preco: sugerirPreco(registro.nicho, config.precos) });
  progresso('Pronto');
  return { registro, ...(url ? { url } : {}), avisos };
}
