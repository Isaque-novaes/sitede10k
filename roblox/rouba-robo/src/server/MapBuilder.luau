--[[
	Constrói o mapa inteiro por código: chão, esteira, fábrica, reciclagem
	e as 8 bases. Assim o jogo funciona num lugar vazio do Roblox Studio.

	Cada base tem um "quadro" (CFrame) próprio: a origem fica no centro do
	piso e o eixo +Z local aponta para a entrada (virada para a esteira).
]]

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

local CORES_BASES = {
	Color3.fromRGB(230, 70, 70),
	Color3.fromRGB(70, 130, 240),
	Color3.fromRGB(80, 200, 100),
	Color3.fromRGB(245, 200, 50),
	Color3.fromRGB(160, 90, 230),
	Color3.fromRGB(250, 140, 50),
	Color3.fromRGB(240, 110, 180),
	Color3.fromRGB(60, 210, 220),
}

local function peca(props)
	local parte = Instance.new("Part")
	parte.Anchored = true
	parte.TopSurface = Enum.SurfaceType.Smooth
	parte.BottomSurface = Enum.SurfaceType.Smooth
	parte.Material = Enum.Material.SmoothPlastic
	for nome, valor in pairs(props) do
		if nome ~= "Parent" then
			parte[nome] = valor
		end
	end
	parte.Parent = props.Parent
	return parte
end

local function placa(parte, texto, cor, largura, altura, deslocamento, distancia)
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
	rotulo.Text = texto
	rotulo.TextColor3 = cor or Color3.new(1, 1, 1)
	rotulo.TextStrokeTransparency = 0
	rotulo.TextScaled = true
	rotulo.Font = Enum.Font.FredokaOne
	rotulo.Parent = gui

	gui.Parent = parte
	return rotulo
end

local function construirBase(indice, centro, girada, pasta)
	local cor = CORES_BASES[indice]
	local quadro = CFrame.new(centro)
	if girada then
		quadro = quadro * CFrame.Angles(0, math.pi, 0)
	end

	local modelo = Instance.new("Model")
	modelo.Name = "Base" .. indice
	modelo.Parent = pasta

	local function local_(x, y, z)
		return quadro * CFrame.new(x, y, z)
	end

	-- piso
	peca({
		Name = "Piso",
		Size = Vector3.new(LARGURA_BASE, 0.4, PROFUNDIDADE_BASE),
		CFrame = local_(0, -0.2, 0),
		Color = cor:Lerp(Color3.new(1, 1, 1), 0.6),
		Material = Enum.Material.Concrete,
		Parent = modelo,
	})

	-- paredes (fundo, laterais e frente com a entrada no meio)
	local meiaLargura = LARGURA_BASE / 2
	local meiaProfundidade = PROFUNDIDADE_BASE / 2
	local yParede = ALTURA_PAREDE / 2
	local function parede(nome, tamanho, x, z)
		peca({
			Name = nome,
			Size = tamanho,
			CFrame = local_(x, yParede, z),
			Color = cor,
			Material = Enum.Material.SmoothPlastic,
			Parent = modelo,
		})
	end
	parede("ParedeFundo", Vector3.new(LARGURA_BASE, ALTURA_PAREDE, 2), 0, -meiaProfundidade + 1)
	parede("ParedeEsquerda", Vector3.new(2, ALTURA_PAREDE, PROFUNDIDADE_BASE), -meiaLargura + 1, 0)
	parede("ParedeDireita", Vector3.new(2, ALTURA_PAREDE, PROFUNDIDADE_BASE), meiaLargura - 1, 0)
	local larguraFrente = (LARGURA_BASE - LARGURA_ENTRADA) / 2
	local xFrente = LARGURA_ENTRADA / 2 + larguraFrente / 2
	parede("FrenteEsquerda", Vector3.new(larguraFrente, ALTURA_PAREDE, 2), -xFrente, meiaProfundidade - 1)
	parede("FrenteDireita", Vector3.new(larguraFrente, ALTURA_PAREDE, 2), xFrente, meiaProfundidade - 1)

	-- pedestais: 2 fileiras de 5
	local pedestais = {}
	for fileira, z in ipairs({ -16, -4 }) do
		for coluna, x in ipairs({ -20, -10, 0, 10, 20 }) do
			local numero = (fileira - 1) * 5 + coluna
			peca({
				Name = "Pedestal" .. numero,
				Size = Vector3.new(6, 1, 6),
				CFrame = local_(x, 0.5, z),
				Color = Color3.fromRGB(70, 70, 80),
				Material = Enum.Material.DiamondPlate,
				Parent = modelo,
			})
			-- o robô fica em cima do pedestal, olhando para a entrada
			pedestais[numero] = local_(x, 1, z) * CFrame.Angles(0, math.pi, 0)
		end
	end

	-- botão de trancar (o dono pisa nele)
	local botao = peca({
		Name = "BotaoTrancar",
		Size = Vector3.new(6, 0.3, 6),
		CFrame = local_(-22, 0.15, 17),
		Color = Color3.fromRGB(255, 60, 60),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = modelo,
	})
	local rotuloBotao = placa(botao, "TRANCAR BASE", Color3.new(1, 1, 1), 200, 40, Vector3.new(0, 3, 0), 60)

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
	local rotuloTranca = placa(barreira, "", Color3.fromRGB(255, 90, 90), 260, 50, Vector3.new(0, ALTURA_PAREDE / 2 + 3, 0), 150)

	-- placa com o nome do dono
	local suportePlaca = peca({
		Name = "SuportePlaca",
		Size = Vector3.new(1, 1, 1),
		CFrame = local_(0, ALTURA_PAREDE + 4, -meiaProfundidade + 1),
		Transparency = 1,
		CanCollide = false,
		Parent = modelo,
	})
	local rotuloDono = placa(suportePlaca, "Base livre", Color3.new(1, 1, 1), 360, 70, Vector3.new(0, 0, 0), 300)

	return {
		indice = indice,
		quadro = quadro,
		cor = cor,
		modelo = modelo,
		pedestais = pedestais,
		botao = botao,
		rotuloBotao = rotuloBotao,
		barreira = barreira,
		rotuloTranca = rotuloTranca,
		rotuloDono = rotuloDono,
		nascer = local_(0, 3, 16),
		saida = local_(0, 3, meiaProfundidade + 8),
	}
end

function MapBuilder.construir()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2

	local mapa = Instance.new("Folder")
	mapa.Name = "Mapa"
	mapa.Parent = workspace

	-- chão
	peca({
		Name = "Chao",
		Size = Vector3.new(420, 1, 330),
		CFrame = CFrame.new(0, -0.5, 0),
		Color = Color3.fromRGB(90, 170, 80),
		Material = Enum.Material.Grass,
		Parent = mapa,
	})

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

	-- esteira
	local yEsteira = 1
	local esteira = peca({
		Name = "Esteira",
		Size = Vector3.new(330, 1, 10),
		CFrame = CFrame.new(0, 0.5, 0),
		Color = Color3.fromRGB(45, 45, 50),
		Material = Enum.Material.DiamondPlate,
		Parent = mapa,
	})
	-- esteira de verdade: quem sobe nela é levado junto com os robôs
	esteira.AssemblyLinearVelocity = Vector3.new(Config.ESTEIRA.VELOCIDADE, 0, 0)
	for _, z in ipairs({ -5.4, 5.4 }) do
		peca({
			Name = "Trilho",
			Size = Vector3.new(330, 1.4, 0.8),
			CFrame = CFrame.new(0, 0.7, z),
			Color = Color3.fromRGB(255, 200, 0),
			Material = Enum.Material.Neon,
			Parent = mapa,
		})
	end

	-- fábrica (de onde saem os robôs)
	local fabrica = peca({
		Name = "Fabrica",
		Size = Vector3.new(26, 22, 26),
		CFrame = CFrame.new(-163, 11, 0),
		Color = Color3.fromRGB(110, 115, 130),
		Material = Enum.Material.Metal,
		Parent = mapa,
	})
	placa(fabrica, "FÁBRICA DE ROBÔS", Color3.fromRGB(255, 220, 60), 420, 80, Vector3.new(0, 15, 0), 400)
	peca({
		Name = "Chamine",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(16, 5, 5),
		CFrame = CFrame.new(-168, 30, 6) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(80, 80, 90),
		Material = Enum.Material.Metal,
		Parent = mapa,
	})

	-- reciclagem (onde somem os robôs que ninguém comprou)
	local reciclagem = peca({
		Name = "Reciclagem",
		Size = Vector3.new(22, 16, 22),
		CFrame = CFrame.new(163, 8, 0),
		Color = Color3.fromRGB(40, 70, 50),
		Material = Enum.Material.Metal,
		Parent = mapa,
	})
	placa(reciclagem, "RECICLAGEM", Color3.fromRGB(120, 255, 140), 320, 60, Vector3.new(0, 11, 0), 400)

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
