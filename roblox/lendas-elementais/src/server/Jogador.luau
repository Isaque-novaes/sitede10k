--[[
	Tudo sobre o jogador no servidor: nível, XP, moedas, elementos,
	melhorias, vida, zona em que está, morte e volta.

	O servidor é o dono de todos esses números. O jogador só pede coisas
	("quero atacar", "quero comprar") e o servidor confere e decide.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Textos = require(Shared:WaitForChild("Textos"))

local Jogador = {}

Jogador.estados = {} -- [Player] = estado
Jogador.mundo = nil
Jogador.remotos = nil
Jogador.ouvintes = {} -- avisados quando algo acontece (missões)
Jogador.aoDerrotarJogador = nil -- ligado pelo Main (recompensa de PvP)

local aleatorio = Random.new()

local function agora()
	return workspace:GetServerTimeNow()
end
Jogador.agora = agora

function Jogador.iniciar(mundo, remotos)
	Jogador.mundo = mundo
	Jogador.remotos = remotos
end

function Jogador.aleatorio()
	return aleatorio
end

-- Eventos para as missões ------------------------------------------------------
function Jogador.emitir(estado, tipo, quantidade, info)
	for _, ouvinte in ipairs(Jogador.ouvintes) do
		ouvinte(estado, tipo, quantidade or 1, info)
	end
end

-- Avisos no idioma de cada jogador ---------------------------------------------
local function montarTexto(idioma, chave, ...)
	local valores = { ... }
	for i = 1, select("#", ...) do
		if type(valores[i]) == "function" then
			valores[i] = valores[i](idioma)
		end
	end
	return Textos.t(idioma, chave, table.unpack(valores, 1, select("#", ...)))
end

function Jogador.idiomaDe(player)
	local estado = Jogador.estados[player]
	return estado and estado.idioma or Textos.idiomaDe(player.LocaleId)
end

-- tipo: "bom", "ruim", "alerta" ou "info"
function Jogador.avisar(player, tipo, chave, ...)
	Jogador.remotos.Aviso:FireClient(player, montarTexto(Jogador.idiomaDe(player), chave, ...), tipo or "info")
end

function Jogador.avisarTodos(tipo, chave, ...)
	for player in pairs(Jogador.estados) do
		Jogador.avisar(player, tipo, chave, ...)
	end
end

-- Ajudantes para textos que mudam com o idioma
function Jogador.nomeDe(item)
	return function(idioma)
		return Config.nomeDe(item, idioma)
	end
end

function Jogador.numero(valor)
	return function(idioma)
		return Format.numero(valor, idioma)
	end
end

-- Personagem --------------------------------------------------------------------
function Jogador.personagemDe(player)
	local personagem = player.Character
	local humanoid = personagem and personagem:FindFirstChildOfClass("Humanoid")
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if raiz and humanoid and humanoid.Health > 0 then
		return raiz, humanoid, personagem
	end
	return nil
end

function Jogador.posicaoDe(estado)
	local raiz = Jogador.personagemDe(estado.player)
	return raiz and raiz.Position
end

-- Contas ------------------------------------------------------------------------
function Jogador.vidaMaxima(estado)
	return Config.vidaMaxima(estado.nivel, estado.melhorias.vida)
end

function Jogador.dano(estado)
	return Config.danoTotal(estado.nivel, estado.melhorias.dano)
end

function Jogador.multiplicadorXP(estado)
	local m = 1
	if estado.passes.xp2 then
		m = m * 2
	end
	if estado.passes.vip then
		m = m * (1 + Config.LOJA.VIP_BONUS)
	end
	if agora() < estado.xp2Ate then
		m = m * 2
	end
	m = m * (1 + Config.BONUS.POR_AMIGO * math.min(estado.amigos, Config.BONUS.MAX_AMIGOS))
	m = m * (1 + Config.BONUS.POR_ELEMENTO * (#estado.elementos - 1))
	if estado.noGrupo then
		m = m * (1 + Config.GRUPO.BONUS)
	end
	if estado.premium then
		m = m * (1 + Config.BONUS.PREMIUM)
	end
	return m
end

function Jogador.multiplicadorMoedas(estado)
	local m = 1
	if estado.passes.moedas2 then
		m = m * 2
	end
	if estado.passes.vip then
		m = m * (1 + Config.LOJA.VIP_BONUS)
	end
	if estado.noGrupo then
		m = m * (1 + Config.GRUPO.BONUS)
	end
	if estado.premium then
		m = m * (1 + Config.BONUS.PREMIUM)
	end
	return m
end

function Jogador.elementoAtual(estado)
	return Config.ElementoPorId[estado.equipado] or Config.Elementos[1]
end

function Jogador.temElemento(estado, id)
	for _, elemento in ipairs(estado.elementos) do
		if elemento == id then
			return true
		end
	end
	return false
end

-- Dinheiro e XP ------------------------------------------------------------------
function Jogador.darMoedas(estado, valor, semBonus)
	if type(valor) ~= "number" or valor ~= valor or valor <= 0 then
		return 0
	end
	local total = math.floor(semBonus and valor or valor * Jogador.multiplicadorMoedas(estado))
	estado.moedas = estado.moedas + total
	estado.valorMoedas.Value = math.min(estado.moedas, 9e18)
	return total
end

function Jogador.gastarMoedas(estado, valor)
	if estado.moedas < valor then
		return false
	end
	estado.moedas = estado.moedas - valor
	estado.valorMoedas.Value = math.min(estado.moedas, 9e18)
	return true
end

function Jogador.darXP(estado, valor, semBonus)
	if type(valor) ~= "number" or valor ~= valor or valor <= 0 then
		return 0
	end
	if estado.nivel >= Config.NIVEL_MAXIMO then
		return 0
	end
	local total = math.floor(semBonus and valor or valor * Jogador.multiplicadorXP(estado))
	estado.xp = estado.xp + total

	local subiu = 0
	while estado.nivel < Config.NIVEL_MAXIMO and estado.xp >= Config.xpDoNivel(estado.nivel) do
		estado.xp = estado.xp - Config.xpDoNivel(estado.nivel)
		estado.nivel = estado.nivel + 1
		subiu = subiu + 1
	end
	if estado.nivel >= Config.NIVEL_MAXIMO then
		estado.xp = 0
	end

	if subiu > 0 then
		estado.valorNivel.Value = estado.nivel
		Jogador.aplicarPersonagem(estado, true)
		Jogador.avisar(estado.player, "bom", "subiu_nivel", estado.nivel)
		Jogador.remotos.Efeito:FireClient(estado.player, "subirNivel")
		Jogador.emitir(estado, "subirNivel", subiu)
		-- avisa quando um elemento novo fica disponível
		for _, elemento in ipairs(Config.Elementos) do
			if elemento.nivel > estado.nivel - subiu and elemento.nivel <= estado.nivel then
				Jogador.avisar(estado.player, "alerta", "novo_elemento", elemento.nivel, Jogador.nomeDe(elemento))
			end
		end
	end
	Jogador.atualizarAtributos(estado)
	return total
end

-- Vida e combate ------------------------------------------------------------------
-- Ajusta vida, velocidade e pulo do personagem conforme o nível e as melhorias.
function Jogador.aplicarPersonagem(estado, curar)
	local _, humanoid = Jogador.personagemDe(estado.player)
	if not humanoid then
		return
	end
	local maxima = Jogador.vidaMaxima(estado)
	humanoid.MaxHealth = maxima
	if curar then
		humanoid.Health = maxima
	end
	humanoid.WalkSpeed = Config.velocidade(estado.melhorias.velocidade)
	humanoid.JumpPower = Config.PULO_BASE
	humanoid.UseJumpPower = true
end

function Jogador.emCombate(estado)
	return agora() - (estado.ultimoDano or 0) < Config.TEMPO_EM_COMBATE
end

-- Aplica dano no jogador. `de` é quem causou (estado de outro jogador ou nil).
function Jogador.machucar(estado, dano, de, nomeDoAtacante)
	local _, humanoid = Jogador.personagemDe(estado.player)
	if not humanoid or estado.morto then
		return
	end
	if estado.escudoAte and agora() < estado.escudoAte then
		dano = dano * (1 - (estado.escudoReducao or 0))
	end
	dano = math.max(1, math.floor(dano))
	estado.ultimoDano = agora()
	estado.ultimoAtacante = de
	estado.ultimoNomeAtacante = nomeDoAtacante
	humanoid:TakeDamage(dano)
	Jogador.remotos.Efeito:FireClient(estado.player, "levouDano")
	if humanoid.Health <= 0 then
		Jogador.morrer(estado, de, nomeDoAtacante)
	end
end

function Jogador.morrer(estado, de, nomeDoAtacante)
	if estado.morto then
		return
	end
	-- morte avisada pelo Roblox (sem culpado): usa quem bateu por último
	if not de and agora() - (estado.ultimoDano or -math.huge) < 10 then
		de = estado.ultimoAtacante
		nomeDoAtacante = nomeDoAtacante or estado.ultimoNomeAtacante
	end
	if de and Jogador.estados[de.player] ~= de then
		de = nil -- quem bateu já saiu do jogo
	end
	estado.morto = true
	estado.lento = nil
	estado.escudoAte = nil
	estado.invisivelAte = nil
	local player = estado.player
	if de then
		Jogador.avisar(player, "ruim", "voce_morreu", de.player.DisplayName, Config.RESPAWN)
		if Jogador.aoDerrotarJogador and Jogador.estados[de.player] == de then
			Jogador.aoDerrotarJogador(de, estado)
		end
	else
		Jogador.avisar(player, "ruim", "voce_morreu_monstro", nomeDoAtacante or "?", Config.RESPAWN)
	end
	player:SetAttribute("Morto", true)
	task.delay(Config.RESPAWN, function()
		if Jogador.estados[player] == estado then
			player:LoadCharacterAsync()
		end
	end)
end

-- Zonas ----------------------------------------------------------------------------
function Jogador.zonaDe(estado)
	local posicao = Jogador.posicaoDe(estado)
	if not posicao then
		return Config.ZonaPorId.vila, false
	end
	local zona, fora = Config.zonaDe(posicao)
	return zona, fora
end

-- Dois jogadores só podem se atacar se os dois estiverem numa zona de PvP.
function Jogador.podeAtacar(atacante, alvo)
	if atacante == alvo or alvo.morto then
		return false
	end
	local zonaA, foraA = Jogador.zonaDe(atacante)
	local zonaB, foraB = Jogador.zonaDe(alvo)
	if foraA or foraB then
		return false
	end
	return zonaA.pvp and zonaB.pvp
end

-- Chamado várias vezes por segundo: cuida de zona, regeneração e efeitos.
function Jogador.vigiar()
	for _, estado in pairs(Jogador.estados) do
		local zona = Jogador.zonaDe(estado)
		if zona.id ~= estado.zonaAtual then
			estado.zonaAtual = zona.id
			estado.player:SetAttribute("Zona", zona.id)
			estado.player:SetAttribute("ZonaPvp", zona.pvp)
			Jogador.avisar(estado.player, zona.pvp and "alerta" or "info",
				zona.pvp and "zona_entrou_pvp" or "zona_entrou_segura", Jogador.nomeDe(zona))
			if not estado.zonasVisitadas[zona.id] then
				estado.zonasVisitadas[zona.id] = true
				Jogador.emitir(estado, "visitarZona", 1)
			end
		end

		-- fim dos efeitos temporários
		local instante = agora()
		local _, humanoid = Jogador.personagemDe(estado.player)
		if humanoid then
			local velocidade = Config.velocidade(estado.melhorias.velocidade)
			if estado.lentoAte and instante < estado.lentoAte then
				velocidade = velocidade * Config.EFEITOS.LENTIDAO.fator
			elseif estado.lentoAte then
				estado.lentoAte = nil
			end
			if math.abs(humanoid.WalkSpeed - velocidade) > 0.1 then
				humanoid.WalkSpeed = velocidade
			end
			-- regenera fora de combate
			if not Jogador.emCombate(estado) and humanoid.Health > 0 then
				local maxima = Jogador.vidaMaxima(estado)
				if humanoid.Health < maxima then
					humanoid.Health = math.min(maxima, humanoid.Health + maxima * Config.REGENERACAO * 0.25)
				end
			end
		end
		if estado.invisivelAte and instante >= estado.invisivelAte then
			estado.invisivelAte = nil
			Jogador.mostrarPersonagem(estado, true)
		end
	end
end

function Jogador.mostrarPersonagem(estado, visivel)
	local personagem = estado.player.Character
	if not personagem then
		return
	end
	local transparencia = visivel and 0 or Config.EFEITOS.SUMIR.transparencia
	for _, item in ipairs(personagem:GetDescendants()) do
		if item:IsA("BasePart") and item.Name ~= "HumanoidRootPart" then
			item.LocalTransparencyModifier = 0
			item.Transparency = transparencia
		elseif item:IsA("Decal") then
			item.Transparency = transparencia
		end
	end
end

-- Atributos que a tela do jogador lê ------------------------------------------------
function Jogador.atualizarAtributos(estado)
	local player = estado.player
	player:SetAttribute("Nivel", estado.nivel)
	player:SetAttribute("XP", estado.xp)
	player:SetAttribute("XPDoNivel", Config.xpDoNivel(estado.nivel))
	player:SetAttribute("Moedas", math.min(estado.moedas, 9e18))
	player:SetAttribute("Dano", Jogador.dano(estado))
	player:SetAttribute("VidaMaxima", Jogador.vidaMaxima(estado))
	player:SetAttribute("Equipado", estado.equipado)
	player:SetAttribute("Aura", estado.aura)
	player:SetAttribute("Elementos", table.concat(estado.elementos, ","))
	player:SetAttribute("MultXP", Jogador.multiplicadorXP(estado))
	player:SetAttribute("MultMoedas", Jogador.multiplicadorMoedas(estado))
	player:SetAttribute("XP2Ate", estado.xp2Ate)
	player:SetAttribute("Amigos", math.min(estado.amigos, Config.BONUS.MAX_AMIGOS))
	for tipo, nivel in pairs(estado.melhorias) do
		player:SetAttribute("Melhoria_" .. tipo, nivel)
	end
	for _, passe in ipairs(Config.LOJA.PASSES) do
		player:SetAttribute("Passe_" .. passe.chave, estado.passes[passe.chave] == true)
	end
end

-- Aura: bolinhas girando em volta do jogador ------------------------------------------
function Jogador.aplicarAura(estado)
	local personagem = estado.player.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then
		return
	end
	local antiga = raiz:FindFirstChild("Aura")
	if antiga then
		antiga:Destroy()
	end
	local aura = Config.AuraPorId[estado.aura]
	if not aura or aura.id == "nenhuma" then
		return
	end
	local emissor = Instance.new("ParticleEmitter")
	emissor.Name = "Aura"
	emissor.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emissor.Color = ColorSequence.new(aura.cor)
	emissor.LightEmission = 1
	emissor.LightInfluence = 0
	emissor.Rate = 18
	emissor.Lifetime = NumberRange.new(0.8, 1.4)
	emissor.Speed = NumberRange.new(1, 3)
	emissor.SpreadAngle = Vector2.new(180, 180)
	emissor.Size = NumberSequence.new(0.9, 0)
	emissor.Parent = raiz
end

-- Entrada e saída -----------------------------------------------------------------------
function Jogador.adicionar(player, dados, podeSalvar)
	local estado = {
		player = player,
		idioma = Textos.idiomaDe(player.LocaleId),
		nivel = math.clamp(tonumber(dados.nivel) or 1, 1, Config.NIVEL_MAXIMO),
		xp = math.max(0, tonumber(dados.xp) or 0),
		moedas = tonumber(dados.moedas) or Config.MOEDAS_INICIAIS,
		elementos = {},
		equipado = "fogo",
		aura = "nenhuma",
		melhorias = {
			vida = math.clamp(tonumber(dados.melhorias.vida) or 0, 0, Config.MELHORIAS.vida.max),
			dano = math.clamp(tonumber(dados.melhorias.dano) or 0, 0, Config.MELHORIAS.dano.max),
			velocidade = math.clamp(tonumber(dados.melhorias.velocidade) or 0, 0, Config.MELHORIAS.velocidade.max),
		},
		passes = {},
		amigos = 0,
		noGrupo = false,
		premium = false,
		xp2Ate = tonumber(dados.xp2Ate) or 0,
		recargas = {}, -- [golpe] = quando pode usar de novo
		zonasVisitadas = {},
		ultimasVitimas = {}, -- [userId] = quando derrotou (evita ficar farmando o mesmo)
		dados = dados,
		podeSalvar = podeSalvar,
		morto = false,
		saindo = false,
	}
	for _, passe in ipairs(Config.LOJA.PASSES) do
		estado.passes[passe.chave] = false
	end

	-- elementos aprendidos
	local vistos = {}
	if type(dados.elementos) == "table" then
		for _, id in ipairs(dados.elementos) do
			if Config.ElementoPorId[id] and not vistos[id] then
				vistos[id] = true
				table.insert(estado.elementos, id)
			end
		end
	end
	if #estado.elementos == 0 then
		estado.elementos = { "fogo" }
	end
	if Jogador.temElemento(estado, dados.equipado) then
		estado.equipado = dados.equipado
	else
		estado.equipado = estado.elementos[1]
	end
	if Config.AuraPorId[dados.aura] then
		estado.aura = dados.aura
	end

	Jogador.estados[player] = estado

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local valorNivel = Instance.new("IntValue")
	valorNivel.Name = "Nivel"
	valorNivel.Value = estado.nivel
	valorNivel.Parent = leaderstats
	local valorMoedas = Instance.new("IntValue")
	valorMoedas.Name = "Moedas"
	valorMoedas.Value = math.min(estado.moedas, 9e18)
	valorMoedas.Parent = leaderstats
	leaderstats.Parent = player
	estado.valorNivel = valorNivel
	estado.valorMoedas = valorMoedas

	Jogador.atualizarAtributos(estado)
	return estado
end

function Jogador.guardar(estado)
	local dados = estado.dados
	dados.nivel = estado.nivel
	dados.xp = math.floor(estado.xp)
	dados.moedas = math.floor(estado.moedas)
	dados.elementos = estado.elementos
	dados.equipado = estado.equipado
	dados.aura = estado.aura
	dados.melhorias = {
		vida = estado.melhorias.vida,
		dano = estado.melhorias.dano,
		velocidade = estado.melhorias.velocidade,
	}
	dados.xp2Ate = estado.xp2Ate
	return dados
end

function Jogador.remover(player)
	local estado = Jogador.estados[player]
	if not estado then
		return nil, nil
	end
	estado.saindo = true
	local dados = Jogador.guardar(estado)
	Jogador.estados[player] = nil
	return estado, dados
end

-- Chamado quando o personagem nasce (ou renasce)
function Jogador.aoNascer(estado, personagem)
	local humanoid = personagem:WaitForChild("Humanoid", 10)
	if not humanoid or Jogador.estados[estado.player] ~= estado then
		return
	end
	personagem:WaitForChild("HumanoidRootPart", 10)
	estado.morto = false
	estado.lentoAte = nil
	estado.escudoAte = nil
	estado.invisivelAte = nil
	estado.ultimoAtacante = nil
	estado.ultimoNomeAtacante = nil
	estado.ultimoDano = nil
	estado.player:SetAttribute("Morto", false)
	Jogador.aplicarPersonagem(estado, true)
	Jogador.aplicarAura(estado)
	humanoid.Died:Connect(function()
		Jogador.morrer(estado, nil, "?")
	end)
	task.wait(0.1)
	if personagem.Parent and Jogador.estados[estado.player] == estado then
		personagem:PivotTo(Jogador.mundo.nascer)
	end
end

return Jogador
