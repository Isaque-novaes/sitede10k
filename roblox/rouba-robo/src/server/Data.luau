--[[
	Salva e carrega o progresso com DataStore, do jeito seguro:

	- UpdateAsync (nunca GetAsync + SetAsync), com novas tentativas.
	- Trava de sessão: só um servidor por vez cuida dos dados de um jogador.
	  Isso impede o truque de duplicar robôs entrando em outro servidor
	  antes do primeiro terminar de salvar.
	- Versão dos dados: saves antigos são convertidos automaticamente.
	- Se a leitura falhar, o jogador é convidado a entrar de novo, em vez
	  de jogar com um perfil vazio que apagaria o progresso verdadeiro.

	No Roblox Studio o salvamento só funciona com "Game Settings > Security >
	Enable Studio Access to API Services". Sem isso o jogo roda sem salvar.
]]

local DataStoreService = game:GetService("DataStoreService")

local Data = {}

local NOME_DO_COFRE = "RoubaRobo_v1"
local VERSAO = 2
local TRAVA_VENCE = 600 -- segundos: uma trava mais velha que isso é de um servidor que caiu
local TENTATIVAS = 4

local cofre = nil
local okCofre, erroCofre = pcall(function()
	cofre = DataStoreService:GetDataStore(NOME_DO_COFRE)
end)
if not okCofre then
	warn("[Robot Heist] DataStore indisponível: " .. tostring(erroCofre))
end

local function chave(player)
	return "jogador_" .. player.UserId
end

local function copiar(valor)
	if type(valor) ~= "table" then
		return valor
	end
	local copia = {}
	for k, v in pairs(valor) do
		copia[k] = copiar(v)
	end
	return copia
end
Data.copiar = copiar

function Data.padrao()
	return {
		versao = VERSAO,
		dinheiro = nil, -- nil = usa o dinheiro inicial
		renascimentos = 0,
		robos = {}, -- { { id = "parafusinho", mut = "dourado", vaga = 1 }, ... }
		descobertos = {}, -- { parafusinho = true, ... }
		melhorias = { renda = 0, vagas = 0, tapa = 0 },
		diario = { sequencia = 0, ultimoDia = -1 },
		missoes = { dia = -1, progresso = {}, pegas = {} },
		saida = 0, -- os.time() da última saída (para o dinheiro offline)
		grupoPremiado = false,
		vipPremiado = false,
		indicePremios = {}, -- { ["4"] = true } raridades completas (chave texto)
		compras = {}, -- últimos PurchaseIds já entregues
		dobroAte = 0, -- os.time() até quando vale o x2 do anúncio
		totalGanho = 0, -- para o ranking
	}
end

-- Converte saves antigos para a versão atual (preenche o que falta).
function Data.migrar(dados)
	if type(dados) ~= "table" then
		return Data.padrao()
	end
	local padrao = Data.padrao()
	for k, v in pairs(padrao) do
		if dados[k] == nil then
			dados[k] = v
		end
	end
	for k, v in pairs(padrao.melhorias) do
		if type(dados.melhorias[k]) ~= "number" then
			dados.melhorias[k] = v
		end
	end
	if type(dados.diario) ~= "table" then
		dados.diario = padrao.diario
	end
	if type(dados.missoes) ~= "table" then
		dados.missoes = padrao.missoes
	end
	dados.versao = VERSAO
	return dados
end

local function travaAtiva(dados)
	local trava = type(dados) == "table" and dados.sessao
	return type(trava) == "table" and trava.id ~= game.JobId and (os.time() - (tonumber(trava.t) or 0)) < TRAVA_VENCE
end

local function semAcessoNoStudio(erro)
	local texto = tostring(erro)
	return string.find(texto, "Studio", 1, true) ~= nil or string.find(texto, "publish", 1, true) ~= nil
end

-- Retorna (dados, situacao):
--   "ok"      carregou e travou a sessão
--   "sem_api" Studio sem acesso: joga sem salvar
--   "ocupado" outro servidor ainda está salvando: pedir para entrar de novo
--   "falha"   o Roblox não respondeu: pedir para entrar de novo
function Data.carregar(player)
	if not cofre then
		return Data.padrao(), "sem_api"
	end
	local ocupado = false
	for tentativa = 1, TENTATIVAS + 2 do
		ocupado = false
		local ok, resultado = pcall(function()
			return cofre:UpdateAsync(chave(player), function(antigo)
				if travaAtiva(antigo) then
					ocupado = true
					return nil -- não mexe em dados que outro servidor está usando
				end
				local dados = Data.migrar(antigo or Data.padrao())
				dados.sessao = { id = game.JobId, t = os.time() }
				return dados
			end)
		end)
		if ok and not ocupado and type(resultado) == "table" then
			return Data.migrar(copiar(resultado)), "ok"
		end
		if not ok then
			if semAcessoNoStudio(resultado) then
				return Data.padrao(), "sem_api"
			end
			warn(string.format("[Robot Heist] Falha ao carregar %s (tentativa %d): %s",
				player.Name, tentativa, tostring(resultado)))
		end
		if player.Parent == nil then
			return nil, "falha"
		end
		task.wait(math.min(2 ^ tentativa, 8))
	end
	if ocupado then
		return nil, "ocupado"
	end
	return nil, "falha"
end

-- Salva. liberar = true solta a trava (o jogador saiu do servidor).
function Data.salvar(player, dados, liberar)
	if not cofre then
		return false
	end
	local paraSalvar = copiar(dados)
	paraSalvar.versao = VERSAO
	if liberar then
		paraSalvar.sessao = nil
	else
		paraSalvar.sessao = { id = game.JobId, t = os.time() }
	end
	for tentativa = 1, TENTATIVAS do
		local recusado = false
		local ok, erro = pcall(function()
			cofre:UpdateAsync(chave(player), function(antigo)
				if travaAtiva(antigo) then
					recusado = true
					return nil -- outro servidor assumiu: não sobrescreve
				end
				return paraSalvar
			end)
		end)
		if ok then
			if recusado then
				warn("[Robot Heist] Save de " .. player.Name .. " recusado: outro servidor tem a trava.")
				return false
			end
			return true
		end
		if semAcessoNoStudio(erro) then
			return false
		end
		warn(string.format("[Robot Heist] Falha ao salvar %s (tentativa %d): %s",
			player.Name, tentativa, tostring(erro)))
		if tentativa < TENTATIVAS then
			task.wait(math.min(2 ^ tentativa, 8))
		end
	end
	return false
end

return Data
