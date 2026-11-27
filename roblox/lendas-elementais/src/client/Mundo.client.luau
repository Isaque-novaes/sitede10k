--[[
	O mundo visto por este jogador: placas e nomes no idioma dele,
	números de dano subindo, efeitos de tela, portais e o placar.
]]

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Textos = require(Shared:WaitForChild("Textos"))
local Remotos = ReplicatedStorage:WaitForChild("Remotos")

local jogador = Players.LocalPlayer
local idioma = Textos.idiomaDe(jogador.LocaleId)
local function T(chave, ...)
	return Textos.t(idioma, chave, ...)
end

local CONTORNO = Color3.fromRGB(20, 23, 43)

-- Sons -------------------------------------------------------------------------
local function tocar(nome, volume)
	local id = Config.SONS[nome]
	if not id or id == "" then
		return
	end
	local som = Instance.new("Sound")
	som.SoundId = id
	som.Volume = volume or 0.5
	som.PlaybackSpeed = 0.95 + math.random() * 0.1
	som.Parent = SoundService
	som:Play()
	Debris:AddItem(som, 4)
end

-- Textos fixos do mundo ------------------------------------------------------------
local function traduzir(rotulo)
	local chave = rotulo:GetAttribute("Chave")
	if not chave then
		return
	end
	local valor = rotulo:GetAttribute("Valor")
	if chave == "portal_para" and valor then
		local zona = Config.ZonaPorId[valor]
		rotulo.Text = T("portal_para", zona and string.upper(Config.nomeDe(zona, idioma)) or "")
	else
		rotulo.Text = T(chave)
	end
end
for _, rotulo in ipairs(CollectionService:GetTagged("TextoLocal")) do
	traduzir(rotulo)
end
CollectionService:GetInstanceAddedSignal("TextoLocal"):Connect(traduzir)

-- Nome dos monstros ------------------------------------------------------------------
local function nomearMonstro(modelo)
	local raiz = modelo:FindFirstChild("Raiz")
	local barra = raiz and raiz:FindFirstChild("Barra")
	local rotulo = barra and barra:FindFirstChild("Nome")
	if not rotulo then
		return
	end
	local id = rotulo:GetAttribute("Monstro")
	local def = id and Config.Monstros[id]
	if def then
		rotulo.Text = Config.nomeDe(def, idioma) .. "  " .. T("nivel_curto", rotulo:GetAttribute("Nivel") or 1)
	elseif id == "boneco" then
		rotulo.Text = T("placa_treino")
	end
end

local pastaMonstros = workspace:WaitForChild("Monstros", 30)
if pastaMonstros then
	for _, modelo in ipairs(pastaMonstros:GetChildren()) do
		nomearMonstro(modelo)
	end
	pastaMonstros.ChildAdded:Connect(function(modelo)
		task.defer(nomearMonstro, modelo)
	end)
end

-- Portais ------------------------------------------------------------------------------
ProximityPromptService.PromptShown:Connect(function(prompt)
	local destino = prompt:GetAttribute("Portal")
	if not destino then
		return
	end
	local zona = Config.ZonaPorId[destino]
	local nivelMinimo = prompt:GetAttribute("NivelMinimo") or 0
	local meuNivel = jogador:GetAttribute("Nivel") or 1
	prompt.ObjectText = zona and Config.nomeDe(zona, idioma) or ""
	if meuNivel < nivelMinimo then
		prompt.ActionText = T("precisa_nivel", nivelMinimo)
	else
		prompt.ActionText = T("portal_para", ""):gsub("%s+$", "")
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	local destino = prompt:GetAttribute("Portal")
	if destino and player == jogador then
		Remotos.Viajar:FireServer(destino)
	end
end)

-- Placar ----------------------------------------------------------------------------------
local function atualizarPlacar()
	local mapa = workspace:FindFirstChild("Mapa")
	local zonas = mapa and mapa:FindFirstChild("Zonas")
	local vila = zonas and zonas:FindFirstChild("Vila")
	local ranking = vila and vila:FindFirstChild("Ranking")
	local telaRanking = ranking and ranking:FindFirstChild("Tela")
	if not telaRanking then
		return
	end
	local total = ranking:GetAttribute("RTotal") or 0
	for i = 1, 10 do
		local linha = telaRanking:FindFirstChild("Linha" .. i)
		if linha then
			if i <= total then
				local nome = ranking:GetAttribute("R" .. i .. "Nome") or "?"
				local nivel = ranking:GetAttribute("R" .. i .. "Valor") or 1
				linha.Text = i .. ". " .. nome .. "  —  " .. T("nivel", nivel)
				linha.TextColor3 = i == 1 and Color3.fromRGB(255, 216, 77) or Color3.new(1, 1, 1)
			elseif i == 1 then
				linha.Text = T("ranking_carregando")
			else
				linha.Text = ""
			end
		end
	end
end

task.spawn(function()
	while true do
		atualizarPlacar()
		task.wait(2)
	end
end)

-- Efeitos de tela ---------------------------------------------------------------------------
local telaEfeitos = Instance.new("ScreenGui")
telaEfeitos.Name = "Efeitos"
telaEfeitos.ResetOnSpawn = false
telaEfeitos.IgnoreGuiInset = true
telaEfeitos.DisplayOrder = 5
telaEfeitos.Parent = jogador:WaitForChild("PlayerGui")

local function piscarTela(cor, intensidade)
	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = cor
	flash.BackgroundTransparency = 1 - (intensidade or 0.3)
	flash.BorderSizePixel = 0
	flash.Parent = telaEfeitos
	local sumir = TweenService:Create(flash, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 })
	sumir:Play()
	Debris:AddItem(flash, 0.6)
end

-- número de dano subindo
local function numeroDeDano(posicao, cor, valor)
	if typeof(posicao) ~= "Vector3" then
		return
	end
	local suporte = Instance.new("Part")
	suporte.Anchored = true
	suporte.CanCollide = false
	suporte.CanQuery = false
	suporte.CanTouch = false
	suporte.Transparency = 1
	suporte.Size = Vector3.new(0.2, 0.2, 0.2)
	suporte.Position = posicao + Vector3.new(math.random(-15, 15) / 10, 3, math.random(-15, 15) / 10)
	suporte.Parent = workspace

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(110, 40)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Adornee = suporte
	local rotulo = Instance.new("TextLabel")
	rotulo.Size = UDim2.fromScale(1, 1)
	rotulo.BackgroundTransparency = 1
	rotulo.Font = Enum.Font.LuckiestGuy
	rotulo.TextScaled = true
	rotulo.Text = "-" .. Format.numero(valor, idioma)
	rotulo.TextColor3 = typeof(cor) == "Color3" and cor or Color3.new(1, 1, 1)
	rotulo.TextStrokeTransparency = 0
	rotulo.TextStrokeColor3 = CONTORNO
	rotulo.Parent = gui
	gui.Parent = suporte

	TweenService:Create(suporte, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = suporte.Position + Vector3.new(0, 7, 0) }):Play()
	TweenService:Create(rotulo, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(suporte, 0.9)
end

local function brilhoNoPersonagem(cor, duracao)
	local personagem = jogador.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then
		return
	end
	local bolha = Instance.new("Part")
	bolha.Shape = Enum.PartType.Ball
	bolha.Size = Vector3.new(9, 9, 9)
	bolha.Color = cor
	bolha.Material = Enum.Material.ForceField
	bolha.Transparency = 0.5
	bolha.CanCollide = false
	bolha.CanQuery = false
	bolha.CanTouch = false
	bolha.Massless = true
	bolha.CFrame = raiz.CFrame
	bolha.Parent = workspace
	local solda = Instance.new("WeldConstraint")
	solda.Part0 = raiz
	solda.Part1 = bolha
	solda.Parent = bolha
	Debris:AddItem(bolha, duracao or 6)
end

Remotos:WaitForChild("Efeito").OnClientEvent:Connect(function(tipo, posicao, cor, valor)
	if tipo == "dano" then
		numeroDeDano(posicao, cor, valor or 0)
		tocar("acerto", 0.25)
	elseif tipo == "levouDano" then
		piscarTela(Color3.fromRGB(255, 40, 40), 0.22)
	elseif tipo == "matou" then
		tocar("morte")
	elseif tipo == "subirNivel" then
		piscarTela(Color3.fromRGB(255, 216, 77), 0.3)
		brilhoNoPersonagem(Color3.fromRGB(255, 216, 77), 2)
		tocar("subirNivel", 0.7)
	elseif tipo == "premio" then
		piscarTela(typeof(cor) == "Color3" and cor or Color3.fromRGB(255, 216, 77), 0.25)
		tocar("premio")
	elseif tipo == "melhoria" then
		brilhoNoPersonagem(Color3.fromRGB(80, 220, 110), 1.5)
		tocar("premio")
	elseif tipo == "escudo" then
		brilhoNoPersonagem(typeof(cor) == "Color3" and cor or Color3.fromRGB(190, 170, 140), valor or 6)
	end
end)

-- Empurrão (impulso do próprio golpe ou do inimigo) --------------------------------------------
Remotos:WaitForChild("Empurrao").OnClientEvent:Connect(function(velocidade)
	local personagem = jogador.Character
	local humanoid = personagem and personagem:FindFirstChildOfClass("Humanoid")
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not humanoid or not raiz or typeof(velocidade) ~= "Vector3" or humanoid.Health <= 0 then
		return
	end
	raiz.AssemblyLinearVelocity = velocidade
end)
