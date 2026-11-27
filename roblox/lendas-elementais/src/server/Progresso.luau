--[[
	Prêmio diário, missões do dia, PvP (quem derrota quem) e os bônus de
	amigos, grupo e Roblox Premium.

	Os dias seguem o relógio do Roblox (UTC), igual para o mundo todo:
	um "dia" novo começa à 0h UTC, que é 21h no horário de Brasília.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Textos = require(Shared:WaitForChild("Textos"))
local Jogador = require(script.Parent:WaitForChild("Jogador"))

local Progresso = {}

local DIA = 86400

local function diaAtual()
	return math.floor(Jogador.agora() / DIA)
end
Progresso.diaAtual = diaAtual

-- Prêmios ---------------------------------------------------------------------
-- Entrega e devolve a descrição (para o aviso), no idioma do jogador.
function Progresso.darPremio(estado, premio)
	if premio.tipo == "moedas" then
		local valor = Jogador.darMoedas(estado, premio.valor)
		return function(idioma)
			return Textos.t(idioma, "premio_moedas", valor)
		end
	elseif premio.tipo == "xp" then
		local valor = Jogador.darXP(estado, math.floor(Config.xpDoNivel(estado.nivel) * premio.nivelFracao))
		return function(idioma)
			return Textos.t(idioma, "premio_xp", valor)
		end
	elseif premio.tipo == "xp2" then
		estado.xp2Ate = math.max(Jogador.agora(), estado.xp2Ate) + premio.minutos * 60
		Jogador.atualizarAtributos(estado)
		return function(idioma)
			return Textos.t(idioma, "premio_xp2", premio.minutos)
		end
	end
	return ""
end

-- Prêmio diário -----------------------------------------------------------------
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
		Jogador.avisar(estado.player, "info", "diario_ja")
		return false
	end
	local d = estado.dados.diario
	local hoje = diaAtual()
	local sequencia = (tonumber(d.ultimoDia) == hoje - 1) and (tonumber(d.sequencia) or 0) or 0
	d.sequencia = sequencia + 1
	d.ultimoDia = hoje
	local descricao = Progresso.darPremio(estado, Config.PREMIO_DIARIO[dia])
	Jogador.avisar(estado.player, "bom", "diario_ok", dia, descricao)
	Jogador.remotos.Efeito:FireClient(estado.player, "premio")
	Progresso.atualizarAtributos(estado)
	return true
end

-- Missões -------------------------------------------------------------------------
local function garantirMissoes(estado)
	local m = estado.dados.missoes
	local hoje = diaAtual()
	if m.dia ~= hoje then
		m.dia = hoje
		m.progresso = {}
		m.pegas = {}
		m.zonas = {}
		estado.zonasVisitadas = {}
	end
	if estado.diaMissoes ~= hoje then
		estado.diaMissoes = hoje
		estado.missoesDoDia = Config.missoesDoDia(hoje, estado.player.UserId)
	end
end

function Progresso.contar(estado, tipo, quantidade)
	if not estado.dados then
		return
	end
	garantirMissoes(estado)
	local m = estado.dados.missoes
	local mudou = false
	for _, missao in ipairs(estado.missoesDoDia) do
		if missao.tipo == tipo and not m.pegas[missao.id] then
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
	Jogador.avisar(estado.player, "bom", "missao_ok", descricao)
	Jogador.remotos.Efeito:FireClient(estado.player, "premio")
	Progresso.atualizarAtributos(estado)
	return true
end

-- PvP: recompensa por derrotar outro jogador ---------------------------------------
-- Quem perde não perde nada: o prêmio é pago pelo jogo.
function Progresso.derrotouJogador(vencedor, perdedor)
	local id = perdedor.player.UserId
	local instante = Jogador.agora()
	local repetido = (vencedor.ultimasVitimas[id] or -math.huge) + Config.PVP.ESPERA_MESMO_ALVO > instante
	local diferenca = math.abs(vencedor.nivel - perdedor.nivel)
	if repetido or diferenca > Config.PVP.DIFERENCA_NIVEL then
		Jogador.avisar(vencedor.player, "info", "derrotou_sem_premio", perdedor.player.DisplayName)
		return false
	end
	vencedor.ultimasVitimas[id] = instante
	local base = Config.xpDoNivel(perdedor.nivel)
	local xp = Jogador.darXP(vencedor, math.floor(base * Config.PVP.XP))
	local moedas = Jogador.darMoedas(vencedor, math.floor(base * Config.PVP.XP * Config.PVP.MOEDAS))
	Jogador.avisar(vencedor.player, "bom", "derrotou_jogador", perdedor.player.DisplayName,
		Jogador.numero(xp), Jogador.numero(moedas))
	Jogador.remotos.Efeito:FireClient(vencedor.player, "matou", Jogador.posicaoDe(perdedor), Color3.fromRGB(255, 90, 90))
	Jogador.emitir(vencedor, "matarJogador", 1)
	vencedor.dados.jogadoresDerrotados = (vencedor.dados.jogadoresDerrotados or 0) + 1
	return true
end

-- Bônus: amigos, grupo e Premium -----------------------------------------------------
local amizades = {}

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
	for player, estado in pairs(Jogador.estados) do
		local n = 0
		for outroPlayer in pairs(Jogador.estados) do
			if outroPlayer ~= player and saoAmigos(player, outroPlayer) then
				n = n + 1
			end
		end
		if estado.amigos ~= n and Jogador.estados[player] == estado then
			estado.amigos = n
			Jogador.atualizarAtributos(estado)
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
	if not ok or Jogador.estados[estado.player] ~= estado then
		return
	end
	estado.noGrupo = noGrupo == true
	estado.player:SetAttribute("NoGrupo", estado.noGrupo)
	if estado.noGrupo and not estado.dados.grupoPremiado then
		estado.dados.grupoPremiado = true
		Jogador.darMoedas(estado, Config.GRUPO.MOEDAS, true)
		Jogador.avisar(estado.player, "bom", "grupo_bonus", Jogador.numero(Config.GRUPO.MOEDAS))
	end
	Jogador.atualizarAtributos(estado)
end

function Progresso.conferirPremium(estado)
	estado.premium = estado.player.MembershipType == Enum.MembershipType.Premium
	Jogador.atualizarAtributos(estado)
end

-- Atributos que a tela lê --------------------------------------------------------------
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

-- Entrada e relógio ------------------------------------------------------------------
function Progresso.aoEntrar(estado)
	garantirMissoes(estado)
	Progresso.conferirPremium(estado)
	Progresso.atualizarAtributos(estado)
	task.spawn(Progresso.atualizarAmigos)
	task.spawn(Progresso.conferirGrupo, estado)
end

local minutos = 0
function Progresso.cadaMinuto()
	minutos = minutos + 1
	for _, estado in pairs(Jogador.estados) do
		local diaAntes = estado.diaMissoes
		Jogador.emitir(estado, "minutos", 1)
		garantirMissoes(estado)
		if diaAntes ~= estado.diaMissoes then
			Progresso.atualizarAtributos(estado)
		end
	end
	if minutos % 3 == 0 then
		for _, estado in pairs(Jogador.estados) do
			task.spawn(Progresso.conferirGrupo, estado)
		end
	end
end

function Progresso.iniciar()
	table.insert(Jogador.ouvintes, Progresso.contar)
	Players.PlayerMembershipChanged:Connect(function(player)
		local estado = Jogador.estados[player]
		if estado then
			Progresso.conferirPremium(estado)
		end
	end)
end

return Progresso
