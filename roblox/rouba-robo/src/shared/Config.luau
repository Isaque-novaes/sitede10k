--[[
	Robot Heist / Rouba Robô — configuração do jogo.

	Tudo que dá pra ajustar sem mexer na lógica fica aqui: preços, renda,
	chances, tempos, robôs, melhorias, prêmios, missões e loja. Este módulo
	fica em ReplicatedStorage: servidor e jogadores leem os mesmos valores.
]]

local Config = {}

Config.NOME = { pt = "Rouba Robô", en = "Robot Heist" }

-- Economia -------------------------------------------------------------------
Config.DINHEIRO_INICIAL = 100
Config.VENDA_DEVOLVE = 0.5 -- vender um robô devolve 50% do preço

-- Vagas: 10 no começo, até 15 com melhorias e +5 com o passe (máximo 20)
Config.VAGAS = { INICIAIS = 10, MAX_MELHORIAS = 5, PASSE = 5 }
Config.MAX_PEDESTAIS = Config.VAGAS.INICIAIS + Config.VAGAS.MAX_MELHORIAS + Config.VAGAS.PASSE

-- Esteira da fábrica ---------------------------------------------------------
Config.ESTEIRA = {
	INTERVALO = 2.2, -- segundos entre um robô e outro
	VELOCIDADE = 7, -- studs por segundo
}

-- Roubo ----------------------------------------------------------------------
Config.ROUBO = {
	SEGURAR = 1, -- segundos segurando E para roubar ou vender
	VELOCIDADE_CARREGANDO = 11,
	VELOCIDADE_NORMAL = 16,
	TEMPO_MAXIMO = 45, -- depois disso o robô volta sozinho pro dono
}

-- Tranca da base -------------------------------------------------------------
Config.TRANCA = {
	DURACAO = 60,
	EXTRA_POR_RENASCIMENTO = 10,
}

-- Tapa -----------------------------------------------------------------------
Config.TAPA = {
	RECARGA = 1.2,
	ALCANCE = 8,
	FORCA = 70,
	FORCA_POR_NIVEL = 15,
}

-- Renascimento ---------------------------------------------------------------
Config.RENASCER = {
	CUSTO_BASE = 1000000,
	CRESCIMENTO = 5,
	BONUS = 0.5, -- +50% de renda por renascimento
}

-- Sorte: o evento grátis e a comprada usam a mesma força ---------------------
Config.SORTE = {
	A_CADA = 600, -- evento grátis a cada 10 minutos
	DURACAO = 120,
	FORCA = 3, -- multiplica a chance de robôs Raro ou melhor
}

-- Melhorias da base (pagas com o dinheiro do jogo) --------------------------
Config.MELHORIAS = {
	renda = { max = 10, custoBase = 5000, crescimento = 3, bonus = 0.10 },
	vagas = { max = Config.VAGAS.MAX_MELHORIAS, custoBase = 20000, crescimento = 4 },
	tapa = { max = 5, custoBase = 10000, crescimento = 3 },
}

-- Prêmio diário: 7 dias seguidos; faltou um dia, volta para o 1 ------------
-- dinheiro = o maior entre "minimo" e "minutos" da renda atual
Config.PREMIO_DIARIO = {
	{ tipo = "dinheiro", minimo = 500, minutos = 2 },
	{ tipo = "dinheiro", minimo = 2000, minutos = 5 },
	{ tipo = "dinheiro", minimo = 10000, minutos = 10 },
	{ tipo = "robo", raridade = 3 },
	{ tipo = "dinheiro", minimo = 100000, minutos = 30 },
	{ tipo = "sorte", minutos = 10 },
	{ tipo = "robo", raridade = 5 },
}

-- Missões diárias: 3 sorteadas por dia --------------------------------------
-- tipo: o que conta; meta: quantas vezes; raridade: só para "comprarRaridade"
Config.MISSOES = {
	{ id = "tempo", tipo = "minutos", meta = 10, premio = { tipo = "dinheiro", minimo = 5000, minutos = 5 } },
	{ id = "roubar1", tipo = "roubar", meta = 1, premio = { tipo = "dinheiro", minimo = 10000, minutos = 10 } },
	{ id = "roubar2", tipo = "roubar", meta = 2, premio = { tipo = "dinheiro", minimo = 20000, minutos = 15 } },
	{ id = "comprar5", tipo = "comprar", meta = 5, premio = { tipo = "dinheiro", minimo = 5000, minutos = 5 } },
	{ id = "comprarRaro", tipo = "comprarRaridade", raridade = 3, meta = 1, premio = { tipo = "dinheiro", minimo = 15000, minutos = 10 } },
	{ id = "comprarEpico", tipo = "comprarRaridade", raridade = 4, meta = 1, premio = { tipo = "sorte", minutos = 5 } },
	{ id = "vender3", tipo = "vender", meta = 3, premio = { tipo = "dinheiro", minimo = 5000, minutos = 5 } },
	{ id = "tapa", tipo = "tapaLadrao", meta = 1, premio = { tipo = "dinheiro", minimo = 15000, minutos = 10 } },
	{ id = "trancar", tipo = "trancar", meta = 3, premio = { tipo = "dinheiro", minimo = 5000, minutos = 5 } },
	{ id = "melhorar", tipo = "melhorar", meta = 1, premio = { tipo = "dinheiro", minimo = 10000, minutos = 10 } },
}
Config.MISSOES_POR_DIA = 3

-- Dinheiro ganho com o jogo fechado -----------------------------------------
Config.OFFLINE = {
	MAX_HORAS = 4,
	EFICIENCIA = 0.5, -- rende 50% do normal
	MINIMO_SEGUNDOS = 120, -- menos que isso não conta
}

-- Bônus ----------------------------------------------------------------------
Config.BONUS = {
	POR_AMIGO = 0.10, -- +10% por amigo no servidor
	MAX_AMIGOS = 4,
	PREMIUM = 0.10, -- assinantes do Roblox Premium
	POR_RARIDADE_COMPLETA = 0.05, -- completar todos os robôs de uma raridade no Índice
}

-- Grupo do Roblox (0 = desligado). Crie o grupo e cole o número aqui.
Config.GRUPO = { ID = 0, BONUS = 0.10, RARIDADE_PREMIO = 3 }

-- Raridades ------------------------------------------------------------------
-- peso = chance relativa de aparecer na esteira
Config.Raridades = {
	{ nome = "Comum", en = "Common", cor = Color3.fromRGB(214, 220, 229), peso = 50, escala = 1.0 },
	{ nome = "Incomum", en = "Uncommon", cor = Color3.fromRGB(74, 222, 128), peso = 25, escala = 1.1 },
	{ nome = "Raro", en = "Rare", cor = Color3.fromRGB(56, 189, 248), peso = 13, escala = 1.2 },
	{ nome = "Épico", en = "Epic", cor = Color3.fromRGB(180, 107, 255), peso = 7, escala = 1.35 },
	{ nome = "Lendário", en = "Legendary", cor = Color3.fromRGB(251, 191, 36), peso = 3.5, escala = 1.5 },
	{ nome = "Mítico", en = "Mythic", cor = Color3.fromRGB(251, 90, 114), peso = 1.2, escala = 1.65 },
	{ nome = "Secreto", en = "Secret", cor = Color3.fromRGB(255, 107, 255), peso = 0.3, escala = 1.85 },
}

-- Mutações: aparecem por acaso e multiplicam preço e renda
Config.Mutacoes = {
	{ id = "dourado", nome = "Dourado", en = "Golden", chance = 0.08, mult = 2, cor = Color3.fromRGB(255, 200, 61) },
	{ id = "diamante", nome = "Diamante", en = "Diamond", chance = 0.02, mult = 4, cor = Color3.fromRGB(184, 241, 255) },
	{ id = "arcoiris", nome = "Arco-íris", en = "Rainbow", chance = 0.005, mult = 8, cor = Color3.fromRGB(255, 107, 213) },
}

-- Robôs ----------------------------------------------------------------------
-- forma: "caixa", "barril" ou "bola". preco em $, renda em $ por segundo.
Config.Robos = {
	-- Comum
	{ id = "parafusinho", nome = "Parafusinho", en = "Little Bolt", raridade = 1, preco = 25, renda = 1,
		forma = "caixa", cor = Color3.fromRGB(160, 165, 175), detalhe = Color3.fromRGB(90, 95, 105) },
	{ id = "bipbop", nome = "Bip-Bop", en = "Beep-Boop", raridade = 1, preco = 60, renda = 2,
		forma = "bola", cor = Color3.fromRGB(120, 200, 230), detalhe = Color3.fromRGB(40, 90, 120) },
	{ id = "torradeira", nome = "Torradeira Turbo", en = "Turbo Toaster", raridade = 1, preco = 150, renda = 5,
		forma = "caixa", cor = Color3.fromRGB(240, 138, 75), detalhe = Color3.fromRGB(107, 74, 58) },

	-- Incomum
	{ id = "ventilador", nome = "Ventilador Valente", en = "Brave Fan", raridade = 2, preco = 400, renda = 12,
		forma = "barril", cor = Color3.fromRGB(110, 214, 160), detalhe = Color3.fromRGB(40, 80, 70) },
	{ id = "lata", nome = "Lata Elétrica", en = "Shocking Can", raridade = 2, preco = 900, renda = 25,
		forma = "barril", cor = Color3.fromRGB(230, 60, 60), detalhe = Color3.fromRGB(240, 240, 240) },
	{ id = "aspirador", nome = "Aspirador Espião", en = "Spy Vacuum", raridade = 2, preco = 2000, renda = 50,
		forma = "bola", cor = Color3.fromRGB(60, 60, 70), detalhe = Color3.fromRGB(0, 255, 140) },

	-- Raro
	{ id = "microondas", nome = "Micro-ondas Maluco", en = "Crazy Microwave", raridade = 3, preco = 5000, renda = 110,
		forma = "caixa", cor = Color3.fromRGB(235, 235, 240), detalhe = Color3.fromRGB(40, 40, 50) },
	{ id = "drone", nome = "Drone Fofoqueiro", en = "Gossip Drone", raridade = 3, preco = 12000, renda = 240,
		forma = "bola", cor = Color3.fromRGB(255, 159, 61), detalhe = Color3.fromRGB(42, 46, 69) },
	{ id = "geladeira", nome = "Geladeira Ninja", en = "Ninja Fridge", raridade = 3, preco = 25000, renda = 450,
		forma = "caixa", cor = Color3.fromRGB(42, 46, 69), detalhe = Color3.fromRGB(225, 29, 72) },

	-- Épico
	{ id = "liquidificador", nome = "Liquidificador Sinistro", en = "Sinister Blender", raridade = 4, preco = 60000, renda = 1000,
		forma = "barril", cor = Color3.fromRGB(120, 60, 180), detalhe = Color3.fromRGB(200, 255, 80) },
	{ id = "pastel", nome = "Robô Pastel", en = "Pastry Bot", raridade = 4, preco = 140000, renda = 2200,
		forma = "caixa", cor = Color3.fromRGB(244, 198, 110), detalhe = Color3.fromRGB(168, 100, 42) },
	{ id = "tanquinho", nome = "Tanquinho 3000", en = "Washer 3000", raridade = 4, preco = 300000, renda = 4500,
		forma = "barril", cor = Color3.fromRGB(200, 230, 255), detalhe = Color3.fromRGB(40, 110, 220) },

	-- Lendário
	{ id = "capitao", nome = "Capitão Circuito", en = "Captain Circuit", raridade = 5, preco = 750000, renda = 10000,
		forma = "caixa", cor = Color3.fromRGB(30, 90, 200), detalhe = Color3.fromRGB(255, 210, 0) },
	{ id = "forro", nome = "Ciborgue do Forró", en = "Disco Cyborg", raridade = 5, preco = 1800000, renda = 22000,
		forma = "bola", cor = Color3.fromRGB(192, 122, 61), detalhe = Color3.fromRGB(251, 228, 122) },
	{ id = "bateria", nome = "Rainha Bateria", en = "Battery Queen", raridade = 5, preco = 4000000, renda = 45000,
		forma = "barril", cor = Color3.fromRGB(255, 225, 77), detalhe = Color3.fromRGB(42, 46, 69) },

	-- Mítico
	{ id = "sucata", nome = "Titã de Sucata", en = "Scrap Titan", raridade = 6, preco = 10000000, renda = 100000,
		forma = "caixa", cor = Color3.fromRGB(130, 90, 60), detalhe = Color3.fromRGB(255, 90, 30) },
	{ id = "dragao", nome = "Dragão Mecânico", en = "Mecha Dragon", raridade = 6, preco = 25000000, renda = 220000,
		forma = "barril", cor = Color3.fromRGB(46, 154, 91), detalhe = Color3.fromRGB(255, 77, 77) },
	{ id = "colosso", nome = "Colosso Turbinado", en = "Turbo Colossus", raridade = 6, preco = 60000000, renda = 500000,
		forma = "caixa", cor = Color3.fromRGB(90, 90, 110), detalhe = Color3.fromRGB(0, 220, 255) },

	-- Secreto
	{ id = "fantasma", nome = "Robô Fantasma", en = "Ghost Bot", raridade = 7, preco = 150000000, renda = 1200000,
		forma = "bola", cor = Color3.fromRGB(235, 240, 255), detalhe = Color3.fromRGB(120, 200, 255) },
	{ id = "galactico", nome = "Núcleo Galáctico", en = "Galactic Core", raridade = 7, preco = 400000000, renda = 3000000,
		forma = "bola", cor = Color3.fromRGB(42, 22, 96), detalhe = Color3.fromRGB(255, 107, 255) },
	{ id = "supremo", nome = "Supremo Pixel", en = "Supreme Pixel", raridade = 7, preco = 1000000000, renda = 8000000,
		forma = "caixa", cor = Color3.fromRGB(20, 20, 20), detalhe = Color3.fromRGB(0, 255, 120) },
}

-- Loja com Robux -------------------------------------------------------------
-- Crie os Passes e Produtos no Creator Hub (seu jogo > Monetização) e cole os
-- números (IDs) aqui. Com id = 0 o item não aparece. "preco" é só o valor
-- mostrado enquanto o preço real ainda não carregou.
Config.LOJA = {
	PASSES = {
		{ chave = "dobro", id = 0, preco = 149 }, -- dinheiro em dobro
		{ chave = "vip", id = 0, preco = 199 }, -- etiqueta, +50% e robô Épico
		{ chave = "vagas", id = 0, preco = 99 }, -- +5 vagas
		{ chave = "tranca", id = 0, preco = 49 }, -- tranca dura o dobro
	},
	PACOTES = {
		{ chave = "maleta", id = 0, preco = 25, minutos = 10, minimo = 5000 },
		{ chave = "cofre", id = 0, preco = 99, minutos = 60, minimo = 50000 },
		{ chave = "banco", id = 0, preco = 249, minutos = 240, minimo = 250000 },
	},
	SORTE = { id = 0, preco = 49, minutos = 15 },
	CAIXA = {
		id = 0,
		preco = 149,
		chances = {
			{ raridade = 4, peso = 70 },
			{ raridade = 5, peso = 24 },
			{ raridade = 6, peso = 5 },
			{ raridade = 7, peso = 1 },
		},
	},
	-- Anúncio com prêmio: crie um Produto de Desenvolvedor só para o anúncio
	ANUNCIO = { id = 0, minutos = 10 },
	VIP_BONUS = 0.5,
	VIP_ROBO_RARIDADE = 4,
}

-- Sons (troque pelos do seu jogo; vazio = sem som) --------------------------
Config.SONS = {
	compra = "rbxasset://sounds/electronicpingshort.wav",
	tapa = "rbxasset://sounds/swordslash.wav",
	alerta = "",
	roubo = "",
	premio = "",
	renascer = "",
	clique = "",
}

-- Índices auxiliares (não mexa) ----------------------------------------------
Config.RoboPorId = {}
for _, robo in ipairs(Config.Robos) do
	Config.RoboPorId[robo.id] = robo
end

Config.MutacaoPorId = {}
for _, mutacao in ipairs(Config.Mutacoes) do
	Config.MutacaoPorId[mutacao.id] = mutacao
end

Config.PassePorChave = {}
for _, passe in ipairs(Config.LOJA.PASSES) do
	Config.PassePorChave[passe.chave] = passe
end

Config.MissaoPorId = {}
for _, missao in ipairs(Config.MISSOES) do
	Config.MissaoPorId[missao.id] = missao
end

function Config.robosDaRaridade(raridade)
	local lista = {}
	for _, robo in ipairs(Config.Robos) do
		if robo.raridade == raridade then
			table.insert(lista, robo)
		end
	end
	return lista
end

function Config.custoRenascer(renascimentos)
	return Config.RENASCER.CUSTO_BASE * (Config.RENASCER.CRESCIMENTO ^ renascimentos)
end

function Config.multiplicadorRenascer(renascimentos)
	return 1 + Config.RENASCER.BONUS * renascimentos
end

function Config.duracaoTranca(renascimentos, passeTranca)
	local duracao = Config.TRANCA.DURACAO + Config.TRANCA.EXTRA_POR_RENASCIMENTO * renascimentos
	if passeTranca then
		duracao = duracao * 2
	end
	return duracao
end

-- custo para ir do nível atual para o próximo (nil se já está no máximo)
function Config.custoMelhoria(tipo, nivelAtual)
	local m = Config.MELHORIAS[tipo]
	if not m or nivelAtual >= m.max then
		return nil
	end
	return m.custoBase * (m.crescimento ^ nivelAtual)
end

function Config.vagasTotais(nivelVagas, passeVagas)
	local total = Config.VAGAS.INICIAIS + math.min(nivelVagas, Config.VAGAS.MAX_MELHORIAS)
	if passeVagas then
		total = total + Config.VAGAS.PASSE
	end
	return total
end

-- Preço e renda de um robô considerando a mutação (sem bônus do jogador)
function Config.precoDe(robo, mutacaoId)
	local mutacao = mutacaoId and Config.MutacaoPorId[mutacaoId]
	return robo.preco * (mutacao and mutacao.mult or 1)
end

function Config.rendaDe(robo, mutacaoId)
	local mutacao = mutacaoId and Config.MutacaoPorId[mutacaoId]
	return robo.renda * (mutacao and mutacao.mult or 1)
end

-- Nome no idioma: idioma = "pt" ou "en"
function Config.nomeDe(item, idioma)
	if idioma == "en" and item.en then
		return item.en
	end
	return item.nome
end

function Config.nomeCompleto(robo, mutacaoId, idioma)
	local mutacao = mutacaoId and Config.MutacaoPorId[mutacaoId]
	local nome = Config.nomeDe(robo, idioma)
	if mutacao then
		if idioma == "en" then
			return mutacao.en .. " " .. nome
		end
		return nome .. " " .. mutacao.nome
	end
	return nome
end

-- Recompensa em dinheiro: o maior entre o mínimo e alguns minutos de renda
function Config.dinheiroDe(premio, rendaPorSegundo)
	return math.floor(math.max(premio.minimo or 0, (rendaPorSegundo or 0) * 60 * (premio.minutos or 0)))
end

local function sortearPeso(lista, campoPeso, aleatorio)
	local total = 0
	for _, item in ipairs(lista) do
		total = total + item[campoPeso]
	end
	local alvo = aleatorio:NextNumber() * total
	for _, item in ipairs(lista) do
		alvo = alvo - item[campoPeso]
		if alvo <= 0 then
			return item
		end
	end
	return lista[#lista]
end

function Config.sortearMutacao(aleatorio)
	local dado = aleatorio:NextNumber()
	for i = #Config.Mutacoes, 1, -1 do
		local mutacao = Config.Mutacoes[i]
		if dado < mutacao.chance then
			return mutacao.id
		end
	end
	return nil
end

-- Sorteia um robô e uma mutação. `sorte` > 1 favorece Raro ou melhor.
function Config.sortear(sorte, aleatorio)
	sorte = sorte or 1
	aleatorio = aleatorio or Random.new()
	local opcoes = {}
	for i, raridade in ipairs(Config.Raridades) do
		local peso = raridade.peso
		if i >= 3 then
			peso = peso * sorte
		end
		table.insert(opcoes, { raridade = i, peso = peso })
	end
	local escolhida = sortearPeso(opcoes, "peso", aleatorio).raridade
	local candidatos = Config.robosDaRaridade(escolhida)
	local robo = candidatos[aleatorio:NextInteger(1, #candidatos)]
	return robo, Config.sortearMutacao(aleatorio)
end

-- Robô aleatório de uma raridade exata (prêmios)
function Config.sortearDaRaridade(raridade, aleatorio)
	aleatorio = aleatorio or Random.new()
	local candidatos = Config.robosDaRaridade(raridade)
	return candidatos[aleatorio:NextInteger(1, #candidatos)]
end

-- Robô da caixa surpresa (sempre Épico ou melhor)
function Config.sortearCaixa(aleatorio)
	aleatorio = aleatorio or Random.new()
	local raridade = sortearPeso(Config.LOJA.CAIXA.chances, "peso", aleatorio).raridade
	return Config.sortearDaRaridade(raridade, aleatorio), Config.sortearMutacao(aleatorio)
end

-- As 3 missões do dia são as mesmas para o jogador o dia inteiro
function Config.missoesDoDia(dia, userId)
	local aleatorio = Random.new(dia * 7919 + (userId % 100003))
	local restantes = {}
	for _, missao in ipairs(Config.MISSOES) do
		table.insert(restantes, missao)
	end
	local escolhidas = {}
	for _ = 1, math.min(Config.MISSOES_POR_DIA, #restantes) do
		local i = aleatorio:NextInteger(1, #restantes)
		table.insert(escolhidas, table.remove(restantes, i))
	end
	return escolhidas
end

return Config
