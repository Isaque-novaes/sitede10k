--[[
	Rouba Robô — script principal do servidor.
	Monta o mapa, liga os sistemas e cuida da entrada e saída de jogadores.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))

local pasta = script.Parent
local MapBuilder = require(pasta:WaitForChild("MapBuilder"))
local Data = require(pasta:WaitForChild("Data"))
local Game = require(pasta:WaitForChild("Game"))
local Conveyor = require(pasta:WaitForChild("Conveyor"))
local Stealing = require(pasta:WaitForChild("Stealing"))
local Shop = require(pasta:WaitForChild("Shop"))

-- Canais de comunicação com os jogadores ------------------------------------
local remotos = Instance.new("Folder")
remotos.Name = "Remotos"
local function remoto(nome)
	local evento = Instance.new("RemoteEvent")
	evento.Name = nome
	evento.Parent = remotos
	return evento
end
local Notificar = remoto("Notificar") -- servidor -> jogador: aviso na tela
local Empurrao = remoto("Empurrao") -- servidor -> jogador: levou um tapa
local Renascer = remoto("Renascer") -- jogador -> servidor: quer renascer
local Teste = remoto("Teste") -- jogador -> servidor: botões de teste (só no Studio)
remotos.Parent = ReplicatedStorage

-- Liga os sistemas -----------------------------------------------------------
local mundo = MapBuilder.construir()
Game.iniciar(mundo, {
	Notificar = Notificar,
	Empurrao = Empurrao,
})
Conveyor.iniciar()
Stealing.iniciar()
Shop.iniciar()

local function salvar(estado)
	if estado.podeSalvar then
		Data.salvar(estado.player, Game.serializar(estado))
	end
end
Shop.aoComprar = function(estado)
	task.spawn(salvar, estado)
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
	end
end

local function aoEntrar(player)
	local dados, podeSalvar = Data.carregar(player)
	if player.Parent == nil then
		return -- saiu enquanto carregava
	end
	local estado = Game.adicionarJogador(player, dados, podeSalvar)
	if not estado then
		return
	end
	Shop.verificarPasse(estado)

	player.CharacterAdded:Connect(function(personagem)
		aoNascer(player, estado, personagem)
	end)
	if player.Character then
		task.spawn(aoNascer, player, estado, player.Character)
	end

	Game.notificar(player, "Bem-vindo ao " .. Config.NOME_DO_JOGO .. "! Compre robôs na esteira segurando E.", "info")
	Game.notificar(player, "Pise no botão vermelho da sua base para trancá-la. Use o Tapa contra ladrões!", "info")
	if not podeSalvar then
		Game.notificar(player, "Atenção: o progresso desta partida não será salvo.", "alerta")
	end
end

Players.PlayerAdded:Connect(aoEntrar)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(aoEntrar, player)
end

Players.PlayerRemoving:Connect(function(player)
	local estado, dados = Game.removerJogador(player)
	if estado and estado.podeSalvar then
		Data.salvar(player, dados)
	end
end)

game:BindToClose(function()
	local pendentes = 0
	for _, estado in pairs(Game.estados) do
		if estado.podeSalvar then
			pendentes = pendentes + 1
			task.spawn(function()
				salvar(estado)
				pendentes = pendentes - 1
			end)
		end
	end
	local limite = os.clock() + 20
	while pendentes > 0 and os.clock() < limite do
		task.wait(0.1)
	end
end)

-- Pedidos dos jogadores ------------------------------------------------------
Renascer.OnServerEvent:Connect(function(player)
	local estado = Game.estados[player]
	if estado then
		Game.renascer(estado)
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
		Game.notificar(player, "[Teste] +" .. Format.dinheiro(valor), "info")
	elseif acao == "sorte" then
		Conveyor.iniciarHoraDaSorte()
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
		task.wait(120)
		for _, estado in pairs(Game.estados) do
			task.spawn(salvar, estado)
		end
	end
end)

print("[Rouba Robô] Servidor pronto!")
