--[[
	Monta o modelo 3D de cada robô com peças simples (sem precisar de
	malhas ou imagens enviadas). Robôs mais raros ficam maiores e ganham
	luz, asas e auréola. A mutação muda a cor e o material.

	O modelo é construído com a base dos pés na origem; quem chama usa
	modelo:PivotTo(cframe) para colocá-lo no lugar.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))

local RobotFactory = {}

local function novaParte(modelo, nome, tamanho, cframe, cor, material)
	local parte = Instance.new("Part")
	parte.Name = nome
	parte.Size = tamanho
	parte.CFrame = cframe
	parte.Color = cor
	parte.Material = material or Enum.Material.SmoothPlastic
	parte.TopSurface = Enum.SurfaceType.Smooth
	parte.BottomSurface = Enum.SurfaceType.Smooth
	parte.Anchored = true
	parte.CanCollide = false
	parte.CanTouch = false
	parte.Parent = modelo
	return parte
end

local function rotulo(pai, nome, texto, cor, ordem, altura)
	local r = Instance.new("TextLabel")
	r.Name = nome
	r.BackgroundTransparency = 1
	r.Size = UDim2.new(1, 0, 0, altura or 18)
	r.Text = texto
	r.TextColor3 = cor
	r.TextStrokeTransparency = 0
	r.TextStrokeColor3 = Color3.new(0, 0, 0)
	r.TextScaled = true
	r.Font = Enum.Font.FredokaOne
	r.LayoutOrder = ordem
	r.Parent = pai
	return r
end

function RobotFactory.construir(robo, mutacaoId)
	local raridade = Config.Raridades[robo.raridade]
	local mutacao = mutacaoId and Config.MutacaoPorId[mutacaoId] or nil
	local s = raridade.escala

	local corPrincipal = robo.cor
	local materialPrincipal = Enum.Material.SmoothPlastic
	if mutacao and mutacao.id == "dourado" then
		corPrincipal = mutacao.cor
		materialPrincipal = Enum.Material.Metal
	elseif mutacao and mutacao.id == "diamante" then
		corPrincipal = mutacao.cor
		materialPrincipal = Enum.Material.Glass
	elseif mutacao and mutacao.id == "arcoiris" then
		corPrincipal = mutacao.cor
		materialPrincipal = Enum.Material.Neon
	end
	local corDetalhe = robo.detalhe
	local corOlhos = Color3.fromRGB(140, 255, 255)
	if robo.raridade >= 7 then
		corOlhos = robo.detalhe
	end
	local corBrilho = raridade.cor
	if robo.raridade >= 7 then
		corBrilho = robo.detalhe
	end

	local modelo = Instance.new("Model")
	modelo.Name = robo.id

	-- raiz invisível nos pés: é o ponto de referência do modelo
	local raiz = novaParte(modelo, "Raiz", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, 0, 0), corDetalhe)
	raiz.Transparency = 1
	modelo.PrimaryPart = raiz

	-- pernas
	for _, lado in ipairs({ -1, 1 }) do
		novaParte(modelo, "Perna", Vector3.new(0.7, 1.2, 0.7) * s,
			CFrame.new(0.6 * lado * s, 0.6 * s, 0), corDetalhe)
	end

	-- corpo
	local alturaCorpo
	local larguraCorpo
	local corpo
	if robo.forma == "barril" then
		alturaCorpo, larguraCorpo = 2.2, 2.2
		corpo = novaParte(modelo, "Corpo", Vector3.new(alturaCorpo, larguraCorpo, larguraCorpo) * s,
			CFrame.new(0, (1.2 + alturaCorpo / 2) * s, 0) * CFrame.Angles(0, 0, math.pi / 2),
			corPrincipal, materialPrincipal)
		corpo.Shape = Enum.PartType.Cylinder
	elseif robo.forma == "bola" then
		alturaCorpo, larguraCorpo = 2.4, 2.4
		corpo = novaParte(modelo, "Corpo", Vector3.new(2.4, 2.4, 2.4) * s,
			CFrame.new(0, (1.1 + alturaCorpo / 2) * s, 0), corPrincipal, materialPrincipal)
		corpo.Shape = Enum.PartType.Ball
	else
		alturaCorpo, larguraCorpo = 2, 2.4
		corpo = novaParte(modelo, "Corpo", Vector3.new(larguraCorpo, alturaCorpo, 1.8) * s,
			CFrame.new(0, (1.2 + alturaCorpo / 2) * s, 0), corPrincipal, materialPrincipal)
	end
	if mutacao and mutacao.id == "dourado" then
		corpo.Reflectance = 0.3
	elseif mutacao and mutacao.id == "diamante" then
		corpo.Transparency = 0.15
		corpo.Reflectance = 0.2
	end
	local yCorpo = (1.2 + alturaCorpo / 2) * s
	local topoCorpo = (1.2 + alturaCorpo) * s

	-- braços
	for _, lado in ipairs({ -1, 1 }) do
		novaParte(modelo, "Braco", Vector3.new(0.5, 1.6, 0.5) * s,
			CFrame.new((larguraCorpo / 2 + 0.3) * lado * s, yCorpo, 0) * CFrame.Angles(0, 0, 0.25 * lado),
			corDetalhe)
	end

	-- cabeça, olhos e boca (a frente do robô é o -Z)
	local yCabeca = topoCorpo + 0.6 * s
	local cabeca = novaParte(modelo, "Cabeca", Vector3.new(1.7, 1.2, 1.5) * s,
		CFrame.new(0, yCabeca, 0), corPrincipal, materialPrincipal)
	for _, lado in ipairs({ -1, 1 }) do
		novaParte(modelo, "Olho", Vector3.new(0.4, 0.4, 0.12) * s,
			CFrame.new(0.4 * lado * s, yCabeca + 0.12 * s, -0.76 * s), corOlhos, Enum.Material.Neon)
	end
	novaParte(modelo, "Boca", Vector3.new(0.9, 0.15, 0.1) * s,
		CFrame.new(0, yCabeca - 0.3 * s, -0.76 * s), corDetalhe)

	-- antena
	local topoCabeca = yCabeca + 0.6 * s
	novaParte(modelo, "Antena", Vector3.new(0.15, 0.8, 0.15) * s,
		CFrame.new(0, topoCabeca + 0.4 * s, 0), corDetalhe)
	novaParte(modelo, "PontaAntena", Vector3.new(0.4, 0.4, 0.4) * s,
		CFrame.new(0, topoCabeca + 0.9 * s, 0), corBrilho, Enum.Material.Neon).Shape = Enum.PartType.Ball

	-- extras por raridade
	if robo.raridade >= 4 then
		novaParte(modelo, "Peito", Vector3.new(0.8, 0.8, 0.1) * s,
			CFrame.new(0, yCorpo, -(larguraCorpo / 2 + 0.02) * s), corBrilho, Enum.Material.Neon)
	end
	if robo.raridade >= 5 then
		local luz = Instance.new("PointLight")
		luz.Color = corBrilho
		luz.Range = 10 * s
		luz.Brightness = 2
		luz.Parent = corpo
	end
	if robo.raridade >= 6 then
		for _, lado in ipairs({ -1, 1 }) do
			novaParte(modelo, "Asa", Vector3.new(0.2, 1.8, 1.4) * s,
				CFrame.new(1.1 * lado * s, yCorpo + 0.4 * s, 1.0 * s) * CFrame.Angles(0, 0.5 * lado, 0.35 * lado),
				corDetalhe, Enum.Material.Neon)
		end
	end
	if robo.raridade >= 7 then
		local aureola = novaParte(modelo, "Aureola", Vector3.new(0.15, 1.8, 1.8) * s,
			CFrame.new(0, topoCabeca + 1.4 * s, 0) * CFrame.Angles(0, 0, math.pi / 2),
			corBrilho, Enum.Material.Neon)
		aureola.Shape = Enum.PartType.Cylinder
		aureola.Transparency = 0.3
	end

	if mutacao and mutacao.id == "arcoiris" then
		CollectionService:AddTag(corpo, "Arcoiris")
		CollectionService:AddTag(cabeca, "Arcoiris")
	end

	-- placa de informações em cima da cabeça
	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.Adornee = cabeca
	gui.Size = UDim2.fromOffset(220, 100)
	gui.StudsOffset = Vector3.new(0, 1.2 * s + 2.2, 0)
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	gui.Parent = raiz

	local lista = Instance.new("UIListLayout")
	lista.SortOrder = Enum.SortOrder.LayoutOrder
	lista.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lista.VerticalAlignment = Enum.VerticalAlignment.Bottom
	lista.Parent = gui

	if mutacao then
		rotulo(gui, "Mutacao", mutacao.nome, mutacao.cor, 1, 16)
	end
	rotulo(gui, "Nome", robo.nome, Color3.new(1, 1, 1), 2, 22)
	local rotuloRaridade = rotulo(gui, "Raridade", raridade.nome, raridade.cor, 3, 18)
	if robo.raridade >= 7 then
		rotuloRaridade.TextStrokeColor3 = Color3.new(1, 1, 1)
	end
	local rotuloPreco = rotulo(gui, "Preco", Format.dinheiro(Config.precoDe(robo, mutacaoId)),
		Color3.fromRGB(120, 255, 120), 4, 18)
	local rotuloRenda = rotulo(gui, "Renda", Format.dinheiro(Config.rendaDe(robo, mutacaoId)) .. "/s",
		Color3.fromRGB(255, 230, 90), 5, 16)

	-- o botão "segure E" do robô
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Interagir"
	prompt.ActionText = "Comprar"
	prompt.ObjectText = Config.nomeCompleto(robo, mutacaoId) .. " — " .. Format.dinheiro(Config.precoDe(robo, mutacaoId))
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt:SetAttribute("Robo", true)
	prompt.Parent = corpo

	return {
		modelo = modelo,
		raiz = raiz,
		corpo = corpo,
		prompt = prompt,
		rotuloPreco = rotuloPreco,
		rotuloRenda = rotuloRenda,
	}
end

return RobotFactory
