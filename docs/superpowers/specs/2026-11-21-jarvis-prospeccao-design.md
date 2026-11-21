# Jarvis de prospecção: design

Data: 2026-11-21
Status: rascunho para aprovação

## 1. Intenção e porquê

O usuário faz sites cinematográficos com rolagem (o processo está em `sitede10k-skill.zip`: vídeo gerado com IA no Higgsfield, HTML/CSS/JS puro, publicação na HostGator). Ele está começando, **ainda não vendeu nenhum site e não tem portfólio**. Quando pensa em vender, o que mais preocupa é **convencer o dono do negócio e fechar**.

A inspiração é um reel da Bandit Studio: um "Jarvis" com uma esfera de partículas, painéis futuristas e voz, que apresenta os sites dos clientes. Lá, o Jarvis é uma vitrine. Aqui ele tem duas funções:

1. **Achar e convencer clientes:** encontrar negócios locais que precisam de site e preparar, para cada um, o material que ajuda a fechar.
2. **Ser vitrine:** ter visual futurista e voz desde a primeira versão, para o usuário também gravar vídeos e atrair clientes pelo Instagram.

Como o usuário não tem portfólio, cada **prévia de site** gerada pelo Jarvis faz dois papéis: convence aquele negócio e vira amostra do trabalho.

## 2. Objetivos, não-objetivos e anti-objetivos

**Objetivos (v1)**
- Por comando de voz ou texto ("acha barbearias em Campinas"), buscar negócios locais no Google Maps e listar primeiro os que mais precisam de site.
- Para cada negócio escolhido, preparar: diagnóstico online, prévia do site publicada num link, primeira mensagem personalizada e respostas para objeções.
- Abrir o WhatsApp do usuário com a mensagem pronta, com um clique.
- Acompanhar cada contato por etapas e avisar quem precisa de nova mensagem.
- Sugerir uma faixa de preço por tipo de negócio.
- Interface futurista (esfera, painéis, sequência de inicialização) com voz: o Jarvis ouve e fala em português do Brasil.
- Modo vitrine: "Jarvis, apresenta os projetos" passa pelas prévias uma a uma, falando sobre cada uma, para gravar vídeos.
- Custo mensal zero no volume do usuário (até 10 abordagens por semana).

**Não-objetivos (ficam fora da v1)**
- Reconhecimento de rosto pela webcam, rastreamento da mão e "jogar o site para o tablet" (fase 2).
- Uso no celular ou hospedagem na internet (talvez numa fase futura, migrando para a abordagem C).
- Construir o site de 10k de verdade. Isso continua sendo a skill `site-de-10k`.
- Contratos, cobrança, nota fiscal.
- Prospecção por e-mail, por mensagem direta no Instagram ou em outras redes.
- Vários usuários.

**Anti-objetivos (se acontecer, falhou mesmo funcionando)**
- **Mandar mensagens sozinho ou em massa.** O WhatsApp bane números assim, e isso queima a reputação do usuário. Todo envio é um clique humano.
- **Gerar cobrança surpresa** no Google ou em qualquer serviço.
- **Insistir demais:** no máximo 2 mensagens de acompanhamento por contato. Quem pedir para não ser contatado nunca mais aparece.
- **Prévia que pareça o site oficial do negócio** ou que engane alguém. Toda prévia diz que é uma demonstração.
- **Copiar o visual ou a marca da Bandit Studio.** A direção é parecida (HUD azul, esfera), mas o design é próprio.
- Usuário precisar mexer em código ou editar arquivo para usar no dia a dia.

## 3. Restrições

- **Custo:** só planos gratuitos. O Google Maps exige cartão cadastrado na conta do Google Cloud, mesmo dentro da cota grátis (o usuário já sabe e concordou).
- **Plataforma:** computador Windows, navegador Chrome ou Edge.
- **Volume:** até 10 abordagens por semana, o que dá umas 100 consultas por mês ao Google Maps.
- **Usuário iniciante:** a instalação e a criação das chaves precisam de guia passo a passo. O uso diário é por voz ou cliques, sem terminal.
- **Idioma:** tudo em português do Brasil, linguagem simples, sem travessão nos textos da interface (estilo do usuário).
- **Rede:** precisa de internet para as APIs e para o reconhecimento de voz do navegador.

## 4. Abordagens consideradas

| | Abordagem | Vantagens | Custos |
|---|---|---|---|
| **A (escolhida)** | App próprio no Windows: servidor Node.js local e interface no navegador | Visual e voz ao vivo, custo zero, dados no PC do usuário, serve para gravar vídeo | A construção maior. Exige instalar o Node.js e criar chaves grátis. Só no PC |
| B | Jarvis dentro do Claude Code (comandos, painel estático) | Pronto mais rápido, IA mais esperta, sem chaves | Sem voz nem visual ao vivo, o que contradiz o pedido. Gasta o limite do plano do Claude |
| C | App hospedado na internet | Abre no celular | Precisa de login e de chaves na nuvem. Mais peças e mais pontos de falha |

Descartadas: automação sem código (n8n, Make), porque o plano grátis é limitado e não dá o visual; e copiar dados direto das páginas do Google Maps, que viola as regras do Google e quebra com frequência.

**O usuário escolheu A.** O formato técnico ("tanto faz") ficou por conta do Claude.

## 5. Requisitos expandidos

### 5.1 Escopo e restrições

- **Volume de dados:** dezenas a poucas centenas de negócios no total. Cerca de 10 abordagens e algumas buscas por semana.
- **Restrições rígidas:** custo zero, Windows, pt-BR, envio sempre manual.
- **Integrações:** Google Places API (New), PageSpeed Insights API, Gemini API (plano grátis), Pexels API, GitHub (publicar as prévias no GitHub Pages), WhatsApp por link `wa.me`, Web Speech API do navegador.
- **Tolerância a falhas:** ferramenta pessoal. Se uma API falhar, o Jarvis avisa em uma frase e o resto continua funcionando. Nenhum dado do funil pode se perder.
- **Usuário:** uma pessoa, iniciante em programação, usando à noite ou nas horas vagas.

### 5.2 Modelo de dados

**Negócio (lead):** um por lugar do Google, com o `place_id` como chave única. Nunca se duplica, mesmo aparecendo em buscas diferentes.
- Do Google: nome, endereço, cidade, telefone (nacional e internacional), site, nota, número de avaliações, link do Maps, categorias, situação (aberto ou fechado).
- Calculados: tem WhatsApp provável (celular brasileiro: DDD + 9 dígitos começando com 9), tipo de presença online (`sem_site`, `so_rede_social` quando o "site" é Instagram, Linktree ou similar, `site_fraco`, `site_ok`), prioridade (número), nicho.
- Etapa do funil e datas de cada mudança.
- Notas livres do usuário.
- Bandeira `nao_contatar` (permanente).

**Diagnóstico:** um por negócio (pode ser refeito). Contém: data, nota de desempenho no celular (0 a 100) e tempo de carregamento quando há site, se tem HTTPS, resumo da nota e das avaliações, concorrentes próximos do mesmo tipo (quantos têm site e o nome do mais bem avaliado com site), e um texto curto em linguagem de dono de negócio.

**Prévia:** uma por negócio (versões numeradas quando é refeita). Contém: link público, data de publicação, textos gerados, fotos usadas (com crédito do Pexels).

**Material de abordagem:** a primeira mensagem, as mensagens de acompanhamento 1 e 2, e as respostas para objeções personalizadas para aquele negócio.

**Interação (histórico):** cada evento com data: mensagem aberta no WhatsApp, envio confirmado pelo usuário, resposta registrada, reunião marcada, nota adicionada, mudança de etapa.

**Busca:** termo, cidade, data e quantos resultados vieram. Serve para não repetir buscas e para o contador de cota.

**Configurações:** nome do usuário (para o Jarvis cumprimentar e assinar mensagens), cidade padrão, meta semanal (10), dias para acompanhamento (3 e 7), tabela de preços por nicho, voz escolhida.

**Uso das APIs:** contagem por mês de cada API, para o limite de segurança.

**Retenção:** tudo fica até o usuário apagar. Negócios `perdido` e `descartado` continuam guardados para não reaparecerem como novos. Apagar um negócio remove também a prévia publicada.

### 5.3 Comportamento e fluxos

**Abertura**
1. O usuário dá dois cliques em `Iniciar Jarvis` (atalho na área de trabalho). O servidor sobe e o navegador abre a interface.
2. A sequência de inicialização mostra linhas de status (módulos de voz, Google, IA, prévias) e depois "SISTEMA ONLINE". Linhas com falha aparecem em vermelho com o motivo em uma frase.
3. O Jarvis cumprimenta pelo nome e pelo horário e fala o resumo do dia: quantos contatos cobrar hoje, quantos responderam, progresso da meta semanal.

**Busca (caminho feliz)**
1. O usuário fala ou digita "acha barbearias em Campinas".
2. A IA transforma a frase num comando (`buscar`, com nicho e cidade). Se faltar a cidade, usa a cidade padrão.
3. Busca no Google Maps (até 20 resultados). Descarta fechados, já cadastrados e marcados como `nao_contatar`.
4. Classifica a presença online e roda o teste de velocidade só nos que têm site (no máximo 3 ao mesmo tempo).
5. Ordena por prioridade: sem site ou só rede social primeiro, depois site fraco. Dentro de cada grupo, os com mais avaliações e nota maior vêm antes, porque são negócios ativos que podem pagar.
6. Mostra os cartões na tela e fala "Encontrei 14 barbearias. 6 não têm site. A melhor oportunidade é a Barbearia X, nota 4,8 com 230 avaliações e sem site."

**Preparar um negócio**
1. O usuário escolhe o negócio ("prepara a Barbearia X" ou um clique no cartão).
2. Roda o diagnóstico completo, incluindo os concorrentes próximos.
3. Gera os textos da prévia com a IA, busca 3 a 5 fotos do nicho no Pexels, monta a página e publica no GitHub Pages.
4. Gera a primeira mensagem, as duas de acompanhamento e as respostas para objeções.
5. A etapa muda para `preparado`. O Jarvis fala "Prévia no ar. A mensagem está pronta."

**Abordar**
1. O usuário clica em "Abrir no WhatsApp". O link `wa.me` abre o WhatsApp (Desktop ou Web) com o texto pronto.
2. Ao voltar para o Jarvis, aparece a pergunta "Mandou a mensagem?" (Sim / Ainda não). Com "Sim", a etapa vira `abordado` e o relógio do acompanhamento começa.
3. Sem WhatsApp provável (telefone fixo ou sem telefone), o Jarvis mostra o telefone para ligar e um link de busca no Google "nome + cidade + instagram". O usuário registra a abordagem manualmente.

**Funil e acompanhamento**
- Etapas: `encontrado` → `preparado` → `abordado` → `respondeu` → `reuniao` → `proposta` → `fechou`. A qualquer momento: `perdido`, `descartado` ou a bandeira `nao_contatar`.
- 3 dias após `abordado` sem resposta: entra na lista "cobrar hoje" com o acompanhamento 1 pronto.
- 7 dias após o acompanhamento 1 sem resposta: entra de novo com o acompanhamento 2.
- Depois do acompanhamento 2 sem resposta: o Jarvis sugere marcar como `perdido`. Nunca há um terceiro.
- O usuário muda etapas por voz ("a Barbearia X respondeu"), por clique ou arrastando o cartão.
- Painel fixo com a contagem por etapa e a meta da semana.

**Objeções**
- Um roteiro base fixo (escrito na construção) cobre: "tá caro", "já tenho Instagram", "vou pensar", "não tenho tempo", "meu sobrinho faz", "já tenho site", "não preciso, já tenho clientes".
- Para cada negócio, a IA adapta as respostas ao nicho e ao diagnóstico dele.
- Por voz: "Jarvis, ele disse que tá caro" mostra e fala a resposta para o negócio aberto.

**Preço**
- Tabela de faixas por nicho e por pacote (básico, profissional, premium cinematográfico), mais manutenção mensal. A faixa sugerida aparece no cartão do negócio.
- Os valores iniciais são pesquisados na construção (preços praticados por freelancers e agências no Brasil) e ficam editáveis nas configurações.

**Falhas e casos de borda**
- Uma API fora do ar ou com erro de chave: o Jarvis avisa qual parte não funciona, e o resto continua.
- Limite grátis do Gemini atingido: as mensagens caem para modelos de texto com campos preenchidos (nome, nicho, achado do diagnóstico) e a prévia usa textos padrão do nicho. Avisa o usuário.
- Cota de segurança do Google atingida: novas buscas são bloqueadas até o mês virar, com aviso claro.
- O reconhecimento de voz não entendeu: o Jarvis pede para repetir e mostra a caixa de texto.
- Negócio sem telefone: fica com "sem contato direto" e as alternativas acima.
- Busca sem resultado: sugere ampliar a cidade ou trocar o nicho.
- Publicação da prévia falhou: tenta de novo uma vez. Se falhar de novo, mantém a prévia local e avisa.

**Modo vitrine**
- "Jarvis, apresenta os projetos" (ou um botão) passa pelas prévias publicadas, uma por vez, em destaque na tela. Para cada uma, o Jarvis fala o nome do negócio e o que o site resolve.
- Só entram prévias que o usuário marcou como "pode mostrar". O padrão é não mostrar, porque o dono do negócio não autorizou. A partir do primeiro cliente fechado, os sites reais entram aqui.

**Avisos (efeitos colaterais)**
- Só dentro do app: o resumo falado na abertura e a lista "cobrar hoje". Nenhum e-mail ou notificação externa na v1.

### 5.4 Integrações e dependências

| Serviço | Uso | Chave | Custo e limite |
|---|---|---|---|
| Google Places API (New), Text Search | Buscar negócios e concorrentes | Chave do Google Cloud (projeto **com** faturamento) | Campos como site, telefone e nota caem no nível Enterprise: 1.000 chamadas grátis por mês. Uso previsto: cerca de 100 |
| PageSpeed Insights API v5 | Testar o site no celular | A mesma chave do Google Cloud | Grátis |
| Gemini API | Entender comandos, escrever textos, mensagens e objeções | Chave do AI Studio num **projeto separado sem faturamento** | Grátis com limite por minuto e por dia |
| Pexels API | Fotos para as prévias | Chave do Pexels | Grátis |
| GitHub API | Publicar as prévias num repositório público `previas` com GitHub Pages | Token fino do GitHub, só com escrita nesse repositório | Grátis |
| WhatsApp | `https://wa.me/55DDDNUMERO?text=...` | Nenhuma | Grátis |
| Web Speech API | Ouvir (SpeechRecognition, pt-BR) e falar (speechSynthesis) | Nenhuma | Grátis. O reconhecimento usa os servidores do navegador |

**Ponto importante sobre o Gemini:** se a chave do Gemini ficar no mesmo projeto do Google Cloud que tem faturamento (o do Maps), o uso deixa de ser grátis. Por isso são dois projetos separados.

**Sequência:** busca no Google → classificação → teste de velocidade (só quem tem site) → o usuário escolhe → diagnóstico completo → textos da IA → fotos → publicação → mensagens. Cada passo grava o resultado na hora. Se algo falhar no meio, o que já foi feito fica salvo e o passo pode ser refeito sozinho.

**Sem transações distribuídas:** é um app de uma pessoa, com arquivos locais. Cada escrita é atômica (grava num arquivo temporário e depois renomeia).

**Tudo sob demanda:** sem filas, sem webhooks, sem tarefas de fundo. O cálculo de "cobrar hoje" acontece na abertura e quando a lista é aberta.

### 5.5 Não-funcionais

- **Desempenho:** busca com classificação em menos de 60 segundos para 20 resultados. Preparar um negócio (diagnóstico, prévia publicada e mensagens) em menos de 2 minutos. A interface mostra o progresso enquanto isso.
- **Custo garantido:** no Google Cloud, limite diário de chamadas configurado no console (Places: 30 por dia) e alerta de orçamento de R$ 1. No app, um contador mensal que bloqueia ao chegar em 800 chamadas do Places.
- **Segurança e privacidade:** as chaves ficam num arquivo `.env` fora do git. O servidor só escuta `127.0.0.1`. Os dados ficam numa pasta local fora do git. Só se guardam dados públicos de contato de empresas. A bandeira `nao_contatar` atende a quem pedir para sair, e apagar um negócio apaga tudo dele, incluindo a prévia publicada. A prévia tem `noindex` e um aviso visível de que é uma demonstração. O endereço da prévia leva um trecho aleatório (por exemplo `/barbearia-x-7f3k/`), para ninguém achar a prévia por adivinhação. A prévia é removida sozinha quando o negócio vira `perdido`, `descartado` ou `nao_contatar`, e também 45 dias depois da publicação se o negócio não passou de `abordado`.
- **Cópia de segurança:** um botão "exportar meus dados" gera um arquivo único com tudo, para o usuário guardar. O app também guarda uma cópia automática da última semana na pasta de dados.
- **Concorrência:** sequencial, com no máximo 3 testes de velocidade em paralelo.
- **Observabilidade:** um log local simples (arquivo) de chamadas às APIs e erros, e um painel "status dos sistemas" na interface.
- **Testes:** testes automáticos com o executor nativo do Node (`node --test`) para classificação, prioridade, leitura de telefone, links do WhatsApp, regras do funil e do acompanhamento, e contador de cota. Integrações testadas com respostas gravadas, sem chamar as APIs de verdade nos testes. Um roteiro de teste manual da voz e do visual.

### 5.6 Trade-offs e suposições

**Fora do escopo:** listado na seção 2.

**Suposições**

| Suposição | Confiança |
|---|---|
| Text Search com site, telefone e nota fica no nível Enterprise, com 1.000 chamadas grátis por mês | MÉDIA: confirmar na página de preços na construção |
| O plano grátis do Gemini dá conta de umas 100 a 200 chamadas por semana | ALTA |
| O reconhecimento de voz em pt-BR funciona no Chrome e no Edge no Windows | ALTA |
| O usuário aceita cadastrar cartão no Google Cloud | MÉDIA: ele disse "tudo certo" depois de ser avisado |
| Muitos negócios locais não têm site ou têm site fraco | MÉDIA-ALTA |
| Telefone celular do Google Maps costuma ter WhatsApp | MÉDIA |
| O usuário aceita as prévias num endereço `usuario.github.io/previas/...` | MÉDIA |
| A licença do Pexels permite usar as fotos em prévias | ALTA |
| O nome "Jarvis" pertence à Marvel. Sem problema para uso pessoal, mas é um risco em vídeos de marketing | ALTA: o nome do assistente fica configurável |

**Custo da complexidade:** são cinco serviços externos e quatro chaves. A configuração inicial é a parte mais frágil para um iniciante. Por isso o app tem um assistente de configuração na primeira abertura, que testa cada chave e diz o que falta em linguagem simples.

**Pontos cegos**
- O Google pode mudar preços ou cotas: o contador e o limite do console protegem contra isso.
- A voz do navegador varia: no Edge as vozes "Natural" em pt-BR são bem melhores. Recomendar o Edge.
- Prévias com fotos genéricas podem parecer genéricas: o texto personalizado (nome, bairro, nota real, serviços do nicho) precisa carregar a personalização.
- O dono pode estranhar um site pronto com o nome dele: o aviso de demonstração e o tom da mensagem ("fiz uma amostra de como poderia ficar") cuidam disso.

**Como desfazer:** tudo é local. Desinstalar é apagar a pasta. As chaves podem ser revogadas nos painéis de cada serviço, e o repositório `previas` pode ser apagado no GitHub.

## 6. Decisões de "como"

**Do usuário:** abordagem A, negócios locais, custo zero, Windows, envio por um clique, as quatro munições (diagnóstico, prévia, mensagem, objeções), funil completo com acompanhamento, visual e voz já na v1, até 10 abordagens por semana. Ainda não tem domínio nem hospedagem, então as prévias ficam no GitHub Pages (`usuario.github.io/previas/...`). Quando houver domínio, ele pode apontar para o GitHub Pages sem mudar o app, e por isso o endereço base das prévias fica nas configurações.

**Do Claude (o usuário pode corrigir)**
- Node.js LTS, servidor HTTP simples, interface em HTML, CSS e JavaScript puros, como no reel e na skill do usuário. Bibliotecas de visual (por exemplo Three.js para a esfera) ficam copiadas no projeto, sem build.
- Dados em arquivos JSON locais, com escrita atômica. Sem banco de dados que precise de compilação no Windows.
- O app fica na pasta `jarvis/` deste repositório.
- Fala por "aperte para falar" (barra de espaço ou clique na esfera) na v1, em vez de escuta contínua. Há também uma caixa de texto para digitar.
- Prévias no GitHub Pages, num repositório público separado `previas`.
- Acompanhamento em 3 e 7 dias, no máximo 2.
- Faixas de preço iniciais pesquisadas na construção e editáveis.
- O nome do assistente fica configurável, com "Jarvis" como padrão.
- Abrir com dois cliques num atalho `.bat`, que sobe o servidor e abre o navegador.
- Modo vitrine só com prévias marcadas como "pode mostrar".
- Endereço da prévia com trecho aleatório e remoção automática (perdido, descartado, não contatar ou 45 dias parado em `abordado`).
- Exportar dados com um botão, mais uma cópia automática semanal.
- O nome do usuário, o nome do estúdio (se houver) e o WhatsApp dele ficam nas configurações e aparecem na assinatura das mensagens e no rodapé das prévias.

## 7. Deixado para o construtor

- O design visual exato dentro da direção (HUD azul escuro, esfera de partículas, painéis, sequência de inicialização), desde que seja original.
- O modelo de página da prévia e como ele varia por nicho.
- O texto exato dos prompts da IA e dos modelos de mensagem, respeitando: mensagem curta (até cerca de 400 caracteres), um achado concreto do diagnóstico, o link da prévia, sem pressão, assinada com o nome do usuário.
- A estrutura de pastas e arquivos dentro de `jarvis/`.
- Os ajustes finos da regra de prioridade.
- A porta local e os detalhes do assistente de configuração.
