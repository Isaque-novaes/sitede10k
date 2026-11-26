--[[
	Constrói o mapa inteiro por código: iluminação, chão, calçadas,
	árvores, esteira, fábrica, reciclagem, placar, quadro "como jogar" e
	as 8 bases. Funciona num lugar vazio do Roblox Studio.

	Cada base tem um "quadro" (CFrame) próprio: a origem fica no centro do
	piso e o eixo +Z local aponta para a entrada (virada para a esteira).

	Os textos do mundo saem no idioma de cada jogador: aqui eles recebem
	uma chave (atributo "Chave" + tag "TextoLocal") e o script do jogador
	troca pelo texto certo.
]]

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local MapBuilder = {}

local LARGURA_BASE = 60 -- eixo X local
local PROFUNDIDADE_BASE = 50 -- eixo Z local
local ALTURA_PAREDE = 12
local LARGURA_ENTRADA = 14

MapBuilder.LARGURA_BASE = LARGURA_BASE
MapBuilder.PROFUNDIDADE_BASE = PROFUNDIDADE_BASE

local CONTORNO = Color3.fromRGB(20, 23, 43)
local CINZA_BASE = Color3.fromRGB(185, 194, 211)
local OURO = Color3.fromRGB(255, 200, 61)

local CORES_BASES = {
	Color3.fromRGB(255, 94, 126),
	Color3.fromRGB(61, 165, 255),
	Color3.fromRGB(34, 197, 94),
	Color3.fromRGB(255, 176, 32),
	Color3.fromRGB(166, 77, 255),
	Color3.fromRGB(255, 122, 26),
	Color3.fromRGB(255, 61, 165),
	Color3.fromRGB(20, 184, 166),
}

local function peca(props)
	local classe = props.Classe or "Part"
	local parte = Instance.new(classe)
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

-- Texto flutuante. `chave` = texto traduzido pelo jogador (Textos.luau).
local function placa(parte, chave, textoPadrao, cor, largura, altura, deslocamento, distancia, fonte)
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
	rotulo.Text = textoPadrao or ""
	rotulo.TextColor3 = cor or Color3.new(1, 1, 1)
	rotulo.TextStrokeTransparency = 0
	rotulo.TextStrokeColor3 = CONTORNO
	rotulo.TextScaled = true
	rotulo.Font = fonte or Enum.Font.LuckiestGuy
	rotulo.Parent = gui
	if chave then
		rotulo:SetAttribute("Chave", chave)
		CollectionService:AddTag(rotulo, "TextoLocal")
	end

	gui.Parent = parte
	return rotulo, gui
end

local function arvore(pasta, posicao, tamanho)
	local tronco = peca({
		Name = "Tronco",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6 * tamanho, 1.6 * tamanho, 1.6 * tamanho),
		CFrame = CFrame.new(posicao + Vector3.new(0, 3 * tamanho, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(140, 90, 55),
		Parent = pasta,
	})
	tronco.CanCollide = true
	peca({
		Name = "Copa",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(8, 8, 8) * tamanho,
		CFrame = CFrame.new(posicao + Vector3.new(0, 8 * tamanho, 0)),
		Color = Color3.fromRGB(70, 190, 80),
		CanCollide = false,
		Parent = pasta,
	})
	peca({
		Name = "Copa",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(5.5, 5.5, 5.5) * tamanho,
		CFrame = CFrame.new(posicao + Vector3.new(1.5 * tamanho, 11 * tamanho, 0.5 * tamanho)),
		Color = Color3.fromRGB(110, 215, 95),
		CanCollide = false,
		Parent = pasta,
	})
end

local function poste(pasta, posicao)
	peca({
		Name = "Poste",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(9, 0.6, 0.6),
		CFrame = CFrame.new(posicao + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = CONTORNO,
		Parent = pasta,
	})
	peca({
		Name = "Lampada",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.6, 1.6, 1.6),
		CFrame = CFrame.new(posicao + Vector3.new(0, 9.4, 0)),
		Color = Color3.fromRGB(255, 243, 163),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = pasta,
	})
end

-- Iluminação "cartoon de dia de sol" ------------------------------------------
local function iluminar()
	Lighting.ClockTime = 13.5
	Lighting.Brightness = 2.3
	Lighting.Ambient = Color3.fromRGB(95, 95, 115)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 170)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.ShadowSoftness = 0.3
	Lighting.GlobalShadows = true

	local atmosfera = Instance.new("Atmosphere")
	atmosfera.Density = 0.25
	atmosfera.Offset = 0.1
	atmosfera.Color = Color3.fromRGB(199, 220, 255)
	atmosfera.Decay = Color3.fromRGB(106, 170, 230)
	atmosfera.Glare = 0.2
	atmosfera.Haze = 1
	atmosfera.Parent = Lighting

	local brilho = Instance.new("BloomEffect")
	brilho.Intensity = 0.6
	brilho.Size = 28
	brilho.Threshold = 1.6
	brilho.Parent = Lighting

	local cores = Instance.new("ColorCorrectionEffect")
	cores.Saturation = 0.15
	cores.Contrast = 0.08
	cores.Brightness = 0.02
	cores.Parent = Lighting

	local raios = Instance.new("SunRaysEffect")
	raios.Intensity = 0.06
	raios.Spread = 0.8
	raios.Parent = Lighting
end

-- Base -----------------------------------------------------------------------
local POSICOES_VAGAS = {}
for _, z in ipairs({ -19, -11, -3, 5 }) do
	for _, x in ipairs({ -20, -10, 0, 10, 20 }) do
		table.insert(POSICOES_VAGAS, Vector3.new(x, 0, z))
	end
end

local function construirBase(indice, centro, girada, pasta)
	local cor = CORES_BASES[indice]
	local quadro = CFrame.new(centro)
	if girada then
		quadro = quadro * CFrame.Angles(0, math.pi, 0)
	end

	local modelo = Instance.new("Model")
	modelo.Name = "Base" .. indice
	modelo:SetAttribute("Indice", indice)
	modelo:SetAttribute("DonoNome", "")
	modelo:SetAttribute("Nivel", 0)
	modelo:SetAttribute("TrancadaAte", 0)
	modelo.Parent = pasta

	local function local_(x, y, z)
		return quadro * CFrame.new(x, y, z)
	end

	local meiaLargura = LARGURA_BASE / 2
	local meiaProfundidade = PROFUNDIDADE_BASE / 2
	local yParede = ALTURA_PAREDE / 2

	-- piso
	local piso = peca({
		Name = "Piso",
		Size = Vector3.new(LARGURA_BASE, 0.4, PROFUNDIDADE_BASE),
		CFrame = local_(0, -0.2, 0),
		Color = Color3.fromRGB(255, 236, 242),
		Parent = modelo,
	})

	-- paredes (fundo, laterais e frente com a entrada no meio)
	local paredes = {}
	local function parede(nome, tamanho, x, z)
		local p = peca({
			Name = nome,
			Size = tamanho,
			CFrame = local_(x, yParede, z),
			Color = CINZA_BASE,
			Parent = modelo,
		})
		table.insert(paredes, p)
		return p
	end
	parede("ParedeFundo", Vector3.new(LARGURA_BASE, ALTURA_PAREDE, 2), 0, -meiaProfundidade + 1)
	parede("ParedeEsquerda", Vector3.new(2, ALTURA_PAREDE, PROFUNDIDADE_BASE), -meiaLargura + 1, 0)
	parede("ParedeDireita", Vector3.new(2, ALTURA_PAREDE, PROFUNDIDADE_BASE), meiaLargura - 1, 0)
	local larguraFrente = (LARGURA_BASE - LARGURA_ENTRADA) / 2
	local xFrente = LARGURA_ENTRADA / 2 + larguraFrente / 2
	parede("FrenteEsquerda", Vector3.new(larguraFrente, ALTURA_PAREDE, 2), -xFrente, meiaProfundidade - 1)
	parede("FrenteDireita", Vector3.new(larguraFrente, ALTURA_PAREDE, 2), xFrente, meiaProfundidade - 1)

	-- enfeites que aparecem conforme o nível da base
	local enfeites = { faixa = {}, lampadas = {}, bandeira = {}, pilares = {}, ouro = {}, coroa = {}, feixes = {} }
	local function enfeite(grupo, props)
		props.Parent = modelo
		props.CanCollide = false
		props.Transparency = 1
		local p = peca(props)
		table.insert(enfeites[grupo], p)
		return p
	end

	-- faixa neon no alto das paredes (nível 3)
	enfeite("faixa", { Name = "Faixa", Size = Vector3.new(LARGURA_BASE + 0.2, 1, 2.2), CFrame = local_(0, ALTURA_PAREDE - 1.5, -meiaProfundidade + 1), Material = Enum.Material.Neon, Color = cor })
	enfeite("faixa", { Name = "Faixa", Size = Vector3.new(2.2, 1, PROFUNDIDADE_BASE + 0.2), CFrame = local_(-meiaLargura + 1, ALTURA_PAREDE - 1.5, 0), Material = Enum.Material.Neon, Color = cor })
	enfeite("faixa", { Name = "Faixa", Size = Vector3.new(2.2, 1, PROFUNDIDADE_BASE + 0.2), CFrame = local_(meiaLargura - 1, ALTURA_PAREDE - 1.5, 0), Material = Enum.Material.Neon, Color = cor })

	-- lâmpadas nos cantos e bandeira (nível 5)
	for _, canto in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
		enfeite("lampadas", {
			Name = "Lampada",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(2.4, 2.4, 2.4),
			CFrame = local_(canto[1] * (meiaLargura - 1), ALTURA_PAREDE + 1.2, canto[2] * (meiaProfundidade - 1)),
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 243, 163),
		})
	end
	enfeite("bandeira", { Name = "Mastro", Size = Vector3.new(0.5, 10, 0.5), CFrame = local_(-meiaLargura + 4, ALTURA_PAREDE + 5, -meiaProfundidade + 1), Color = CONTORNO })
	enfeite("bandeira", { Name = "Bandeira", Size = Vector3.new(5, 3, 0.3), CFrame = local_(-meiaLargura + 6.7, ALTURA_PAREDE + 8.3, -meiaProfundidade + 1), Color = cor })

	-- pilares neon na entrada (nível 8)
	for _, lado in ipairs({ -1, 1 }) do
		enfeite("pilares", {
			Name = "Pilar",
			Size = Vector3.new(1.4, ALTURA_PAREDE + 4, 1.4),
			CFrame = local_(lado * (LARGURA_ENTRADA / 2 + 0.7), (ALTURA_PAREDE + 4) / 2, meiaProfundidade - 0.2),
			Material = Enum.Material.Neon,
			Color = cor,
		})
	end

	-- acabamento dourado, coroa e holofotes (nível 10)
	enfeite("ouro", { Name = "Ouro", Size = Vector3.new(LARGURA_BASE + 0.6, 0.8, 2.6), CFrame = local_(0, ALTURA_PAREDE + 0.4, -meiaProfundidade + 1), Material = Enum.Material.Metal, Color = OURO, Reflectance = 0.2 })
	enfeite("ouro", { Name = "Ouro", Size = Vector3.new(2.6, 0.8, PROFUNDIDADE_BASE + 0.6), CFrame = local_(-meiaLargura + 1, ALTURA_PAREDE + 0.4, 0), Material = Enum.Material.Metal, Color = OURO, Reflectance = 0.2 })
	enfeite("ouro", { Name = "Ouro", Size = Vector3.new(2.6, 0.8, PROFUNDIDADE_BASE + 0.6), CFrame = local_(meiaLargura - 1, ALTURA_PAREDE + 0.4, 0), Material = Enum.Material.Metal, Color = OURO, Reflectance = 0.2 })
	for i, x in ipairs({ -2.2, 0, 2.2 }) do
		enfeite("coroa", {
			Name = "Coroa",
			Classe = "WedgePart",
			Size = Vector3.new(0.6, i == 2 and 3 or 2.2, 1.6),
			CFrame = local_(x, ALTURA_PAREDE + 9.5, -meiaProfundidade + 1),
			Material = Enum.Material.Metal,
			Color = OURO,
		})
	end
	for _, lado in ipairs({ -1, 1 }) do
		local foco = enfeite("feixes", {
			Name = "Holofote",
			Size = Vector3.new(1.5, 1.5, 1.5),
			CFrame = local_(lado * (meiaLargura - 6), ALTURA_PAREDE + 1, -meiaProfundidade + 1),
			Material = Enum.Material.Neon,
			Color = OURO,
		})
		local a0 = Instance.new("Attachment")
		a0.Parent = foco
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(lado * 12, 70, -10)
		a1.Parent = foco
		local feixe = Instance.new("Beam")
		feixe.Attachment0 = a0
		feixe.Attachment1 = a1
		feixe.Width0 = 2
		feixe.Width1 = 8
		feixe.Color = ColorSequence.new(Color3.fromRGB(255, 243, 163))
		feixe.Transparency = NumberSequence.new(0.6, 1)
		feixe.LightEmission = 1
		feixe.FaceCamera = true
		feixe.Enabled = false
		feixe.Parent = foco
	end

	-- pedestais: 4 fileiras de 5 (as primeiras vagas ficam no fundo)
	local pedestais = {}
	local vagas = {}
	for numero, posicao in ipairs(POSICOES_VAGAS) do
		local bloco = peca({
			Name = "Pedestal" .. numero,
			Size = Vector3.new(6, 1, 6),
			CFrame = local_(posicao.X, 0.5, posicao.Z),
			Color = Color3.fromRGB(59, 63, 92),
			Material = Enum.Material.DiamondPlate,
			Parent = modelo,
		})
		local anel = peca({
			Name = "Anel" .. numero,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.25, 6.6, 6.6),
			CFrame = local_(posicao.X, 1.02, posicao.Z) * CFrame.Angles(0, 0, math.pi / 2),
			Color = Color3.fromRGB(90, 95, 120),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = modelo,
		})
		-- o robô fica em cima do pedestal, olhando para a entrada
		pedestais[numero] = local_(posicao.X, 1, posicao.Z) * CFrame.Angles(0, math.pi, 0)
		vagas[numero] = { bloco = bloco, anel = anel }
	end

	-- botão de trancar (o dono pisa nele)
	local botao = peca({
		Name = "BotaoTrancar",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 6, 6),
		CFrame = local_(-21, 0.2, 16) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(255, 59, 59),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = modelo,
	})
	local rotuloBotao = placa(botao, "trancar_base", "LOCK BASE", Color3.new(1, 1, 1), 200, 40, Vector3.new(0, 3, 0), 60)

	-- barreira de laser na entrada (só aparece quando trancada)
	local barreira = peca({
		Name = "Barreira",
		Size = Vector3.new(LARGURA_ENTRADA, ALTURA_PAREDE, 1),
		CFrame = local_(0, yParede, meiaProfundidade - 1),
		Color = Color3.fromRGB(255, 40, 40),
		Material = Enum.Material.ForceField,
		Transparency = 1,
		CanCollide = false,
		Parent = modelo,
	})
	local rotuloTranca = placa(barreira, nil, "", Color3.fromRGB(255, 120, 120), 260, 50, Vector3.new(0, ALTURA_PAREDE / 2 + 3, 0), 150)

	-- placa com o nome do dono e o nível
	local suportePlaca = peca({
		Name = "SuportePlaca",
		Size = Vector3.new(1, 1, 1),
		CFrame = local_(0, ALTURA_PAREDE + 5, -meiaProfundidade + 1),
		Transparency = 1,
		CanCollide = false,
		Parent = modelo,
	})
	local gui = Instance.new("BillboardGui")
	gui.Name = "Placa"
	gui.Size = UDim2.fromOffset(380, 96)
	gui.MaxDistance = 300
	gui.LightInfluence = 0
	gui.Adornee = suportePlaca
	local lista = Instance.new("UIListLayout")
	lista.SortOrder = Enum.SortOrder.LayoutOrder
	lista.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lista.Parent = gui
	local rotuloDono = Instance.new("TextLabel")
	rotuloDono.Name = "Titulo"
	rotuloDono.LayoutOrder = 1
	rotuloDono.Size = UDim2.new(1, 0, 0.65, 0)
	rotuloDono.BackgroundTransparency = 1
	rotuloDono.Font = Enum.Font.LuckiestGuy
	rotuloDono.TextScaled = true
	rotuloDono.TextColor3 = Color3.new(1, 1, 1)
	rotuloDono.TextStrokeTransparency = 0
	rotuloDono.TextStrokeColor3 = CONTORNO
	rotuloDono.Text = "FREE BASE"
	rotuloDono.Parent = gui
	local rotuloNivel = Instance.new("TextLabel")
	rotuloNivel.Name = "Nivel"
	rotuloNivel.LayoutOrder = 2
	rotuloNivel.Size = UDim2.new(1, 0, 0.35, 0)
	rotuloNivel.BackgroundTransparency = 1
	rotuloNivel.Font = Enum.Font.FredokaOne
	rotuloNivel.TextScaled = true
	rotuloNivel.TextColor3 = Color3.fromRGB(255, 216, 77)
	rotuloNivel.TextStrokeTransparency = 0
	rotuloNivel.TextStrokeColor3 = CONTORNO
	rotuloNivel.Text = ""
	rotuloNivel.Parent = gui
	gui.Parent = suportePlaca

	local base = {
		indice = indice,
		quadro = quadro,
		cor = cor,
		modelo = modelo,
		piso = piso,
		paredes = paredes,
		enfeites = enfeites,
		pedestais = pedestais,
		vagas = vagas,
		botao = botao,
		rotuloBotao = rotuloBotao,
		barreira = barreira,
		rotuloTranca = rotuloTranca,
		rotuloDono = rotuloDono,
		rotuloNivel = rotuloNivel,
		nascer = local_(0, 3, 15),
		saida = local_(0, 3, meiaProfundidade + 8),
	}
	MapBuilder.aplicarNivel(base, 0, false)
	MapBuilder.atualizarVagas(base, 0, {})
	return base
end

-- Mostra os enfeites da base de acordo com o nível de renda (0 a 10).
function MapBuilder.aplicarNivel(base, nivel, ocupada)
	local t = 0
	if ocupada then
		t = 0.25 + 0.75 * math.min(1, nivel / 5)
	end
	local corParede = CINZA_BASE:Lerp(base.cor, t)
	for _, p in ipairs(base.paredes) do
		p.Color = corParede
	end
	local function mostrar(grupo, visivel)
		for _, p in ipairs(base.enfeites[grupo]) do
			p.Transparency = visivel and 0 or 1
			for _, item in ipairs(p:GetChildren()) do
				if item:IsA("Beam") then
					item.Enabled = visivel
				end
			end
		end
	end
	mostrar("faixa", ocupada and nivel >= 3)
	mostrar("lampadas", ocupada and nivel >= 5)
	mostrar("bandeira", ocupada and nivel >= 5)
	mostrar("pilares", ocupada and nivel >= 8)
	mostrar("ouro", ocupada and nivel >= 10)
	mostrar("coroa", ocupada and nivel >= 10)
	mostrar("feixes", ocupada and nivel >= 10)
	base.modelo:SetAttribute("Nivel", ocupada and nivel or 0)
end

-- Pedestais liberados aparecem; o anel acende com a cor da raridade.
-- coresOcupadas[vaga] = Color3 da raridade do robô naquela vaga
function MapBuilder.atualizarVagas(base, totalLiberadas, coresOcupadas)
	for numero, vaga in ipairs(base.vagas) do
		local liberada = numero <= totalLiberadas
		vaga.bloco.Transparency = liberada and 0 or 0.75
		local cor = coresOcupadas[numero]
		if liberada and cor then
			vaga.anel.Transparency = 0
			vaga.anel.Color = cor
		elseif liberada then
			vaga.anel.Transparency = 0.4
			vaga.anel.Color = Color3.fromRGB(110, 115, 140)
		else
			vaga.anel.Transparency = 1
		end
	end
end

-- Quadro com SurfaceGui de frente para a esteira
local function quadroDeAviso(pasta, nome, cframe, chaveTitulo, corTitulo, linhas)
	local quadro = peca({
		Name = nome,
		Size = Vector3.new(18, 14, 1),
		CFrame = cframe,
		Color = CONTORNO,
		Parent = pasta,
	})
	for _, x in ipairs({ -7, 7 }) do
		peca({
			Name = "Perna",
			Size = Vector3.new(1, 3, 1),
			CFrame = cframe * CFrame.new(x, -8.5, 0),
			Color = CONTORNO,
			Parent = pasta,
		})
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Tela"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Adornee = quadro
	local lista = Instance.new("UIListLayout")
	lista.SortOrder = Enum.SortOrder.LayoutOrder
	lista.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lista.Padding = UDim.new(0, 6)
	lista.Parent = gui
	local margem = Instance.new("UIPadding")
	margem.PaddingTop = UDim.new(0, 18)
	margem.PaddingLeft = UDim.new(0, 18)
	margem.PaddingRight = UDim.new(0, 18)
	margem.Parent = gui
	local titulo = Instance.new("TextLabel")
	titulo.Name = "Titulo"
	titulo.LayoutOrder = 0
	titulo.Size = UDim2.new(1, 0, 0, 56)
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
		linha.Size = UDim2.new(1, 0, 0, 30)
		linha.BackgroundTransparency = 1
		linha.Font = Enum.Font.FredokaOne
		linha.TextScaled = true
		linha.TextXAlignment = Enum.TextXAlignment.Left
		linha.TextColor3 = Color3.new(1, 1, 1)
		linha.Text = ""
		linha.Parent = gui
		rotulos[i] = linha
	end
	gui.Parent = quadro
	return quadro, rotulos
end

function MapBuilder.construir()
	iluminar()

	local mapa = Instance.new("Folder")
	mapa.Name = "Mapa"
	mapa.Parent = workspace

	-- chão e calçadas
	peca({
		Name = "Chao",
		Size = Vector3.new(420, 1, 330),
		CFrame = CFrame.new(0, -0.5, 0),
		Color = Color3.fromRGB(106, 200, 90),
		Material = Enum.Material.Grass,
		Parent = mapa,
	})
	for _, z in ipairs({ -21, 21 }) do
		peca({
			Name = "Calcada",
			Size = Vector3.new(330, 0.2, 26),
			CFrame = CFrame.new(0, 0.1, z),
			Color = Color3.fromRGB(255, 236, 196),
			Parent = mapa,
		})
	end

	-- bordas invisíveis para ninguém cair do mapa
	local bordas = {
		{ Vector3.new(420, 60, 2), Vector3.new(0, 30, -166) },
		{ Vector3.new(420, 60, 2), Vector3.new(0, 30, 166) },
		{ Vector3.new(2, 60, 330), Vector3.new(-211, 30, 0) },
		{ Vector3.new(2, 60, 330), Vector3.new(211, 30, 0) },
	}
	for i, borda in ipairs(bordas) do
		peca({
			Name = "Borda" .. i,
			Size = borda[1],
			CFrame = CFrame.new(borda[2]),
			Transparency = 1,
			Parent = mapa,
		})
	end

	-- árvores atrás das bases
	local decoracao = Instance.new("Folder")
	decoracao.Name = "Decoracao"
	decoracao.Parent = mapa
	local sorteio = Random.new(7)
	for _, z in ipairs({ -105, -140, 105, 140 }) do
		for x = -175, 175, 50 do
			local deslocamento = Vector3.new(sorteio:NextNumber(-8, 8), 0, sorteio:NextNumber(-6, 6))
			arvore(decoracao, Vector3.new(x, 0, z) + deslocamento, sorteio:NextNumber(0.9, 1.4))
		end
	end
	for _, x in ipairs({ -195, 195 }) do
		for z = -60, 60, 40 do
			arvore(decoracao, Vector3.new(x, 0, z), sorteio:NextNumber(1, 1.3))
		end
	end
	for x = -120, 120, 40 do
		poste(decoracao, Vector3.new(x, 0, 9))
		poste(decoracao, Vector3.new(x, 0, -9))
	end

	-- esteira (de verdade: quem sobe nela é levado junto)
	local yEsteira = 1
	local esteira = peca({
		Name = "Esteira",
		Size = Vector3.new(330, 1, 10),
		CFrame = CFrame.new(0, 0.5, 0),
		Color = Color3.fromRGB(52, 54, 74),
		Material = Enum.Material.DiamondPlate,
		Parent = mapa,
	})
	esteira.AssemblyLinearVelocity = Vector3.new(Config.ESTEIRA.VELOCIDADE, 0, 0)
	for _, z in ipairs({ -5.4, 5.4 }) do
		peca({
			Name = "Trilho",
			Size = Vector3.new(330, 1.4, 0.8),
			CFrame = CFrame.new(0, 0.7, z),
			Color = Color3.fromRGB(255, 210, 63),
			Material = Enum.Material.Neon,
			Parent = mapa,
		})
	end
	for x = -140, 140, 14 do
		for _, lado in ipairs({ -1, 1 }) do
			peca({
				Name = "Seta",
				Size = Vector3.new(2.6, 0.06, 0.5),
				CFrame = CFrame.new(x, 1.03, lado * 1.1) * CFrame.Angles(0, lado * 0.6, 0),
				Color = Color3.fromRGB(255, 140, 0),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = mapa,
			})
		end
	end

	-- fábrica (de onde saem os robôs)
	local fabrica = peca({
		Name = "Fabrica",
		Size = Vector3.new(30, 24, 30),
		CFrame = CFrame.new(-165, 12, 0),
		Color = Color3.fromRGB(108, 122, 153),
		Material = Enum.Material.Metal,
		Parent = mapa,
	})
	peca({ Name = "FaixaFabrica", Size = Vector3.new(30.4, 1.6, 30.4), CFrame = CFrame.new(-165, 21, 0), Color = Color3.fromRGB(255, 61, 165), Material = Enum.Material.Neon, Parent = mapa })
	peca({ Name = "Telhado", Size = Vector3.new(22, 6, 22), CFrame = CFrame.new(-167, 27, 0), Color = Color3.fromRGB(255, 210, 63), Parent = mapa })
	peca({ Name = "Portao", Size = Vector3.new(1, 9, 13), CFrame = CFrame.new(-149.6, 4.5, 0), Color = Color3.fromRGB(30, 30, 42), Parent = mapa })
	for _, z in ipairs({ -9, 9 }) do
		peca({
			Name = "Engrenagem",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.8, 7, 7),
			CFrame = CFrame.new(-149.6, 15, z),
			Color = z < 0 and Color3.fromRGB(255, 176, 32) or Color3.fromRGB(61, 165, 255),
			Parent = mapa,
		})
	end
	for _, z in ipairs({ -7, 7 }) do
		local chamine = peca({
			Name = "Chamine",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(14, 5, 5),
			CFrame = CFrame.new(-174, 31, z) * CFrame.Angles(0, 0, math.pi / 2),
			Color = Color3.fromRGB(85, 96, 122),
			Material = Enum.Material.Metal,
			Parent = mapa,
		})
		local fumaca = Instance.new("Smoke")
		fumaca.Color = Color3.fromRGB(230, 235, 245)
		fumaca.Opacity = 0.12
		fumaca.RiseVelocity = 6
		fumaca.Size = 5
		fumaca.Parent = chamine
	end
	placa(fabrica, "fabrica", "ROBOT FACTORY", Color3.fromRGB(255, 216, 77), 460, 80, Vector3.new(0, 19, 0), 450)

	-- reciclagem (onde somem os robôs que ninguém comprou)
	local reciclagem = peca({
		Name = "Reciclagem",
		Size = Vector3.new(22, 16, 22),
		CFrame = CFrame.new(163, 8, 0),
		Color = Color3.fromRGB(40, 70, 55),
		Material = Enum.Material.Metal,
		Parent = mapa,
	})
	peca({ Name = "FaixaReciclagem", Size = Vector3.new(22.4, 1.2, 22.4), CFrame = CFrame.new(163, 13, 0), Color = Color3.fromRGB(75, 240, 138), Material = Enum.Material.Neon, Parent = mapa })
	peca({ Name = "Boca", Size = Vector3.new(1, 7, 12), CFrame = CFrame.new(151.6, 3.5, 0), Color = Color3.fromRGB(20, 30, 25), Parent = mapa })
	placa(reciclagem, "reciclagem", "RECYCLER", Color3.fromRGB(120, 255, 140), 340, 60, Vector3.new(0, 11, 0), 450)

	-- ponto de nascimento neutro (todo mundo é levado para a própria base)
	local nascer = Instance.new("SpawnLocation")
	nascer.Name = "Nascer"
	nascer.Anchored = true
	nascer.Size = Vector3.new(8, 0.4, 8)
	nascer.CFrame = CFrame.new(0, 0.2, 21)
	nascer.Neutral = true
	nascer.Duration = 0
	nascer.Transparency = 0.6
	nascer.CanCollide = false
	nascer.Parent = mapa

	-- placar dos mais ricos (lado sul) e "como jogar" (lado norte)
	local ranking, linhasRanking = quadroDeAviso(mapa, "Ranking", CFrame.new(0, 10, 46),
		"ranking_titulo", Color3.fromRGB(255, 216, 77), 10)
	local _, linhasComo = quadroDeAviso(mapa, "ComoJogar", CFrame.new(0, 10, -46) * CFrame.Angles(0, math.pi, 0),
		"como_jogar", Color3.fromRGB(75, 240, 138), 4)
	for i, linha in ipairs(linhasComo) do
		linha.Size = UDim2.new(1, 0, 0, 52)
		linha:SetAttribute("Chave", "passo" .. i)
		CollectionService:AddTag(linha, "TextoLocal")
	end

	-- bases: 4 ao norte (entrada para +Z) e 4 ao sul (giradas)
	local pastaBases = Instance.new("Folder")
	pastaBases.Name = "Bases"
	pastaBases.Parent = mapa

	local bases = {}
	local xs = { -114, -38, 38, 114 }
	for i, x in ipairs(xs) do
		bases[i] = construirBase(i, Vector3.new(x, 0.2, -62), false, pastaBases)
	end
	for i, x in ipairs(xs) do
		bases[4 + i] = construirBase(4 + i, Vector3.new(x, 0.2, 62), true, pastaBases)
	end

	local pastaRobos = Instance.new("Folder")
	pastaRobos.Name = "Robos"
	pastaRobos.Parent = workspace

	return {
		bases = bases,
		pastaRobos = pastaRobos,
		ranking = ranking,
		linhasRanking = linhasRanking,
		esteira = {
			inicioX = -158,
			fimX = 154,
			y = yEsteira,
			z = 0,
		},
	}
end

-- Converte uma posição do mundo para o espaço da base e diz se está dentro.
-- `folga` aumenta (ou diminui, se negativa) a área considerada.
function MapBuilder.dentroDaBase(base, posicao, folga)
	folga = folga or 0
	local relativo = base.quadro:PointToObjectSpace(posicao)
	return math.abs(relativo.X) <= LARGURA_BASE / 2 + folga
		and math.abs(relativo.Z) <= PROFUNDIDADE_BASE / 2 + folga
		and relativo.Y > -5
		and relativo.Y < 40
end

return MapBuilder
