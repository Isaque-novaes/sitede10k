# Rouba Robô 🤖

Um jogo de Roblox no gênero "compre, guarde e roube", o mesmo estilo dos
jogos mais jogados de novembro de 2026 (Steal An Egg está em 1º). O nome,
os robôs, o mapa e o código são originais. Só o gênero é o mesmo.

## Como se joga

1. Cada jogador ganha uma **base** com 10 pedestais.
2. Robôs saem da **Fábrica** numa esteira. Chegue perto e aperte **E** para comprar.
3. Robôs na sua base geram **dinheiro por segundo**.
4. Entre na base de outro jogador e **segure E** num robô para **roubar**.
   Ele vai para a sua cabeça e você fica mais lento. Leve até a SUA base.
5. Para se defender, use o **Tapa**: um tapa em quem está roubando faz o robô voltar.
6. Pise no **botão vermelho** da sua base para **trancar** por 60 segundos.
7. Segure E num robô seu para **vender** (devolve 50% do preço).
8. Com $1M você pode **Renascer**: zera tudo, mas ganha +50% de dinheiro para sempre.

Extras: 21 robôs em 7 raridades (Comum até Secreto), mutações (Dourado x2,
Diamante x4, Arco-íris x8), **Hora da Sorte** a cada 10 minutos, **Índice**
de robôs descobertos, placar, progresso salvo e loja opcional com Robux.

## Como abrir no Roblox Studio (jeito fácil)

1. Instale o [Roblox Studio](https://create.roblox.com/) e entre com sua conta.
2. Baixe o arquivo **`RoubaRobo.rbxlx`** desta pasta.
3. No Studio: **Arquivo > Abrir do arquivo** (*File > Open from File*) e escolha o `RoubaRobo.rbxlx`.
4. Aperte **Play**. O mapa é criado sozinho quando o jogo começa.

No Studio aparecem dois botões a mais ("Teste: +$" e "Teste: Sorte"),
para você testar sem esperar. Eles não funcionam no jogo publicado.

### Testar o roubo com 2 jogadores

Aba **Teste** (*Test*) > em "Clientes e Servidores" (*Clients and Servers*) escolha **2 jogadores** > **Iniciar** (*Start*).
Abrem duas janelas, uma para cada jogador.

### Testar com o Claude conectado ao Studio (plugin oficial do Roblox)

O plugin [Roblox Studio](https://github.com/Roblox/roblox-studio-agent-plugin)
conecta o Claude Code ao Studio aberto no seu computador. Com ele o Claude
consegue apertar Play, ler o console, tirar print da tela e corrigir os
scripts direto no seu place. Só funciona no Claude Code instalado no seu
Mac ou PC (não funciona no Claude pela web nem em sessões na nuvem).

1. No Claude Code do seu computador, rode `/plugin`, procure **Roblox Studio** e instale.
2. Abra o `RoubaRobo.rbxlx` no Studio.
3. No Studio: **Assistant → … → Settings → MCP Servers** → ligue **Enable Studio as MCP server**.
4. Volte ao Claude Code e peça: *"lista minhas janelas do Roblox Studio"*. Ele deve mostrar o Rouba Robô.
5. Depois peça, por exemplo: *"Dá Play no Rouba Robô, compra um robô na esteira,
   olha o console e corrige qualquer erro. Depois tira um print da minha base."*

Antes de mudanças grandes, salve uma cópia do place: o plugin altera o place direto.

## Publicar

1. **Arquivo > Publicar no Roblox** (*File > Publish to Roblox*) e dê um nome ao jogo.
2. **Configurações do Jogo > Segurança** (*Game Settings > Security*) > ligue **Enable Studio Access to API Services**.
   Sem isso o progresso não é salvo nos testes do Studio. No jogo publicado ele salva normalmente.
3. Em **Configurações do Jogo > Lugares** (*Places*), coloque **máximo de 8 jogadores** por servidor
   (o mapa tem 8 bases).
4. Deixe o jogo **Público** quando quiser que outras pessoas joguem.

## Ganhar Robux (opcional)

1. No [Creator Hub](https://create.roblox.com/dashboard/creations), entre no jogo >
   **Monetização** e crie:
   - um **Passe** "Dinheiro em dobro"
   - um ou dois **Produtos de Desenvolvedor** (pacotes de dinheiro)
2. Copie os números (IDs) e cole em `src/shared/Config.luau`, na parte `Config.Loja`.
3. Gere o `.rbxlx` de novo (veja abaixo) ou cole o `Config` atualizado no Studio.

O botão **Loja** só aparece quando há pelo menos um ID configurado.

## Mudar o jogo

Quase tudo fica em **`src/shared/Config.luau`**: preços, renda, chances de cada
raridade, tempo da tranca, força do tapa, custo do renascimento, intervalo da
Hora da Sorte e a lista de robôs (nome, cores, forma). Mude os números e
gere o `.rbxlx` de novo:

```
python3 ferramentas/montar_place.py
```

## Para quem programa

| Pasta | Vai para | O que tem |
|---|---|---|
| `src/shared/` | ReplicatedStorage/Shared | `Config` (ajustes e robôs), `Format` (números na tela) |
| `src/server/` | ServerScriptService/Server | `Main` (liga tudo), `Game` (jogadores, bases, dinheiro, tranca, renascer), `Conveyor` (esteira e compra), `Stealing` (roubo, venda e Tapa), `MapBuilder` (mapa por código), `RobotFactory` (modelos dos robôs), `Data` (salvamento), `Shop` (Robux) |
| `src/client/` | StarterPlayerScripts/Client | `HUD` (interface), `Efeitos` (texto do E, empurrão, arco-íris) |

- **Rojo:** o `default.project.json` segue o mesmo mapeamento (`rojo serve` ou `rojo build -o RoubaRobo.rbxlx`).
- **Testes sem Studio:** `pip install lupa` e depois `python3 ferramentas/teste/verificar.py`.
  O script checa a sintaxe e roda o jogo inteiro num Roblox simulado
  (2–9 jogadores comprando, roubando, levando tapa, trancando, vendendo,
  renascendo, saindo e voltando). Cada classe, propriedade, evento e enum
  é conferido na API oficial do Roblox. Hoje: 127 verificações, 0 falhas.
- O servidor decide tudo (compra, roubo, dinheiro). O cliente só mostra a tela
  e pede "renascer". Assim, ninguém consegue trapacear mandando dados falsos.

## Próximas ideias

- Sons (compra, alarme de roubo, tapa) e animação do tapa
- Mais robôs e um evento por semana
- Melhorias de base (mais vagas, tranca mais longa) compradas com dinheiro do jogo
- Ranking global de dinheiro (OrderedDataStore)
- Ícone e miniatura do jogo para a página do Roblox
