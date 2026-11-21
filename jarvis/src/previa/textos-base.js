import { normalizar } from '../util/slug.js';
import { normalizarTelefoneBR, provavelCelular } from '../util/whatsapp.js';

export const NICHOS = ['barbearia', 'salao', 'estetica', 'restaurante', 'pizzaria', 'hamburgueria', 'cafeteria', 'padaria', 'clinica', 'odontologia', 'academia', 'petshop', 'oficina', 'imobiliaria', 'generico'];

/** Ordem importa: o primeiro que bater vence ("clínica de estética" é estética, não clínica). */
const PALAVRAS = [
  ['odontologia', ['odonto', 'dentist', 'dental']],
  ['estetica', ['estetic', 'depilac', 'sobrancelha', 'spa', 'micropigment', 'harmonizac']],
  ['petshop', ['pet', 'petshop', 'veterinar', 'banho e tosa', 'banho tosa']],
  ['barbearia', ['barbear', 'barber', 'barbeir']],
  ['salao', ['salao', 'cabeleir', 'beleza', 'hair', 'manicure', 'esmalteria']],
  ['pizzaria', ['pizza']],
  ['hamburgueria', ['hamburg', 'burger', 'lanchonete', 'smash']],
  ['cafeteria', ['cafeteria', 'coffee', 'cafe']],
  ['padaria', ['padaria', 'panificad', 'confeitaria', 'doceria']],
  ['restaurante', ['restaurante', 'bistro', 'cozinha', 'churrascaria', 'comida', 'sushi', 'marmita', 'self service']],
  ['academia', ['academia', 'crossfit', 'pilates', 'fitness', 'gym', 'treino', 'musculac']],
  ['oficina', ['oficina', 'mecanic', 'auto center', 'funilaria', 'borracharia', 'autopecas']],
  ['imobiliaria', ['imobiliar', 'imoveis', 'imovel', 'corretor']],
  ['clinica', ['clinica', 'medic', 'fisioterap', 'consultorio', 'saude', 'psicolog', 'nutricion']],
];

/**
 * Chaves curtas (até 4 letras) precisam ser a palavra inteira; as outras, o começo de uma palavra.
 * Assim "espetinhos" não vira pet shop e "Espaço" não vira spa.
 */
const bate = (t, chave) => (chave.length <= 4 ? t.includes(` ${chave} `) : t.includes(` ${chave}`));

/** @param {string} texto */
export function identificarNicho(texto) {
  const t = ` ${normalizar(texto).replace(/-/g, ' ')} `;
  if (NICHOS.includes(t.trim())) return t.trim();
  for (const [nicho, chaves] of PALAVRAS) if (chaves.some((c) => bate(t, c))) return nicho;
  return 'generico';
}

/** `requer` lista o que o negócio precisa ter para a pergunta fazer sentido: contato, endereco, horarios. */
const P = (pergunta, resposta, requer = []) => ({ pergunta, resposta, requer });
const S = (nome, descricao) => ({ nome, descricao });

const PERGUNTAS_COMUNS = [
  P('Como faço para falar com vocês?', 'O jeito mais rápido é pelo WhatsApp. Respondemos assim que possível durante o horário de atendimento.', ['contato']),
  P('Onde vocês ficam?', 'Estamos em {lugar}. O endereço completo e o link do mapa estão aqui no site.', ['endereco']),
  P('Quais formas de pagamento vocês aceitam?', 'Trabalhamos com as formas de pagamento mais usadas. Se tiver dúvida, pergunte pelo WhatsApp antes de vir.'),
];

const BANCO = {
  barbearia: {
    titulos: ['Seu corte, do seu jeito', 'Barba e cabelo no capricho', 'Estilo que se nota de longe', 'Barbearia clássica, corte de hoje'],
    subtitulos: ['Corte e barba em {lugar}, com hora marcada e sem pressa', '{nome}: corte, barba e acabamento na navalha', 'A barbearia de {lugar} para quem gosta de sair bem arrumado'],
    servicos: [S('Corte masculino', 'Tesoura, máquina e acabamento na navalha.'), S('Barba completa', 'Toalha quente, navalha e finalização caprichada.'), S('Corte e barba', 'O combo para sair pronto de uma vez.'), S('Corte infantil', 'Paciência e cuidado com os pequenos.'), S('Sobrancelha', 'Alinhamento rápido para fechar o visual.'), S('Pigmentação', 'Disfarça falhas na barba e no cabelo.')],
    sobre: ['{nome} é o lugar para sentar, conversar e sair com o visual em dia. O atendimento é sem pressa e cada corte sai do jeito que você pediu.', 'Em {lugar}, {nome} junta a técnica da barbearia clássica com os cortes de hoje. Ambiente tranquilo, gente atenta e horário respeitado.'],
    perguntas: [P('Precisa agendar?', 'Recomendamos agendar pelo WhatsApp para garantir seu horário e não esperar.'), P('Atendem crianças?', 'Sim. Corte infantil com calma e cuidado.'), P('Quanto tempo leva um corte?', 'Depende do serviço. Ao agendar, a gente já avisa o tempo certinho.')],
    chamadas: ['Agende seu horário', 'Marque seu corte agora', 'Reserve sua cadeira'],
  },
  salao: {
    titulos: ['Cabelo bonito todo dia', 'Seu cabelo em boas mãos', 'Cuidado que aparece no espelho'],
    subtitulos: ['Corte, cor e tratamento em {lugar}', '{nome}: beleza com atenção a cada detalhe', 'O salão de {lugar} para você sair se sentindo linda'],
    servicos: [S('Corte', 'Corte pensado para o seu rosto e o seu dia a dia.'), S('Escova e modelagem', 'Acabamento bonito que dura.'), S('Coloração', 'Cor uniforme, com produtos de qualidade.'), S('Mechas e luzes', 'Iluminação natural feita com técnica.'), S('Hidratação', 'Tratamentos para devolver brilho e força.'), S('Manicure e pedicure', 'Unhas bem feitas para completar o visual.')],
    sobre: ['{nome} é um espaço para cuidar de você com calma. Cada atendimento começa ouvindo o que você quer.', 'Em {lugar}, {nome} cuida do seu cabelo com técnica e carinho, do corte rápido à transformação completa.'],
    perguntas: [P('Precisa agendar?', 'Sim, recomendamos agendar pelo WhatsApp para reservar o tempo certo para o seu serviço.'), P('Vocês fazem avaliação antes da química?', 'Sim. Antes de coloração ou mechas, avaliamos o fio para indicar o melhor caminho.'), P('Quanto tempo dura uma coloração?', 'Varia conforme o cabelo e a técnica. Ao agendar, informamos a duração.')],
    chamadas: ['Agende seu horário', 'Reserve seu momento', 'Marque sua visita'],
  },
  estetica: {
    titulos: ['Pele cuidada, autoestima em alta', 'Cuidado de verdade com você', 'Seu momento de cuidar de si'],
    subtitulos: ['Estética facial e corporal em {lugar}', '{nome}: tratamentos com atenção e segurança', 'Protocolos feitos para o seu objetivo'],
    servicos: [S('Limpeza de pele', 'Pele renovada, limpa e hidratada.'), S('Design de sobrancelhas', 'Formato que valoriza o seu rosto.'), S('Depilação', 'Rápida, cuidadosa e com higiene.'), S('Drenagem linfática', 'Menos inchaço e mais leveza.'), S('Massagem relaxante', 'Uma pausa para o corpo e a mente.'), S('Tratamentos faciais', 'Protocolos para manchas, linhas e textura.')],
    sobre: ['{nome} nasceu para oferecer um cuidado sério e acolhedor. Cada protocolo começa com uma avaliação do que você precisa.', 'Em {lugar}, {nome} une técnica, higiene e um ambiente calmo para você se cuidar sem pressa.'],
    perguntas: [P('Preciso de avaliação antes?', 'Para a maioria dos tratamentos, sim. A avaliação ajuda a indicar o protocolo certo.'), P('Quantas sessões vou precisar?', 'Depende do objetivo e da sua pele. Na avaliação montamos um plano.'), P('Os procedimentos doem?', 'A maioria é tranquila. Explicamos tudo antes e respeitamos o seu limite.')],
    chamadas: ['Agende sua avaliação', 'Reserve seu horário', 'Comece seu cuidado hoje'],
  },
  restaurante: {
    titulos: ['Comida feita com carinho', 'Sabor de casa, todo dia', 'Mesa farta em {lugar}'],
    subtitulos: ['{nome}: pratos caprichados em {lugar}', 'Almoço e jantar com tempero de verdade', 'O restaurante de {lugar} para comer bem sem complicação'],
    servicos: [S('Almoço', 'Pratos do dia preparados na hora.'), S('Pratos à la carte', 'Receitas da casa para todos os gostos.'), S('Sobremesas', 'Para fechar a refeição do jeito certo.'), S('Delivery', 'O sabor da casa onde você estiver.'), S('Reservas para grupos', 'Espaço para aniversários e encontros.')],
    sobre: ['{nome} cozinha como se fosse para a própria família. Ingredientes escolhidos e tempero que faz voltar.', 'Em {lugar}, {nome} é ponto de encontro de quem gosta de comer bem, com atendimento simpático e sem pressa.'],
    perguntas: [P('Vocês fazem entrega?', 'Pergunte pelo WhatsApp a área de entrega e os horários.'), P('Dá para reservar mesa?', 'Sim, reservas pelo WhatsApp, principalmente para grupos.'), P('Tem opções vegetarianas?', 'Temos opções no cardápio. Pergunte as do dia pelo WhatsApp.')],
    chamadas: ['Faça seu pedido', 'Reserve sua mesa', 'Venha almoçar com a gente'],
  },
  pizzaria: {
    titulos: ['Pizza quentinha, massa de verdade', 'A pizza que a família pede', 'Forno quente, sabor de sobra'],
    subtitulos: ['{nome}: pizza caprichada em {lugar}', 'Massa leve, borda crocante e recheio generoso', 'Delivery e salão para a sua noite de pizza'],
    servicos: [S('Pizzas tradicionais', 'Os sabores clássicos, bem recheados.'), S('Pizzas especiais', 'Combinações da casa para variar.'), S('Pizzas doces', 'Para fechar a noite com sobremesa.'), S('Bordas recheadas', 'Um extra que faz diferença.'), S('Delivery', 'Chega quentinha na sua casa.')],
    sobre: ['{nome} leva a sério a massa, o forno e o recheio. O resultado é a pizza que vira tradição de sexta à noite.', 'Em {lugar}, {nome} reúne família e amigos em volta de uma boa pizza, no salão ou em casa.'],
    perguntas: [P('Qual a área de entrega?', 'Pergunte pelo WhatsApp se atendemos o seu endereço.'), P('Dá para pedir meio a meio?', 'Sim, monte a sua com dois sabores.'), P('Quanto tempo demora a entrega?', 'Varia com o movimento. Informamos a previsão quando você faz o pedido.')],
    chamadas: ['Peça sua pizza agora', 'Faça seu pedido', 'Bateu a fome? Peça já'],
  },
  hamburgueria: {
    titulos: ['Burger de verdade, feito na hora', 'Suculento do primeiro ao último pedaço', 'Fome de burger? A gente resolve'],
    subtitulos: ['{nome}: hambúrguer artesanal em {lugar}', 'Pão macio, carne no ponto e molho da casa', 'Burgers, combos e batata do jeito certo'],
    servicos: [S('Burgers da casa', 'Receitas próprias com carne selecionada.'), S('Smash burger', 'Crosta caramelizada e muito sabor.'), S('Combos', 'Burger, batata e bebida juntos.'), S('Opções vegetarianas', 'Sabor sem carne também.'), S('Delivery', 'Chega quentinho onde você estiver.')],
    sobre: ['{nome} faz cada burger na hora, com ingredientes escolhidos e muito cuidado no ponto da carne.', 'Em {lugar}, {nome} é parada certa para quem leva hambúrguer a sério.'],
    perguntas: [P('Dá para escolher o ponto da carne?', 'Sim, é só avisar no pedido.'), P('Vocês fazem entrega?', 'Pergunte pelo WhatsApp a área e os horários de entrega.'), P('Tem opção sem glúten?', 'Pergunte pelo WhatsApp as opções disponíveis no dia.')],
    chamadas: ['Peça seu burger', 'Faça seu pedido agora', 'Matar a fome é com a gente'],
  },
  cafeteria: {
    titulos: ['Um bom café muda o dia', 'Café especial em {lugar}', 'Pausa boa, café melhor'],
    subtitulos: ['{nome}: café, doces e um lugar gostoso para ficar', 'Grãos selecionados e preparo com cuidado', 'Para começar o dia ou fazer aquela pausa'],
    servicos: [S('Cafés especiais', 'Grãos selecionados e métodos variados.'), S('Bebidas geladas', 'Opções refrescantes para os dias quentes.'), S('Doces e bolos', 'Feitos para acompanhar o café.'), S('Salgados', 'Para um lanche completo.'), S('Café da manhã', 'Comece o dia do jeito certo.')],
    sobre: ['{nome} é um cantinho para respirar, conversar e tomar um café feito com atenção.', 'Em {lugar}, {nome} serve café de qualidade num ambiente tranquilo para trabalhar, ler ou encontrar amigos.'],
    perguntas: [P('Tem wi-fi?', 'Pergunte no balcão as condições de uso.'), P('Vocês vendem grãos para levar?', 'Pergunte pelo WhatsApp os cafés disponíveis.'), P('Fazem encomendas de bolos?', 'Sim, fale com a gente pelo WhatsApp com antecedência.')],
    chamadas: ['Venha tomar um café', 'Passe aqui hoje', 'Faça sua encomenda'],
  },
  padaria: {
    titulos: ['Pão quentinho toda hora', 'O sabor da padaria do bairro', 'Fornada fresca, do jeito que você gosta'],
    subtitulos: ['{nome}: pães, doces e salgados em {lugar}', 'Do café da manhã ao lanche da tarde', 'Produção própria todos os dias'],
    servicos: [S('Pães', 'Fornadas fresquinhas ao longo do dia.'), S('Bolos e tortas', 'Para o dia a dia e para as datas especiais.'), S('Salgados', 'Assados e fritos feitos aqui.'), S('Café da manhã', 'Mesa completa para começar bem.'), S('Encomendas', 'Kits para festas e eventos.')],
    sobre: ['{nome} tem cheiro de pão saindo do forno e atendimento de quem conhece o cliente pelo nome.', 'Em {lugar}, {nome} faz parte da rotina da vizinhança, com produção própria e muito capricho.'],
    perguntas: [P('Que horas sai o pão?', 'Temos fornadas ao longo do dia. Pergunte os horários pelo WhatsApp.'), P('Vocês fazem encomendas para festas?', 'Sim, fale com a gente com antecedência pelo WhatsApp.'), P('Fazem entrega?', 'Pergunte pelo WhatsApp se atendemos o seu endereço.')],
    chamadas: ['Faça sua encomenda', 'Passe aqui hoje', 'Garanta seu pão fresquinho'],
  },
  clinica: {
    titulos: ['Cuidado com a sua saúde, perto de você', 'Atendimento humano e atencioso', 'Saúde em boas mãos'],
    subtitulos: ['{nome}: atendimento com atenção em {lugar}', 'Profissionais que escutam antes de orientar', 'Agende sua consulta com facilidade'],
    servicos: [S('Consultas', 'Atendimento com tempo para escutar você.'), S('Avaliações', 'Entender o seu caso antes de qualquer conduta.'), S('Retornos', 'Acompanhamento do seu tratamento.'), S('Orientação', 'Explicações claras sobre cada etapa.'), S('Agendamento fácil', 'Marque pelo WhatsApp em poucos minutos.')],
    sobre: ['{nome} acredita que um bom atendimento começa ouvindo. Aqui você é tratado com respeito e clareza.', 'Em {lugar}, {nome} oferece cuidado próximo, com profissionais atentos e um ambiente acolhedor.'],
    perguntas: [P('Como agendo uma consulta?', 'Pelo WhatsApp, informando o melhor dia e horário para você.'), P('Atendem convênios?', 'Pergunte pelo WhatsApp quais convênios são aceitos.'), P('Preciso levar algum documento?', 'Leve um documento com foto e, se tiver, exames anteriores.')],
    chamadas: ['Agende sua consulta', 'Marque seu horário', 'Fale com a gente'],
  },
  odontologia: {
    titulos: ['Seu sorriso merece cuidado', 'Dentista de confiança em {lugar}', 'Sorria sem medo'],
    subtitulos: ['{nome}: odontologia com calma e atenção', 'Prevenção, estética e tratamento em um só lugar', 'Atendimento para toda a família'],
    servicos: [S('Limpeza e prevenção', 'A base para um sorriso saudável.'), S('Clareamento', 'Dentes mais claros com segurança.'), S('Restaurações', 'Tratamento discreto e duradouro.'), S('Ortodontia', 'Alinhamento com acompanhamento de perto.'), S('Implantes', 'Devolvem função e confiança.'), S('Odontopediatria', 'Cuidado especial com as crianças.')],
    sobre: ['{nome} trata cada paciente com paciência e explica tudo antes de começar. Sem pressa e sem susto.', 'Em {lugar}, {nome} cuida do seu sorriso com técnica atual e um atendimento acolhedor.'],
    perguntas: [P('Tenho medo de dentista. E agora?', 'Fique tranquilo. Explicamos cada passo e respeitamos o seu tempo.'), P('Atendem crianças?', 'Sim, com cuidado especial para os pequenos.'), P('Fazem avaliação antes do tratamento?', 'Sim. A avaliação define o melhor plano para o seu caso.')],
    chamadas: ['Agende sua avaliação', 'Marque sua consulta', 'Cuide do seu sorriso'],
  },
  academia: {
    titulos: ['Seu treino começa aqui', 'Mais disposição a cada semana', 'Treine com quem entende'],
    subtitulos: ['{nome}: estrutura e acompanhamento em {lugar}', 'Musculação, funcional e aulas para todos os níveis', 'Resultado com orientação de verdade'],
    servicos: [S('Musculação', 'Equipamentos para treinar cada grupo muscular.'), S('Treino funcional', 'Força, mobilidade e condicionamento.'), S('Aulas coletivas', 'Treinar junto é mais motivador.'), S('Avaliação física', 'Ponto de partida para o seu plano.'), S('Acompanhamento', 'Professores atentos à sua evolução.')],
    sobre: ['{nome} é para quem quer evoluir com segurança, do primeiro treino ao objetivo mais ousado.', 'Em {lugar}, {nome} reúne estrutura, professores presentes e um ambiente que dá vontade de voltar.'],
    perguntas: [P('Nunca treinei. Posso começar?', 'Pode sim. Montamos um treino de acordo com o seu nível.'), P('Tem aula experimental?', 'Pergunte pelo WhatsApp como funciona a primeira visita.'), P('Quais os horários?', 'Os horários estão aqui no site. Na dúvida, chame no WhatsApp.', ['horarios'])],
    chamadas: ['Comece a treinar', 'Agende sua visita', 'Venha conhecer'],
  },
  petshop: {
    titulos: ['Seu pet bem cuidado e feliz', 'Banho, tosa e muito carinho', 'Amor e cuidado para o seu melhor amigo'],
    subtitulos: ['{nome}: banho, tosa e produtos em {lugar}', 'Cuidado com calma para cães e gatos', 'Tudo para o seu pet num só lugar'],
    servicos: [S('Banho', 'Produtos adequados e secagem com cuidado.'), S('Tosa', 'Higiênica ou na tesoura, do jeito certo.'), S('Hidratação', 'Pelos macios e brilhantes.'), S('Rações e petiscos', 'Marcas selecionadas para cada fase.'), S('Acessórios', 'Coleiras, camas e brinquedos.'), S('Leva e traz', 'Buscamos e entregamos o seu pet.')],
    sobre: ['{nome} trata cada pet como se fosse da casa. Paciência, carinho e atenção do começo ao fim.', 'Em {lugar}, {nome} cuida de cães e gatos com produtos de qualidade e muito respeito ao tempo de cada um.'],
    perguntas: [P('Precisa agendar o banho?', 'Sim, agende pelo WhatsApp para garantir o horário.'), P('Vocês buscam o pet em casa?', 'Pergunte pelo WhatsApp se atendemos o seu endereço.'), P('Meu pet é bravo. Vocês atendem?', 'Sim, com calma e cuidado. Conte para a gente antes.')],
    chamadas: ['Agende o banho', 'Marque um horário', 'Cuide do seu pet hoje'],
  },
  oficina: {
    titulos: ['Seu carro em boas mãos', 'Manutenção sem dor de cabeça', 'Mecânica de confiança em {lugar}'],
    subtitulos: ['{nome}: diagnóstico honesto e serviço bem feito', 'Revisão, freios, suspensão e muito mais', 'Orçamento claro antes de qualquer serviço'],
    servicos: [S('Revisão completa', 'Verificação dos itens de segurança.'), S('Troca de óleo', 'Rápida e com o óleo certo.'), S('Freios e suspensão', 'Segurança e conforto ao dirigir.'), S('Diagnóstico eletrônico', 'Encontra o problema antes de trocar peças.'), S('Alinhamento e balanceamento', 'Pneus durando mais e direção firme.')],
    sobre: ['{nome} explica o problema, mostra a peça e passa o orçamento antes de começar. Sem surpresa na conta.', 'Em {lugar}, {nome} cuida do seu carro com honestidade e prazo combinado.'],
    perguntas: [P('Vocês passam orçamento antes?', 'Sim, sempre. Nada é feito sem a sua aprovação.'), P('Quanto tempo demora o serviço?', 'Depende do serviço. Combinamos o prazo no orçamento.'), P('Atendem qualquer marca?', 'Pergunte pelo WhatsApp sobre o seu modelo.')],
    chamadas: ['Peça seu orçamento', 'Agende uma revisão', 'Traga seu carro'],
  },
  imobiliaria: {
    titulos: ['O imóvel certo para a sua nova fase', 'Encontre seu lugar em {lugar}', 'Comprar, vender ou alugar com segurança'],
    subtitulos: ['{nome}: imóveis e atendimento de perto', 'Quem conhece a região ajuda você a decidir melhor', 'Do primeiro contato à entrega das chaves'],
    servicos: [S('Venda de imóveis', 'Opções selecionadas para o seu momento.'), S('Locação', 'Aluguel com segurança para os dois lados.'), S('Avaliação', 'Preço justo para vender ou alugar.'), S('Administração de aluguéis', 'Cuidamos do contrato e da cobrança.'), S('Documentação', 'Orientação do começo ao fim.')],
    sobre: ['{nome} conhece cada rua de {lugar} e ajuda você a encontrar o imóvel que faz sentido para a sua vida.', '{nome} acompanha cada negociação de perto, com transparência e atendimento próximo.'],
    perguntas: [P('Vocês ajudam com financiamento?', 'Sim, orientamos você em cada etapa.'), P('Como anuncio meu imóvel?', 'Fale com a gente pelo WhatsApp para agendar uma avaliação.'), P('Posso visitar os imóveis?', 'Sim, agende a visita pelo WhatsApp.')],
    chamadas: ['Fale com um corretor', 'Encontre seu imóvel', 'Agende uma visita'],
  },
  generico: {
    titulos: ['Qualidade que você percebe', 'Atendimento de perto, do jeito certo', 'Feito com cuidado em {lugar}'],
    subtitulos: ['{nome}: atendimento atencioso em {lugar}', 'Conheça o que fazemos e fale com a gente', 'Gente de verdade cuidando de você'],
    servicos: [S('Atendimento personalizado', 'Entendemos o que você precisa antes de oferecer.'), S('Orçamento sem compromisso', 'Você decide com calma.'), S('Qualidade garantida', 'Cuidado em cada detalhe.'), S('Entrega no prazo', 'Combinado é combinado.'), S('Pós-venda', 'Continuamos por perto depois da compra.')],
    sobre: ['{nome} nasceu para atender bem quem passa por aqui, com honestidade e atenção.', 'Em {lugar}, {nome} cuida de cada cliente como gostaria de ser atendido.'],
    perguntas: [P('Como peço um orçamento?', 'É só chamar no WhatsApp e contar o que você precisa.'), P('Quanto tempo leva para responder?', 'Respondemos o mais rápido possível no horário de atendimento.')],
    chamadas: ['Fale com a gente', 'Peça seu orçamento', 'Chame no WhatsApp'],
  },
};

const sortear = (lista, aleatorio) => lista[Math.floor(aleatorio() * lista.length)];

/** Por onde o visitante fala com o negócio, igual ao botão da prévia: whatsapp, telefone ou nenhum. */
function canalDeContato(negocio) {
  if (negocio.whatsapp || provavelCelular(negocio.telefone)) return 'whatsapp';
  if (normalizarTelefoneBR(negocio.telefone)) return 'telefone';
  return null;
}

/** Os textos do banco falam em WhatsApp. Sem WhatsApp, troca pelo canal que o negócio tem. */
function ajustarCanal(texto, canal) {
  if (canal === 'whatsapp') return texto;
  if (canal === 'telefone') return texto.replace(/(pelo|no) WhatsApp/g, 'por telefone').replace(/WhatsApp/g, 'telefone');
  return texto.replace(/com a gente (pelo|no) WhatsApp/g, 'com a gente').replace(/(pelo|no) WhatsApp/g, 'direto com a gente').replace(/WhatsApp/g, 'atendimento');
}

function trechoDeAvaliacao(avaliacoes) {
  const boa = (avaliacoes ?? []).find((a) => a.nota >= 5 && a.texto?.trim());
  if (!boa) return null;
  const t = boa.texto.trim().replace(/\s+/g, ' ').replace(/"/g, "'");
  if (t.length <= 120) return { texto: t, autor: boa.autor };
  const corte = t.slice(0, 120);
  const espaco = corte.lastIndexOf(' ');
  return { texto: `${(espaco > 60 ? corte.slice(0, espaco) : corte).replace(/[\s,.;:!?]+$/, '')}…`, autor: boa.autor };
}

/**
 * Textos da prévia sem IA, a partir do nicho do negócio.
 * @param {import('./tipos.js').Negocio} negocio
 * @param {() => number} [aleatorio]
 * @returns {import('./tipos.js').TextosPrevia}
 */
export function textosBase(negocio, aleatorio = Math.random) {
  const nicho = identificarNicho(negocio.nicho ?? '');
  const banco = BANCO[nicho];
  const lugar = negocio.bairro || negocio.cidade;
  const canal = canalDeContato(negocio);
  const temos = {
    contato: canal !== null,
    endereco: !!(negocio.endereco || negocio.mapsUrl),
    horarios: (negocio.horarios?.length ?? 0) > 0,
  };
  const preencher = (texto) => ajustarCanal(texto.replaceAll('{nome}', negocio.nome).replaceAll('{lugar}', lugar), canal);

  let sobre = preencher(sortear(banco.sobre, aleatorio));
  const trecho = trechoDeAvaliacao(negocio.avaliacoes);
  if (trecho) sobre += ` "${trecho.texto}", conta ${trecho.autor}.`;

  const perguntas = [...banco.perguntas, ...PERGUNTAS_COMUNS]
    .filter((p) => p.requer.every((r) => temos[r]))
    .map((p) => ({ pergunta: preencher(p.pergunta), resposta: preencher(p.resposta) }));
  const chamadas = canal === 'whatsapp' ? banco.chamadas : banco.chamadas.filter((c) => !c.includes('WhatsApp'));

  return {
    titulo: preencher(sortear(banco.titulos, aleatorio)),
    subtitulo: preencher(sortear(banco.subtitulos, aleatorio)),
    servicos: banco.servicos.map((s) => ({ nome: preencher(s.nome), descricao: preencher(s.descricao) })),
    sobre,
    perguntas: perguntas.slice(0, 5),
    chamada: preencher(sortear(chamadas, aleatorio)),
  };
}
