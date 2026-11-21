import { linkWhatsApp } from '../util/whatsapp.js';
import { limparTextos } from '../util/texto.js';

const LIMITE_PRIMEIRA = 400;

/** Respostas base para as objeções mais comuns. A IA adapta ao nicho quando pode. */
export const ROTEIRO_OBJECOES = {
  caro: 'Entendo. Um site bem feito trabalha todos os dias por vocês, e costuma se pagar com poucos clientes novos. Posso montar um pacote que caiba no momento de vocês.',
  tenho_instagram: 'O Instagram é ótimo para quem já segue vocês. O site aparece para quem procura no Google e ainda não conhece, e leva direto para o WhatsApp.',
  vou_pensar: 'Claro, sem pressa. A amostra fica no ar por um tempo para vocês verem com calma. Se surgir qualquer dúvida, é só me chamar.',
  sem_tempo: 'Por isso eu cuido de tudo: textos, fotos e publicação. Vocês só olham e aprovam, em poucos minutos.',
  sobrinho_faz: 'Que bom ter ajuda em casa. Se em algum momento quiserem um site profissional, com animação e pensado para trazer clientes, a amostra está aqui.',
  ja_tenho_site: 'Que ótimo. Posso mostrar o que dá para melhorar, como velocidade no celular e um botão direto para o WhatsApp, e vocês decidem.',
  ja_tenho_clientes: 'Isso mostra que o trabalho de vocês é bom. O site ajuda a manter a agenda cheia nos dias mais fracos e a mostrar esse trabalho para mais gente.',
};

const PRESSAO = /!!|urgente|[uú]ltima chance|s[oó] hoje/i;
export const temPressao = (texto) => PRESSAO.test(String(texto));

function cortarFrase(texto, limite) {
  if (texto.length <= limite) return texto;
  const corte = texto.slice(0, Math.max(0, limite - 1));
  const espaco = corte.lastIndexOf(' ');
  return `${(espaco > 20 ? corte.slice(0, espaco) : corte).replace(/[\s,.;:]+$/, '')}…`;
}

/**
 * Mensagens sem IA: primeira abordagem, dois acompanhamentos e o roteiro de objeções.
 * @returns {import('../prospeccao/tipos.js').Abordagem}
 */
export function mensagensPadrao(registro, diagnostico, { url, nomeUsuario, estudio }) {
  const abertura = `Oi, tudo bem? Sou ${nomeUsuario}, do ${estudio}.`;
  const amostra = `Fiz uma amostra de como poderia ficar o site de vocês: ${url}`;
  const convite = 'Se quiser, te explico como funciona.';
  let achado = diagnostico?.achadoPrincipal ?? '';
  let primeira = [abertura, achado, amostra, convite, nomeUsuario].filter(Boolean).join(' ');
  if (primeira.length > LIMITE_PRIMEIRA) primeira = [abertura, achado, amostra, nomeUsuario].filter(Boolean).join(' ');
  if (primeira.length > LIMITE_PRIMEIRA) {
    const sobra = LIMITE_PRIMEIRA - [abertura, amostra, nomeUsuario].join(' ').length - 2;
    achado = cortarFrase(achado, Math.max(0, sobra));
    primeira = [abertura, achado, amostra, nomeUsuario].filter(Boolean).join(' ');
  }
  return limparTextos({
    primeira,
    acompanhamento1: `Oi! Passando para saber se deu para ver a amostra do site de vocês: ${url} Qualquer dúvida, é só me chamar. ${nomeUsuario}`,
    acompanhamento2: `Oi! Não quero incomodar, então essa é minha última mensagem sobre o site. A amostra continua aqui se quiserem ver com calma: ${url} Obrigado pela atenção. ${nomeUsuario}`,
    objecoes: { ...ROTEIRO_OBJECOES },
  });
}

/** Link do WhatsApp com a mensagem pronta, ou null quando o número não parece celular. */
export function linkAbordagem(registro, texto) {
  if (!registro.whatsappProvavel) return null;
  return linkWhatsApp(registro.telefoneInternacional ?? registro.telefone, texto);
}
