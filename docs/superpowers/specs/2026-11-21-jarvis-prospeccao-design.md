# Jarvis de prospecção: design

Data: 2026-11-21
Status: rascunho para aprovação (versão 2: prévias únicas com material real, marca Estúdio Dez)

## 1. Intenção e porquê

O usuário faz sites cinematográficos com rolagem (o processo está em `sitede10k-skill.zip`: vídeo gerado com IA no Higgsfield, HTML/CSS/JS puro, publicação na HostGator). Ele está começando, **ainda não vendeu nenhum site e não tem portfólio**. Quando pensa em vender, o que mais preocupa é **convencer o dono do negócio e fechar**. A marca dele passa a ser **Estúdio Dez**, com uma conta nova e profissional no Instagram.

A inspiração é um reel da Bandit Studio: um "Jarvis" com uma esfera de partículas, painéis futuristas e voz, que apresenta os sites dos clientes. Lá, o Jarvis é uma vitrine. Aqui ele tem duas funções:

1. **Achar e convencer clientes:** encontrar negócios locais que precisam de site e preparar, para cada um, o material que ajuda a fechar. A peça central é uma **prévia de site única, profissional e animada, feita com as fotos, os vídeos e as avaliações reais daquele negócio**.
2. **Ser vitrine:** ter visual futurista e voz desde a primeira versão, para o usuário gravar vídeos e atrair clientes pelo Instagram.

Como o usuário não tem portfólio, cada prévia faz dois papéis: convence aquele negócio e vira amostra do trabalho.

## 2. Objetivos, não-objetivos e anti-objetivos

**Objetivos (v1)**
- Por comando de voz ou texto ("acha barbearias em Campinas"), buscar negócios locais no Google Maps e listar primeiro os que mais precisam de site.
- Para cada negócio escolhido, preparar: diagnóstico online, prévia do site publicada num link, primeira mensagem personalizada e respostas para objeções.
- **Prévias únicas:** nenhuma prévia igual a outra, mesmo para negócios do mesmo nicho na mesma cidade.
- **Prévias com material real:** fotos, vídeos, legendas e bio do Instagram do negócio (pelo caminho oficial da Meta), fotos e avaliações do Google Maps. Fotos de banco de imagens só completam o que faltar.
- **Prévias profissionais:** animações de qualidade, bom funcionamento no celular e no PC, carregamento rápido.
- Abrir o WhatsApp do usuário com a mensagem pronta, com um clique.
- Acompanhar cada contato por etapas e avisar quem precisa de nova mensagem.
- Sugerir uma faixa de preço por tipo de negócio.
- Interface futurista (esfera, painéis, sequência de inicialização) com voz: o Jarvis ouve e fala em português do Brasil.
- Modo vitrine: "Jarvis, apresenta os projetos" passa pelas prévias uma a uma, falando sobre cada uma, para gravar vídeos.
- Custo mensal zero no volume do usuário (até 10 abordagens por semana).

**Não-objetivos (ficam fora da v1)**
- Reconhecimento de rosto pela webcam, rastreamento da mão e "jogar o site para o tablet" (fase 2).
- **Máquina de reels com postagem automática no Instagram do Estúdio Dez:** é um projeto separado, desenhado depois que o Jarvis existir (ver seção 8).
- Uso no celular ou hospedagem na internet (talvez numa fase futura, migrando para a abordagem C).
- Vídeo gerado por IA nas prévias (Higgsfield é pago). O vídeo de topo, quando existe, vem dos reels do próprio negócio.
- Construir o site de 10k de verdade. Isso continua sendo a skill `site-de-10k`.
- Contratos, cobrança, nota fiscal.
- Prospecção por e-mail, por mensagem direta no Instagram ou em outras redes.
- Vários usuários.

**Anti-objetivos (se acontecer, falhou mesmo funcionando)**
- **Mandar mensagens sozinho ou em massa.** O WhatsApp bane números assim, e isso queima a reputação do usuário. Todo envio é um clique humano.
- **Coletar dados do Instagram fora do caminho oficial** (robôs, login automatizado, raspagem de página). Isso viola as regras do Instagram e pode banir a conta do Estúdio Dez, que é o canal de divulgação do usuário.
- **Prévia com cara de modelo pronto**, ou duas prévias que pareçam a mesma com outro nome.
- **Prévia quebrada no celular**, lenta ou com animação travando.
- **Gerar cobrança surpresa** no Google, na Meta ou em qualquer serviço.
- **Insistir demais:** no máximo 2 mensagens de acompanhamento por contato. Quem pedir para não ser contatado nunca mais aparece.
- **Prévia que pareça o site oficial do negócio** ou que engane alguém. Toda prévia diz que é uma demonstração do Estúdio Dez.
- **Copiar o visual ou a marca da Bandit Studio.** A direção é parecida (HUD azul, esfera), mas o design é próprio.
- Usuário precisar mexer em código ou editar arquivo para usar no dia a dia.

## 3. Restrições

- **Custo:** só planos gratuitos. O Google Maps exige cartão cadastrado na conta do Google Cloud, mesmo dentro da cota grátis (o usuário já sabe e concordou).
- **Plataforma:** computador Windows, navegador Chrome ou Edge.
- **Volume:** até 10 abordagens por semana.
- **Instagram:** a conta do Estúdio Dez precisa ser profissional (comercial ou criador) e estar ligada a uma página do Facebook. O usuário vai criar a conta e fazer isso. O Business Discovery só lê contas **profissionais** de outros negócios. Contas pessoais ou com restrição de idade não retornam dados.
- **Usuário iniciante:** a instalação e a criação das chaves precisam de guia passo a passo. O uso diário é por voz ou cliques, sem terminal.
- **Idioma:** tudo em português do Brasil, linguagem simples, sem travessão nos textos da interface e das prévias (estilo do usuário).
- **Rede:** precisa de internet para as APIs e para o reconhecimento de voz do navegador.

## 4. Abordagens consideradas

### 4.1 Forma do Jarvis

| | Abordagem | Vantagens | Custos |
|---|---|---|---|
| **A (escolhida)** | App próprio no Windows: servidor Node.js local e interface no navegador | Visual e voz ao vivo, custo zero, dados no PC do usuário, serve para gravar vídeo | A construção maior. Exige instalar o Node.js e criar chaves grátis. Só no PC |
| B | Jarvis dentro do Claude Code (comandos, painel estático) | Pronto mais rápido, IA mais esperta, sem chaves | Sem voz nem visual ao vivo, o que contradiz o pedido. Gasta o limite do plano do Claude |
| C | App hospedado na internet | Abre no celular | Precisa de login e de chaves na nuvem. Mais peças e mais pontos de falha |

Descartadas: automação sem código (n8n, Make), porque o plano grátis é limitado e não dá o visual; e copiar dados direto das páginas do Google Maps, que viola as regras do Google e quebra com frequência.

**O usuário escolheu A.**

### 4.2 Como gerar prévias únicas

| | Abordagem | Vantagens | Custos |
|---|---|---|---|
| **A (escolhida)** | **Kit de design com a IA como diretora de arte:** peças prontas e testadas (modelos de topo, variações de seção, estilos de animação, pares de fontes). A IA escolhe a combinação para cada negócio e escreve os textos. As cores vêm das fotos e da logo do negócio | Sempre profissional, rápido e grátis. A exclusividade vem da combinação e do conteúdo real | Estruturas podem lembrar umas às outras, mas nunca são iguais. O kit é a maior parte da construção |
| B | A IA grátis escreve cada site do zero, com conferência automática | Exclusividade máxima | Qualidade irregular. Prévias quebradas ou genéricas. Mais lento e gasta o limite grátis |
| C | O Claude faz cada prévia no Claude Code | A maior qualidade | Não é automático e gasta o limite do plano do Claude |

**O usuário escolheu A.**

Descartada: raspar o Instagram com robô ou login automatizado (viola as regras e arrisca a conta do usuário).

## 5. Requisitos expandidos

### 5.1 Escopo e restrições

- **Volume de dados:** dezenas a poucas centenas de negócios no total. Cerca de 10 abordagens e algumas buscas por semana. Por prévia: até cerca de 15 fotos e 1 vídeo do negócio.
- **Restrições rígidas:** custo zero, Windows, pt-BR, envio sempre manual, Instagram só pelo caminho oficial.
- **Integrações:** Google Places API (New) (busca, detalhes, fotos e avaliações), PageSpeed Insights API, Gemini API (plano grátis, com busca no Google para achar o @ do Instagram), Instagram Graph API (Business Discovery), Pexels API, GitHub (publicar as prévias no GitHub Pages), WhatsApp por link `wa.me`, Web Speech API do navegador, ffmpeg e um navegador invisível no próprio PC (conferência das prévias).
- **Tolerância a falhas:** ferramenta pessoal. Se uma API falhar, o Jarvis avisa em uma frase e o resto continua funcionando. Nenhum dado do funil pode se perder.
- **Usuário:** uma pessoa, iniciante em programação, usando à noite ou nas horas vagas.

### 5.2 Modelo de dados

**Negócio (lead):** um por lugar do Google, com o `place_id` como chave única. Nunca se duplica, mesmo aparecendo em buscas diferentes.
- Do Google: nome, endereço, bairro, cidade, telefone (nacional e internacional), site, nota, número de avaliações, link do Maps, categorias, horário de funcionamento, situação (aberto ou fechado), até 5 avaliações com texto, referências de fotos.
- Do Instagram (quando houver e for conta profissional): @ confirmado, bio, número de seguidores e de posts, foto de perfil, posts recentes (tipo, legenda, data, curtidas, link, endereço da mídia).
- Calculados: tem WhatsApp provável (celular brasileiro: DDD + 9 dígitos começando com 9), tipo de presença online (`sem_site`, `so_rede_social` quando o "site" é Instagram, Linktree ou similar, `site_fraco`, `site_ok`), prioridade (número), nicho, "clima" do negócio (palavras que a IA extrai das legendas, fotos e avaliações: por exemplo "rústico, familiar, artesanal").
- Etapa do funil e datas de cada mudança.
- Notas livres do usuário.
- Bandeira `nao_contatar` (permanente).

**Material do negócio:** as fotos e o vídeo baixados para a prévia, cada um com origem (Instagram, Google ou Pexels), crédito, tamanho e as cores principais extraídas.

**Diagnóstico:** um por negócio (pode ser refeito). Contém: data, nota de desempenho no celular (0 a 100) e tempo de carregamento quando há site, se tem HTTPS, resumo da nota e das avaliações, presença no Instagram (seguidores, frequência de posts), concorrentes próximos do mesmo tipo (quantos têm site e o nome do mais bem avaliado com site), e um texto curto em linguagem de dono de negócio.

**Prévia:** uma por negócio (versões numeradas quando é refeita). Contém:
- Link público, data de publicação, bandeira "pode mostrar" (para o modo vitrine).
- **Assinatura de design:** modelo de topo, par de fontes, estilo de animação, sequência e variações das seções, paleta (cores em hexadecimal). Serve para garantir que nenhuma prévia se repete.
- Textos gerados, materiais usados e resultado da conferência automática (capturas de tela no celular e no PC, que também viram a miniatura do cartão no Jarvis).

**Material de abordagem:** a primeira mensagem, as mensagens de acompanhamento 1 e 2, e as respostas para objeções personalizadas para aquele negócio.

**Interação (histórico):** cada evento com data: mensagem aberta no WhatsApp, envio confirmado pelo usuário, resposta registrada, reunião marcada, nota adicionada, mudança de etapa.

**Busca:** termo, cidade, data e quantos resultados vieram. Serve para não repetir buscas e para o contador de cota.

**Configurações:** nome do usuário, nome do estúdio (padrão "Estúdio Dez"), @ do Instagram do estúdio, WhatsApp do usuário, cidade padrão, meta semanal (10), dias para acompanhamento (3 e 7), tabela de preços por nicho, voz escolhida, nome do assistente (padrão "Jarvis"), endereço base das prévias.

**Uso das APIs:** contagem por mês de cada API, para o limite de segurança.

**Retenção:** tudo fica até o usuário apagar. Negócios `perdido` e `descartado` continuam guardados para não reaparecerem como novos. Apagar um negócio remove também a prévia publicada e o material baixado.

### 5.3 Comportamento e fluxos

**Abertura**
1. O usuário dá dois cliques em `Iniciar Jarvis` (atalho na área de trabalho). O servidor sobe e o navegador abre a interface.
2. A sequência de inicialização mostra linhas de status (voz, Google, IA, Instagram, prévias) e depois "SISTEMA ONLINE". Linhas com falha aparecem em vermelho com o motivo em uma frase.
3. O Jarvis cumprimenta pelo nome e pelo horário e fala o resumo do dia: quantos contatos cobrar hoje, quantos responderam, progresso da meta semanal. Se a chave da Meta vence em menos de 7 dias, avisa e mostra como renovar.

**Busca (caminho feliz)**
1. O usuário fala ou digita "acha barbearias em Campinas".
2. A IA transforma a frase num comando (`buscar`, com nicho e cidade). Se faltar a cidade, usa a cidade padrão.
3. Busca no Google Maps (até 20 resultados). Descarta fechados, já cadastrados e marcados como `nao_contatar`.
4. Classifica a presença online e roda o teste de velocidade só nos que têm site (no máximo 3 ao mesmo tempo).
5. Ordena por prioridade: sem site ou só rede social primeiro, depois site fraco. Dentro de cada grupo, os com mais avaliações e nota maior vêm antes, porque são negócios ativos que podem pagar.
6. Mostra os cartões na tela e fala "Encontrei 14 barbearias. 6 não têm site. A melhor oportunidade é a Barbearia X, nota 4,8 com 230 avaliações e sem site."

**Preparar um negócio**
1. O usuário escolhe o negócio ("prepara a Barbearia X" ou um clique no cartão).
2. **Detalhes do Google:** horário, até 5 avaliações e até 10 fotos.
3. **Achar o Instagram:** se o "site" do Google já é um link do Instagram, usa esse @. Se não, a IA com busca no Google sugere o @ mais provável. O usuário confirma com um clique, troca ou diz "não tem". Sem @ confirmado, nada é buscado no Instagram.
4. **Puxar o Instagram (Business Discovery):** bio, seguidores e até 50 posts recentes. Se a conta não for profissional, o Jarvis avisa ("o Instagram deles é pessoal, vou usar as fotos do Google") e segue.
5. **Escolher o material:** a IA escolhe as melhores fotos (nítidas, sem texto grande por cima, variadas: ambiente, produto ou serviço, equipe, fachada) e, se houver, um reel curto para o topo. Fotos de banco de imagens (Pexels) só completam se faltarem fotos boas.
6. **Tratar o material:** redimensiona e comprime as fotos (versões para celular e para PC), extrai as cores principais, comprime o vídeo (até 720p, sem som, cerca de 4 MB) e gera a imagem de capa do vídeo.
7. **Diagnóstico completo,** incluindo concorrentes próximos e presença no Instagram.
8. **Direção de arte:** a IA recebe o "clima" do negócio, o material e a lista de assinaturas já usadas, e escolhe a combinação do kit (topo, fontes, animação, seções, paleta a partir das cores extraídas). O Jarvis confere a regra de exclusividade (abaixo). Se repetir, pede outra combinação.
9. **Textos:** a IA escreve na voz do negócio (baseada nas legendas dele) e usa as palavras dos próprios clientes (das avaliações): título, subtítulo, serviços, sobre, perguntas frequentes, chamada para ação (WhatsApp do negócio).
10. **Montar e conferir:** o Jarvis monta a página, abre num navegador invisível em 390 px (celular) e 1440 px (PC) e confere: nada vazando para os lados, nenhuma imagem quebrada, nenhum erro no console, textos legíveis sobre as imagens. Tira as capturas. Se falhar, corrige ou troca a variação e confere de novo (até 2 tentativas). Depois disso, avisa o usuário.
11. **Publicar** no GitHub Pages.
12. Gera a primeira mensagem, as duas de acompanhamento e as respostas para objeções.
13. A etapa muda para `preparado`. O Jarvis fala "Prévia no ar. A mensagem está pronta." e mostra as capturas.

**Regra de exclusividade das prévias**
- A assinatura tem 5 partes: modelo de topo, par de fontes, estilo de animação, sequência de seções e paleta.
- Nenhuma prévia pode repetir a assinatura inteira de outra.
- Para negócios do mesmo nicho na mesma cidade, a prévia nova precisa mudar pelo menos 3 das 5 partes em relação a todas as anteriores.
- A paleta conta como "igual" quando as cores principais são muito próximas.
- Mesmo com a mesma estrutura, o conteúdo nunca se repete: fotos, textos, avaliações e cores são do próprio negócio.

**O kit de design (o mínimo para a v1)**
- Pelo menos 8 modelos de topo: vídeo de fundo, foto grande com texto, colagem de fotos, texto grande com foto recortada, carrossel, tela dividida e outros.
- Variações de cada tipo de seção (pelo menos 3 por tipo): serviços ou cardápio, sobre ou história, galeria, avaliações, números (nota, anos, clientes), localização e horário, perguntas frequentes, chamada final.
- Pelo menos 6 estilos de animação: revelar ao rolar, paralaxe, zoom lento nas fotos, texto aparecendo por partes, contadores, avaliações em faixa contínua, transições de seção. Cada estilo define uma "personalidade" de movimento (suave, enérgico, elegante).
- Pelo menos 10 pares de fontes com personalidade, nunca Inter ou Roboto como fonte de título.
- Tudo responsivo, com celular primeiro. Animações respeitam a opção "reduzir movimento" do aparelho.
- Toda peça do kit é testada sozinha no celular e no PC antes de entrar no kit.

**Abordar**
1. O usuário clica em "Abrir no WhatsApp". O link `wa.me` abre o WhatsApp (Desktop ou Web) com o texto pronto.
2. Ao voltar para o Jarvis, aparece a pergunta "Mandou a mensagem?" (Sim / Ainda não). Com "Sim", a etapa vira `abordado` e o relógio do acompanhamento começa.
3. Sem WhatsApp provável (telefone fixo ou sem telefone), o Jarvis mostra o telefone para ligar e o link do Instagram do negócio (se houver). O usuário registra a abordagem manualmente.

**Funil e acompanhamento**
- Etapas: `encontrado` → `preparado` → `abordado` → `respondeu` → `reuniao` → `proposta` → `fechou`. A qualquer momento: `perdido`, `descartado` ou a bandeira `nao_contatar`.
- 3 dias após `abordado` sem resposta: entra na lista "cobrar hoje" com o acompanhamento 1 pronto.
- 7 dias após o acompanhamento 1 sem resposta: entra de novo com o acompanhamento 2.
- Depois do acompanhamento 2 sem resposta: o Jarvis sugere marcar como `perdido`. Nunca há um terceiro.
- O usuário muda etapas por voz ("a Barbearia X respondeu"), por clique ou arrastando o cartão.
- Painel fixo com a contagem por etapa e a meta da semana.

**Objeções**
- Um roteiro base fixo (escrito na construção) cobre: "tá caro", "já tenho Instagram", "vou pensar", "não tenho tempo", "meu sobrinho faz", "já tenho site", "não preciso, já tenho clientes".
- Para cada negócio, a IA adapta as respostas ao nicho, ao diagnóstico e ao Instagram dele.
- Por voz: "Jarvis, ele disse que tá caro" mostra e fala a resposta para o negócio aberto.

**Preço**
- Tabela de faixas por nicho e por pacote (básico, profissional, premium cinematográfico), mais manutenção mensal. A faixa sugerida aparece no cartão do negócio.
- Os valores iniciais são pesquisados na construção (preços praticados por freelancers e agências no Brasil) e ficam editáveis nas configurações.

**Modo vitrine**
- "Jarvis, apresenta os projetos" (ou um botão) passa pelas prévias publicadas, uma por vez, em destaque na tela. Para cada uma, o Jarvis fala o nome do negócio e o que o site resolve.
- Só entram prévias que o usuário marcou como "pode mostrar". O padrão é não mostrar, porque o dono do negócio não autorizou. A partir do primeiro cliente fechado, os sites reais entram aqui.

**Falhas e casos de borda**
- Uma API fora do ar ou com erro de chave: o Jarvis avisa qual parte não funciona, e o resto continua.
- Limite grátis do Gemini atingido: as mensagens caem para modelos de texto com campos preenchidos (nome, nicho, achado do diagnóstico). A direção de arte cai para uma escolha automática por regras que respeitam a exclusividade. Os textos da prévia usam frases base do nicho com o nome, o bairro e trechos das avaliações. Avisa o usuário.
- Chave da Meta vencida: as prévias seguem só com o material do Google e avisam como renovar.
- Instagram do negócio pessoal, privado ou inexistente: segue com o Google. Sem fotos boas no Google também: completa com o Pexels e avisa "esta prévia tem poucas fotos reais".
- Reel sem download liberado pelo dono: usa um modelo de topo sem vídeo.
- Cota de segurança do Google atingida: novas buscas são bloqueadas até o mês virar, com aviso claro.
- O reconhecimento de voz não entendeu: o Jarvis pede para repetir e mostra a caixa de texto.
- Negócio sem telefone: fica com "sem contato direto" e as alternativas acima.
- Busca sem resultado: sugere ampliar a cidade ou trocar o nicho.
- Conferência da prévia falhou duas vezes: não publica, mostra as capturas e o problema, e oferece "tentar outra combinação".
- Publicação da prévia falhou: tenta de novo uma vez. Se falhar de novo, mantém a prévia local e avisa.

**Avisos (efeitos colaterais)**
- Só dentro do app: o resumo falado na abertura e a lista "cobrar hoje". Nenhum e-mail ou notificação externa na v1.

### 5.4 Integrações e dependências

| Serviço | Uso | Chave | Custo e limite |
|---|---|---|---|
| Google Places API (New): Text Search | Buscar negócios e concorrentes | Chave do Google Cloud (projeto **com** faturamento) | Campos como site, telefone e nota caem no nível Enterprise: 1.000 chamadas grátis por mês. Uso previsto: cerca de 100 |
| Google Places API (New): Place Details e Place Photos | Avaliações, horário e fotos do negócio escolhido | A mesma | Avaliações caem no nível Enterprise + Atmosphere (1.000 grátis por mês). Uso previsto: cerca de 40 detalhes e 400 fotos por mês. Confirmar as cotas na construção |
| PageSpeed Insights API v5 | Testar o site no celular | A mesma | Grátis |
| Gemini API | Entender comandos, achar o @ (com busca no Google), escolher material, direção de arte, textos, mensagens, objeções | Chave do AI Studio num **projeto separado sem faturamento** | Grátis com limite por minuto e por dia |
| Instagram Graph API: Business Discovery | Bio, seguidores e posts de contas profissionais de negócios | Token da Meta: app grátis no painel de desenvolvedores, Login do Facebook para empresas, conta do Estúdio Dez profissional e ligada a uma página do Facebook | Grátis. Limite da plataforma, folgado para esse volume. O token de longa duração vence em cerca de 60 dias e precisa de renovação guiada |
| Pexels API | Completar fotos que faltarem | Chave do Pexels | Grátis |
| GitHub API | Publicar as prévias num repositório público `previas` com GitHub Pages | Token fino do GitHub, só com escrita nesse repositório | Grátis |
| WhatsApp | `https://wa.me/55DDDNUMERO?text=...` | Nenhuma | Grátis |
| Web Speech API | Ouvir (SpeechRecognition, pt-BR) e falar (speechSynthesis) | Nenhuma | Grátis. O reconhecimento usa os servidores do navegador |
| ffmpeg | Comprimir o vídeo do topo e gerar a capa | Nenhuma | Grátis. Instalado com `winget install ffmpeg` (mesmo passo da skill `site-de-10k`) |
| Navegador invisível | Conferir as prévias no celular e no PC e tirar capturas | Nenhuma | Grátis. Usa o Edge ou o Chrome já instalado no PC, sem baixar outro navegador |

**Chaves no total:** 5 (Google Cloud, Gemini, Meta, Pexels, GitHub). O assistente de configuração da primeira abertura guia e testa cada uma.

**Ponto importante sobre o Gemini:** se a chave do Gemini ficar no mesmo projeto do Google Cloud que tem faturamento (o do Maps), o uso deixa de ser grátis. Por isso são dois projetos separados.

**Ponto importante sobre o Instagram:** o Business Discovery só existe na versão da API com Login do Facebook. Ele usa o @ do negócio e não retorna o endereço de mídia de reels cujo dono desativou o download.

**Sequência:** busca no Google → classificação → teste de velocidade (só quem tem site) → o usuário escolhe → detalhes do Google → Instagram → escolha e tratamento do material → diagnóstico → direção de arte → textos → montagem e conferência → publicação → mensagens. Cada passo grava o resultado na hora. Se algo falhar no meio, o que já foi feito fica salvo e o passo pode ser refeito sozinho.

**Sem transações distribuídas:** é um app de uma pessoa, com arquivos locais. Cada escrita é atômica (grava num arquivo temporário e depois renomeia).

**Tudo sob demanda:** sem filas, sem webhooks, sem tarefas de fundo. O cálculo de "cobrar hoje" e a limpeza de prévias vencidas acontecem na abertura.

### 5.5 Não-funcionais

- **Desempenho do Jarvis:** busca com classificação em menos de 60 segundos para 20 resultados. Preparar um negócio (do clique até a prévia publicada e as mensagens) em menos de 3 minutos, com progresso visível na tela.
- **Qualidade das prévias:** passam na conferência automática no celular (390 px) e no PC (1440 px). Meta de nota de desempenho no celular de pelo menos 80 no teste do Google (fotos comprimidas, vídeo leve, fontes carregadas sem travar). Animações suaves e desligadas para quem pede "reduzir movimento".
- **Custo garantido:** no Google Cloud, limite diário de chamadas configurado no console (Places: 30 buscas e 100 fotos por dia) e alerta de orçamento de R$ 1. No app, um contador mensal que bloqueia ao chegar em 800 chamadas de cada tipo do Places.
- **Segurança e privacidade:** as chaves ficam num arquivo `.env` fora do git. O servidor só escuta `127.0.0.1`. Os dados e o material baixado ficam numa pasta local fora do git. Só se guardam dados públicos de empresas. A bandeira `nao_contatar` atende a quem pedir para sair, e apagar um negócio apaga tudo dele, incluindo a prévia publicada.
- **Prévias discretas:** cada prévia tem `noindex`, um aviso visível de que é uma demonstração do Estúdio Dez, e os créditos de origem do material. O endereço leva um trecho aleatório (por exemplo `/barbearia-x-7f3k/`). A prévia sai do ar sozinha quando o negócio vira `perdido`, `descartado` ou `nao_contatar`, e também 45 dias depois da publicação se o negócio não passou de `abordado`.
- **Uso do material do negócio:** as fotos e vídeos dele aparecem só na prévia feita para ele mesmo ver. Não entram no modo vitrine nem em divulgação sem a marcação "pode mostrar".
- **Cópia de segurança:** um botão "exportar meus dados" gera um arquivo único com tudo. O app também guarda uma cópia automática semanal na pasta de dados.
- **Concorrência:** sequencial, com no máximo 3 testes de velocidade e 4 downloads de mídia em paralelo.
- **Observabilidade:** um log local simples (arquivo) de chamadas às APIs e erros, e um painel "status dos sistemas" na interface.
- **Testes:** testes automáticos com o executor nativo do Node (`node --test`) para classificação, prioridade, leitura de telefone, links do WhatsApp, regras do funil e do acompanhamento, contador de cota, regra de exclusividade e montagem das prévias. Integrações testadas com respostas gravadas, sem chamar as APIs de verdade nos testes. Cada peça do kit tem uma página de teste conferida no celular e no PC. Um roteiro de teste manual da voz e do visual.

### 5.6 Trade-offs e suposições

**Fora do escopo:** listado na seção 2.

**Suposições**

| Suposição | Confiança |
|---|---|
| Text Search com site, telefone e nota fica no nível Enterprise, com 1.000 chamadas grátis por mês | MÉDIA: confirmar na página de preços na construção |
| Place Details com avaliações e Place Photos cabem nas cotas grátis no volume previsto | MÉDIA: confirmar na construção |
| O plano grátis do Gemini dá conta de umas 200 a 400 chamadas por semana, incluindo algumas com busca no Google | MÉDIA-ALTA |
| A maioria dos negócios locais com Instagram usa conta profissional | MÉDIA |
| O Business Discovery retorna o endereço de mídia das fotos e da maioria dos vídeos | MÉDIA: confirmar na construção |
| Um app da Meta em modo de desenvolvimento, usado só pelo próprio dono, acessa o Business Discovery sem revisão da Meta | MÉDIA: confirmar na construção |
| O reconhecimento de voz em pt-BR funciona no Chrome e no Edge no Windows | ALTA |
| O usuário aceita cadastrar cartão no Google Cloud | MÉDIA: ele disse "tudo certo" depois de ser avisado |
| Muitos negócios locais não têm site ou têm site fraco | MÉDIA-ALTA |
| Telefone celular do Google Maps costuma ter WhatsApp | MÉDIA |
| O usuário aceita as prévias num endereço `usuario.github.io/previas/...` | ALTA: ele confirmou que não tem domínio |
| Usar as fotos do próprio negócio numa prévia discreta feita para ele é aceitável | MÉDIA: risco baixo com `noindex`, endereço aleatório, remoção automática e créditos |
| A licença do Pexels permite usar as fotos em prévias | ALTA |
| O nome "Jarvis" pertence à Marvel. Sem problema para uso pessoal, mas é um risco em vídeos de marketing | ALTA: o nome do assistente fica configurável |

**Custo da complexidade:** são oito serviços externos e cinco chaves. A configuração inicial é a parte mais frágil para um iniciante. Por isso o app tem um assistente de configuração na primeira abertura, que testa cada chave e diz o que falta em linguagem simples. O Instagram é opcional para o Jarvis funcionar: sem ele, as prévias usam o Google.

**Pontos cegos**
- O Google ou a Meta podem mudar preços, cotas ou regras: o contador, os limites do console e o modo sem Instagram protegem contra isso.
- A voz do navegador varia: no Edge as vozes "Natural" em pt-BR são bem melhores. Recomendar o Edge.
- Fotos do Instagram muitas vezes têm texto por cima, baixa qualidade ou são de cliente. A escolha do material precisa filtrar bem, e o usuário pode trocar fotos antes de publicar.
- O dono pode estranhar um site pronto com o nome e as fotos dele: o aviso de demonstração e o tom da mensagem ("fiz uma amostra de como poderia ficar o site de vocês") cuidam disso.
- Montar o kit com qualidade alta é trabalho de design de verdade. A v1 só fica pronta quando o kit passa na barra "parece site profissional" na avaliação do próprio usuário.

**Como desfazer:** tudo é local. Desinstalar é apagar a pasta. As chaves podem ser revogadas nos painéis de cada serviço, e o repositório `previas` pode ser apagado no GitHub.

## 6. Decisões de "como"

**Do usuário**
- Abordagem A para o Jarvis e abordagem A (kit com IA diretora de arte) para as prévias.
- Negócios locais, custo zero, Windows, envio por um clique.
- As quatro munições (diagnóstico, prévia, mensagem, objeções), funil completo com acompanhamento.
- Visual e voz já na v1. Até 10 abordagens por semana.
- Prévias únicas para cada negócio, com o material real do Instagram e do Google, animadas, funcionando no celular e no PC.
- Marca Estúdio Dez, com uma conta nova e profissional no Instagram, ligada a uma página do Facebook.
- Sem domínio por enquanto: prévias no GitHub Pages (`usuario.github.io/previas/...`). Quando houver domínio, ele pode apontar para o GitHub Pages sem mudar o app, e por isso o endereço base das prévias fica nas configurações.

**Do Claude (o usuário pode corrigir)**
- Node.js LTS, servidor HTTP simples, interface em HTML, CSS e JavaScript puros, como no reel e na skill do usuário. Bibliotecas de visual (por exemplo Three.js para a esfera) ficam copiadas no projeto, sem build.
- Dados em arquivos JSON locais, com escrita atômica. Sem banco de dados que precise de compilação no Windows. Bibliotecas com partes nativas só se tiverem versão pronta para Windows (por exemplo, para tratar imagens).
- O app fica na pasta `jarvis/` deste repositório.
- Fala por "aperte para falar" (barra de espaço ou clique na esfera) na v1, em vez de escuta contínua. Há também uma caixa de texto para digitar.
- Acompanhamento em 3 e 7 dias, no máximo 2.
- Faixas de preço iniciais pesquisadas na construção e editáveis.
- O nome do assistente fica configurável, com "Jarvis" como padrão.
- Abrir com dois cliques num atalho `.bat`, que sobe o servidor e abre o navegador.
- Modo vitrine só com prévias marcadas como "pode mostrar".
- Endereço da prévia com trecho aleatório e remoção automática.
- Exportar dados com um botão, mais uma cópia automática semanal.
- O @ do Instagram do negócio sempre é confirmado pelo usuário com um clique antes de buscar.
- Regra de exclusividade: assinatura de 5 partes, mudança mínima de 3 partes no mesmo nicho e cidade.
- Tamanho mínimo do kit: 8 topos, 3 variações por tipo de seção, 6 estilos de animação, 10 pares de fontes.
- Conferência automática das prévias com o navegador já instalado no PC, nos tamanhos 390 px e 1440 px.

## 7. Deixado para o construtor

- O design visual exato do Jarvis dentro da direção (HUD azul escuro, esfera de partículas, painéis, sequência de inicialização), desde que seja original.
- O desenho de cada peça do kit, desde que passe na barra de qualidade e nas regras acima.
- O texto exato dos prompts da IA e dos modelos de mensagem, respeitando: mensagem curta (até cerca de 400 caracteres), um achado concreto do diagnóstico, o link da prévia, sem pressão, assinada com o nome do usuário e do Estúdio Dez.
- A estrutura de pastas e arquivos dentro de `jarvis/`.
- Os ajustes finos da regra de prioridade e dos critérios de escolha de fotos.
- A porta local e os detalhes do assistente de configuração.
- A ordem de construção, desde que o kit de prévias seja validado com o usuário cedo, porque é o que mais pesa na venda.

## 8. Próximo projeto (fora deste documento)

**Máquina de reels do Estúdio Dez:** gerar reels e publicar automaticamente na conta do Estúdio Dez, com o objetivo de atrair clientes, como no reel da Bandit Studio. A publicação automática é possível pelo caminho oficial (API de publicação de conteúdo do Instagram para contas profissionais). Será desenhado depois que o Jarvis existir, porque o Jarvis em ação e as prévias marcadas como "pode mostrar" são a matéria-prima dos reels.
