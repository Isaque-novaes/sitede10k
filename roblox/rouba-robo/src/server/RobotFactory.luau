--[[
	Monta o modelo 3D de cada robô com peças simples (sem malhas ou
	imagens enviadas). Robôs mais raros ficam maiores e ganham faíscas,
	luz, asas e auréola. A mutação muda a cor e o material.

	O modelo é montado com os pés na origem; quem chama usa
	modelo:PivotTo(cframe). A placa em cima da cabeça recebe os textos no
	idioma de cada jogador (atributos RoboId/Mut + tag "RoboInfo").
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))

local RobotFactory = {}

local CONTORNO = Color3.fromRGB(20, 23, 43)
local FAISCAS = "rbxasset://textures/particles/sparkles_main.dds"

local function novaParte(modelo, nome, tamanho, cframe, cor, material, forma)
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
	parte.Parent = modelo
	return parte
end

local function rotulo(pai, nome, texto, cor, ordem, altura, fonte)
	local r = Instance.new("TextLabel")
	r.Name = nome
	r.BackgroundTransparency = 1
	r.Size = UDim2.new(1, 0, 0, altura or 18)
	r.Text = texto
	r.TextColor3 = cor
	r.TextStrokeTransparency = 0
	r.TextStrokeColor3 = CONTORNO
	r.TextScaled = true
	r.Font = fonte or Enum.Font.FredokaOne
	r.LayoutOrder = ordem
	r.Parent = pai
	return r
end

local function faiscas(parte, cor, taxa)
	local emissor = Instance.new("ParticleEmitter")
	emissor.Name = "Faiscas"
	emissor.Texture = FAISCAS
	emissor.Color = ColorSequence.new(cor)
	emissor.LightEmission = 1
	emissor.LightInfluence = 0
	emissor.Rate = taxa
	emissor.Lifetime = NumberRange.new(0.8, 1.4)
	emissor.Speed = NumberRange.new(1, 2.5)
	emissor.SpreadAngle = Vector2.new(180, 180)
	emissor.Size = NumberSequence.new(0.35, 0)
	emissor.Parent = parte
	return emissor
end

function RobotFactory.construir(robo, mutacaoId)
	local raridade = Config.Raridades[robo.raridade]
	local mutacao = mutacaoId and Config.MutacaoPorId[mutacaoId] or nil
	local s = raridade.escala

	local corPrincipal = robo.cor
	local materialPrincipal = Enum.Material.SmoothPlastic
	local reflexo = 0
	local transparencia = 0
	if mutacao and mutacao.id == "dourado" then
		corPrincipal = mutacao.cor
		materialPrincipal = Enum.Material.Metal
		reflexo = 0.3
	elseif mutacao and mutacao.id == "diamante" then
		corPrincipal = mutacao.cor
		materialPrincipal = Enum.Material.Glass
		reflexo = 0.2
		transparencia = 0.15
	elseif mutacao and mutacao.id == "arcoiris" then
		corPrincipal = mutacao.cor
		materialPrincipal = Enum.Material.Neon
	end
	local corDetalhe = robo.detalhe
	local corBrilho = raridade.cor
	local corOlhos = Color3.fromRGB(125, 249, 255)
	if robo.raridade >= 7 then
		corOlhos = robo.detalhe
	end
	local corBarriga = corPrincipal:Lerp(Color3.new(1, 1, 1), 0.35)

	local modelo = Instance.new("Model")
	modelo.Name = robo.id
	modelo:SetAttribute("RoboId", robo.id)
	if mutacaoId then
		modelo:SetAttribute("Mut", mutacaoId)
	end

	-- raiz invisível nos pés: o ponto de referência do modelo
	local raiz = novaParte(modelo, "Raiz", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, 0, 0), corDetalhe)
	raiz.Transparency = 1
	modelo.PrimaryPart = raiz

	-- pés e pernas
	for _, lado in ipairs({ -1, 1 }) do
		novaParte(modelo, "Pe", Vector3.new(0.9, 0.4, 1.2) * s, CFrame.new(0.6 * lado * s, 0.2 * s, -0.1 * s), corDetalhe)
		novaParte(modelo, "Perna", Vector3.new(0.55, 1.0, 0.55) * s, CFrame.new(0.6 * lado * s, 0.9 * s, 0), CONTORNO)
	end

	-- corpo
	local alturaCorpo, larguraCorpo
	local corpo
	local yBaseCorpo = 1.3
	if robo.forma == "barril" then
		alturaCorpo, larguraCorpo = 2.2, 2.2
		corpo = novaParte(modelo, "Corpo", Vector3.new(alturaCorpo, larguraCorpo, larguraCorpo) * s,
			CFrame.new(0, (yBaseCorpo + alturaCorpo / 2) * s, 0) * CFrame.Angles(0, 0, math.pi / 2),
			corPrincipal, materialPrincipal, Enum.PartType.Cylinder)
	elseif robo.forma == "bola" then
		alturaCorpo, larguraCorpo = 2.4, 2.4
		corpo = novaParte(modelo, "Corpo", Vector3.new(2.4, 2.4, 2.4) * s,
			CFrame.new(0, (yBaseCorpo - 0.1 + alturaCorpo / 2) * s, 0), corPrincipal, materialPrincipal, Enum.PartType.Ball)
	else
		alturaCorpo, larguraCorpo = 2, 2.4
		corpo = novaParte(modelo, "Corpo", Vector3.new(larguraCorpo, alturaCorpo, 1.8) * s,
			CFrame.new(0, (yBaseCorpo + alturaCorpo / 2) * s, 0), corPrincipal, materialPrincipal)
	end
	corpo.Reflectance = reflexo
	corpo.Transparency = transparencia
	local yCorpo = (yBaseCorpo + alturaCorpo / 2) * s
	local topoCorpo = (yBaseCorpo + alturaCorpo) * s
	local frenteCorpo = -(larguraCorpo / 2) * s
	if robo.forma == "caixa" then
		frenteCorpo = -0.9 * s
	end

	-- placa da barriga
	novaParte(modelo, "Barriga", Vector3.new(1.2, 0.9, 0.12) * s,
		CFrame.new(0, yCorpo - 0.15 * s, frenteCorpo - 0.02 * s), corBarriga)

	-- braços: ombro, braço e mão
	for _, lado in ipairs({ -1, 1 }) do
		local xOmbro = (larguraCorpo / 2 + 0.15) * lado * s
		novaParte(modelo, "Ombro", Vector3.new(0.7, 0.7, 0.7) * s, CFrame.new(xOmbro, topoCorpo - 0.45 * s, 0),
			corDetalhe, nil, Enum.PartType.Ball)
		novaParte(modelo, "Braco", Vector3.new(0.45, 1.3, 0.45) * s,
			CFrame.new(xOmbro + 0.15 * lado * s, yCorpo - 0.25 * s, 0) * CFrame.Angles(0, 0, 0.2 * lado), CONTORNO)
		novaParte(modelo, "Mao", Vector3.new(0.6, 0.6, 0.6) * s,
			CFrame.new(xOmbro + 0.3 * lado * s, yCorpo - 0.95 * s, 0), corDetalhe, nil, Enum.PartType.Ball)
	end

	-- cabeça, visor, olhos e antena (a frente do robô é o -Z)
	local yCabeca = topoCorpo + 0.7 * s
	local cabeca = novaParte(modelo, "Cabeca", Vector3.new(1.8, 1.3, 1.5) * s,
		CFrame.new(0, yCabeca, 0), corPrincipal, materialPrincipal)
	cabeca.Reflectance = reflexo
	cabeca.Transparency = transparencia
	novaParte(modelo, "Visor", Vector3.new(1.4, 0.65, 0.1) * s,
		CFrame.new(0, yCabeca + 0.08 * s, -0.78 * s), CONTORNO)
	for _, lado in ipairs({ -1, 1 }) do
		novaParte(modelo, "Olho", Vector3.new(0.32, 0.32, 0.1) * s,
			CFrame.new(0.32 * lado * s, yCabeca + 0.1 * s, -0.84 * s), corOlhos, Enum.Material.Neon)
	end
	local topoCabeca = yCabeca + 0.65 * s
	novaParte(modelo, "Antena", Vector3.new(0.12, 0.8, 0.12) * s,
		CFrame.new(0, topoCabeca + 0.4 * s, 0), CONTORNO)
	local ponta = novaParte(modelo, "PontaAntena", Vector3.new(0.42, 0.42, 0.42) * s,
		CFrame.new(0, topoCabeca + 0.9 * s, 0), corBrilho, Enum.Material.Neon, Enum.PartType.Ball)

	-- extras por raridade
	if robo.raridade >= 4 then
		novaParte(modelo, "LuzPeito", Vector3.new(0.45, 0.45, 0.1) * s,
			CFrame.new(0, yCorpo - 0.15 * s, frenteCorpo - 0.1 * s), corBrilho, Enum.Material.Neon)
		faiscas(ponta, corBrilho, robo.raridade >= 6 and 6 or 3)
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
			novaParte(modelo, "Asa", Vector3.new(0.2, 1.9, 1.5) * s,
				CFrame.new(1.1 * lado * s, yCorpo + 0.5 * s, 1.0 * s) * CFrame.Angles(0, 0.5 * lado, 0.35 * lado),
				corDetalhe, Enum.Material.Neon)
		end
	end
	if robo.raridade >= 7 then
		local aureola = novaParte(modelo, "Aureola", Vector3.new(0.15, 1.9, 1.9) * s,
			CFrame.new(0, topoCabeca + 1.5 * s, 0) * CFrame.Angles(0, 0, math.pi / 2),
			corBrilho, Enum.Material.Neon, Enum.PartType.Cylinder)
		aureola.Transparency = 0.3
	end

	if mutacao and mutacao.id == "arcoiris" then
		CollectionService:AddTag(corpo, "Arcoiris")
		CollectionService:AddTag(cabeca, "Arcoiris")
		faiscas(corpo, Color3.fromRGB(255, 255, 255), 4)
	elseif mutacao and mutacao.id == "dourado" then
		faiscas(cabeca, mutacao.cor, 2)
	end

	-- placa de informações em cima da cabeça
	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.Adornee = cabeca
	gui.Size = UDim2.fromOffset(220, 104)
	gui.StudsOffset = Vector3.new(0, 1.3 * s + 2.4, 0)
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	gui.Parent = raiz

	local lista = Instance.new("UIListLayout")
	lista.SortOrder = Enum.SortOrder.LayoutOrder
	lista.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lista.VerticalAlignment = Enum.VerticalAlignment.Bottom
	lista.Parent = gui

	if mutacao then
		rotulo(gui, "Mutacao", mutacao.en, mutacao.cor, 1, 16, Enum.Font.LuckiestGuy)
	end
	rotulo(gui, "Nome", robo.en, Color3.new(1, 1, 1), 2, 22)
	rotulo(gui, "Raridade", raridade.en, raridade.cor, 3, 17)
	local rotuloPreco = rotulo(gui, "Preco", Format.dinheiro(Config.precoDe(robo, mutacaoId), "en"),
		Color3.fromRGB(75, 240, 138), 4, 19)
	local rotuloRenda = rotulo(gui, "Renda", Format.dinheiro(Config.rendaDe(robo, mutacaoId), "en") .. "/s",
		Color3.fromRGB(255, 216, 77), 5, 16)
	CollectionService:AddTag(gui, "RoboInfo")

	-- o botão "segure E" do robô (texto traduzido no jogador)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Interagir"
	prompt.ActionText = "Buy"
	prompt.ObjectText = Config.nomeCompleto(robo, mutacaoId, "en") .. " — " .. Format.dinheiro(Config.precoDe(robo, mutacaoId), "en")
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt:SetAttribute("Robo", true)
	prompt:SetAttribute("RoboId", robo.id)
	if mutacaoId then
		prompt:SetAttribute("Mut", mutacaoId)
	end
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
