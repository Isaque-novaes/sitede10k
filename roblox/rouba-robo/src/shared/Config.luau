--[[
	Rouba Robô — configuração do jogo.

	Tudo que dá pra ajustar sem mexer na lógica fica aqui: preços, renda,
	chances, tempos, robôs e loja. Este módulo fica em ReplicatedStorage,
	então o servidor e os jogadores leem os mesmos valores.
]]

local Config = {}

Config.NOME_DO_JOGO = "Rouba Robô"

-- Economia -------------------------------------------------------------------
Config.DINHEIRO_INICIAL = 100
Config.VAGAS_POR_BASE = 10
Config.VENDA_DEVOLVE = 0.5 -- vender um robô devolve 50% do preço

-- Esteira da fábrica ---------------------------------------------------------
Config.ESTEIRA = {
	INTERVALO = 2.2, -- segundos entre um robô e outro
	VELOCIDADE = 7, -- studs por segundo
}

-- Roubo ----------------------------------------------------------------------
Config.ROUBO = {
	SEGURAR = 1, -- segundos segurando E para roubar ou vender
	VELOCIDADE_CARREGANDO = 11, -- velocidade de quem está carregando um robô
	VELOCIDADE_NORMAL = 16,
	TEMPO_MAXIMO = 45, -- depois disso o robô volta sozinho pro dono
}

-- Tranca da base -------------------------------------------------------------
Config.TRANCA = {
	DURACAO = 60, -- segundos
	EXTRA_POR_RENASCIMENTO = 10,
}

-- Tapa (a arma de defesa) ----------------------------------------------------
Config.TAPA = {
	RECARGA = 1.2,
	ALCANCE = 8,
	FORCA = 70,
}

-- Renascimento ---------------------------------------------------------------
Config.RENASCER = {
	CUSTO_BASE = 1000000,
	CRESCIMENTO = 5, -- cada renascimento custa 5x o anterior
	BONUS = 0.5, -- +50% de renda por renascimento
}

-- Evento "Hora da Sorte" -----------------------------------------------------
Config.HORA_DA_SORTE = {
	A_CADA = 600, -- segundos entre eventos
	DURACAO = 120,
	SORTE = 3, -- multiplica a chance de robôs Raro ou melhor
}

-- Raridades ------------------------------------------------------------------
-- peso = chance relativa de aparecer na esteira.
Config.Raridades = {
	{ nome = "Comum", cor = Color3.fromRGB(200, 200, 200), peso = 50, escala = 1.0 },
	{ nome = "Incomum", cor = Color3.fromRGB(90, 220, 110), peso = 25, escala = 1.1 },
	{ nome = "Raro", cor = Color3.fromRGB(70, 160, 255), peso = 13, escala = 1.2 },
	{ nome = "Épico", cor = Color3.fromRGB(180, 90, 255), peso = 7, escala = 1.35 },
	{ nome = "Lendário", cor = Color3.fromRGB(255, 190, 40), peso = 3.5, escala = 1.5 },
	{ nome = "Mítico", cor = Color3.fromRGB(255, 70, 70), peso = 1.2, escala = 1.65 },
	{ nome = "Secreto", cor = Color3.fromRGB(30, 30, 30), peso = 0.3, escala = 1.85 },
}

-- Mutações: aparecem por acaso e multiplicam preço e renda.
Config.Mutacoes = {
	{ id = "dourado", nome = "Dourado", chance = 0.08, mult = 2, cor = Color3.fromRGB(255, 200, 40) },
	{ id = "diamante", nome = "Diamante", chance = 0.02, mult = 4, cor = Color3.fromRGB(150, 235, 255) },
	{ id = "arcoiris", nome = "Arco-íris", chance = 0.005, mult = 8, cor = Color3.fromRGB(255, 120, 200) },
}

-- Robôs ----------------------------------------------------------------------
-- forma: "caixa", "barril" ou "bola". preco em $, renda em $ por segundo.
Config.Robos = {
	-- Comum
	{ id = "parafusinho", nome = "Parafusinho", raridade = 1, preco = 25, renda = 1,
		forma = "caixa", cor = Color3.fromRGB(160, 165, 175), detalhe = Color3.fromRGB(90, 95, 105) },
	{ id = "bipbop", nome = "Bip-Bop", raridade = 1, preco = 60, renda = 2,
		forma = "bola", cor = Color3.fromRGB(120, 200, 230), detalhe = Color3.fromRGB(40, 90, 120) },
	{ id = "torradeira", nome = "Torradeira Turbo", raridade = 1, preco = 150, renda = 5,
		forma = "caixa", cor = Color3.fromRGB(210, 120, 70), detalhe = Color3.fromRGB(70, 50, 40) },

	-- Incomum
	{ id = "ventilador", nome = "Ventilador Valente", raridade = 2, preco = 400, renda = 12,
		forma = "barril", cor = Color3.fromRGB(110, 210, 160), detalhe = Color3.fromRGB(40, 80, 70) },
	{ id = "lata", nome = "Lata Elétrica", raridade = 2, preco = 900, renda = 25,
		forma = "barril", cor = Color3.fromRGB(230, 60, 60), detalhe = Color3.fromRGB(240, 240, 240) },
	{ id = "aspirador", nome = "Aspirador Espião", raridade = 2, preco = 2000, renda = 50,
		forma = "bola", cor = Color3.fromRGB(60, 60, 70), detalhe = Color3.fromRGB(0, 255, 140) },

	-- Raro
	{ id = "microondas", nome = "Micro-ondas Maluco", raridade = 3, preco = 5000, renda = 110,
		forma = "caixa", cor = Color3.fromRGB(235, 235, 240), detalhe = Color3.fromRGB(40, 40, 50) },
	{ id = "drone", nome = "Drone Fofoqueiro", raridade = 3, preco = 12000, renda = 240,
		forma = "bola", cor = Color3.fromRGB(255, 140, 40), detalhe = Color3.fromRGB(30, 30, 30) },
	{ id = "geladeira", nome = "Geladeira Ninja", raridade = 3, preco = 25000, renda = 450,
		forma = "caixa", cor = Color3.fromRGB(30, 35, 45), detalhe = Color3.fromRGB(220, 30, 30) },

	-- Épico
	{ id = "liquidificador", nome = "Liquidificador Sinistro", raridade = 4, preco = 60000, renda = 1000,
		forma = "barril", cor = Color3.fromRGB(120, 60, 180), detalhe = Color3.fromRGB(200, 255, 80) },
	{ id = "pastel", nome = "Robô Pastel", raridade = 4, preco = 140000, renda = 2200,
		forma = "caixa", cor = Color3.fromRGB(240, 200, 110), detalhe = Color3.fromRGB(170, 100, 40) },
	{ id = "tanquinho", nome = "Tanquinho 3000", raridade = 4, preco = 300000, renda = 4500,
		forma = "barril", cor = Color3.fromRGB(200, 230, 255), detalhe = Color3.fromRGB(40, 110, 220) },

	-- Lendário
	{ id = "capitao", nome = "Capitão Circuito", raridade = 5, preco = 750000, renda = 10000,
		forma = "caixa", cor = Color3.fromRGB(30, 90, 200), detalhe = Color3.fromRGB(255, 210, 0) },
	{ id = "forro", nome = "Ciborgue do Forró", raridade = 5, preco = 1800000, renda = 22000,
		forma = "bola", cor = Color3.fromRGB(190, 120, 60), detalhe = Color3.fromRGB(250, 230, 120) },
	{ id = "bateria", nome = "Rainha Bateria", raridade = 5, preco = 4000000, renda = 45000,
		forma = "barril", cor = Color3.fromRGB(255, 220, 60), detalhe = Color3.fromRGB(30, 30, 30) },

	-- Mítico
	{ id = "sucata", nome = "Titã de Sucata", raridade = 6, preco = 10000000, renda = 100000,
		forma = "caixa", cor = Color3.fromRGB(130, 90, 60), detalhe = Color3.fromRGB(255, 90, 30) },
	{ id = "dragao", nome = "Dragão Mecânico", raridade = 6, preco = 25000000, renda = 220000,
		forma = "barril", cor = Color3.fromRGB(40, 140, 80), detalhe = Color3.fromRGB(255, 60, 60) },
	{ id = "colosso", nome = "Colosso Turbinado", raridade = 6, preco = 60000000, renda = 500000,
		forma = "caixa", cor = Color3.fromRGB(90, 90, 110), detalhe = Color3.fromRGB(0, 220, 255) },

	-- Secreto
	{ id = "fantasma", nome = "Robô Fantasma", raridade = 7, preco = 150000000, renda = 1200000,
		forma = "bola", cor = Color3.fromRGB(235, 240, 255), detalhe = Color3.fromRGB(120, 200, 255) },
	{ id = "galactico", nome = "Núcleo Galáctico", raridade = 7, preco = 400000000, renda = 3000000,
		forma = "bola", cor = Color3.fromRGB(40, 20, 90), detalhe = Color3.fromRGB(255, 100, 255) },
	{ id = "supremo", nome = "Supremo Pixel", raridade = 7, preco = 1000000000, renda = 8000000,
		forma = "caixa", cor = Color3.fromRGB(20, 20, 20), detalhe = Color3.fromRGB(0, 255, 120) },
}

-- Loja (opcional) ------------------------------------------------------------
-- Crie o Passe de Jogo e os Produtos no site do Roblox (Criações > seu jogo >
-- Monetização) e cole os números aqui. Com 0 o item não aparece na loja.
Config.Loja = {
	PASSE_DINHEIRO_EM_DOBRO = 0,
	PACOTES = {
		-- recompensa = o maior valor entre "minimo" e "minutos" de renda atual
		{ id = 0, nome = "Maleta de Dinheiro", minutos = 10, minimo = 5000 },
		{ id = 0, nome = "Cofre de Dinheiro", minutos = 60, minimo = 50000 },
	},
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

function Config.custoRenascer(renascimentos)
	return Config.RENASCER.CUSTO_BASE * (Config.RENASCER.CRESCIMENTO ^ renascimentos)
end

function Config.multiplicador(renascimentos)
	return 1 + Config.RENASCER.BONUS * renascimentos
end

function Config.duracaoTranca(renascimentos)
	return Config.TRANCA.DURACAO + Config.TRANCA.EXTRA_POR_RENASCIMENTO * renascimentos
end

-- Preço e renda de um robô considerando a mutação (sem bônus do jogador).
function Config.precoDe(robo, mutacaoId)
	local mutacao = mutacaoId and Config.MutacaoPorId[mutacaoId]
	return robo.preco * (mutacao and mutacao.mult or 1)
end

function Config.rendaDe(robo, mutacaoId)
	local mutacao = mutacaoId and Config.MutacaoPorId[mutacaoId]
	return robo.renda * (mutacao and mutacao.mult or 1)
end

function Config.nomeCompleto(robo, mutacaoId)
	local mutacao = mutacaoId and Config.MutacaoPorId[mutacaoId]
	if mutacao then
		return robo.nome .. " " .. mutacao.nome
	end
	return robo.nome
end

-- Sorteia um robô e uma mutação. `sorte` > 1 favorece Raro ou melhor.
-- `aleatorio` é um objeto Random (opcional, ajuda nos testes).
function Config.sortear(sorte, aleatorio)
	sorte = sorte or 1
	aleatorio = aleatorio or Random.new()

	local total = 0
	local pesos = {}
	for i, raridade in ipairs(Config.Raridades) do
		local peso = raridade.peso
		if i >= 3 then
			peso = peso * sorte
		end
		pesos[i] = peso
		total = total + peso
	end

	local alvo = aleatorio:NextNumber() * total
	local escolhida = #Config.Raridades
	for i, peso in ipairs(pesos) do
		alvo = alvo - peso
		if alvo <= 0 then
			escolhida = i
			break
		end
	end

	local candidatos = {}
	for _, robo in ipairs(Config.Robos) do
		if robo.raridade == escolhida then
			table.insert(candidatos, robo)
		end
	end
	local robo = candidatos[aleatorio:NextInteger(1, #candidatos)]

	local mutacaoId = nil
	local dado = aleatorio:NextNumber()
	-- da mais rara para a mais comum
	for i = #Config.Mutacoes, 1, -1 do
		local mutacao = Config.Mutacoes[i]
		if dado < mutacao.chance then
			mutacaoId = mutacao.id
			break
		end
	end

	return robo, mutacaoId
end

return Config
