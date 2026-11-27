--[[
	Monstros e chefes: como são montados, como perseguem o jogador,
	como atacam, como morrem e como voltam.

	Eles não usam o sistema de personagem do Roblox: são peças movidas
	pelo servidor. Fica mais leve e não precisa de nenhum modelo pronto.
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Jogador = require(script.Parent:WaitForChild("Jogador"))

local Monstros = {}

local Combate = nil -- ligado pelo Main
local vivos = {}
local aleatorio = Random.new()
local CONTORNO = Color3.fromRGB(20, 23, 43)

function Monstros.ligarCombate(modulo)
	Combate = modulo
end

local function agora()
	return workspace:GetServerTimeNow()
end

-- Modelo ---------------------------------------------------------------------
local function peca(modelo, nome, tamanho, cframe, cor, material, forma)
	local parte = Instance.new("Part")
	parte.Name = nome
	if forma then
		parte.Shape = forma
	end
	parte.Size = tamanho
	parte.CFrame = cframe
	parte.Color = cor
	parte.Material = material or Enum.Material.SmoothPlastic
	parte.TopSurface = Enum.SurfaceType.Smooth
	parte.BottomSurface = Enum.SurfaceType.Smooth
	parte.Anchored = true
	parte.CanCollide = false
	parte.CanTouch = false
	parte.CanQuery = false
	parte.Parent = modelo
	return parte
end

-- Monta o corpo do monstro com a base dos pés na origem.
local function construir(def, nivel)
	local escala = def.escala or 1
	local modelo = Instance.new("Model")
	modelo.Name = def.id or "Monstro"
	modelo:SetAttribute("Nivel", nivel)
	if def.chefe then
		modelo:SetAttribute("Chefe", true)
	end

	local altura
	local raiz = peca(modelo, "Raiz", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, 0, 0), CONTORNO)
	raiz.Transparency = 1
	modelo.PrimaryPart = raiz

	if def.forma == "bola" then
		altura = 5 * escala
		peca(modelo, "Corpo", Vector3.new(5, 5, 5) * escala, CFrame.new(0, 2.5 * escala, 0),
			def.cor, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		peca(modelo, "Barriga", Vector3.new(3, 2.6, 0.4) * escala, CFrame.new(0, 2 * escala, -2.3 * escala),
			def.detalhe, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	elseif def.forma == "caixa" then
		altura = 7 * escala
		peca(modelo, "Corpo", Vector3.new(5, 5, 4) * escala, CFrame.new(0, 3.4 * escala, 0), def.cor)
		peca(modelo, "Cabeca", Vector3.new(3.6, 2.6, 3) * escala, CFrame.new(0, 7.1 * escala, 0), def.cor)
		for _, lado in ipairs({ -1, 1 }) do
			peca(modelo, "Braco", Vector3.new(1.4, 4, 1.4) * escala, CFrame.new(3.2 * lado * escala, 3.6 * escala, 0), def.detalhe)
			peca(modelo, "Perna", Vector3.new(1.6, 1.4, 1.6) * escala, CFrame.new(1.4 * lado * escala, 0.7 * escala, 0), def.detalhe)
		end
	else -- "alto"
		altura = 7.5 * escala
		peca(modelo, "Corpo", Vector3.new(3.4, 4.4, 3) * escala, CFrame.new(0, 3.4 * escala, 0), def.cor)
		peca(modelo, "Cabeca", Vector3.new(3, 2.8, 2.8) * escala, CFrame.new(0, 7 * escala, 0),
			def.cor, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		for _, lado in ipairs({ -1, 1 }) do
			peca(modelo, "Braco", Vector3.new(1.2, 3.6, 1.2) * escala,
				CFrame.new(2.4 * lado * escala, 3.6 * escala, 0) * CFrame.Angles(0, 0, 0.25 * lado), def.detalhe)
		end
		if def.anda then
			for _, lado in ipairs({ -1, 1 }) do
				peca(modelo, "Perna", Vector3.new(1.2, 1.4, 1.2) * escala, CFrame.new(1 * lado * escala, 0.7 * escala, 0), def.detalhe)
			end
		end
	end

	-- olhos (ficam na frente, no -Z)
	local alturaOlhos = (def.forma == "bola" and 3.2 or (def.forma == "caixa" and 7.2 or 7.2)) * escala
	local afastamento = (def.forma == "bola" and 2.4 or 1.6) * escala
	for _, lado in ipairs({ -1, 1 }) do
		peca(modelo, "Olho", Vector3.new(0.7, 0.7, 0.3) * escala,
			CFrame.new(0.75 * lado * escala, alturaOlhos, -afastamento),
			def.chefe and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 240, 180), Enum.Material.Neon)
	end

	if def.chefe then
		local luz = Instance.new("PointLight")
		luz.Color = def.detalhe
		luz.Range = 34
		luz.Brightness = 3
		luz.Parent = raiz
		local emissor = Instance.new("ParticleEmitter")
		emissor.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emissor.Color = ColorSequence.new(def.detalhe)
		emissor.LightEmission = 1
		emissor.Rate = 14
		emissor.Lifetime = NumberRange.new(0.8, 1.6)
		emissor.Speed = NumberRange.new(2, 5)
		emissor.SpreadAngle = Vector2.new(180, 180)
		emissor.Size = NumberSequence.new(1.4, 0)
		emissor.Parent = raiz
	end

	-- barra de vida e nome (o nome é traduzido no jogador)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Barra"
	gui.Adornee = raiz
	gui.Size = UDim2.fromOffset(def.chefe and 320 or 190, def.chefe and 76 or 54)
	gui.StudsOffset = Vector3.new(0, altura + 2.5, 0)
	gui.MaxDistance = def.chefe and 500 or 160
	gui.LightInfluence = 0

	local nome = Instance.new("TextLabel")
	nome.Name = "Nome"
	nome.Size = UDim2.new(1, 0, 0.55, 0)
	nome.BackgroundTransparency = 1
	nome.Font = Enum.Font.FredokaOne
	nome.TextScaled = true
	nome.TextColor3 = def.chefe and Color3.fromRGB(255, 120, 120) or Color3.new(1, 1, 1)
	nome.TextStrokeTransparency = 0
	nome.TextStrokeColor3 = CONTORNO
	nome.Text = ""
	nome:SetAttribute("Monstro", def.id)
	nome:SetAttribute("Nivel", nivel)
	nome.Parent = gui

	local fundo = Instance.new("Frame")
	fundo.Name = "Fundo"
	fundo.Size = UDim2.new(1, 0, 0.3, 0)
	fundo.Position = UDim2.new(0, 0, 0.62, 0)
	fundo.BackgroundColor3 = CONTORNO
	fundo.BorderSizePixel = 0
	local canto = Instance.new("UICorner")
	canto.CornerRadius = UDim.new(0, 6)
	canto.Parent = fundo
	local barra = Instance.new("Frame")
	barra.Name = "Barra"
	barra.Size = UDim2.fromScale(1, 1)
	barra.BackgroundColor3 = Color3.fromRGB(80, 220, 110)
	barra.BorderSizePixel = 0
	local canto2 = Instance.new("UICorner")
	canto2.CornerRadius = UDim.new(0, 6)
	canto2.Parent = barra
	barra.Parent = fundo
	fundo.Parent = gui
	gui.Parent = raiz

	return modelo, raiz, barra, nome, altura
end

-- Nascer, morrer e voltar -------------------------------------------------------
local function nascer(def, nivel, casa, zonaId)
	local modelo, raiz, barra, rotuloNome, altura = construir(def, nivel)
	local monstro = {
		def = def,
		nivel = nivel,
		chefe = def.chefe == true,
		zonaId = zonaId,
		casa = casa,
		posicao = casa,
		modelo = modelo,
		raiz = raiz,
		barra = barra,
		rotuloNome = rotuloNome,
		altura = altura,
		raio = 3 * (def.escala or 1),
		vidaMaxima = Config.vidaMonstro(nivel, def.chefe),
		dano = Config.danoMonstro(nivel, def.chefe),
		proximoAtaque = 0,
		dadoPor = {}, -- quanto dano cada jogador causou
		giro = aleatorio:NextNumber() * math.pi * 2,
	}
	monstro.vida = monstro.vidaMaxima
	modelo:PivotTo(CFrame.new(casa))
	modelo.Parent = Jogador.mundo.pastaMonstros
	table.insert(vivos, monstro)
	return monstro
end

local function quemMaisBateu(monstro)
	local melhor, maior = nil, 0
	for estado, dano in pairs(monstro.dadoPor) do
		if dano > maior and Jogador.estados[estado.player] == estado then
			melhor, maior = estado, dano
		end
	end
	return melhor
end

local function morrer(monstro)
	if monstro.morto then
		return
	end
	monstro.morto = true
	local vencedor = quemMaisBateu(monstro)
	if Combate then
		Combate.explosao(monstro.posicao + Vector3.new(0, monstro.altura / 2, 0),
			monstro.def.detalhe, monstro.chefe and 20 or 8, monstro.chefe and 90 or 30)
	end
	if vencedor then
		local xp = Jogador.darXP(vencedor, Config.xpMonstro(monstro.nivel, monstro.chefe))
		local moedas = Jogador.darMoedas(vencedor, Config.moedasMonstro(monstro.nivel, monstro.chefe))
		Jogador.avisar(vencedor.player, "bom", "derrotou_monstro", Jogador.nomeDe(monstro.def),
			Jogador.numero(xp), Jogador.numero(moedas))
		Jogador.remotos.Efeito:FireClient(vencedor.player, "matou", monstro.posicao, monstro.def.detalhe)
		Jogador.emitir(vencedor, monstro.chefe and "chefe" or "matar", 1)
		vencedor.dados.monstrosDerrotados = (vencedor.dados.monstrosDerrotados or 0) + 1
		if monstro.chefe then
			vencedor.dados.chefesDerrotados = (vencedor.dados.chefesDerrotados or 0) + 1
			Jogador.avisarTodos("alerta", "chefe_derrotado", vencedor.player.DisplayName, Jogador.nomeDe(monstro.def))
		end
	end

	monstro.modelo:Destroy()
	for i, outro in ipairs(vivos) do
		if outro == monstro then
			table.remove(vivos, i)
			break
		end
	end

	local espera = monstro.chefe and Config.MONSTRO.RENASCER_CHEFE or Config.MONSTRO.RENASCER
	task.delay(espera, function()
		local novoNivel = Config.nivelMonstro(monstro.def, aleatorio)
		nascer(monstro.def, novoNivel, monstro.casa, monstro.zonaId)
		if monstro.chefe then
			local zona = Config.ZonaPorId[monstro.zonaId]
			Jogador.avisarTodos("alerta", "chefe_voltou", Jogador.nomeDe(monstro.def), Jogador.nomeDe(zona))
		end
	end)
end

function Monstros.machucar(monstro, dano, estadoJogador)
	if monstro.morto then
		return
	end
	dano = math.max(1, math.floor(dano))
	if monstro.boneco then
		return -- boneco de treino: mostra o dano mas não morre nem revida
	end
	monstro.vida = math.max(0, monstro.vida - dano)
	if estadoJogador then
		monstro.dadoPor[estadoJogador] = (monstro.dadoPor[estadoJogador] or 0) + dano
		monstro.alvo = estadoJogador -- bateu nele? agora ele vem atrás de você
	end
	local fracao = monstro.vida / monstro.vidaMaxima
	if monstro.barra then
		monstro.barra.Size = UDim2.fromScale(fracao, 1)
		monstro.barra.BackgroundColor3 = fracao > 0.5 and Color3.fromRGB(80, 220, 110)
			or (fracao > 0.25 and Color3.fromRGB(255, 190, 60) or Color3.fromRGB(240, 70, 70))
	end
	if monstro.vida <= 0 then
		morrer(monstro)
	end
end

function Monstros.deixarLento(monstro, duracao)
	monstro.lentoAte = agora() + duracao
end

function Monstros.ativos()
	return vivos
end

function Monstros.quantidade()
	return #vivos
end

-- Inteligência -------------------------------------------------------------------
local function alvoMaisPerto(monstro)
	local melhor, menor = nil, Config.MONSTRO.AGRESSAO
	for _, estado in pairs(Jogador.estados) do
		if not estado.morto and not (estado.invisivelAte and agora() < estado.invisivelAte) then
			local posicao = Jogador.posicaoDe(estado)
			if posicao then
				local distancia = (posicao - monstro.posicao).Magnitude
				if distancia < menor then
					melhor, menor = estado, distancia
				end
			end
		end
	end
	return melhor
end

local function atacar(monstro, estado, posicaoAlvo, distancia)
	local instante = agora()
	if instante < monstro.proximoAtaque then
		return
	end
	if monstro.def.atira and distancia <= Config.MONSTRO.ALCANCE_TIRO then
		monstro.proximoAtaque = instante + Config.MONSTRO.RECARGA_ATAQUE
		if Combate then
			local origem = monstro.posicao + Vector3.new(0, monstro.altura * 0.7, 0)
			Combate.tiroDeMonstro(monstro, origem, (posicaoAlvo - origem).Unit, monstro.dano)
		end
	elseif distancia <= Config.MONSTRO.ALCANCE_ATAQUE + monstro.raio then
		monstro.proximoAtaque = instante + Config.MONSTRO.RECARGA_ATAQUE
		Jogador.machucar(estado, monstro.dano, nil, Jogador.nomeDe(monstro.def))
		if Combate then
			Combate.explosao(posicaoAlvo, monstro.def.detalhe, 3, 12)
		end
	end
end

-- Roda algumas vezes por segundo (não precisa ser a cada quadro)
function Monstros.passo(dt)
	local instante = agora()
	for _, monstro in ipairs(vivos) do
		if not monstro.morto and not monstro.boneco then
			local alvo = monstro.alvo
			local posicaoAlvo = alvo and Jogador.posicaoDe(alvo)
			local invisivel = alvo and alvo.invisivelAte and instante < alvo.invisivelAte
			if not posicaoAlvo or alvo.morto or invisivel
				or (posicaoAlvo - monstro.casa).Magnitude > Config.MONSTRO.DESISTE then
				alvo = alvoMaisPerto(monstro)
				monstro.alvo = alvo
				posicaoAlvo = alvo and Jogador.posicaoDe(alvo)
			end

			local velocidade = (monstro.def.velocidade or 12)
			if monstro.lentoAte and instante < monstro.lentoAte then
				velocidade = velocidade * Config.EFEITOS.LENTIDAO.fator
			end

			local destino, perseguindo
			if posicaoAlvo then
				destino, perseguindo = posicaoAlvo, true
			else
				destino, perseguindo = monstro.casa, false
				-- longe de casa? volta e se cura
				if (monstro.posicao - monstro.casa).Magnitude < 3 and monstro.vida < monstro.vidaMaxima then
					monstro.vida = math.min(monstro.vidaMaxima, monstro.vida + monstro.vidaMaxima * 0.2)
					if monstro.barra then
						monstro.barra.Size = UDim2.fromScale(monstro.vida / monstro.vidaMaxima, 1)
						monstro.barra.BackgroundColor3 = Color3.fromRGB(80, 220, 110)
					end
					monstro.dadoPor = {}
				end
			end

			local delta = Vector3.new(destino.X - monstro.posicao.X, 0, destino.Z - monstro.posicao.Z)
			local distancia = delta.Magnitude
			local paraPerto = Config.MONSTRO.ALCANCE_ATAQUE * 0.6 + monstro.raio
			if monstro.def.atira and perseguindo then
				paraPerto = Config.MONSTRO.ALCANCE_TIRO * 0.6
			end
			if distancia > paraPerto then
				local passoTamanho = math.min(velocidade * dt, distancia)
				monstro.posicao = monstro.posicao + delta.Unit * passoTamanho
			end

			-- altura: quem anda fica no chão, quem flutua balança
			local alturaBase = monstro.casa.Y
			if monstro.def.anda then
				monstro.posicao = Vector3.new(monstro.posicao.X, alturaBase, monstro.posicao.Z)
			else
				monstro.posicao = Vector3.new(monstro.posicao.X,
					alturaBase + 3 + math.sin(instante * 2 + monstro.giro) * 1.2, monstro.posicao.Z)
			end

			-- vira para onde está indo
			local olhar = distancia > 0.5 and delta.Unit or Vector3.new(0, 0, 1)
			monstro.modelo:PivotTo(CFrame.new(monstro.posicao, monstro.posicao - olhar))

			if perseguindo and posicaoAlvo then
				atacar(monstro, alvo, posicaoAlvo, (posicaoAlvo - monstro.posicao).Magnitude)
			end
		end
	end
end

-- Nasce tudo ------------------------------------------------------------------------
function Monstros.povoar()
	for _, zona in ipairs(Config.Zonas) do
		local info = Jogador.mundo.zonas[zona.id]
		if info and zona.monstros then
			local proximo = 1
			for _, id in ipairs(zona.monstros) do
				local def = Config.Monstros[id]
				def.id = id
				for _ = 1, (def.quantidade or 8) do
					local casa = info.nascimentos[((proximo - 1) % #info.nascimentos) + 1]
					proximo = proximo + 1
					local espalhar = Vector3.new(aleatorio:NextNumber(-14, 14), 0, aleatorio:NextNumber(-14, 14))
					nascer(def, Config.nivelMonstro(def, aleatorio), casa + espalhar, zona.id)
				end
			end
			if zona.chefe then
				local def = Config.Monstros[zona.chefe]
				def.id = zona.chefe
				nascer(def, Config.nivelMonstro(def, aleatorio), info.arenaChefe, zona.id)
			end
		end
	end
end

-- Bonecos de treino: levam dano, mostram quanto e não morrem -------------------
function Monstros.prepararBonecos()
	for _, boneco in ipairs(Jogador.mundo.vila.bonecos) do
		local def = { id = "boneco", nome = "Boneco de Treino", en = "Training Dummy",
			cor = Color3.fromRGB(190, 150, 110), detalhe = Color3.fromRGB(255, 216, 77), escala = 1 }
		table.insert(vivos, {
			def = def,
			nivel = 1,
			boneco = true,
			posicao = boneco.raiz.Position,
			casa = boneco.raiz.Position,
			modelo = boneco.modelo,
			raiz = boneco.raiz,
			raio = 3,
			altura = 11,
			vida = math.huge,
			vidaMaxima = math.huge,
			dano = 0,
			proximoAtaque = math.huge,
			dadoPor = {},
			giro = 0,
		})
	end
end

return Monstros
