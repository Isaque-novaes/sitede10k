--[[
	A esteira da fábrica: sorteia robôs, faz eles andarem e cuida da
	compra. Também controla o evento "Hora da Sorte".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Game = require(script.Parent:WaitForChild("Game"))

local Conveyor = {}

local ativos = {} -- robôs na esteira, em ordem de criação
local aleatorio = Random.new()
local FRENTE = CFrame.Angles(0, -math.pi / 2, 0) -- olhando para +X (sentido da esteira)
local sorteAte = 0

function Conveyor.sorteAtual()
	if os.clock() < sorteAte then
		return Config.HORA_DA_SORTE.SORTE
	end
	return 1
end

function Conveyor.iniciarHoraDaSorte()
	local duracao = Config.HORA_DA_SORTE.DURACAO
	sorteAte = os.clock() + duracao
	ReplicatedStorage:SetAttribute("HoraDaSorteAte", workspace:GetServerTimeNow() + duracao)
	Game.notificarTodos("HORA DA SORTE! Robôs raros saem " .. Config.HORA_DA_SORTE.SORTE
		.. "x mais da fábrica por " .. Format.tempo(duracao) .. "!", "alerta")
end

function Conveyor.gerar(x)
	local esteira = Game.mundo.esteira
	x = x or esteira.inicioX
	local def, mutacaoId = Config.sortear(Conveyor.sorteAtual(), aleatorio)
	local robo = Game.novoRobo(def, mutacaoId, CFrame.new(x, esteira.y, esteira.z) * FRENTE)
	robo.x = x
	table.insert(ativos, robo)

	local raridade = Config.Raridades[def.raridade]
	if def.raridade >= 5 or mutacaoId == "diamante" or mutacaoId == "arcoiris" then
		Game.notificarTodos("Saiu da fábrica: " .. Config.nomeCompleto(def, mutacaoId)
			.. " (" .. raridade.nome .. ")! Corre!", "alerta")
	end
	return robo
end

function Conveyor.passo(dt)
	local esteira = Game.mundo.esteira
	local distancia = Config.ESTEIRA.VELOCIDADE * dt
	for i = #ativos, 1, -1 do
		local robo = ativos[i]
		if robo.estado ~= "esteira" then
			table.remove(ativos, i)
		else
			robo.x = robo.x + distancia
			if robo.x >= esteira.fimX then
				table.remove(ativos, i)
				Game.destruirRobo(robo)
			else
				robo.modelo:PivotTo(CFrame.new(robo.x, esteira.y, esteira.z) * FRENTE)
			end
		end
	end
end

function Conveyor.comprar(robo, player)
	local estado = Game.estados[player]
	if not estado or robo.estado ~= "esteira" then
		return
	end
	local vaga = Game.vagaLivre(estado)
	if not vaga then
		Game.notificar(player, "Sua base está cheia! Segure E num robô seu para vender e abrir espaço.", "ruim")
		return
	end
	local preco = Config.precoDe(robo.def, robo.mut)
	if not Game.gastar(estado, preco) then
		Game.notificar(player, "Falta dinheiro: " .. Config.nomeCompleto(robo.def, robo.mut)
			.. " custa " .. Format.dinheiro(preco) .. ".", "ruim")
		return
	end
	Game.colocarNaBase(estado, robo, vaga, false)
	Game.notificar(player, "Você comprou " .. Config.nomeCompleto(robo.def, robo.mut) .. "!", "bom")
end

function Conveyor.quantidade()
	return #ativos
end

function Conveyor.robos()
	return ativos
end

function Conveyor.iniciar()
	Game.acoes.esteira = Conveyor.comprar

	-- já começa com a esteira cheia, para ninguém esperar
	local esteira = Game.mundo.esteira
	local espaco = Config.ESTEIRA.VELOCIDADE * Config.ESTEIRA.INTERVALO
	local x = esteira.fimX - espaco
	while x > esteira.inicioX do
		Conveyor.gerar(x)
		x = x - espaco
	end

	RunService.Heartbeat:Connect(Conveyor.passo)

	task.spawn(function()
		while true do
			Conveyor.gerar()
			task.wait(Config.ESTEIRA.INTERVALO)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Config.HORA_DA_SORTE.A_CADA)
			Conveyor.iniciarHoraDaSorte()
		end
	end)
end

return Conveyor
