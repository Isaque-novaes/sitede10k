--[[
	O coração do jogo no servidor: jogadores, bases, vagas, robôs,
	dinheiro, bônus, tranca da base e renascimento.

	Estados de um robô:
	  "esteira"   andando na esteira, à venda
	  "voando"    indo para uma base (animação)
	  "base"      parado num pedestal, gerando dinheiro
	  "carregado" na cabeça de um ladrão
	  "solto"     acabou de sair da cabeça do ladrão
	  "destruido" já saiu do jogo

	Conveyor e Stealing registram em Game.acoes o que acontece quando
	alguém segura E num robô em cada estado. Progresso ouve Game.emitir
	para contar as missões.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Textos = require(Shared:WaitForChild("Textos"))
local MapBuilder = require(script.Parent:WaitForChild("MapBuilder"))
local RobotFactory = require(script.Parent:WaitForChild("RobotFactory"))

local Game = {}

Game.estados = {} -- [Player] = estado do jogador
Game.mundo = nil
Game.remotos = nil
Game.acoes = {} -- [estadoDoRobo] = function(robo, player)
Game.ouvintes = {} -- funções chamadas em Game.emitir

-- ganchos preenchidos pelo Stealing
Game.aoDestruirCarregado = nil -- function(robo)
Game.aoSairComCarga = nil -- function(estadoLadrao)

local MAIOR_INTEIRO = 9e18
local aleatorio = Random.new()

local function agora()
	return workspace:GetServerTimeNow()
end
Game.agora = agora

function Game.iniciar(mundo, remotos)
	Game.mundo = mundo
	Game.remotos = remotos
end

-- Eventos para missões ---------------------------------------------------------

function Game.emitir(estado, tipo, quantidade, info)
	for _, ouvinte in ipairs(Game.ouvintes) do
		ouvinte(estado, tipo, quantidade or 1, info)
	end
end

-- Avisos na tela, no idioma de cada jogador ----------------------------------
-- Argumentos que são funções recebem o idioma (ex.: nome do robô traduzido).

local function montarTexto(idioma, chave, ...)
	local valores = { ... }
	for i = 1, select("#", ...) do
		if type(valores[i]) == "function" then
			valores[i] = valores[i](idioma)
		end
	end
	return Textos.t(idioma, chave, table.unpack(valores, 1, select("#", ...)))
end

function Game.idiomaDe(player)
	local estado = Game.estados[player]
	if estado then
		return estado.idioma
	end
	return Textos.idiomaDe(player.LocaleId)
end

-- tipo: "bom", "ruim", "alerta" ou "info"
function Game.notificar(player, tipo, chave, ...)
	Game.remotos.Notificar:FireClient(player, montarTexto(Game.idiomaDe(player), chave, ...), tipo or "info")
end

function Game.notificarTodos(tipo, chave, ...)
	for player in pairs(Game.estados) do
		Game.notificar(player, tipo, chave, ...)
	end
end

function Game.efeito(tipo, posicao, cor)
	Game.remotos.Efeito:FireAllClients(tipo, posicao, cor)
end

-- Ajudantes para textos que dependem do idioma
function Game.nomeRobo(def, mut)
	return function(idioma)
		return Config.nomeCompleto(def, mut, idioma)
	end
end

function Game.nomeRaridade(raridade)
	return function(idioma)
		return Config.nomeDe(Config.Raridades[raridade], idioma)
	end
end

function Game.dinheiroTexto(valor)
	return function(idioma)
		return Format.dinheiro(valor, idioma)
	end
end

function Game.tempoTexto(segundos)
	return Format.tempo(segundos)
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
		Game.atualizarBase(dono)
		Game.atualizarAtributos(dono)
	end
end

-- Vagas e bases ---------------------------------------------------------------

function Game.vagasTotais(estado)
	return Config.vagasTotais(estado.melhorias.vagas, estado.passes.vagas)
end

function Game.vagasOcupadas(estado)
	local n = 0
	for _ in pairs(estado.vagas) do
		n = n + 1
	end
	return n
end

function Game.vagaLivre(estado)
	for vaga = 1, Game.vagasTotais(estado) do
		if estado.vagas[vaga] == nil then
			return vaga
		end
	end
	return nil
end

-- Atualiza o visual da base: cor e enfeites pelo nível, pedestais e anéis.
function Game.atualizarBase(estado)
	local base = estado.base
	if base.dono ~= estado then
		return
	end
	MapBuilder.aplicarNivel(base, estado.melhorias.renda, true)
	local cores = {}
	for vaga, robo in pairs(estado.vagas) do
		cores[vaga] = Config.Raridades[robo.def.raridade].cor
	end
	MapBuilder.atualizarVagas(base, Game.vagasTotais(estado), cores)
end

-- Põe o robô na vaga do jogador. instantaneo = sem animação (ao carregar).
function Game.colocarNaBase(estado, robo, vaga, instantaneo)
	estado.vagas[vaga] = robo
	robo.dono = estado
	robo.vaga = vaga
	robo.ladrao = nil
	local novo = not estado.descobertos[robo.def.id]
	estado.descobertos[robo.def.id] = true

	local prompt = robo.prompt
	prompt.Enabled = false
	prompt.ActionText = "Steal"
	prompt.HoldDuration = Config.ROUBO.SEGURAR
	prompt.ObjectText = Config.nomeCompleto(robo.def, robo.mut, "en")
	prompt:SetAttribute("DonoId", estado.player.UserId)
	prompt:SetAttribute("Venda", Game.valorVenda(robo))
	robo.modelo:SetAttribute("DonoId", estado.player.UserId)

	local alvo = estado.base.pedestais[vaga]
	local function chegou()
		if robo.dono == estado and estado.vagas[vaga] == robo and robo.estado == "voando" then
			robo.estado = "base"
			prompt.Enabled = true
			Game.atualizarAtributos(estado)
			if not instantaneo then
				Game.efeito("pouso", alvo.Position, Config.Raridades[robo.def.raridade].cor)
			end
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
	Game.atualizarBase(estado)
	Game.atualizarAtributos(estado)
	if novo and Game.aoDescobrir then
		Game.aoDescobrir(estado, robo.def)
	end
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
		Game.atualizarBase(dono)
		Game.atualizarAtributos(dono)
	end
end

-- Dá um robô de presente (prêmio, caixa, VIP, grupo). Se a base estiver
-- cheia, vira dinheiro (o valor cheio do robô).
function Game.darRobo(estado, def, mut)
	local vaga = Game.vagaLivre(estado)
	if not vaga then
		local valor = Config.precoDe(def, mut)
		Game.adicionarDinheiro(estado, valor)
		Game.notificar(estado.player, "info", "premio_robo_cheio", Game.nomeRobo(def, mut), Game.dinheiroTexto(valor))
		return false
	end
	local origem = estado.base.nascer * CFrame.new(0, 12, 0)
	local robo = Game.novoRobo(def, mut, origem)
	Game.colocarNaBase(estado, robo, vaga, false)
	return true
end

function Game.pegarBaseLivre()
	for _, base in ipairs(Game.mundo.bases) do
		if base.dono == nil then
			return base
		end
	end
	return nil
end

-- Dinheiro e bônus ------------------------------------------------------------

function Game.raridadesCompletas(estado)
	local n = 0
	for _ in pairs(estado.indicePremios) do
		n = n + 1
	end
	return n
end

function Game.multiplicador(estado)
	local m = Config.multiplicadorRenascer(estado.renascimentos)
	m = m * (1 + Config.MELHORIAS.renda.bonus * estado.melhorias.renda)
	if estado.passes.dobro then
		m = m * 2
	end
	if estado.passes.vip then
		m = m * (1 + Config.LOJA.VIP_BONUS)
	end
	m = m * (1 + Config.BONUS.POR_AMIGO * math.min(estado.amigos, Config.BONUS.MAX_AMIGOS))
	if estado.noGrupo then
		m = m * (1 + Config.GRUPO.BONUS)
	end
	if estado.premium then
		m = m * (1 + Config.BONUS.PREMIUM)
	end
	m = m * (1 + Config.BONUS.POR_RARIDADE_COMPLETA * Game.raridadesCompletas(estado))
	if agora() < estado.dobroAte then
		m = m * 2
	end
	return m
end

-- renda sem o x2 temporário do anúncio (usada no dinheiro offline)
function Game.rendaBase(estado)
	local total = 0
	for _, robo in pairs(estado.vagas) do
		if robo.estado == "base" then
			total = total + Config.rendaDe(robo.def, robo.mut)
		end
	end
	return total
end

function Game.rendaPorSegundo(estado)
	return Game.rendaBase(estado) * Game.multiplicador(estado)
end

local function mostrarDinheiro(estado)
	estado.valorDinheiro.Value = math.min(math.floor(estado.dinheiro), MAIOR_INTEIRO)
end

function Game.adicionarDinheiro(estado, valor)
	if type(valor) ~= "number" or valor ~= valor or valor < 0 then
		return
	end
	estado.dinheiro = estado.dinheiro + valor
	estado.totalGanho = estado.totalGanho + valor
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

local ultimoDobro = {}
function Game.pagarRenda()
	for _, estado in pairs(Game.estados) do
		local renda = Game.rendaPorSegundo(estado)
		if renda > 0 then
			Game.adicionarDinheiro(estado, renda)
		end
		-- quando o x2 do anúncio acaba, a tela precisa saber
		local dobroAtivo = agora() < estado.dobroAte
		if ultimoDobro[estado] ~= dobroAtivo then
			ultimoDobro[estado] = dobroAtivo
			Game.atualizarAtributos(estado)
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
	player:SetAttribute("VagasOcupadas", Game.vagasOcupadas(estado))
	player:SetAttribute("VagasTotais", Game.vagasTotais(estado))
	player:SetAttribute("NivelRenda", estado.melhorias.renda)
	player:SetAttribute("NivelVagas", estado.melhorias.vagas)
	player:SetAttribute("NivelTapa", estado.melhorias.tapa)
	player:SetAttribute("PasseDobro", estado.passes.dobro)
	player:SetAttribute("PasseVip", estado.passes.vip)
	player:SetAttribute("PasseVagas", estado.passes.vagas)
	player:SetAttribute("PasseTranca", estado.passes.tranca)
	player:SetAttribute("DobroAte", estado.dobroAte)
	player:SetAttribute("Amigos", math.min(estado.amigos, Config.BONUS.MAX_AMIGOS))

	local lista = {}
	for _, def in ipairs(Config.Robos) do
		if estado.descobertos[def.id] then
			table.insert(lista, def.id)
		end
	end
	player:SetAttribute("Descobertos", table.concat(lista, ","))

	local completas = {}
	for raridade = 1, #Config.Raridades do
		if estado.indicePremios[tostring(raridade)] then
			table.insert(completas, tostring(raridade))
		end
	end
	player:SetAttribute("IndicePremios", table.concat(completas, ","))
end

-- Entrada e saída de jogadores ------------------------------------------------

function Game.adicionarJogador(player, dados, podeSalvar)
	local base = Game.pegarBaseLivre()
	if not base then
		player:Kick(Textos.t(Textos.idiomaDe(player.LocaleId), "servidor_cheio"))
		return nil
	end

	local estado = {
		player = player,
		idioma = Textos.idiomaDe(player.LocaleId),
		base = base,
		vagas = {},
		dinheiro = tonumber(dados.dinheiro) or Config.DINHEIRO_INICIAL,
		renascimentos = tonumber(dados.renascimentos) or 0,
		descobertos = {},
		melhorias = {
			renda = math.clamp(tonumber(dados.melhorias.renda) or 0, 0, Config.MELHORIAS.renda.max),
			vagas = math.clamp(tonumber(dados.melhorias.vagas) or 0, 0, Config.MELHORIAS.vagas.max),
			tapa = math.clamp(tonumber(dados.melhorias.tapa) or 0, 0, Config.MELHORIAS.tapa.max),
		},
		passes = { dobro = false, vip = false, vagas = false, tranca = false },
		amigos = 0,
		noGrupo = false,
		premium = false,
		indicePremios = {},
		dobroAte = tonumber(dados.dobroAte) or 0,
		totalGanho = tonumber(dados.totalGanho) or 0,
		dados = dados, -- campos que o Progresso e a Loja usam
		podeSalvar = podeSalvar,
		carregando = nil,
		trancadaAte = 0,
		noBotao = false,
		ultimoTapa = 0,
		saindo = false,
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
	if type(dados.indicePremios) == "table" then
		for raridade, sim in pairs(dados.indicePremios) do
			if sim and Config.Raridades[tonumber(raridade) or 0] then
				estado.indicePremios[tostring(raridade)] = true
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

	base.modelo:SetAttribute("DonoNome", player.DisplayName)
	base.modelo:SetAttribute("DonoId", player.UserId)
	player:SetAttribute("Base", base.indice)
	return estado
end

-- Devolve os robôs salvos para os pedestais (depois que os passes carregaram,
-- para as vagas extras do passe já contarem).
function Game.restaurarRobos(estado)
	local dados = estado.dados
	if type(dados.robos) ~= "table" then
		return
	end
	local total = Game.vagasTotais(estado)
	for _, salvo in ipairs(dados.robos) do
		local def = type(salvo) == "table" and Config.RoboPorId[salvo.id]
		if def then
			local mut = salvo.mut
			if mut ~= nil and Config.MutacaoPorId[mut] == nil then
				mut = nil
			end
			local vaga = tonumber(salvo.vaga)
			if vaga == nil or vaga < 1 or vaga > total or estado.vagas[vaga] then
				vaga = Game.vagaLivre(estado)
			end
			if vaga then
				local robo = Game.novoRobo(def, mut, estado.base.pedestais[vaga])
				Game.colocarNaBase(estado, robo, vaga, true)
			else
				-- não cabe mais (nunca deveria acontecer): vira dinheiro
				Game.adicionarDinheiro(estado, Config.precoDe(def, mut))
			end
		end
	end
	Game.atualizarBase(estado)
	Game.atualizarAtributos(estado)
end

function Game.serializar(estado)
	local robos = {}
	for vaga = 1, Config.MAX_PEDESTAIS do
		local robo = estado.vagas[vaga]
		if robo then
			table.insert(robos, { id = robo.def.id, mut = robo.mut, vaga = vaga })
		end
	end
	local descobertos = {}
	for id in pairs(estado.descobertos) do
		descobertos[id] = true
	end
	local indice = {}
	for raridade in pairs(estado.indicePremios) do
		indice[raridade] = true
	end
	local dados = estado.dados
	dados.dinheiro = math.floor(estado.dinheiro)
	dados.renascimentos = estado.renascimentos
	dados.robos = robos
	dados.descobertos = descobertos
	dados.indicePremios = indice
	dados.melhorias = {
		renda = estado.melhorias.renda,
		vagas = estado.melhorias.vagas,
		tapa = estado.melhorias.tapa,
	}
	dados.dobroAte = estado.dobroAte
	dados.totalGanho = math.floor(estado.totalGanho)
	dados.saida = math.floor(agora())
	return dados
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
	base.modelo:SetAttribute("DonoNome", "")
	base.modelo:SetAttribute("DonoId", 0)
	base.modelo:SetAttribute("TrancadaAte", 0)
	base.barreira.Transparency = 1
	MapBuilder.aplicarNivel(base, 0, false)
	MapBuilder.atualizarVagas(base, 0, {})
	Game.estados[player] = nil
	ultimoDobro[estado] = nil
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
	local duracao = Config.duracaoTranca(estado.renascimentos, estado.passes.tranca)
	estado.trancadaAte = agora() + duracao
	estado.base.barreira.Transparency = 0.2
	estado.base.modelo:SetAttribute("TrancadaAte", estado.trancadaAte)
	Game.atualizarAtributos(estado)
	Game.notificar(estado.player, "bom", "trancou", duracao)
	Game.emitir(estado, "trancar", 1)
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

-- Roda várias vezes por segundo: botão de trancar e expulsão de intrusos.
-- (A contagem regressiva é desenhada no jogador a partir do atributo.)
function Game.vigiarBases()
	for _, estado in pairs(Game.estados) do
		local base = estado.base
		if Game.trancada(estado) then
			base.barreira.Transparency = 0.2
			for player, outro in pairs(Game.estados) do
				if outro ~= estado then
					local raiz, _, personagem = raizDe(player)
					if raiz and MapBuilder.dentroDaBase(base, raiz.Position, 0) then
						personagem:PivotTo(base.saida)
					end
				end
			end
		elseif base.barreira.Transparency < 1 then
			base.barreira.Transparency = 1
		end

		-- tranca quando o dono PISA no botão (precisa sair e pisar de novo)
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
		Game.notificar(estado.player, "ruim", "renascer_falta", Game.dinheiroTexto(custo))
		return false
	end
	if estado.carregando then
		Game.notificar(estado.player, "ruim", "renascer_carregando")
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
	Game.atualizarBase(estado)
	Game.atualizarAtributos(estado)

	local mult = Config.multiplicadorRenascer(estado.renascimentos)
	Game.notificarTodos("alerta", "renasceu", estado.player.DisplayName, function(idioma)
		return Format.multiplicador(mult, idioma)
	end)
	local raiz = raizDe(estado.player)
	if raiz then
		Game.efeito("renascer", raiz.Position, Color3.fromRGB(166, 77, 255))
	end
	return true
end

-- Sorteio usado por prêmios
function Game.aleatorio()
	return aleatorio
end

return Game
