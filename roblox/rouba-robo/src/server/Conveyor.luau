--[[
	A esteira da fábrica: sorteia robôs, faz eles andarem e cuida da
	compra. Também controla a "Hora da Sorte" (grátis a cada 10 minutos,
	ou comprada por alguém para o servidor inteiro).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Game = require(script.Parent:WaitForChild("Game"))

local Conveyor = {}

local ativos = {} -- robôs na esteira, em ordem de criação
local aleatorio = Random.new()
local FRENTE = CFrame.Angles(0, -math.pi / 2, 0) -- olhando para +X (sentido da esteira)
local sorteAte = 0

function Conveyor.sorteAtual()
	if Game.agora() < sorteAte then
		return Config.SORTE.FORCA
	end
	return 1
end

-- Começa (ou estende) a sorte. quem = nome de quem pagou (nil = evento grátis)
function Conveyor.iniciarSorte(segundos, quem)
	local inicio = math.max(Game.agora(), sorteAte)
	sorteAte = inicio + segundos
	ReplicatedStorage:SetAttribute("HoraDaSorteAte", sorteAte)
	ReplicatedStorage:SetAttribute("HoraDaSortePor", quem or "")
	local restante = Game.tempoTexto(sorteAte - Game.agora())
	if quem then
		Game.notificarTodos("alerta", "sorte_presente", quem, Config.SORTE.FORCA, restante)
	else
		Game.notificarTodos("alerta", "sorte_gratis", Config.SORTE.FORCA, restante)
	end
end

function Conveyor.gerar(x)
	local esteira = Game.mundo.esteira
	x = x or esteira.inicioX
	local def, mutacaoId = Config.sortear(Conveyor.sorteAtual(), aleatorio)
	local robo = Game.novoRobo(def, mutacaoId, CFrame.new(x, esteira.y, esteira.z) * FRENTE)
	robo.x = x
	table.insert(ativos, robo)

	if def.raridade >= 5 or mutacaoId == "diamante" or mutacaoId == "arcoiris" then
		Game.notificarTodos("alerta", "saiu_fabrica", Game.nomeRobo(def, mutacaoId), Game.nomeRaridade(def.raridade))
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
		Game.notificar(player, "ruim", "base_cheia_compra")
		return
	end
	local preco = Config.precoDe(robo.def, robo.mut)
	if not Game.gastar(estado, preco) then
		Game.notificar(player, "ruim", "falta_dinheiro", Game.nomeRobo(robo.def, robo.mut), Game.dinheiroTexto(preco))
		return
	end
	Game.efeito("compra", robo.modelo:GetPivot().Position, Config.Raridades[robo.def.raridade].cor)
	Game.colocarNaBase(estado, robo, vaga, false)
	Game.notificar(player, "bom", "comprou", Game.nomeRobo(robo.def, robo.mut))
	Game.emitir(estado, "comprar", 1, { raridade = robo.def.raridade })
end

function Conveyor.quantidade()
	return #ativos
end

function Conveyor.robos()
	return ativos
end

function Conveyor.iniciar()
	Game.acoes.esteira = Conveyor.comprar
	ReplicatedStorage:SetAttribute("HoraDaSorteAte", 0)
	ReplicatedStorage:SetAttribute("HoraDaSortePor", "")

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
			task.wait(Config.SORTE.A_CADA)
			Conveyor.iniciarSorte(Config.SORTE.DURACAO, nil)
		end
	end)
end

return Conveyor
