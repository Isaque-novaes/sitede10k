# Robot Heist / Rouba Robô 🤖

Jogo de Roblox no gênero "compre, guarde e roube", o estilo dos jogos mais
jogados de novembro de 2026 (Steal An Egg está em 1º). O nome, os robôs, o
mapa e o código são originais. Só o gênero é o mesmo.

Bilíngue: quem joga em português vê **Rouba Robô**, o resto do mundo vê
**Robot Heist**. O idioma é escolhido sozinho, pelo idioma da conta.

## Como se joga

1. Cada jogador ganha uma **base**: começa com 10 vagas e vai até 20.
2. Robôs saem da **Fábrica** numa esteira. Chegue perto e aperte **E** para comprar.
3. Robôs na base geram **dinheiro por segundo**.
4. Entre na base de outro jogador e **segure E** num robô para **roubar**.
   Leve até a SUA base antes que o dono te dê um **Tapa**.
5. Pise no **botão vermelho** da sua base para **trancar** por 60 segundos.
6. Segure E num robô seu para **vender** (devolve 50%).
7. **Melhore a base** com dinheiro do jogo: mais renda (+10% por nível),
   mais vagas e tapa mais forte. A base fica mais bonita a cada nível.
8. Com $1M dá para **Renascer**: zera dinheiro e robôs, mantém as melhorias
   e dá +50% de dinheiro para sempre.

O que faz o jogador voltar: prêmio diário (7 dias seguidos), 3 missões por
dia, dinheiro ganho com o jogo fechado (até 4 h), +5% por raridade completa
no Índice, +10% por amigo no servidor, bônus do grupo e de Roblox Premium,
Hora da Sorte a cada 10 minutos e placar global dos mais ricos.

## Como abrir no Roblox Studio

1. Instale o [Roblox Studio](https://create.roblox.com/) e entre com sua conta.
2. Baixe o arquivo **`RoubaRobo.rbxlx`** desta pasta.
3. No Studio: **Arquivo > Abrir do arquivo** (*File > Open from File*).
4. Aperte **Play**. O mapa é criado sozinho quando o jogo começa.

No Studio aparecem botões de teste: "+$" (dinheiro), "Sorte" e "+1 dia"
(libera o prêmio diário, novas missões e o "bem-vindo de volta"). Eles não
funcionam no jogo publicado. A loja mostra todos os itens no Studio, mesmo
sem estarem configurados, para você ver como fica.

**Testar com 2 jogadores:** aba **Teste** (*Test*) > "Clientes e Servidores"
(*Clients and Servers*) > **2 jogadores** > **Iniciar** (*Start*).

**O jogo apareceu em inglês?** Ele segue o idioma da sua conta do Roblox.
Para ver em português, mude em roblox.com > Configurações > Informações da
conta > Idioma. É assim que os jogadores de fora vão ver o jogo.

**Se a interface ficar grande ou pequena demais:** ela encolhe sozinha em
janelas pequenas, mas você pode ajustar no começo de
`src/client/HUD.client.luau`, na linha `local ESCALA_DA_TELA = 1`
(0.8 deixa menor, 1.2 maior).

## Publicar

1. **Arquivo > Publicar no Roblox** (*File > Publish to Roblox*).
2. **Configurações do Jogo > Segurança** (*Game Settings > Security*) > ligue
   **Enable Studio Access to API Services** (para salvar nos testes do Studio).
3. **Configurações do Jogo > Lugares** (*Places*): **máximo de 8 jogadores** (são 8 bases).
4. No Creator Hub, coloque o nome **Robot Heist**, a descrição (em inglês, com
   as palavras "steal" e "robot", que ajudam nas buscas) e adicione a tradução
   em português: nome **Rouba Robô**.
5. Deixe o jogo **Público**.

## Ganhar Robux: passo a passo

No [Creator Hub](https://create.roblox.com/dashboard/creations) > seu jogo >
**Monetização**, crie os itens abaixo e copie o número (ID) de cada um para
`src/shared/Config.luau`, na parte `Config.LOJA`. Item com `id = 0` não aparece.

| Item | Tipo | Preço sugerido | Onde colar o ID |
|---|---|---|---|
| Dinheiro em dobro | Passe | 149 | `PASSES` › `dobro` |
| VIP (etiqueta, +50%, robô Épico) | Passe | 199 | `PASSES` › `vip` |
| +5 vagas | Passe | 99 | `PASSES` › `vagas` |
| Tranca longa | Passe | 49 | `PASSES` › `tranca` |
| Maleta (10 min de renda) | Produto | 25 | `PACOTES` › `maleta` |
| Cofre (1 h de renda) | Produto | 99 | `PACOTES` › `cofre` |
| Banco (4 h de renda) | Produto | 249 | `PACOTES` › `banco` |
| Sorte do servidor (15 min) | Produto | 49 | `SORTE` |
| Caixa surpresa (Épico ou melhor) | Produto | 149 | `CAIXA` |
| Anúncio com prêmio | Produto (preço qualquer) | — | `ANUNCIO` |

- Os preços na tela vêm direto do Roblox. Se você mudar o preço no site, o
  jogo mostra o novo preço sozinho.
- **Caixa surpresa:** as chances ficam visíveis (Épico 70%, Lendário 24%,
  Mítico 5%, Secreto 1%). Em países que proíbem sorteio pago, ela some sozinha.
- **Anúncio com prêmio:** o jogador assiste um anúncio do Roblox e ganha x2
  por 10 minutos (ou dobra o dinheiro offline). Você ganha com os anúncios.
  O Roblox só mostra anúncios em jogos publicados que cumprem as regras de
  anúncios da plataforma, então teste depois de publicar.
- **Grupo:** crie um grupo no Roblox (custa 100 Robux) e coloque o número em
  `Config.GRUPO.ID`. Quem entra ganha +10% e um robô Raro.
- **Roblox Premium:** assinantes ganham +10% de dinheiro, e o Roblox te paga
  pelo tempo que eles passam no jogo ("Premium Payouts"), sem configurar nada.
- Para sacar Robux em dinheiro (DevEx), o Roblox exige no mínimo 30.000 Robux
  ganhos, 13 anos ou mais e conta verificada.

Depois de colar os IDs, gere o `.rbxlx` de novo (abaixo) ou cole o `Config`
atualizado no Studio, e publique.

## Mudar o jogo

Quase tudo fica em **`src/shared/Config.luau`**: preços, renda, chances,
tempos, robôs (nome em português e inglês, cores e forma), melhorias, prêmios
diários, missões, bônus e loja. Os textos da tela estão em
**`src/shared/Textos.luau`** (português e inglês). Depois de mudar:

```
python3 ferramentas/montar_place.py
```

**Sons:** ficam em `Config.SONS`. Coloque os IDs de sons da biblioteca do
Roblox (Creator Store > Áudio). Com o plugin do Roblox no seu PC, dá para
pedir ao Claude: *"procura sons de moeda, alarme e tapa e coloca no Config.SONS"*.

## Próxima etapa (no seu PC, com o plugin do Roblox)

Com o [plugin oficial](https://github.com/Roblox/roblox-studio-agent-plugin)
no Claude Code, peça por exemplo:

- *"Dá Play com 2 jogadores, testa comprar, roubar e trancar, e corrige o que der errado."*
- *"Gera modelos 3D para os robôs Lendários, Míticos e Secretos e troca no RobotFactory."*
- *"Faz ícones para os botões e a miniatura do jogo."*

## Para quem programa

| Pasta | Vai para | O que tem |
|---|---|---|
| `src/shared/` | ReplicatedStorage/Shared | `Config` (ajustes), `Textos` (PT/EN), `Format` (números) |
| `src/server/` | ServerScriptService/Server | `Main` (liga tudo), `Game` (jogadores, bases, dinheiro, bônus, tranca, renascer), `Conveyor` (esteira, compra, sorte), `Stealing` (roubo, venda, Tapa), `Progresso` (diário, missões, offline, melhorias, Índice, amigos, grupo), `Shop` (Robux, caixa, anúncio), `Ranking` (placar global), `MapBuilder` (mapa), `RobotFactory` (robôs), `Data` (salvamento) |
| `src/client/` | StarterPlayerScripts/Client | `HUD` (interface), `Mundo` (textos do mundo, efeitos, chat VIP) |

- **Rojo:** `default.project.json` segue o mesmo mapeamento.
- **Segurança:** o servidor decide tudo (dinheiro, compras, prêmios, roubo).
  Os pedidos do jogador são conferidos e têm limite de frequência.
- **Salvamento:** `UpdateAsync` com trava de sessão (impede duplicar robôs
  trocando de servidor), versão dos dados (saves antigos são convertidos) e
  cada compra é entregue uma única vez.
- **Testes sem Studio:** `pip install lupa` e `python3 ferramentas/teste/verificar.py`.
  Roda o jogo inteiro num Roblox simulado com 4 a 12 jogadores (comprar,
  roubar, tapa, tranca, melhorias, prêmio diário, missões, offline, loja,
  anúncio, caixa, trava de sessão, falha de dados, interface nos dois
  idiomas...) e confere cada classe, propriedade e evento na API oficial do
  Roblox, todos os textos nos dois idiomas e se a interface cabe em telas de
  386x412 até 1920x1080. Hoje: 221 verificações, 0 falhas.
