--[[
	Tudo que faz o jogador voltar: prêmio diário, missões do dia, dinheiro
	ganho com o jogo fechado, melhorias da base, prêmios do Índice e os
	bônus de amigos, grupo e Roblox Premium.

	Os dias seguem o relógio do Roblox (UTC), igual para o mundo todo:
	um "dia" novo começa à 0h UTC, que é 21h no horário de Brasília.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Textos = require(Shared:WaitForChild("Textos"))
local Game = require(script.Parent:WaitForChild("Game"))
local Conveyor = require(script.Parent:WaitForChild("Conveyor"))

local Progresso = {}

local DIA = 86400

local function diaAtual()
	return math.floor(Game.agora() / DIA)
end
Progresso.diaAtual = diaAtual

-- Prêmios ----------------------------------------------------------------------
-- Entrega um prêmio e devolve a descrição (para o aviso).
function Progresso.darPremio(estado, premio)
	if premio.tipo == "dinheiro" then
		local valor = Config.dinheiroDe(premio, Game.rendaPorSegundo(estado))
		Game.adicionarDinheiro(estado, valor)
		return Game.dinheiroTexto(valor)
	elseif premio.tipo == "robo" then
		local def = Config.sortearDaRaridade(premio.raridade, Game.aleatorio())
		Game.darRobo(estado, def, nil)
		return Game.nomeRobo(def, nil)
	elseif premio.tipo == "sorte" then
		Conveyor.iniciarSorte(premio.minutos * 60, estado.player.DisplayName)
		return function(idioma)
			return Textos.t(idioma, "premio_sorte", premio.minutos)
		end
	end
	return ""
end

-- Prêmio diário ----------------------------------------------------------------
-- Retorna (dia 1..7 que aparece, pode pegar agora?)
function Progresso.situacaoDiario(estado)
	local d = estado.dados.diario
	local hoje = diaAtual()
	local sequencia = tonumber(d.sequencia) or 0
	local ultimo = tonumber(d.ultimoDia) or -1
	if ultimo == hoje then
		return ((sequencia - 1) % #Config.PREMIO_DIARIO) + 1, false
	end
	if ultimo ~= hoje - 1 then
		sequencia = 0
	end
	return (sequencia % #Config.PREMIO_DIARIO) + 1, true
end

function Progresso.pegarDiario(estado)
	local dia, pronto = Progresso.situacaoDiario(estado)
	if not pronto then
		Game.notificar(estado.player, "info", "diario_ja")
		return false
	end
	local d = estado.dados.diario
	local hoje = diaAtual()
	local sequencia = (tonumber(d.ultimoDia) == hoje - 1) and (tonumber(d.sequencia) or 0) or 0
	d.sequencia = sequencia + 1
	d.ultimoDia = hoje
	local descricao = Progresso.darPremio(estado, Config.PREMIO_DIARIO[dia])
	Game.notificar(estado.player, "bom", "diario_ok", dia, descricao)
	Game.remotos.Efeito:FireClient(estado.player, "premio")
	Progresso.atualizarAtributos(estado)
	Game.atualizarAtributos(estado)
	return true
end

-- Missões ----------------------------------------------------------------------
local function garantirMissoes(estado)
	local m = estado.dados.missoes
	local hoje = diaAtual()
	if m.dia ~= hoje then
		m.dia = hoje
		m.progresso = {}
		m.pegas = {}
	end
	if estado.diaMissoes ~= hoje then
		estado.diaMissoes = hoje
		estado.missoesDoDia = Config.missoesDoDia(hoje, estado.player.UserId)
	end
end

function Progresso.contar(estado, tipo, quantidade, info)
	if not estado.dados then
		return
	end
	garantirMissoes(estado)
	local m = estado.dados.missoes
	local mudou = false
	for _, missao in ipairs(estado.missoesDoDia) do
		local conta = missao.tipo == tipo
		if missao.tipo == "comprarRaridade" then
			conta = tipo == "comprar" and info ~= nil and (info.raridade or 0) >= missao.raridade
		end
		if conta and not m.pegas[missao.id] then
			local atual = tonumber(m.progresso[missao.id]) or 0
			if atual < missao.meta then
				m.progresso[missao.id] = math.min(missao.meta, atual + quantidade)
				mudou = true
			end
		end
	end
	if mudou then
		Progresso.atualizarAtributos(estado)
	end
end

function Progresso.pegarMissao(estado, indice)
	if type(indice) ~= "number" or indice ~= indice or indice % 1 ~= 0 then
		return false
	end
	garantirMissoes(estado)
	local missao = estado.missoesDoDia[indice]
	if not missao then
		return false
	end
	local m = estado.dados.missoes
	if m.pegas[missao.id] or (tonumber(m.progresso[missao.id]) or 0) < missao.meta then
		return false
	end
	m.pegas[missao.id] = true
	local descricao = Progresso.darPremio(estado, missao.premio)
	Game.notificar(estado.player, "bom", "missao_ok", descricao)
	Game.remotos.Efeito:FireClient(estado.player, "premio")
	Progresso.atualizarAtributos(estado)
	Game.atualizarAtributos(estado)
	return true
end

-- Dinheiro com o jogo fechado ------------------------------------------------
function Progresso.calcularOffline(estado)
	local saida = tonumber(estado.dados.saida) or 0
	if saida <= 0 then
		return 0
	end
	local segundos = math.min(Game.agora() - saida, Config.OFFLINE.MAX_HORAS * 3600)
	if segundos < Config.OFFLINE.MINIMO_SEGUNDOS then
		return 0
	end
	local multiplicador = Game.multiplicador(estado)
	if Game.agora() < estado.dobroAte then
		multiplicador = multiplicador / 2 -- o x2 do anúncio não vale para o tempo fora
	end
	return math.floor(Game.rendaBase(estado) * multiplicador * segundos * Config.OFFLINE.EFICIENCIA)
end

function Progresso.coletarOffline(estado, dobrado)
	local valor = estado.offlinePendente or 0
	if valor <= 0 then
		return false
	end
	estado.offlinePendente = 0
	if dobrado then
		valor = valor * 2
	end
	Game.adicionarDinheiro(estado, valor)
	estado.player:SetAttribute("OfflinePendente", 0)
	Game.notificar(estado.player, "bom", "offline_ok", Game.dinheiroTexto(valor))
	Game.remotos.Efeito:FireClient(estado.player, "premio")
	return true
end

-- Melhorias da base ------------------------------------------------------------
function Progresso.melhorar(estado, tipo)
	if tipo ~= "renda" and tipo ~= "vagas" and tipo ~= "tapa" then
		return false
	end
	local nivel = estado.melhorias[tipo]
	local custo = Config.custoMelhoria(tipo, nivel)
	if not custo then
		Game.notificar(estado.player, "info", "melhoria_max")
		return false
	end
	if not Game.gastar(estado, custo) then
		Game.notificar(estado.player, "ruim", "melhoria_falta", Game.dinheiroTexto(custo))
		return false
	end
	estado.melhorias[tipo] = nivel + 1
	Game.atualizarBase(estado)
	Game.atualizarAtributos(estado)
	Game.notificar(estado.player, "bom", "melhorou", function(idioma)
		return Textos.t(idioma, "melhoria_" .. tipo)
	end, nivel + 1)
	Game.efeito("melhoria", estado.base.quadro.Position + Vector3.new(0, 14, 0), estado.base.cor)
	Game.emitir(estado, "melhorar", 1)
	return true
end

-- Índice: completar uma raridade dá +5% para sempre -------------------------
local function raridadeCompleta(estado, raridade)
	for _, def in ipairs(Config.robosDaRaridade(raridade)) do
		if not estado.descobertos[def.id] then
			return false
		end
	end
	return true
end

function Progresso.conferirIndice(estado, avisar)
	local ganhou = false
	for raridade = 1, #Config.Raridades do
		local chave = tostring(raridade)
		if not estado.indicePremios[chave] and raridadeCompleta(estado, raridade) then
			estado.indicePremios[chave] = true
			ganhou = true
			if avisar then
				Game.notificar(estado.player, "bom", "indice_completo", Game.nomeRaridade(raridade))
				Game.remotos.Efeito:FireClient(estado.player, "premio")
			end
		end
	end
	if ganhou then
		Game.atualizarAtributos(estado)
	end
end

-- Bônus: amigos, grupo e Premium ---------------------------------------------
local amizades = {} -- [userIdA .. ":" .. userIdB] = true/false

local function saoAmigos(a, b)
	local chave = math.min(a.UserId, b.UserId) .. ":" .. math.max(a.UserId, b.UserId)
	if amizades[chave] == nil then
		local ok, resultado = pcall(function()
			return a:IsFriendsWithAsync(b.UserId)
		end)
		amizades[chave] = ok and resultado == true
	end
	return amizades[chave]
end

function Progresso.atualizarAmigos()
	for player, estado in pairs(Game.estados) do
		local n = 0
		for outroPlayer in pairs(Game.estados) do
			if outroPlayer ~= player and saoAmigos(player, outroPlayer) then
				n = n + 1
			end
		end
		if estado.amigos ~= n and Game.estados[player] == estado then
			estado.amigos = n
			Game.atualizarAtributos(estado)
		end
	end
end

function Progresso.conferirGrupo(estado)
	if Config.GRUPO.ID == 0 then
		return
	end
	local ok, noGrupo = pcall(function()
		return estado.player:IsInGroupAsync(Config.GRUPO.ID)
	end)
	if not ok or Game.estados[estado.player] ~= estado then
		return
	end
	estado.noGrupo = noGrupo == true
	estado.player:SetAttribute("NoGrupo", estado.noGrupo)
	if estado.noGrupo and not estado.dados.grupoPremiado then
		estado.dados.grupoPremiado = true
		local def = Config.sortearDaRaridade(Config.GRUPO.RARIDADE_PREMIO, Game.aleatorio())
		Game.darRobo(estado, def, nil)
		Game.notificar(estado.player, "bom", "grupo_bonus", Game.nomeRaridade(Config.GRUPO.RARIDADE_PREMIO))
	end
	Game.atualizarAtributos(estado)
end

function Progresso.conferirPremium(estado)
	estado.premium = estado.player.MembershipType == Enum.MembershipType.Premium
	Game.atualizarAtributos(estado)
end

-- Atributos que a tela lê -----------------------------------------------------
function Progresso.atualizarAtributos(estado)
	local player = estado.player
	local dia, pronto = Progresso.situacaoDiario(estado)
	player:SetAttribute("DiarioDia", dia)
	player:SetAttribute("DiarioPronto", pronto)
	garantirMissoes(estado)
	local m = estado.dados.missoes
	player:SetAttribute("MissoesDia", diaAtual())
	for i = 1, Config.MISSOES_POR_DIA do
		local missao = estado.missoesDoDia[i]
		player:SetAttribute("M" .. i .. "Id", missao and missao.id or "")
		player:SetAttribute("M" .. i .. "Prog", missao and (tonumber(m.progresso[missao.id]) or 0) or 0)
		player:SetAttribute("M" .. i .. "Pega", missao and m.pegas[missao.id] == true or false)
	end
end

-- Entrada, saída e relógio ----------------------------------------------------
function Progresso.aoEntrar(estado)
	garantirMissoes(estado)
	Progresso.conferirIndice(estado, false)
	Progresso.conferirPremium(estado)
	estado.offlinePendente = Progresso.calcularOffline(estado)
	estado.player:SetAttribute("OfflinePendente", estado.offlinePendente)
	Progresso.atualizarAtributos(estado)
	task.spawn(Progresso.atualizarAmigos)
	task.spawn(Progresso.conferirGrupo, estado)
end

-- Quem sai sem pegar o dinheiro offline não perde: entra direto na conta.
function Progresso.aoSair(estado)
	if (estado.offlinePendente or 0) > 0 then
		Game.adicionarDinheiro(estado, estado.offlinePendente)
		estado.offlinePendente = 0
	end
end

local minutos = 0
function Progresso.cadaMinuto()
	minutos = minutos + 1
	for _, estado in pairs(Game.estados) do
		local diaAntes = estado.diaMissoes
		Game.emitir(estado, "minutos", 1)
		garantirMissoes(estado)
		if diaAntes ~= estado.diaMissoes then
			Progresso.atualizarAtributos(estado)
		end
	end
	if minutos % 3 == 0 then
		for _, estado in pairs(Game.estados) do
			task.spawn(Progresso.conferirGrupo, estado)
		end
	end
end

function Progresso.iniciar()
	table.insert(Game.ouvintes, Progresso.contar)
	Game.aoDescobrir = function(estado)
		Progresso.conferirIndice(estado, true)
	end
	Players.PlayerMembershipChanged:Connect(function(player)
		local estado = Game.estados[player]
		if estado then
			Progresso.conferirPremium(estado)
		end
	end)
end

return Progresso
