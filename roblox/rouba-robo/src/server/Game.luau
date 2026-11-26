--[[
	O coração do jogo no servidor: jogadores, bases, vagas, robôs,
	dinheiro, renda, tranca da base e renascimento.

	Estados de um robô:
	  "esteira"   andando na esteira, à venda
	  "voando"    indo para uma base (animação)
	  "base"      parado num pedestal, gerando dinheiro
	  "carregado" na cabeça de um ladrão
	  "destruido" já saiu do jogo

	Os módulos Conveyor e Stealing registram em Game.acoes o que acontece
	quando alguém segura E num robô em cada estado.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local MapBuilder = require(script.Parent:WaitForChild("MapBuilder"))
local RobotFactory = require(script.Parent:WaitForChild("RobotFactory"))

local Game = {}

Game.estados = {} -- [Player] = estado do jogador
Game.mundo = nil
Game.remotos = nil
Game.acoes = {} -- [estadoDoRobo] = function(robo, player)

-- ganchos preenchidos pelo Stealing
Game.aoDestruirCarregado = nil -- function(robo)
Game.aoSairComCarga = nil -- function(estadoLadrao)

local MAIOR_INTEIRO = 9e18

local function agora()
	return workspace:GetServerTimeNow()
end

function Game.iniciar(mundo, remotos)
	Game.mundo = mundo
	Game.remotos = remotos
end

-- Avisos na tela ---------------------------------------------------------------

-- tipo: "bom", "ruim", "alerta" ou "info"
function Game.notificar(player, texto, tipo)
	Game.remotos.Notificar:FireClient(player, texto, tipo or "info")
end

function Game.notificarTodos(texto, tipo)
	Game.remotos.Notificar:FireAllClients(texto, tipo or "info")
end

-- Robôs ------------------------------------------------------------------------

function Game.novoRobo(def, mutacaoId, cframe)
	local visual = RobotFactory.construir(def, mutacaoId)
	local robo = {
		def = def,
		mut = mutacaoId,
		modelo = visual.modelo,
		prompt = visual.prompt,
		visual = visual,
		estado = "esteira",
		dono = nil,
		vaga = nil,
		ladrao = nil,
		voo = 0,
	}
	visual.prompt.Triggered:Connect(function(player)
		local acao = Game.acoes[robo.estado]
		if acao then
			acao(robo, player)
		end
	end)
	visual.modelo:PivotTo(cframe)
	visual.modelo.Parent = Game.mundo.pastaRobos
	return robo
end

function Game.valorVenda(robo)
	return math.floor(Config.precoDe(robo.def, robo.mut) * Config.VENDA_DEVOLVE)
end

-- Anima o robô num arco até `alvo`. Um voo novo cancela o anterior.
function Game.voar(robo, alvo, aoTerminar)
	robo.voo = robo.voo + 1
	local meuVoo = robo.voo
	local inicio = robo.modelo:GetPivot()
	local distancia = (inicio.Position - alvo.Position).Magnitude
	local duracao = math.clamp(distancia / 70, 0.6, 2)
	local altura = math.clamp(distancia * 0.25, 4, 30)

	task.spawn(function()
		local comeco = os.clock()
		while true do
			if robo.voo ~= meuVoo or robo.modelo.Parent == nil then
				return
			end
			local t = math.min((os.clock() - comeco) / duracao, 1)
			robo.modelo:PivotTo(inicio:Lerp(alvo, t) + Vector3.new(0, altura * 4 * t * (1 - t), 0))
			if t >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
		if aoTerminar then
			aoTerminar()
		end
	end)
end

function Game.destruirRobo(robo)
	if robo.estado == "destruido" then
		return
	end
	if robo.estado == "carregado" and Game.aoDestruirCarregado then
		Game.aoDestruirCarregado(robo)
	end
	local dono = robo.dono
	if dono and robo.vaga and dono.vagas[robo.vaga] == robo then
		dono.vagas[robo.vaga] = nil
	end
	robo.estado = "destruido"
	robo.voo = robo.voo + 1
	robo.dono = nil
	robo.vaga = nil
	robo.modelo:Destroy()
	if dono then
		Game.atualizarAtributos(dono)
	end
end

-- Vagas e bases ---------------------------------------------------------------

function Game.vagaLivre(estado)
	for vaga = 1, Config.VAGAS_POR_BASE do
		if estado.vagas[vaga] == nil then
			return vaga
		end
	end
	return nil
end

-- Põe o robô na vaga do jogador. instantaneo = sem animação (ao carregar).
function Game.colocarNaBase(estado, robo, vaga, instantaneo)
	estado.vagas[vaga] = robo
	robo.dono = estado
	robo.vaga = vaga
	robo.ladrao = nil
	estado.descobertos[robo.def.id] = true

	local prompt = robo.prompt
	prompt.Enabled = false
	prompt.ActionText = "Roubar"
	prompt.HoldDuration = Config.ROUBO.SEGURAR
	prompt.ObjectText = Config.nomeCompleto(robo.def, robo.mut)
	prompt:SetAttribute("DonoId", estado.player.UserId)
	prompt:SetAttribute("Venda", Format.dinheiro(Game.valorVenda(robo)))

	local alvo = estado.base.pedestais[vaga]
	local function chegou()
		if robo.dono == estado and estado.vagas[vaga] == robo and robo.estado == "voando" then
			robo.estado = "base"
			prompt.Enabled = true
			Game.atualizarAtributos(estado)
		end
	end

	robo.estado = "voando"
	if instantaneo then
		robo.voo = robo.voo + 1
		robo.modelo:PivotTo(alvo)
		chegou()
	else
		Game.voar(robo, alvo, chegou)
	end
	Game.atualizarAtributos(estado)
end

-- Tira o robô da vaga do dono atual (sem destruir).
function Game.tirarDaBase(robo)
	local dono = robo.dono
	if dono and robo.vaga and dono.vagas[robo.vaga] == robo then
		dono.vagas[robo.vaga] = nil
	end
	robo.dono = nil
	robo.vaga = nil
	if dono then
		Game.atualizarAtributos(dono)
	end
end

function Game.pegarBaseLivre()
	for _, base in ipairs(Game.mundo.bases) do
		if base.dono == nil then
			return base
		end
	end
	return nil
end

-- Dinheiro e renda ------------------------------------------------------------

function Game.multiplicador(estado)
	local m = Config.multiplicador(estado.renascimentos)
	if estado.dobro then
		m = m * 2
	end
	return m
end

function Game.rendaPorSegundo(estado)
	local total = 0
	for _, robo in pairs(estado.vagas) do
		if robo.estado == "base" then
			total = total + Config.rendaDe(robo.def, robo.mut)
		end
	end
	return total * Game.multiplicador(estado)
end

local function mostrarDinheiro(estado)
	estado.valorDinheiro.Value = math.min(math.floor(estado.dinheiro), MAIOR_INTEIRO)
end

function Game.adicionarDinheiro(estado, valor)
	estado.dinheiro = estado.dinheiro + valor
	mostrarDinheiro(estado)
end

function Game.gastar(estado, valor)
	if estado.dinheiro < valor then
		return false
	end
	estado.dinheiro = estado.dinheiro - valor
	mostrarDinheiro(estado)
	return true
end

function Game.pagarRenda()
	for _, estado in pairs(Game.estados) do
		local renda = Game.rendaPorSegundo(estado)
		if renda > 0 then
			Game.adicionarDinheiro(estado, renda)
		end
	end
end

-- Atributos que a interface do jogador lê
function Game.atualizarAtributos(estado)
	local player = estado.player
	player:SetAttribute("RendaPorSegundo", Game.rendaPorSegundo(estado))
	player:SetAttribute("Multiplicador", Game.multiplicador(estado))
	player:SetAttribute("CustoRenascer", Config.custoRenascer(estado.renascimentos))
	player:SetAttribute("TrancadaAte", estado.trancadaAte)

	local ocupadas = 0
	for _ in pairs(estado.vagas) do
		ocupadas = ocupadas + 1
	end
	player:SetAttribute("Vagas", ocupadas .. "/" .. Config.VAGAS_POR_BASE)

	local lista = {}
	for _, def in ipairs(Config.Robos) do
		if estado.descobertos[def.id] then
			table.insert(lista, def.id)
		end
	end
	player:SetAttribute("Descobertos", table.concat(lista, ","))
end

-- Entrada e saída de jogadores ------------------------------------------------

function Game.adicionarJogador(player, dados, podeSalvar)
	local base = Game.pegarBaseLivre()
	if not base then
		player:Kick("Este servidor está cheio. Entre em outro servidor do Rouba Robô!")
		return nil
	end

	local estado = {
		player = player,
		base = base,
		vagas = {},
		dinheiro = tonumber(dados.dinheiro) or Config.DINHEIRO_INICIAL,
		renascimentos = tonumber(dados.renascimentos) or 0,
		descobertos = {},
		podeSalvar = podeSalvar,
		carregando = nil,
		trancadaAte = 0,
		noBotao = false,
		ultimoTapa = 0,
		dobro = false,
		saindo = false,
		compras = {},
	}
	base.dono = estado
	Game.estados[player] = estado

	if type(dados.descobertos) == "table" then
		for id, sim in pairs(dados.descobertos) do
			if sim and Config.RoboPorId[id] then
				estado.descobertos[id] = true
			end
		end
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local valorDinheiro = Instance.new("IntValue")
	valorDinheiro.Name = "Dinheiro"
	valorDinheiro.Parent = leaderstats
	local valorRenascimentos = Instance.new("IntValue")
	valorRenascimentos.Name = "Renascimentos"
	valorRenascimentos.Value = estado.renascimentos
	valorRenascimentos.Parent = leaderstats
	leaderstats.Parent = player
	estado.valorDinheiro = valorDinheiro
	estado.valorRenascimentos = valorRenascimentos
	mostrarDinheiro(estado)

	-- devolve os robôs salvos para os pedestais
	if type(dados.robos) == "table" then
		for _, salvo in ipairs(dados.robos) do
			local def = type(salvo) == "table" and Config.RoboPorId[salvo.id]
			if def then
				local vaga = tonumber(salvo.vaga)
				if vaga == nil or vaga < 1 or vaga > Config.VAGAS_POR_BASE or estado.vagas[vaga] then
					vaga = Game.vagaLivre(estado)
				end
				if vaga then
					local mut = salvo.mut
					if mut ~= nil and Config.MutacaoPorId[mut] == nil then
						mut = nil
					end
					local robo = Game.novoRobo(def, mut, base.pedestais[vaga])
					Game.colocarNaBase(estado, robo, vaga, true)
				end
			end
		end
	end

	base.rotuloDono.Text = "Base de " .. player.DisplayName
	player:SetAttribute("Base", base.indice)
	Game.atualizarAtributos(estado)
	return estado
end

function Game.serializar(estado)
	local robos = {}
	for vaga = 1, Config.VAGAS_POR_BASE do
		local robo = estado.vagas[vaga]
		if robo then
			table.insert(robos, { id = robo.def.id, mut = robo.mut, vaga = vaga })
		end
	end
	local descobertos = {}
	for id in pairs(estado.descobertos) do
		descobertos[id] = true
	end
	return {
		versao = 1,
		dinheiro = math.floor(estado.dinheiro),
		renascimentos = estado.renascimentos,
		robos = robos,
		descobertos = descobertos,
	}
end

-- Retorna (estado, dadosParaSalvar)
function Game.removerJogador(player)
	local estado = Game.estados[player]
	if not estado then
		return nil, nil
	end
	estado.saindo = true
	local dados = Game.serializar(estado)

	if estado.carregando and Game.aoSairComCarga then
		Game.aoSairComCarga(estado)
	end
	for _, robo in pairs(estado.vagas) do
		Game.destruirRobo(robo)
	end
	estado.vagas = {}

	local base = estado.base
	base.dono = nil
	base.rotuloDono.Text = "Base livre"
	base.rotuloTranca.Text = ""
	base.rotuloBotao.Text = "TRANCAR BASE"
	base.barreira.Transparency = 1
	Game.estados[player] = nil
	return estado, dados
end

-- Tranca da base --------------------------------------------------------------

function Game.trancada(estado)
	return agora() < estado.trancadaAte
end

function Game.trancar(estado)
	if Game.trancada(estado) then
		return
	end
	local duracao = Config.duracaoTranca(estado.renascimentos)
	estado.trancadaAte = agora() + duracao
	estado.base.barreira.Transparency = 0.2
	Game.atualizarAtributos(estado)
	Game.notificar(estado.player, "Base trancada por " .. duracao .. " segundos!", "bom")
end

local function raizDe(player)
	local personagem = player.Character
	local humanoid = personagem and personagem:FindFirstChildOfClass("Humanoid")
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if raiz and humanoid and humanoid.Health > 0 then
		return raiz, humanoid, personagem
	end
	return nil
end
Game.raizDe = raizDe

-- Roda várias vezes por segundo: botão de trancar, contagem e expulsão.
function Game.vigiarBases()
	for _, estado in pairs(Game.estados) do
		local base = estado.base
		if Game.trancada(estado) then
			local restante = Format.tempo(estado.trancadaAte - agora())
			base.rotuloTranca.Text = "TRANCADA " .. restante
			base.rotuloBotao.Text = "TRANCADA " .. restante
			base.barreira.Transparency = 0.2
			-- quem não é dono e está dentro é jogado para fora
			for player, outro in pairs(Game.estados) do
				if outro ~= estado then
					local raiz, _, personagem = raizDe(player)
					if raiz and MapBuilder.dentroDaBase(base, raiz.Position, 0) then
						personagem:PivotTo(base.saida)
					end
				end
			end
		else
			if base.barreira.Transparency < 1 then
				base.barreira.Transparency = 1
				base.rotuloTranca.Text = ""
				base.rotuloBotao.Text = "TRANCAR BASE"
			end
		end

		-- tranca quando o dono PISA no botão (precisa sair e pisar de novo;
		-- ficar parado em cima não tranca para sempre)
		local raiz = raizDe(estado.player)
		local emCima = false
		if raiz then
			local delta = raiz.Position - base.botao.Position
			emCima = math.abs(delta.Y) < 6 and Vector3.new(delta.X, 0, delta.Z).Magnitude < 3.5
		end
		if emCima and not estado.noBotao and not Game.trancada(estado) then
			Game.trancar(estado)
		end
		estado.noBotao = emCima
	end
end

-- Renascimento ----------------------------------------------------------------

function Game.renascer(estado)
	local custo = Config.custoRenascer(estado.renascimentos)
	if estado.dinheiro < custo then
		Game.notificar(estado.player, "Para renascer você precisa de " .. Format.dinheiro(custo) .. ".", "ruim")
		return false
	end
	if estado.carregando then
		Game.notificar(estado.player, "Entregue o robô que você está carregando antes de renascer.", "ruim")
		return false
	end

	for _, robo in pairs(estado.vagas) do
		Game.destruirRobo(robo)
	end
	estado.vagas = {}
	estado.renascimentos = estado.renascimentos + 1
	estado.valorRenascimentos.Value = estado.renascimentos
	estado.dinheiro = Config.DINHEIRO_INICIAL
	mostrarDinheiro(estado)
	Game.atualizarAtributos(estado)

	local mult = Format.multiplicador(Config.multiplicador(estado.renascimentos))
	Game.notificarTodos(estado.player.DisplayName .. " renasceu! Agora ganha " .. mult .. " de dinheiro.", "alerta")
	return true
end

return Game
