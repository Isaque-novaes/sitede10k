--[[
	Os golpes no lado do jogador: para onde você está mirando, os três
	botões embaixo da tela e a contagem de recarga.

	Aqui só é desenhado e enviado o pedido. Quem decide se o golpe sai,
	quanto de dano faz e em quem acerta é sempre o servidor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Textos = require(Shared:WaitForChild("Textos"))
local UI = require(Shared:WaitForChild("UI"))
local Remotos = ReplicatedStorage:WaitForChild("Remotos")

local jogador = Players.LocalPlayer
local playerGui = jogador:WaitForChild("PlayerGui")
local idioma = Textos.idiomaDe(jogador.LocaleId)
local function T(chave, ...)
	return Textos.t(idioma, chave, ...)
end

local TECLAS = { Enum.KeyCode.Q, Enum.KeyCode.E }
local NOMES_TECLA = { "golpe_basico", "golpe_especial", "golpe_supremo" }

-- Para onde o golpe vai ---------------------------------------------------------
-- No PC: para onde o mouse está apontando. No celular: para onde o
-- personagem está virado, mirando sozinho no inimigo mais próximo à frente.
local camera = workspace.CurrentCamera

local function personagem()
	local p = jogador.Character
	local raiz = p and p:FindFirstChild("HumanoidRootPart")
	local humanoid = p and p:FindFirstChildOfClass("Humanoid")
	if raiz and humanoid and humanoid.Health > 0 then
		return raiz, humanoid
	end
	return nil
end

local function alvoAutomatico(raiz)
	local frente = raiz.CFrame.LookVector
	local melhor, melhorNota = nil, 0.55
	local monstros = workspace:FindFirstChild("Monstros")
	if monstros then
		for _, modelo in ipairs(monstros:GetChildren()) do
			local alvo = modelo.PrimaryPart or modelo:FindFirstChild("Raiz")
			if alvo then
				local delta = alvo.Position - raiz.Position
				local distancia = delta.Magnitude
				if distancia > 3 and distancia < 180 then
					local nota = frente:Dot(delta.Unit) - distancia / 600
					if nota > melhorNota then
						melhor, melhorNota = alvo.Position, nota
					end
				end
			end
		end
	end
	return melhor
end

local function direcaoDoGolpe()
	local raiz = personagem()
	if not raiz then
		return nil
	end
	local origem = raiz.Position + Vector3.new(0, 1.5, 0)
	if UI.noCelular() then
		local alvo = alvoAutomatico(raiz)
		if alvo then
			return (alvo - origem).Unit
		end
		return raiz.CFrame.LookVector
	end
	local ok, raio = pcall(function()
		local mouse = UserInputService:GetMouseLocation()
		return camera and camera:ViewportPointToRay(mouse.X, mouse.Y)
	end)
	if not ok or not raio then
		return raiz.CFrame.LookVector -- sem mouse: atira para a frente
	end
	-- mira num ponto adiante na linha do mouse
	local destino = raio.Origin + raio.Direction * 300
	local delta = destino - origem
	if delta.Magnitude < 0.1 then
		return raiz.CFrame.LookVector
	end
	return delta.Unit
end

-- Barra de golpes ------------------------------------------------------------------
local tela = UI.novo("ScreenGui", {
	Name = "BarraDeGolpes",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

local barra = UI.novo("Frame", {
	Name = "Golpes",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.new(0, 280, 0, 86),
	BackgroundTransparency = 1,
	Parent = tela,
}, {
	UI.novo("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
	}),
})
UI.escalavel(barra)

local botoes = {}
local recargaAte = { 0, 0, 0 }

local function usar(indice)
	local direcao = direcaoDoGolpe()
	if not direcao then
		return
	end
	if os.clock() < recargaAte[indice] then
		return
	end
	Remotos.Atacar:FireServer(indice, direcao)
end

for indice = 1, 3 do
	local caixa = UI.novo("Frame", {
		Name = "Golpe" .. indice,
		LayoutOrder = indice,
		Size = UDim2.new(0, indice == 1 and 86 or 76, 0, indice == 1 and 86 or 76),
		BackgroundTransparency = 1,
		Parent = barra,
	})
	UI.novo("Frame", {
		Name = "Degrau",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.new(0, 0, 0, 4),
		BackgroundColor3 = UI.COR.contorno,
		Parent = caixa,
	}, { UI.cantos(16) })
	local corpo = UI.novo("TextButton", {
		Name = "Corpo",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UI.COR.painel,
		AutoButtonColor = false,
		Text = "",
		Parent = caixa,
	}, { UI.cantos(16), UI.borda(3) })

	-- tampa escura que desce conforme a recarga passa
	local tampa = UI.novo("Frame", {
		Name = "Recarga",
		Size = UDim2.fromScale(1, 0),
		Position = UDim2.fromScale(0, 1),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = corpo,
	}, { UI.cantos(16) })

	local icone = UI.texto({
		Name = "Icone",
		Size = UDim2.new(1, 0, 0.42, 0),
		Position = UDim2.new(0, 0, 0, 6),
		Text = "",
		TamanhoMax = 34,
		Contorno = false,
		ZIndex = 3,
		Parent = corpo,
	})
	local nome = UI.texto({
		Name = "Nome",
		Size = UDim2.new(1, -8, 0.26, 0),
		Position = UDim2.new(0, 4, 0.46, 0),
		TamanhoMax = 13,
		Contorno = 1.5,
		ZIndex = 3,
		Parent = corpo,
	})
	local tecla = UI.texto({
		Name = "Tecla",
		Size = UDim2.new(1, -8, 0.24, 0),
		Position = UDim2.new(0, 4, 0.74, 0),
		Text = T(NOMES_TECLA[indice]),
		TextColor3 = UI.COR.suave,
		TamanhoMax = 13,
		Contorno = 1.5,
		ZIndex = 3,
		Parent = corpo,
	})
	local segundos = UI.texto({
		Name = "Segundos",
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Font = UI.TITULO,
		TamanhoMax = 30,
		ZIndex = 5,
		Parent = corpo,
	})

	corpo.Activated:Connect(function()
		usar(indice)
	end)
	botoes[indice] = { caixa = caixa, corpo = corpo, tampa = tampa, icone = icone,
		nome = nome, tecla = tecla, segundos = segundos }
end

-- Entradas do teclado e do mouse ---------------------------------------------------
UserInputService.InputBegan:Connect(function(entrada, digitando)
	if digitando then
		return
	end
	if entrada.UserInputType == Enum.UserInputType.MouseButton1 then
		usar(1)
	else
		for i, tecla in ipairs(TECLAS) do
			if entrada.KeyCode == tecla then
				usar(i + 1)
			end
		end
	end
end)

-- segurar o botão do mouse continua atacando
local segurando = false
UserInputService.InputBegan:Connect(function(entrada)
	if entrada.UserInputType == Enum.UserInputType.MouseButton1 then
		segurando = true
	end
end)
UserInputService.InputEnded:Connect(function(entrada)
	if entrada.UserInputType == Enum.UserInputType.MouseButton1 then
		segurando = false
	end
end)

-- Recarga ---------------------------------------------------------------------------
Remotos:WaitForChild("Recarga").OnClientEvent:Connect(function(indice, duracao)
	if type(indice) == "number" and botoes[indice] then
		recargaAte[indice] = os.clock() + duracao
		botoes[indice].duracao = duracao
		UI.pulo(botoes[indice].caixa, 0.9)
	end
end)

-- Desenho --------------------------------------------------------------------------
local ICONES = { fogo = "🔥", gelo = "❄️", raio = "⚡", pedra = "🪨", vento = "🌪️", sombra = "🌑" }

local function atualizarGolpes()
	local elemento = Config.ElementoPorId[jogador:GetAttribute("Equipado") or "fogo"] or Config.Elementos[1]
	for indice, botao in ipairs(botoes) do
		local golpe = elemento[Config.GOLPES[indice]]
		botao.nome.Text = Config.nomeDe(golpe, idioma)
		botao.icone.Text = ICONES[elemento.id] or "✨"
		botao.corpo.BackgroundColor3 = elemento.cor:Lerp(UI.COR.painel, indice == 1 and 0.25 or 0.45)
	end
end

jogador:GetAttributeChangedSignal("Equipado"):Connect(atualizarGolpes)
atualizarGolpes()

RunService.RenderStepped:Connect(function()
	local instante = os.clock()
	for indice, botao in ipairs(botoes) do
		local falta = recargaAte[indice] - instante
		if falta > 0 then
			local duracao = botao.duracao or 1
			botao.tampa.Size = UDim2.fromScale(1, math.clamp(falta / duracao, 0, 1))
			botao.segundos.Text = falta >= 1 and tostring(math.ceil(falta)) or string.format("%.1f", falta)
		elseif botao.tampa.Size.Y.Scale > 0 then
			botao.tampa.Size = UDim2.fromScale(1, 0)
			botao.segundos.Text = ""
		end
	end
	-- segurar o clique continua atacando com o golpe básico
	if segurando and instante >= recargaAte[1] and not UI.noCelular() then
		usar(1)
	end
end)

-- Tamanho da barra conforme a tela --------------------------------------------------
UI.acompanharTela(function(largura)
	local pequena = largura < 900
	barra.Position = UDim2.new(0.5, 0, 1, pequena and -8 or -14)
	for indice, botao in ipairs(botoes) do
		botao.tecla.Visible = not UI.noCelular()
		local tamanho = indice == 1 and 86 or 76
		botao.caixa.Size = UDim2.new(0, tamanho, 0, tamanho)
	end
end)
