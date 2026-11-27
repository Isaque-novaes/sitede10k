# Elemental Legends / Lendas Elementais ⚡

Jogo de Roblox de **mundo aberto, luta com poderes elementais e cada um
por si**, no estilo do Blox Fruits. Você bate em monstros, sobe de nível,
aprende elementos novos e, nas zonas mais fortes, pode enfrentar outros
jogadores.

Bilíngue: quem joga em português vê **Lendas Elementais**, o resto do
mundo vê **Elemental Legends**. O idioma é escolhido sozinho, pela conta.

## Como se joga

1. **Clique** para lançar o golpe básico. **Q** e **E** são os especiais
   (no celular, os três botões ficam embaixo da tela).
2. Derrote monstros para ganhar **XP** e **moedas**.
3. Suba de nível: ganha vida e dano, e libera elementos novos.
4. Com moedas, **aprenda elementos** e **melhore** vida, dano e velocidade.
5. Use os **portais da Vila Central** para viajar às zonas mais fortes.
6. **Zona azul = segura.** Ninguém pode te atacar.
   **Zona vermelha = PvP.** Os monstros dão mais XP, mas outros jogadores
   podem te derrubar.
7. **Morrer não tira nada de você.** Quem te derrubou ganha um prêmio pago
   pelo jogo, e você volta em 4 segundos com a vida cheia.
8. Cada zona tem um **chefe**, que dá 15x mais XP e moedas.

## As zonas

| Zona | Nível | PvP | Monstros | Chefe |
|---|---|---|---|---|
| Vila Central | — | Não | bonecos de treino | — |
| Campo Verde | 1 | Não | Limo Verde, Cogumelo Bravo | Rei Limo |
| Deserto em Chamas | 12 | **Sim** | Diabrete de Fogo, Escorpião de Lava | Senhor das Chamas |
| Pico Gelado | 30 | **Sim** | Golem de Gelo, Lobo da Neve | Titã Congelado |
| Ruínas Sombrias | 55 | **Sim** | Espectro, Guardião Sombrio | Devorador de Almas |

## Os elementos

Cada um tem 3 golpes: básico (clique), especial (Q) e supremo (E).

| Elemento | Nível | Preço | O que tem de diferente |
|---|---|---|---|
| 🔥 Fogo | 1 | grátis | Equilibrado. Explosão em área e chuva de meteoros |
| ❄️ Gelo | 5 | 500 | Mais dano, mas mais lento. Deixa o inimigo lento |
| ⚡ Raio | 15 | 3.000 | Tiros rápidos e fracos. Avanço elétrico e tempestade |
| 🪨 Pedra | 30 | 15.000 | Pedregulho pesado, escudo que corta metade do dano, terremoto |
| 🌪️ Vento | 50 | 60.000 | 3 lâminas por vez, impulso para pular alto, tornado |
| 🌑 Sombra | 75 | 250.000 | Míssil teleguiado, ficar invisível, fenda sombria |

Os elementos não são "um melhor que o outro": são jeitos diferentes de
lutar. Quem tem mais elementos ganha +3% de XP por elemento.

## Como abrir no Roblox Studio

1. Instale o [Roblox Studio](https://create.roblox.com/) e entre com sua conta.
2. Baixe o arquivo **`LendasElementais.rbxlx`** desta pasta.
3. No Studio: **Arquivo > Abrir do arquivo** (*File > Open from File*).
4. Aperte **Play**. O mundo é criado sozinho quando o jogo começa.

No Studio aparecem dois botões de teste: **"+XP"** (sobe rápido de nível e
dá moedas) e **"+1 dia"** (libera o prêmio diário e missões novas). Eles
não funcionam no jogo publicado. A loja mostra todos os itens no Studio
mesmo sem IDs configurados, só para você ver como fica.

**Testar com 2 jogadores:** aba **Teste** (*Test*) > "Clientes e Servidores"
(*Clients and Servers*) > **2 jogadores** > **Iniciar** (*Start*).

**Ver em português:** o jogo segue o idioma da sua conta do Roblox
(roblox.com > Configurações > Informações da conta > Idioma).

**Interface grande ou pequena demais:** ela encolhe sozinha em janelas
pequenas. Para ajustar, mude `UI.ESCALA_DA_TELA` no começo de
`src/shared/UI.luau` (0.8 menor, 1.2 maior).

## Publicar

1. **Arquivo > Publicar no Roblox** (*File > Publish to Roblox*).
2. **Configurações do Jogo > Segurança** > ligue **Enable Studio Access to
   API Services** (para salvar nos testes do Studio).
3. **Configurações do Jogo > Lugares**: o mundo aguenta bem até uns
   **20 jogadores** por servidor.
4. No Creator Hub, use o nome **Elemental Legends** e adicione a tradução
   em português: **Lendas Elementais**. Na descrição em inglês, vale usar
   palavras muito buscadas como *elemental*, *powers*, *magic* e *open world*.
5. Deixe o jogo **Público**.

## Ganhar Robux

**A regra deste jogo: nada que se compra deixa o jogador mais forte na
luta.** Num jogo de PvP, vender poder faz quem não paga ir embora, e aí não
sobra ninguém para pagar. Aqui o Robux compra só XP e moedas mais rápido,
e visual.

No [Creator Hub](https://create.roblox.com/dashboard/creations) > seu jogo
> **Monetização**, crie os itens e cole os números (ID) em
`src/shared/Config.luau`, na parte `Config.LOJA`. Item com `id = 0` não aparece.

| Item | Tipo | Preço sugerido | Onde colar o ID |
|---|---|---|---|
| XP em dobro | Passe | 149 | `PASSES` › `xp2` |
| Moedas em dobro | Passe | 149 | `PASSES` › `moedas2` |
| VIP (etiqueta, aura dourada, +25%) | Passe | 299 | `PASSES` › `vip` |
| Pacote de auras | Passe | 99 | `PASSES` › `aura` |
| Bolsa de moedas (5.000) | Produto | 25 | `PACOTES` › `bolsa` |
| Baú de moedas (25.000) | Produto | 99 | `PACOTES` › `bau` |
| Tesouro (80.000) | Produto | 249 | `PACOTES` › `tesouro` |
| Anúncio com prêmio | Produto (preço qualquer) | — | `ANUNCIO` |

- Os preços na tela vêm do Roblox: se mudar no site, o jogo acompanha.
- **Anúncio com prêmio:** o jogador assiste um anúncio e ganha XP em dobro
  por 10 minutos. Você ganha com o anúncio, inclusive de quem nunca gasta
  Robux. Só funciona em jogo publicado e aprovado nas regras de anúncios.
- **Grupo:** crie um grupo (custa 100 Robux) e coloque o número em
  `Config.GRUPO.ID`. Quem entra ganha +10% e 2.000 moedas.
- **Roblox Premium:** assinantes ganham +10%, e o Roblox te paga pelo tempo
  que eles passam no jogo, sem configurar nada.
- Para sacar Robux em dinheiro (DevEx): mínimo de 30.000 Robux ganhos,
  13 anos ou mais e conta verificada.

## Mudar o jogo

Quase tudo está em **`src/shared/Config.luau`**: níveis, vida, dano,
elementos e seus golpes, zonas, monstros, chefes, melhorias, prêmios,
missões, bônus e loja. Os textos ficam em **`src/shared/Textos.luau`**
(português e inglês). Depois de mudar:

```
python3 ../ferramentas/montar_place.py lendas-elementais
```

**Sons:** ficam em `Config.SONS`, vazios por enquanto. Coloque IDs de sons
da biblioteca do Roblox (Creator Store > Áudio).

## Próxima etapa (no seu PC, com o plugin do Roblox)

Com o [plugin oficial](https://github.com/Roblox/roblox-studio-agent-plugin)
no Claude Code, dá para pedir:

- *"Dá Play, mata uns monstros no Campo Verde e corrige o que estiver estranho."*
- *"Gera modelos 3D para os chefes e troca no Monstros.luau."*
- *"Procura sons de magia, acerto e subir de nível e coloca no Config.SONS."*
- *"Faz animações de ataque para o personagem."*

## Para quem programa

| Pasta | Vai para | O que tem |
|---|---|---|
| `src/shared/` | ReplicatedStorage/Shared | `Config` (todos os ajustes), `Textos` (PT/EN), `Format` (números), `UI` (peças de interface) |
| `src/server/` | ServerScriptService/Server | `Main` (liga tudo), `Jogador` (nível, XP, vida, zonas, morte), `Combate` (golpes, tiros, dano), `Monstros` (IA, chefes), `Mundo` (mapa por código), `Loja` (moedas), `Robux` (passes, produtos, anúncio), `Progresso` (diário, missões, PvP, bônus), `Ranking`, `Data` (salvamento) |
| `src/client/` | StarterPlayerScripts/Client | `HUD` (barras e painéis), `Combate` (mira, botões, recarga), `Mundo` (textos, efeitos, portais) |

- **Segurança:** o servidor decide tudo. O jogador só manda "quero usar o
  golpe 2 nesta direção"; o servidor confere vida, recarga e direção, e os
  tiros existem só no servidor, então ninguém forja um acerto. Todo pedido
  tem limite de frequência.
- **Salvamento:** `UpdateAsync` com trava de sessão (impede duplicar coisas
  trocando de servidor), versão dos dados e cada compra entregue uma vez só.
- **Monstros:** não usam o sistema de personagem do Roblox. São peças
  movidas pelo servidor, o que fica bem mais leve e não precisa de rig.
- **Testes sem Studio:** `pip install lupa` e
  `python3 ../ferramentas/teste/verificar.py lendas-elementais`.
  Roda o jogo inteiro num Roblox simulado: atacar bonecos e monstros,
  subir de nível, comprar e equipar elementos, golpes especiais (escudo,
  invisibilidade, terremoto), melhorias, portais, PvP com recompensa,
  monstros perseguindo e matando, chefes, missões, prêmio diário, loja,
  anúncio, trava de sessão, falha de dados e a tela nos dois idiomas em
  quatro tamanhos. Hoje: **173 verificações, 0 falhas**.
