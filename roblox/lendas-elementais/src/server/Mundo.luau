--[[
	Constrói o mundo inteiro por código: iluminação, chão, a Vila Central,
	as quatro zonas, os portais, os bonecos de treino e os quadros.

	Funciona num lugar vazio do Roblox Studio: não precisa de nenhum
	modelo pronto nem de imagem enviada.

	Os textos do mundo saem no idioma de cada jogador: aqui eles recebem
	uma chave (atributo "Chave" + tag "TextoLocal") e o script do jogador
	troca pelo texto certo.
]]

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Mundo = {}

local CONTORNO = Color3.fromRGB(20, 23, 43)
local ALTURA_CHAO = 0.6

local function peca(props)
	local parte = Instance.new(props.Classe or "Part")
	parte.Anchored = true
	parte.TopSurface = Enum.SurfaceType.Smooth
	parte.BottomSurface = Enum.SurfaceType.Smooth
	parte.Material = Enum.Material.SmoothPlastic
	for nome, valor in pairs(props) do
		if nome ~= "Parent" and nome ~= "Classe" then
			parte[nome] = valor
		end
	end
	parte.Parent = props.Parent
	return parte
end

local function disco(props)
	props.Classe = "Part"
	props.Shape = Enum.PartType.Cylinder
	return peca(props)
end

-- Texto flutuante traduzido no jogador
local function placa(parte, chave, cor, largura, altura, deslocamento, distancia, valor)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Placa"
	gui.Size = UDim2.fromOffset(largura or 300, altura or 60)
	gui.StudsOffset = deslocamento or Vector3.new(0, 0, 0)
	gui.MaxDistance = distancia or 250
	gui.LightInfluence = 0
	gui.Adornee = parte

	local rotulo = Instance.new("TextLabel")
	rotulo.Name = "Texto"
	rotulo.Size = UDim2.fromScale(1, 1)
	rotulo.BackgroundTransparency = 1
	rotulo.Text = ""
	rotulo.TextColor3 = cor or Color3.new(1, 1, 1)
	rotulo.TextStrokeTransparency = 0
	rotulo.TextStrokeColor3 = CONTORNO
	rotulo.TextScaled = true
	rotulo.Font = Enum.Font.LuckiestGuy
	rotulo.Parent = gui
	if chave then
		rotulo:SetAttribute("Chave", chave)
		if valor ~= nil then
			rotulo:SetAttribute("Valor", valor)
		end
		CollectionService:AddTag(rotulo, "TextoLocal")
	end

	gui.Parent = parte
	return rotulo
end

-- Iluminação de desenho animado, bem colorida -------------------------------
local function iluminar()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(100, 100, 120)
	Lighting.OutdoorAmbient = Color3.fromRGB(155, 155, 175)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.ShadowSoftness = 0.3
	Lighting.GlobalShadows = true

	local atmosfera = Instance.new("Atmosphere")
	atmosfera.Density = 0.3
	atmosfera.Offset = 0.15
	atmosfera.Color = Color3.fromRGB(205, 225, 255)
	atmosfera.Decay = Color3.fromRGB(110, 170, 230)
	atmosfera.Glare = 0.25
	atmosfera.Haze = 1.4
	atmosfera.Parent = Lighting

	local brilho = Instance.new("BloomEffect")
	brilho.Intensity = 0.7
	brilho.Size = 30
	brilho.Threshold = 1.5
	brilho.Parent = Lighting

	local cores = Instance.new("ColorCorrectionEffect")
	cores.Saturation = 0.2
	cores.Contrast = 0.1
	cores.Parent = Lighting

	local raios = Instance.new("SunRaysEffect")
	raios.Intensity = 0.08
	raios.Spread = 0.9
	raios.Parent = Lighting
end

-- Enfeites por zona ----------------------------------------------------------
local function arvore(pasta, posicao, tamanho, corCopa, corTronco)
	peca({
		Name = "Tronco",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(7 * tamanho, 1.8 * tamanho, 1.8 * tamanho),
		CFrame = CFrame.new(posicao + Vector3.new(0, 3.5 * tamanho, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = corTronco or Color3.fromRGB(140, 90, 55),
		Parent = pasta,
	})
	for i, deslocamento in ipairs({ Vector3.new(0, 8, 0), Vector3.new(2, 11, 1), Vector3.new(-2, 10.5, -1) }) do
		peca({
			Name = "Copa",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(9 - i * 1.5, 9 - i * 1.5, 9 - i * 1.5) * tamanho,
			CFrame = CFrame.new(posicao + deslocamento * tamanho),
			Color = corCopa,
			CanCollide = false,
			Parent = pasta,
		})
	end
end

local function cacto(pasta, posicao, tamanho)
	local cor = Color3.fromRGB(90, 160, 90)
	peca({ Name = "Cacto", Size = Vector3.new(3, 14, 3) * tamanho, CFrame = CFrame.new(posicao + Vector3.new(0, 7 * tamanho, 0)), Color = cor, Parent = pasta })
	for _, lado in ipairs({ -1, 1 }) do
		peca({ Name = "Braco", Size = Vector3.new(5, 2.5, 2.5) * tamanho, CFrame = CFrame.new(posicao + Vector3.new(3.5 * lado, 9, 0) * tamanho), Color = cor, Parent = pasta })
		peca({ Name = "Braco", Size = Vector3.new(2.5, 5, 2.5) * tamanho, CFrame = CFrame.new(posicao + Vector3.new(5.5 * lado, 11.5, 0) * tamanho), Color = cor, Parent = pasta })
	end
end

local function espinhoDeGelo(pasta, posicao, tamanho)
	for i = 1, 3 do
		peca({
			Name = "Gelo",
			Size = Vector3.new(4 - i * 0.8, 12 - i * 2, 4 - i * 0.8) * tamanho,
			CFrame = CFrame.new(posicao + Vector3.new(i * 1.6 - 2, (12 - i * 2) / 2 * tamanho, i * 1.2 - 2))
				* CFrame.Angles(0, i * 0.7, 0),
			Color = Color3.fromRGB(190, 235, 255),
			Material = Enum.Material.Glass,
			Transparency = 0.25,
			Reflectance = 0.2,
			Parent = pasta,
		})
	end
end

local function pilar(pasta, posicao, tamanho, cor)
	peca({ Name = "Base", Size = Vector3.new(7, 1.5, 7) * tamanho, CFrame = CFrame.new(posicao + Vector3.new(0, 0.75, 0) * tamanho), Color = cor, Parent = pasta })
	peca({ Name = "Pilar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(18 * tamanho, 4.5 * tamanho, 4.5 * tamanho),
		CFrame = CFrame.new(posicao + Vector3.new(0, 10, 0) * tamanho) * CFrame.Angles(0, 0, math.pi / 2), Color = cor, Parent = pasta })
	peca({ Name = "Topo", Shape = Enum.PartType.Ball, Size = Vector3.new(5, 5, 5) * tamanho,
		CFrame = CFrame.new(posicao + Vector3.new(0, 20, 0) * tamanho), Color = Color3.fromRGB(190, 90, 255),
		Material = Enum.Material.Neon, CanCollide = false, Parent = pasta })
end

local function casa(pasta, posicao, giro, corParede, corTelhado)
	local quadro = CFrame.new(posicao) * CFrame.Angles(0, giro, 0)
	peca({ Name = "Parede", Size = Vector3.new(18, 14, 16), CFrame = quadro * CFrame.new(0, 7, 0), Color = corParede, Parent = pasta })
	peca({ Name = "Telhado", Size = Vector3.new(21, 5, 19), CFrame = quadro * CFrame.new(0, 16, 0), Color = corTelhado, Parent = pasta })
	peca({ Name = "Porta", Size = Vector3.new(5, 8, 0.6), CFrame = quadro * CFrame.new(0, 4, -8.2), Color = Color3.fromRGB(120, 80, 50), Parent = pasta })
	for _, lado in ipairs({ -5.5, 5.5 }) do
		peca({ Name = "Janela", Size = Vector3.new(3.5, 3.5, 0.5), CFrame = quadro * CFrame.new(lado, 9.5, -8.2),
			Color = Color3.fromRGB(150, 225, 255), Material = Enum.Material.Glass, Parent = pasta })
	end
end

-- Quadro com texto, de frente para quem chega
local function quadro(pasta, nome, cframe, chaveTitulo, corTitulo, linhas)
	local tabua = peca({ Name = nome, Size = Vector3.new(20, 15, 1), CFrame = cframe, Color = CONTORNO, Parent = pasta })
	for _, x in ipairs({ -8, 8 }) do
		peca({ Name = "Perna", Size = Vector3.new(1.2, 4, 1.2), CFrame = cframe * CFrame.new(x, -9, 0), Color = CONTORNO, Parent = pasta })
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Tela"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Adornee = tabua
	local lista = Instance.new("UIListLayout")
	lista.SortOrder = Enum.SortOrder.LayoutOrder
	lista.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lista.Padding = UDim.new(0, 6)
	lista.Parent = gui
	local margem = Instance.new("UIPadding")
	margem.PaddingTop = UDim.new(0, 16)
	margem.PaddingLeft = UDim.new(0, 16)
	margem.PaddingRight = UDim.new(0, 16)
	margem.Parent = gui
	local titulo = Instance.new("TextLabel")
	titulo.Name = "Titulo"
	titulo.LayoutOrder = 0
	titulo.Size = UDim2.new(1, 0, 0, 58)
	titulo.BackgroundTransparency = 1
	titulo.Font = Enum.Font.LuckiestGuy
	titulo.TextScaled = true
	titulo.TextColor3 = corTitulo
	titulo.Text = ""
	titulo:SetAttribute("Chave", chaveTitulo)
	CollectionService:AddTag(titulo, "TextoLocal")
	titulo.Parent = gui
	local rotulos = {}
	for i = 1, linhas do
		local linha = Instance.new("TextLabel")
		linha.Name = "Linha" .. i
		linha.LayoutOrder = i
		linha.Size = UDim2.new(1, 0, 0, 32)
		linha.BackgroundTransparency = 1
		linha.Font = Enum.Font.FredokaOne
		linha.TextScaled = true
		linha.TextXAlignment = Enum.TextXAlignment.Left
		linha.TextColor3 = Color3.new(1, 1, 1)
		linha.Text = ""
		linha.Parent = gui
		rotulos[i] = linha
	end
	gui.Parent = tabua
	return tabua, rotulos
end

-- Portal -----------------------------------------------------------------------
-- Um disco brilhante com um raio de luz. Segure E para viajar.
local function portal(pasta, posicao, zonaDestino, cor)
	local modelo = Instance.new("Model")
	modelo.Name = "Portal_" .. zonaDestino.id
	modelo.Parent = pasta

	local base = disco({
		Name = "Base",
		Size = Vector3.new(1.2, 18, 18),
		CFrame = CFrame.new(posicao + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = cor,
		Material = Enum.Material.Neon,
		Parent = modelo,
	})
	disco({
		Name = "Anel",
		Size = Vector3.new(0.8, 22, 22),
		CFrame = CFrame.new(posicao + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = CONTORNO,
		Parent = modelo,
	})

	local topo = peca({
		Name = "Luz",
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(posicao + Vector3.new(0, 1, 0)),
		Transparency = 1,
		CanCollide = false,
		Parent = modelo,
	})
	local a0 = Instance.new("Attachment")
	a0.Parent = topo
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, 40, 0)
	a1.Parent = topo
	local feixe = Instance.new("Beam")
	feixe.Attachment0 = a0
	feixe.Attachment1 = a1
	feixe.Width0 = 16
	feixe.Width1 = 10
	feixe.Color = ColorSequence.new(cor)
	feixe.Transparency = NumberSequence.new(0.55, 1)
	feixe.LightEmission = 1
	feixe.FaceCamera = true
	feixe.Parent = topo

	local luz = Instance.new("PointLight")
	luz.Color = cor
	luz.Range = 30
	luz.Brightness = 2.5
	luz.Parent = base

	local rotulo = placa(topo, zonaDestino.id == "vila" and "portal_vila" or "portal_para",
		Color3.new(1, 1, 1), 360, 60, Vector3.new(0, 7, 0), 300, zonaDestino.id)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Viajar"
	prompt.ActionText = "Viajar"
	prompt.ObjectText = Config.nomeDe(zonaDestino, "en")
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt:SetAttribute("Portal", zonaDestino.id)
	prompt:SetAttribute("NivelMinimo", zonaDestino.nivelMinimo)
	prompt.Parent = base

	return { modelo = modelo, base = base, prompt = prompt, rotulo = rotulo, zona = zonaDestino }
end

-- Boneco de treino: não revida e volta sozinho ------------------------------
local function bonecoDeTreino(pasta, posicao)
	local modelo = Instance.new("Model")
	modelo.Name = "BonecoDeTreino"
	local raiz = peca({
		Name = "Raiz",
		Size = Vector3.new(4, 7, 4),
		CFrame = CFrame.new(posicao + Vector3.new(0, 5.5, 0)),
		Color = Color3.fromRGB(190, 150, 110),
		Parent = modelo,
	})
	peca({ Name = "Pe", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 7, 7),
		CFrame = CFrame.new(posicao + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(120, 85, 55), Parent = modelo })
	peca({ Name = "Cabeca", Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4, 4),
		CFrame = CFrame.new(posicao + Vector3.new(0, 11, 0)), Color = Color3.fromRGB(210, 175, 130), Parent = modelo })
	for _, lado in ipairs({ -1, 1 }) do
		peca({ Name = "Braco", Size = Vector3.new(7, 1.6, 1.6), CFrame = CFrame.new(posicao + Vector3.new(4 * lado, 8, 0)),
			Color = Color3.fromRGB(150, 110, 75), Parent = modelo })
	end
	modelo.PrimaryPart = raiz
	modelo.Parent = pasta
	placa(raiz, "placa_treino", Color3.fromRGB(255, 216, 77), 260, 44, Vector3.new(0, 5, 0), 90)
	return { modelo = modelo, raiz = raiz }
end

-- Zonas -------------------------------------------------------------------------
local function construirZona(zona, pasta, portais)
	local modelo = Instance.new("Model")
	modelo.Name = "Zona_" .. zona.id
	modelo.Parent = pasta

	local centro = Vector3.new(zona.centro.X, 0, zona.centro.Y)
	disco({
		Name = "Chao",
		Size = Vector3.new(ALTURA_CHAO, zona.raio * 2, zona.raio * 2),
		CFrame = CFrame.new(centro + Vector3.new(0, ALTURA_CHAO / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = zona.corChao,
		Material = zona.id == "pico" and Enum.Material.Snow
			or (zona.id == "deserto" and Enum.Material.Sand or Enum.Material.Grass),
		Parent = modelo,
	})
	-- borda colorida: azul = seguro, vermelho = PvP
	disco({
		Name = "Borda",
		Size = Vector3.new(0.4, zona.raio * 2 + 10, zona.raio * 2 + 10),
		CFrame = CFrame.new(centro + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = zona.pvp and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(70, 170, 255),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = modelo,
	})

	local sorteio = Random.new(#zona.id * 977)
	local function pontoNaZona(distanciaMin, distanciaMax)
		local angulo = sorteio:NextNumber() * math.pi * 2
		local raio = sorteio:NextNumber(distanciaMin, distanciaMax)
		return centro + Vector3.new(math.cos(angulo) * raio, ALTURA_CHAO, math.sin(angulo) * raio)
	end

	-- enfeites
	if zona.id == "campo" then
		for _ = 1, 22 do
			arvore(modelo, pontoNaZona(40, zona.raio - 25), sorteio:NextNumber(0.9, 1.5), Color3.fromRGB(80, 200, 90))
		end
	elseif zona.id == "deserto" then
		for _ = 1, 18 do
			cacto(modelo, pontoNaZona(40, zona.raio - 25), sorteio:NextNumber(0.9, 1.4))
		end
		for _ = 1, 10 do
			local p = pontoNaZona(50, zona.raio - 30)
			disco({ Name = "Lava", Size = Vector3.new(0.3, sorteio:NextNumber(14, 26), sorteio:NextNumber(14, 26)),
				CFrame = CFrame.new(p + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.pi / 2),
				Color = Color3.fromRGB(255, 110, 30), Material = Enum.Material.Neon, CanCollide = false, Parent = modelo })
		end
	elseif zona.id == "pico" then
		for _ = 1, 20 do
			espinhoDeGelo(modelo, pontoNaZona(40, zona.raio - 25), sorteio:NextNumber(0.9, 1.6))
		end
	elseif zona.id == "ruinas" then
		for _ = 1, 16 do
			pilar(modelo, pontoNaZona(45, zona.raio - 30), sorteio:NextNumber(0.9, 1.5), Color3.fromRGB(70, 60, 95))
		end
	end

	-- pontos onde os monstros aparecem e a arena do chefe
	local nascimentos = {}
	for i = 1, 24 do
		local angulo = (i / 24) * math.pi * 2
		local raio = 60 + ((i % 3) * 45)
		table.insert(nascimentos, centro + Vector3.new(math.cos(angulo) * raio, 4, math.sin(angulo) * raio))
	end

	local direcaoChefe = (centro - Vector3.new(0, 0, 0))
	if direcaoChefe.Magnitude < 1 then
		direcaoChefe = Vector3.new(0, 0, 1)
	end
	local arenaChefe = centro + direcaoChefe.Unit * (zona.raio - 60)
	disco({
		Name = "ArenaChefe",
		Size = Vector3.new(0.5, 90, 90),
		CFrame = CFrame.new(arenaChefe + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(60, 30, 40),
		Material = Enum.Material.Slate,
		CanCollide = false,
		Parent = modelo,
	})

	-- portal de volta para a vila, virado para a entrada
	local entrada = centro - direcaoChefe.Unit * (zona.raio - 40)
	table.insert(portais, portal(modelo, entrada, Config.ZonaPorId.vila, Color3.fromRGB(120, 230, 255)))

	return {
		zona = zona,
		modelo = modelo,
		centro = centro,
		nascimentos = nascimentos,
		arenaChefe = arenaChefe + Vector3.new(0, 6, 0),
		entrada = entrada + Vector3.new(0, 5, 0),
	}
end

-- Vila ---------------------------------------------------------------------------
local function construirVila(pasta, portais)
	local zona = Config.ZonaPorId.vila
	local modelo = Instance.new("Model")
	modelo.Name = "Vila"
	modelo.Parent = pasta

	disco({
		Name = "Chao",
		Size = Vector3.new(ALTURA_CHAO, zona.raio * 2, zona.raio * 2),
		CFrame = CFrame.new(0, ALTURA_CHAO / 2, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(255, 236, 196),
		Parent = modelo,
	})
	disco({
		Name = "Borda",
		Size = Vector3.new(0.4, zona.raio * 2 + 10, zona.raio * 2 + 10),
		CFrame = CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(70, 170, 255),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = modelo,
	})

	-- fonte no meio
	disco({ Name = "Fonte", Size = Vector3.new(3, 26, 26), CFrame = CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(190, 200, 215), Parent = modelo })
	disco({ Name = "Agua", Size = Vector3.new(0.6, 22, 22), CFrame = CFrame.new(0, 3.1, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(90, 190, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = modelo })
	peca({ Name = "Pilar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(14, 4, 4),
		CFrame = CFrame.new(0, 9, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = Color3.fromRGB(190, 200, 215), Parent = modelo })
	local cristal = peca({ Name = "Cristal", Size = Vector3.new(6, 9, 6), CFrame = CFrame.new(0, 19, 0) * CFrame.Angles(0.4, 0.8, 0),
		Color = Color3.fromRGB(150, 230, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = modelo })
	local luzCristal = Instance.new("PointLight")
	luzCristal.Color = Color3.fromRGB(150, 230, 255)
	luzCristal.Range = 50
	luzCristal.Brightness = 3
	luzCristal.Parent = cristal
	placa(cristal, "placa_vila", Color3.fromRGB(255, 216, 77), 420, 70, Vector3.new(0, 7, 0), 400)

	-- casinhas em volta
	local cores = {
		{ Color3.fromRGB(255, 190, 120), Color3.fromRGB(220, 90, 90) },
		{ Color3.fromRGB(190, 220, 255), Color3.fromRGB(80, 130, 220) },
		{ Color3.fromRGB(215, 255, 200), Color3.fromRGB(90, 180, 100) },
		{ Color3.fromRGB(255, 210, 240), Color3.fromRGB(200, 100, 190) },
	}
	for i = 1, 8 do
		local angulo = (i / 8) * math.pi * 2 + 0.4
		local p = Vector3.new(math.cos(angulo) * 86, 0, math.sin(angulo) * 86)
		local cor = cores[(i % #cores) + 1]
		casa(modelo, p, -angulo + math.pi / 2, cor[1], cor[2])
	end

	-- bonecos de treino
	local bonecos = {}
	for i = -1, 1 do
		table.insert(bonecos, bonecoDeTreino(modelo, Vector3.new(i * 16, 0, -46)))
	end

	-- portais para as zonas de luta
	for _, destino in ipairs(Config.Zonas) do
		if destino.id ~= "vila" then
			local direcao = Vector3.new(destino.centro.X, 0, destino.centro.Y).Unit
			table.insert(portais, portal(modelo, direcao * 62, destino, destino.corChao))
		end
	end

	-- quadros
	local placar = quadro(modelo, "Ranking", CFrame.new(40, 10, 48) * CFrame.Angles(0, math.pi, 0),
		"ranking_titulo", Color3.fromRGB(255, 216, 77), 10)
	local _, linhasComo = quadro(modelo, "ComoJogar", CFrame.new(-40, 10, 48) * CFrame.Angles(0, math.pi, 0),
		"como_jogar", Color3.fromRGB(120, 255, 160), 4)
	for i, linha in ipairs(linhasComo) do
		linha.Size = UDim2.new(1, 0, 0, 52)
		linha:SetAttribute("Chave", "passo" .. i)
		CollectionService:AddTag(linha, "TextoLocal")
	end

	-- ponto de nascimento
	local nascer = Instance.new("SpawnLocation")
	nascer.Name = "Nascer"
	nascer.Anchored = true
	nascer.Size = Vector3.new(14, 0.6, 14)
	nascer.CFrame = CFrame.new(0, 0.9, 34)
	nascer.Neutral = true
	nascer.Duration = 0
	nascer.Transparency = 0.5
	nascer.Color = Color3.fromRGB(120, 230, 255)
	nascer.Material = Enum.Material.Neon
	nascer.Parent = modelo

	return { modelo = modelo, nascer = nascer, placar = placar, bonecos = bonecos }
end

function Mundo.construir()
	iluminar()

	local mapa = Instance.new("Folder")
	mapa.Name = "Mapa"
	mapa.Parent = workspace

	-- chão geral embaixo de tudo
	peca({
		Name = "ChaoGeral",
		Size = Vector3.new(2000, 2, 2000),
		CFrame = CFrame.new(0, -1, 0),
		Color = Color3.fromRGB(96, 170, 96),
		Material = Enum.Material.Grass,
		Parent = mapa,
	})
	-- paredes invisíveis na borda do mapa
	for i, dados in ipairs({
		{ Vector3.new(2000, 120, 4), Vector3.new(0, 60, -1000) },
		{ Vector3.new(2000, 120, 4), Vector3.new(0, 60, 1000) },
		{ Vector3.new(4, 120, 2000), Vector3.new(-1000, 60, 0) },
		{ Vector3.new(4, 120, 2000), Vector3.new(1000, 60, 0) },
	}) do
		peca({ Name = "Borda" .. i, Size = dados[1], CFrame = CFrame.new(dados[2]), Transparency = 1, Parent = mapa })
	end

	-- caminhos ligando a vila às zonas (dá para ir andando)
	for _, zona in ipairs(Config.Zonas) do
		if zona.id ~= "vila" then
			local destino = Vector3.new(zona.centro.X, 0, zona.centro.Y)
			local direcao = destino.Unit
			local comprimento = destino.Magnitude
			peca({
				Name = "Caminho_" .. zona.id,
				Size = Vector3.new(26, 0.4, comprimento),
				CFrame = CFrame.new(direcao * (comprimento / 2) + Vector3.new(0, 0.4, 0),
					destino + Vector3.new(0, 0.4, 0)),
				Color = Color3.fromRGB(215, 195, 160),
				Parent = mapa,
			})
		end
	end

	local pastaZonas = Instance.new("Folder")
	pastaZonas.Name = "Zonas"
	pastaZonas.Parent = mapa

	local portais = {}
	local vila = construirVila(pastaZonas, portais)
	local zonas = {}
	for _, zona in ipairs(Config.Zonas) do
		if zona.id ~= "vila" then
			zonas[zona.id] = construirZona(zona, pastaZonas, portais)
		end
	end

	local pastaMonstros = Instance.new("Folder")
	pastaMonstros.Name = "Monstros"
	pastaMonstros.Parent = workspace
	local pastaTiros = Instance.new("Folder")
	pastaTiros.Name = "Tiros"
	pastaTiros.Parent = workspace

	return {
		mapa = mapa,
		vila = vila,
		zonas = zonas,
		portais = portais,
		pastaMonstros = pastaMonstros,
		pastaTiros = pastaTiros,
		nascer = CFrame.new(0, 5, 34),
	}
end

return Mundo
