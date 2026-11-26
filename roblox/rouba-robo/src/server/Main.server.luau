--[[
	Robot Heist / Rouba Robô — script principal do servidor.
	Monta o mapa, liga os sistemas e cuida da entrada e saída de jogadores.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Textos = require(Shared:WaitForChild("Textos"))

local pasta = script.Parent
local MapBuilder = require(pasta:WaitForChild("MapBuilder"))
local Data = require(pasta:WaitForChild("Data"))
local Game = require(pasta:WaitForChild("Game"))
local Conveyor = require(pasta:WaitForChild("Conveyor"))
local Stealing = require(pasta:WaitForChild("Stealing"))
local Progresso = require(pasta:WaitForChild("Progresso"))
local Shop = require(pasta:WaitForChild("Shop"))
local Ranking = require(pasta:WaitForChild("Ranking"))

-- Canais de comunicação com os jogadores ------------------------------------
local remotos = Instance.new("Folder")
remotos.Name = "Remotos"
local function remoto(nome)
	local evento = Instance.new("RemoteEvent")
	evento.Name = nome
	evento.Parent = remotos
	return evento
end
-- servidor -> jogador
local Notificar = remoto("Notificar")
local Empurrao = remoto("Empurrao")
local Efeito = remoto("Efeito")
-- jogador -> servidor (o servidor sempre confere tudo)
local Renascer = remoto("Renascer")
local Melhorar = remoto("Melhorar")
local PegarDiario = remoto("PegarDiario")
local PegarMissao = remoto("PegarMissao")
local ColetarOffline = remoto("ColetarOffline")
local VerAnuncio = remoto("VerAnuncio")
local Teste = remoto("Teste") -- botões de teste (só funcionam no Studio)
remotos.Parent = ReplicatedStorage

-- Liga os sistemas -----------------------------------------------------------
local mundo = MapBuilder.construir()
Game.iniciar(mundo, {
	Notificar = Notificar,
	Empurrao = Empurrao,
	Efeito = Efeito,
})
Conveyor.iniciar()
Stealing.iniciar()
Progresso.iniciar()
Shop.iniciar()

local function salvar(estado, liberar)
	if estado.podeSalvar then
		Data.salvar(estado.player, Game.serializar(estado), liberar)
		Ranking.registrar(estado.player, estado.totalGanho)
	end
end
Shop.aoComprar = function(estado)
	task.spawn(salvar, estado, false)
end

-- Limite de pedidos por jogador (contra quem dispara remotos sem parar) -----
local ultimosPedidos = {}
local function permitir(player, nome, intervalo)
	local porJogador = ultimosPedidos[player]
	if not porJogador then
		porJogador = {}
		ultimosPedidos[player] = porJogador
	end
	local agora = os.clock()
	if porJogador[nome] and agora - porJogador[nome] < intervalo then
		return false
	end
	porJogador[nome] = agora
	return true
end

-- Etiqueta VIP em cima da cabeça
function Game.etiquetaVip(estado)
	local personagem = estado.player.Character
	local cabeca = personagem and personagem:FindFirstChild("Head")
	if not estado.passes.vip or not cabeca or cabeca:FindFirstChild("EtiquetaVip") then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "EtiquetaVip"
	gui.Size = UDim2.fromOffset(80, 30)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	gui.Adornee = cabeca
	local texto = Instance.new("TextLabel")
	texto.Size = UDim2.fromScale(1, 1)
	texto.BackgroundTransparency = 1
	texto.Font = Enum.Font.LuckiestGuy
	texto.TextScaled = true
	texto.Text = "VIP"
	texto.TextColor3 = Color3.fromRGB(255, 216, 77)
	texto.TextStrokeTransparency = 0
	texto.TextStrokeColor3 = Color3.fromRGB(20, 23, 43)
	texto.Parent = gui
	gui.Parent = cabeca
end

-- Jogadores ------------------------------------------------------------------
local function aoNascer(player, estado, personagem)
	local humanoid = personagem:WaitForChild("Humanoid", 10)
	local raiz = personagem:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not raiz then
		return
	end
	humanoid.WalkSpeed = Config.ROUBO.VELOCIDADE_NORMAL
	task.wait(0.1) -- deixa o Roblox terminar de posicionar o personagem
	if Game.estados[player] == estado and personagem.Parent then
		personagem:PivotTo(estado.base.nascer)
		Stealing.darTapa(player)
		Game.etiquetaVip(estado)
	end
end

local function aoEntrar(player)
	local dados, situacao = Data.carregar(player)
	if player.Parent == nil then
		-- saiu enquanto carregava: solta a trava para não travar o próximo servidor
		if situacao == "ok" then
			Data.salvar(player, dados, true)
		end
		return
	end
	local idioma = Textos.idiomaDe(player.LocaleId)
	if situacao == "falha" or situacao == "ocupado" then
		player:Kick(Textos.t(idioma, situacao == "ocupado" and "dados_ocupados" or "dados_falha"))
		return
	end
	local podeSalvar = situacao == "ok"
	local estado = Game.adicionarJogador(player, dados, podeSalvar)
	if not estado then
		if podeSalvar then
			Data.salvar(player, dados, true)
		end
		return
	end

	Shop.verificarPasses(estado)
	Shop.verificarPolitica(estado)
	if Game.estados[player] ~= estado then
		return -- saiu durante a verificação (já foi salvo ao sair)
	end
	Game.restaurarRobos(estado)
	Shop.aplicarPasses(estado)
	Progresso.aoEntrar(estado)

	player.CharacterAdded:Connect(function(personagem)
		aoNascer(player, estado, personagem)
	end)
	if player.Character then
		task.spawn(aoNascer, player, estado, player.Character)
	end

	Game.notificar(player, "info", "bemvindo")
	Game.notificar(player, "info", "dica_tranca")
	if not podeSalvar then
		Game.notificar(player, "alerta", "nao_salva")
	end
end

Players.PlayerAdded:Connect(aoEntrar)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(aoEntrar, player)
end

Players.PlayerRemoving:Connect(function(player)
	ultimosPedidos[player] = nil
	local estadoAtual = Game.estados[player]
	if estadoAtual then
		Progresso.aoSair(estadoAtual)
	end
	local estado, dados = Game.removerJogador(player)
	if estado then
		task.spawn(Progresso.atualizarAmigos)
		if estado.podeSalvar then
			Data.salvar(player, dados, true)
			Ranking.registrar(player, estado.totalGanho)
		end
	end
end)

game:BindToClose(function()
	local pendentes = 0
	for _, estado in pairs(Game.estados) do
		if estado.podeSalvar then
			pendentes = pendentes + 1
			task.spawn(function()
				Progresso.aoSair(estado)
				salvar(estado, true)
				pendentes = pendentes - 1
			end)
		end
	end
	local limite = os.clock() + (RunService:IsStudio() and 3 or 25)
	while pendentes > 0 and os.clock() < limite do
		task.wait(0.1)
	end
end)

-- Pedidos dos jogadores ------------------------------------------------------
local function estadoDe(player, nome, intervalo)
	if not permitir(player, nome, intervalo) then
		return nil
	end
	return Game.estados[player]
end

Renascer.OnServerEvent:Connect(function(player)
	local estado = estadoDe(player, "Renascer", 1)
	if estado then
		Game.renascer(estado)
	end
end)

Melhorar.OnServerEvent:Connect(function(player, tipo)
	local estado = estadoDe(player, "Melhorar", 0.25)
	if estado and type(tipo) == "string" then
		Progresso.melhorar(estado, tipo)
	end
end)

PegarDiario.OnServerEvent:Connect(function(player)
	local estado = estadoDe(player, "PegarDiario", 1)
	if estado then
		Progresso.pegarDiario(estado)
	end
end)

PegarMissao.OnServerEvent:Connect(function(player, indice)
	local estado = estadoDe(player, "PegarMissao", 0.5)
	if estado and type(indice) == "number" then
		Progresso.pegarMissao(estado, indice)
	end
end)

ColetarOffline.OnServerEvent:Connect(function(player)
	local estado = estadoDe(player, "ColetarOffline", 1)
	if estado then
		Progresso.coletarOffline(estado, false)
	end
end)

VerAnuncio.OnServerEvent:Connect(function(player, motivo)
	local estado = estadoDe(player, "VerAnuncio", 5)
	if estado and type(motivo) == "string" then
		Shop.verAnuncio(estado, motivo)
	end
end)

Teste.OnServerEvent:Connect(function(player, acao)
	if not RunService:IsStudio() then
		return -- os botões de teste só funcionam no Roblox Studio
	end
	local estado = Game.estados[player]
	if not estado then
		return
	end
	if acao == "dinheiro" then
		local valor = math.max(1000000, Game.rendaPorSegundo(estado) * 600)
		Game.adicionarDinheiro(estado, valor)
		Game.notificar(player, "info", "teste_dinheiro", Game.dinheiroTexto(valor))
	elseif acao == "sorte" then
		Conveyor.iniciarSorte(Config.SORTE.DURACAO, nil)
	elseif acao == "dia" then
		-- finge que é outro dia: libera o prêmio diário e novas missões
		estado.dados.diario.ultimoDia = Progresso.diaAtual() - 1
		estado.dados.missoes.dia = -1
		estado.diaMissoes = nil
		estado.offlinePendente = math.floor(math.max(1000, Game.rendaPorSegundo(estado) * 600))
		player:SetAttribute("OfflinePendente", estado.offlinePendente)
		Progresso.atualizarAtributos(estado)
	end
end)

-- Laços do jogo --------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(1)
		Game.pagarRenda()
	end
end)

task.spawn(function()
	while true do
		task.wait(0.2)
		Game.vigiarBases()
		Stealing.vigiar()
	end
end)

task.spawn(function()
	while true do
		task.wait(60)
		Progresso.cadaMinuto()
	end
end)

task.spawn(function()
	task.wait(5)
	while true do
		Ranking.atualizar(mundo.ranking)
		task.wait(120)
	end
end)

task.spawn(function()
	while true do
		task.wait(90)
		for _, estado in pairs(Game.estados) do
			task.spawn(salvar, estado, false)
		end
	end
end)

print("[Robot Heist] Servidor pronto!")
