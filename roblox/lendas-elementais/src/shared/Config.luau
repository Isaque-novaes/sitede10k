--[[
	Elemental Legends / Lendas Elementais — configuração do jogo.

	Mundo aberto: você aprende elementos, bate em monstros para subir de
	nível e, nas zonas mais fortes, pode lutar contra outros jogadores.

	Tudo que dá para ajustar sem mexer na lógica está aqui: níveis, dano,
	elementos, zonas, monstros, melhorias, prêmios e loja.
]]

local Config = {}

Config.NOME = { pt = "Lendas Elementais", en = "Elemental Legends" }

-- Jogador --------------------------------------------------------------------
Config.NIVEL_MAXIMO = 100
Config.MOEDAS_INICIAIS = 100

-- XP que falta para o próximo nível
function Config.xpDoNivel(nivel)
	return math.floor(80 * nivel ^ 1.5 + 120)
end

-- Vida e dano crescem com o nível (as melhorias somam em cima)
function Config.vidaBase(nivel)
	return 100 + 8 * (nivel - 1)
end

function Config.danoBase(nivel)
	return 10 + 2 * (nivel - 1)
end

Config.VELOCIDADE_BASE = 18
Config.PULO_BASE = 50
Config.RESPAWN = 4 -- segundos até voltar depois de morrer
Config.REGENERACAO = 0.02 -- fração da vida máxima por segundo, fora de combate
Config.TEMPO_EM_COMBATE = 6 -- segundos sem apanhar para começar a regenerar

-- Melhorias compradas com moedas do jogo (nunca com Robux)
Config.MELHORIAS = {
	vida = { max = 10, custoBase = 300, crescimento = 1.8, bonus = 0.12 }, -- +12% de vida por nível
	dano = { max = 10, custoBase = 400, crescimento = 1.9, bonus = 0.10 }, -- +10% de dano por nível
	velocidade = { max = 5, custoBase = 800, crescimento = 2.2, bonus = 0.06 }, -- +6% de velocidade
}

-- Elementos ------------------------------------------------------------------
-- Cada elemento tem 3 golpes: basico (clique), especial (Q) e supremo (E).
--   dano     = multiplica o dano base do jogador
--   recarga  = segundos até poder usar de novo
--   alcance  = até onde o tiro vai (studs)
--   raio     = tamanho da explosão (0 = acerta só quem for atingido)
--   efeito   = "lentidao", "impulso", "escudo" ou "sumir"
Config.Elementos = {
	{
		id = "fogo", nome = "Fogo", en = "Fire",
		nivel = 1, custo = 0,
		cor = Color3.fromRGB(255, 108, 34), corClara = Color3.fromRGB(255, 214, 120),
		basico = { nome = "Bola de Fogo", en = "Fireball", dano = 1, recarga = 0.6, velocidade = 110, alcance = 190, raio = 0, tamanho = 1.6 },
		especial = { nome = "Explosão", en = "Blast", dano = 2.2, recarga = 7, velocidade = 85, alcance = 160, raio = 14, tamanho = 2.6 },
		supremo = { nome = "Chuva de Meteoros", en = "Meteor Rain", dano = 4.5, recarga = 16, velocidade = 70, alcance = 150, raio = 22, tamanho = 4, tiros = 3 },
	},
	{
		id = "gelo", nome = "Gelo", en = "Ice",
		nivel = 5, custo = 500,
		cor = Color3.fromRGB(120, 215, 255), corClara = Color3.fromRGB(225, 248, 255),
		basico = { nome = "Lança de Gelo", en = "Ice Spear", dano = 1.3, recarga = 0.85, velocidade = 95, alcance = 200, raio = 0, tamanho = 1.5, efeito = "lentidao" },
		especial = { nome = "Campo Congelante", en = "Frost Field", dano = 1.8, recarga = 8, velocidade = 70, alcance = 140, raio = 18, tamanho = 3, efeito = "lentidao" },
		supremo = { nome = "Nevasca", en = "Blizzard", dano = 4, recarga = 18, velocidade = 60, alcance = 130, raio = 26, tamanho = 4.5, efeito = "lentidao" },
	},
	{
		id = "raio", nome = "Raio", en = "Lightning",
		nivel = 15, custo = 3000,
		cor = Color3.fromRGB(255, 232, 60), corClara = Color3.fromRGB(255, 255, 210),
		basico = { nome = "Faísca", en = "Spark", dano = 0.85, recarga = 0.4, velocidade = 180, alcance = 220, raio = 0, tamanho = 1.2 },
		especial = { nome = "Avanço Elétrico", en = "Thunder Dash", dano = 1.6, recarga = 6, velocidade = 200, alcance = 120, raio = 10, tamanho = 2, efeito = "impulso" },
		supremo = { nome = "Tempestade", en = "Thunderstorm", dano = 3.8, recarga = 15, velocidade = 190, alcance = 200, raio = 20, tamanho = 3, tiros = 5 },
	},
	{
		id = "pedra", nome = "Pedra", en = "Stone",
		nivel = 30, custo = 15000,
		cor = Color3.fromRGB(150, 128, 100), corClara = Color3.fromRGB(205, 190, 165),
		basico = { nome = "Pedregulho", en = "Boulder", dano = 1.7, recarga = 1.1, velocidade = 75, alcance = 170, raio = 5, tamanho = 2.4 },
		especial = { nome = "Pele de Pedra", en = "Stone Skin", dano = 0, recarga = 20, alcance = 0, raio = 0, tamanho = 0, efeito = "escudo", duracao = 8, reducao = 0.5 },
		supremo = { nome = "Terremoto", en = "Earthquake", dano = 4.2, recarga = 17, velocidade = 1, alcance = 0, raio = 30, tamanho = 5, empurrao = 90 },
	},
	{
		id = "vento", nome = "Vento", en = "Wind",
		nivel = 50, custo = 60000,
		cor = Color3.fromRGB(150, 255, 205), corClara = Color3.fromRGB(230, 255, 245),
		basico = { nome = "Lâminas de Vento", en = "Wind Blades", dano = 0.55, recarga = 0.45, velocidade = 200, alcance = 180, raio = 0, tamanho = 1.1, tiros = 3, abertura = 7 },
		especial = { nome = "Impulso", en = "Updraft", dano = 1.4, recarga = 7, velocidade = 120, alcance = 100, raio = 12, tamanho = 2.2, efeito = "impulso" },
		supremo = { nome = "Tornado", en = "Tornado", dano = 4, recarga = 16, velocidade = 45, alcance = 160, raio = 20, tamanho = 6, empurrao = 60 },
	},
	{
		id = "sombra", nome = "Sombra", en = "Shadow",
		nivel = 75, custo = 250000,
		cor = Color3.fromRGB(150, 70, 230), corClara = Color3.fromRGB(225, 170, 255),
		basico = { nome = "Míssil Sombrio", en = "Shadow Bolt", dano = 1.45, recarga = 0.7, velocidade = 130, alcance = 230, raio = 0, tamanho = 1.6, teleguiado = true },
		especial = { nome = "Sumir", en = "Vanish", dano = 0, recarga = 22, alcance = 0, raio = 0, tamanho = 0, efeito = "sumir", duracao = 5 },
		supremo = { nome = "Fenda Sombria", en = "Void Rift", dano = 5, recarga = 20, velocidade = 90, alcance = 180, raio = 24, tamanho = 5 },
	},
}

Config.GOLPES = { "basico", "especial", "supremo" }

-- Zonas ----------------------------------------------------------------------
-- pvp = true: jogadores podem se atacar. Nas zonas seguras, ninguém te acerta.
Config.Zonas = {
	{
		id = "vila", nome = "Vila Central", en = "Central Village",
		centro = Vector2.new(0, 0), raio = 120, pvp = false, nivelMinimo = 0,
		corChao = Color3.fromRGB(126, 217, 87), corCeu = Color3.fromRGB(143, 216, 255),
	},
	{
		id = "campo", nome = "Campo Verde", en = "Green Fields",
		centro = Vector2.new(0, -620), raio = 230, pvp = false, nivelMinimo = 0,
		corChao = Color3.fromRGB(106, 200, 90), corCeu = Color3.fromRGB(143, 216, 255),
		monstros = { "limo", "cogumelo" }, chefe = "reiLimo",
	},
	{
		id = "deserto", nome = "Deserto em Chamas", en = "Burning Desert",
		centro = Vector2.new(640, 0), raio = 240, pvp = true, nivelMinimo = 12,
		corChao = Color3.fromRGB(240, 196, 110), corCeu = Color3.fromRGB(255, 170, 110),
		monstros = { "diabrete", "escorpiao" }, chefe = "senhorChamas",
	},
	{
		id = "pico", nome = "Pico Gelado", en = "Frozen Peak",
		centro = Vector2.new(0, 640), raio = 240, pvp = true, nivelMinimo = 30,
		corChao = Color3.fromRGB(226, 243, 255), corCeu = Color3.fromRGB(190, 225, 255),
		monstros = { "golem", "lobo" }, chefe = "titaCongelado",
	},
	{
		id = "ruinas", nome = "Ruínas Sombrias", en = "Shadow Ruins",
		centro = Vector2.new(-680, 0), raio = 250, pvp = true, nivelMinimo = 55,
		corChao = Color3.fromRGB(78, 64, 110), corCeu = Color3.fromRGB(70, 50, 110),
		monstros = { "espectro", "guardiao" }, chefe = "devorador",
	},
}

Config.ZonaPorId = {}
for _, zona in ipairs(Config.Zonas) do
	Config.ZonaPorId[zona.id] = zona
end

-- Monstros -------------------------------------------------------------------
-- forma: "bola", "caixa" ou "alto". anda: true = pula no chão, false = flutua.
Config.Monstros = {
	limo = { nome = "Limo Verde", en = "Green Slime", nivelMin = 1, nivelMax = 8, forma = "bola",
		cor = Color3.fromRGB(110, 220, 120), detalhe = Color3.fromRGB(40, 120, 60), escala = 1, anda = true, velocidade = 11, quantidade = 14 },
	cogumelo = { nome = "Cogumelo Bravo", en = "Angry Mushroom", nivelMin = 8, nivelMax = 15, forma = "alto",
		cor = Color3.fromRGB(230, 90, 110), detalhe = Color3.fromRGB(250, 235, 210), escala = 1.1, anda = true, velocidade = 13, quantidade = 10 },
	diabrete = { nome = "Diabrete de Fogo", en = "Fire Imp", nivelMin = 15, nivelMax = 25, forma = "alto",
		cor = Color3.fromRGB(255, 120, 50), detalhe = Color3.fromRGB(90, 30, 20), escala = 1.1, anda = false, velocidade = 16, quantidade = 12, atira = true },
	escorpiao = { nome = "Escorpião de Lava", en = "Lava Scorpion", nivelMin = 25, nivelMax = 35, forma = "caixa",
		cor = Color3.fromRGB(60, 40, 45), detalhe = Color3.fromRGB(255, 90, 30), escala = 1.35, anda = true, velocidade = 15, quantidade = 10 },
	golem = { nome = "Golem de Gelo", en = "Ice Golem", nivelMin = 35, nivelMax = 48, forma = "caixa",
		cor = Color3.fromRGB(170, 225, 255), detalhe = Color3.fromRGB(70, 130, 190), escala = 1.5, anda = true, velocidade = 12, quantidade = 10 },
	lobo = { nome = "Lobo da Neve", en = "Snow Wolf", nivelMin = 48, nivelMax = 60, forma = "alto",
		cor = Color3.fromRGB(240, 248, 255), detalhe = Color3.fromRGB(100, 140, 180), escala = 1.25, anda = true, velocidade = 20, quantidade = 10 },
	espectro = { nome = "Espectro", en = "Wraith", nivelMin = 60, nivelMax = 80, forma = "alto",
		cor = Color3.fromRGB(150, 110, 220), detalhe = Color3.fromRGB(240, 220, 255), escala = 1.3, anda = false, velocidade = 18, quantidade = 10, atira = true },
	guardiao = { nome = "Guardião Sombrio", en = "Shadow Guardian", nivelMin = 80, nivelMax = 100, forma = "caixa",
		cor = Color3.fromRGB(45, 35, 70), detalhe = Color3.fromRGB(190, 90, 255), escala = 1.7, anda = true, velocidade = 14, quantidade = 8 },

	-- Chefes: mais vida, mais dano e muito mais recompensa
	reiLimo = { nome = "Rei Limo", en = "Slime King", nivel = 18, forma = "bola", chefe = true,
		cor = Color3.fromRGB(80, 230, 140), detalhe = Color3.fromRGB(255, 220, 90), escala = 3.4, anda = true, velocidade = 10 },
	senhorChamas = { nome = "Senhor das Chamas", en = "Flame Lord", nivel = 40, forma = "alto", chefe = true,
		cor = Color3.fromRGB(255, 80, 30), detalhe = Color3.fromRGB(255, 220, 90), escala = 3.2, anda = false, velocidade = 14, atira = true },
	titaCongelado = { nome = "Titã Congelado", en = "Frozen Titan", nivel = 65, forma = "caixa", chefe = true,
		cor = Color3.fromRGB(190, 235, 255), detalhe = Color3.fromRGB(40, 110, 190), escala = 3.6, anda = true, velocidade = 11 },
	devorador = { nome = "Devorador de Almas", en = "Soul Eater", nivel = 110, forma = "alto", chefe = true,
		cor = Color3.fromRGB(30, 20, 50), detalhe = Color3.fromRGB(220, 60, 255), escala = 4, anda = false, velocidade = 16, atira = true },
}

Config.MONSTRO = {
	AGRESSAO = 55, -- distância em que o monstro vem para cima
	DESISTE = 130, -- distância em que ele desiste e volta
	ALCANCE_ATAQUE = 9,
	ALCANCE_TIRO = 70,
	RECARGA_ATAQUE = 1.6,
	RENASCER = 8, -- segundos para voltar
	RENASCER_CHEFE = 150,
	VELOCIDADE_TIRO = 70,
}

function Config.vidaMonstro(nivel, chefe)
	local vida = 30 + 12 * nivel
	if chefe then
		vida = vida * 14
	end
	return math.floor(vida)
end

function Config.danoMonstro(nivel, chefe)
	local dano = 5 + 1.2 * nivel
	if chefe then
		dano = dano * 2
	end
	return math.floor(dano)
end

-- Um monstro do seu nível dá uns 8% do XP que falta: cerca de 12 por nível.
function Config.xpMonstro(nivel, chefe)
	local xp = Config.xpDoNivel(nivel) * 0.08
	if chefe then
		xp = xp * 15
	end
	return math.floor(xp)
end

function Config.moedasMonstro(nivel, chefe)
	local moedas = math.max(3, Config.xpMonstro(nivel, false) / 3)
	if chefe then
		moedas = moedas * 15
	end
	return math.floor(moedas)
end

-- PvP ------------------------------------------------------------------------
Config.PVP = {
	XP = 0.25, -- derrotar um jogador dá 25% do XP que falta para ele subir
	MOEDAS = 0.5, -- e metade disso em moedas
	ESPERA_MESMO_ALVO = 300, -- não ganha de novo do mesmo jogador antes disso
	DIFERENCA_NIVEL = 15, -- acima dessa diferença, derrotar não dá recompensa
}

-- Efeitos --------------------------------------------------------------------
Config.EFEITOS = {
	LENTIDAO = { fator = 0.55, duracao = 2.5 },
	IMPULSO = { forca = 90, altura = 55 },
	SUMIR = { transparencia = 0.85 },
}

-- Loja com moedas do jogo ----------------------------------------------------
-- (elementos e melhorias; nada aqui custa Robux)

-- Loja com Robux -------------------------------------------------------------
-- Crie os itens no Creator Hub e cole os números (IDs) aqui. id = 0 esconde.
Config.LOJA = {
	PASSES = {
		{ chave = "xp2", id = 0, preco = 149 }, -- XP em dobro
		{ chave = "moedas2", id = 0, preco = 149 }, -- moedas em dobro
		{ chave = "vip", id = 0, preco = 299 }, -- etiqueta, aura e +25%
		{ chave = "aura", id = 0, preco = 99 }, -- aura colorida à escolha
	},
	PACOTES = {
		{ chave = "bolsa", id = 0, preco = 25, moedas = 5000 },
		{ chave = "bau", id = 0, preco = 99, moedas = 25000 },
		{ chave = "tesouro", id = 0, preco = 249, moedas = 80000 },
	},
	-- Anúncio com prêmio: XP em dobro por alguns minutos
	ANUNCIO = { id = 0, minutos = 10 },
	VIP_BONUS = 0.25,
}

-- Auras (só visual; a do VIP é a dourada)
Config.Auras = {
	{ id = "nenhuma", nome = "Nenhuma", en = "None", cor = Color3.fromRGB(255, 255, 255) },
	{ id = "dourada", nome = "Dourada", en = "Golden", cor = Color3.fromRGB(255, 208, 70), vip = true },
	{ id = "fogo", nome = "Chamas", en = "Flames", cor = Color3.fromRGB(255, 110, 40), passe = "aura" },
	{ id = "gelo", nome = "Geada", en = "Frost", cor = Color3.fromRGB(130, 220, 255), passe = "aura" },
	{ id = "raio", nome = "Trovão", en = "Thunder", cor = Color3.fromRGB(255, 235, 70), passe = "aura" },
	{ id = "sombra", nome = "Sombra", en = "Shadow", cor = Color3.fromRGB(160, 80, 240), passe = "aura" },
}

-- Prêmio diário (7 dias) -----------------------------------------------------
Config.PREMIO_DIARIO = {
	{ tipo = "moedas", valor = 300 },
	{ tipo = "xp", nivelFracao = 0.3 },
	{ tipo = "moedas", valor = 2000 },
	{ tipo = "xp", nivelFracao = 0.8 },
	{ tipo = "moedas", valor = 12000 },
	{ tipo = "xp2", minutos = 30 },
	{ tipo = "moedas", valor = 60000 },
}

-- Missões diárias ------------------------------------------------------------
Config.MISSOES = {
	{ id = "matar10", tipo = "matar", meta = 10, premio = { tipo = "moedas", valor = 500 } },
	{ id = "matar30", tipo = "matar", meta = 30, premio = { tipo = "moedas", valor = 2000 } },
	{ id = "chefe", tipo = "chefe", meta = 1, premio = { tipo = "xp", nivelFracao = 0.5 } },
	{ id = "subir", tipo = "subirNivel", meta = 2, premio = { tipo = "moedas", valor = 1500 } },
	{ id = "jogador", tipo = "matarJogador", meta = 1, premio = { tipo = "moedas", valor = 2500 } },
	{ id = "tempo", tipo = "minutos", meta = 15, premio = { tipo = "xp2", minutos = 10 } },
	{ id = "elemento", tipo = "usarSupremo", meta = 10, premio = { tipo = "moedas", valor = 800 } },
	{ id = "visitar", tipo = "visitarZona", meta = 2, premio = { tipo = "moedas", valor = 600 } },
}
Config.MISSOES_POR_DIA = 3

-- Bônus ----------------------------------------------------------------------
Config.BONUS = {
	POR_AMIGO = 0.08,
	MAX_AMIGOS = 4,
	PREMIUM = 0.10,
	POR_ELEMENTO = 0.03, -- cada elemento aprendido dá +3% de XP
}

Config.GRUPO = { ID = 0, BONUS = 0.10, MOEDAS = 2000 }

-- Sons (troque pelos do seu jogo; vazio = sem som) --------------------------
Config.SONS = {
	tiro = "",
	acerto = "rbxasset://sounds/impact_water.mp3",
	morte = "",
	subirNivel = "rbxasset://sounds/electronicpingshort.wav",
	moeda = "",
	premio = "",
	chefe = "",
}

-- Índices e contas -----------------------------------------------------------
Config.ElementoPorId = {}
for _, elemento in ipairs(Config.Elementos) do
	Config.ElementoPorId[elemento.id] = elemento
end

Config.AuraPorId = {}
for _, aura in ipairs(Config.Auras) do
	Config.AuraPorId[aura.id] = aura
end

Config.MissaoPorId = {}
for _, missao in ipairs(Config.MISSOES) do
	Config.MissaoPorId[missao.id] = missao
end

Config.PassePorChave = {}
for _, passe in ipairs(Config.LOJA.PASSES) do
	Config.PassePorChave[passe.chave] = passe
end

function Config.custoMelhoria(tipo, nivelAtual)
	local m = Config.MELHORIAS[tipo]
	if not m or nivelAtual >= m.max then
		return nil
	end
	return math.floor(m.custoBase * (m.crescimento ^ nivelAtual))
end

function Config.vidaMaxima(nivel, nivelMelhoria)
	return math.floor(Config.vidaBase(nivel) * (1 + Config.MELHORIAS.vida.bonus * nivelMelhoria))
end

function Config.danoTotal(nivel, nivelMelhoria)
	return Config.danoBase(nivel) * (1 + Config.MELHORIAS.dano.bonus * nivelMelhoria)
end

function Config.velocidade(nivelMelhoria)
	return Config.VELOCIDADE_BASE * (1 + Config.MELHORIAS.velocidade.bonus * nivelMelhoria)
end

-- Nome no idioma do jogador ("pt" ou "en")
function Config.nomeDe(item, idioma)
	if idioma == "en" and item.en then
		return item.en
	end
	return item.nome
end

-- Em que zona está esta posição (sempre devolve uma zona)
function Config.zonaDe(posicao)
	local ponto = Vector2.new(posicao.X, posicao.Z)
	local maisPerto, menorDistancia = Config.Zonas[1], math.huge
	for _, zona in ipairs(Config.Zonas) do
		local distancia = (ponto - zona.centro).Magnitude
		if distancia <= zona.raio then
			return zona
		end
		if distancia - zona.raio < menorDistancia then
			menorDistancia = distancia - zona.raio
			maisPerto = zona
		end
	end
	-- fora de todas as zonas: vale a regra da mais próxima, mas sem PvP
	return maisPerto, true
end

-- Nível sorteado para um monstro desse tipo
function Config.nivelMonstro(def, aleatorio)
	if def.nivel then
		return def.nivel
	end
	return (aleatorio or Random.new()):NextInteger(def.nivelMin, def.nivelMax)
end

-- As 3 missões do dia são sempre as mesmas para o jogador naquele dia
function Config.missoesDoDia(dia, userId)
	local aleatorio = Random.new(dia * 7919 + (userId % 100003))
	local restantes = {}
	for _, missao in ipairs(Config.MISSOES) do
		table.insert(restantes, missao)
	end
	local escolhidas = {}
	for _ = 1, math.min(Config.MISSOES_POR_DIA, #restantes) do
		table.insert(escolhidas, table.remove(restantes, aleatorio:NextInteger(1, #restantes)))
	end
	return escolhidas
end

return Config
