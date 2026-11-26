--[[
	O mundo visto por este jogador:
	  - placas, robôs, bases e placar no idioma do jogador
	  - texto do "segure E": Comprar / Vender / Roubar
	  - efeitos: faíscas, alarme de roubo, prêmios, empurrão do tapa
	  - robôs Arco-íris mudando de cor
	  - botão de trancar piscando na própria base
	  - etiqueta [VIP] no chat
]]

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TextChatService = game:GetService("TextChatService")
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
local function D(n)
	return Format.dinheiro(n, idioma)
end

local FAISCAS = "rbxasset://textures/particles/sparkles_main.dds"

-- Sons -------------------------------------------------------------------------
local function tocar(nome, volume)
	local id = Config.SONS[nome]
	if not id or id == "" then
		return
	end
	local som = Instance.new("Sound")
	som.SoundId = id
	som.Volume = volume or 0.6
	som.PlaybackSpeed = 0.95 + math.random() * 0.1
	som.Parent = SoundService
	som:Play()
	Debris:AddItem(som, 4)
end

-- Textos fixos do mundo (placas da fábrica, quadros...) ----------------------
local function traduzir(rotulo)
	local chave = rotulo:GetAttribute("Chave")
	if chave then
		rotulo.Text = T(chave)
	end
end
for _, rotulo in ipairs(CollectionService:GetTagged("TextoLocal")) do
	traduzir(rotulo)
end
CollectionService:GetInstanceAddedSignal("TextoLocal"):Connect(traduzir)

-- Placa em cima de cada robô ---------------------------------------------------
local function preencherRobo(gui)
	local raiz = gui.Parent
	local modelo = raiz and raiz.Parent
	if not modelo then
		return
	end
	local def = Config.RoboPorId[modelo:GetAttribute("RoboId") or ""]
	if not def then
		return
	end
	local mut = modelo:GetAttribute("Mut")
	local mutacao = mut and Config.MutacaoPorId[mut]
	local nome = gui:FindFirstChild("Nome")
	local raridade = gui:FindFirstChild("Raridade")
	local preco = gui:FindFirstChild("Preco")
	local renda = gui:FindFirstChild("Renda")
	local rotuloMut = gui:FindFirstChild("Mutacao")
	if nome then
		nome.Text = Config.nomeDe(def, idioma)
	end
	if raridade then
		raridade.Text = Config.nomeDe(Config.Raridades[def.raridade], idioma)
	end
	if preco then
		preco.Text = D(Config.precoDe(def, mut))
	end
	if renda then
		renda.Text = D(Config.rendaDe(def, mut)) .. "/s"
	end
	if rotuloMut and mutacao then
		rotuloMut.Text = Config.nomeDe(mutacao, idioma)
	end
end
for _, gui in ipairs(CollectionService:GetTagged("RoboInfo")) do
	preencherRobo(gui)
end
CollectionService:GetInstanceAddedSignal("RoboInfo"):Connect(function(gui)
	task.defer(preencherRobo, gui)
end)

-- Texto do "segure E" ----------------------------------------------------------
ProximityPromptService.PromptShown:Connect(function(prompt)
	if not prompt:GetAttribute("Robo") then
		return
	end
	local def = Config.RoboPorId[prompt:GetAttribute("RoboId") or ""]
	if not def then
		return
	end
	local mut = prompt:GetAttribute("Mut")
	local nome = Config.nomeCompleto(def, mut, idioma)
	local donoId = prompt:GetAttribute("DonoId")
	if donoId == nil then
		prompt.ActionText = T("comprar")
		prompt.ObjectText = nome .. " — " .. D(Config.precoDe(def, mut))
	elseif donoId == jogador.UserId then
		prompt.ActionText = T("vender_por", D(prompt:GetAttribute("Venda") or 0))
		prompt.ObjectText = nome
	else
		prompt.ActionText = T("roubar")
		prompt.ObjectText = nome
	end
end)

-- Bases e placar (atualiza 4 vezes por segundo) ------------------------------
local function rotuloDe(parte, nome)
	local placa = parte and parte:FindFirstChild("Placa")
	return placa and placa:FindFirstChild(nome or "Texto")
end

local function atualizarBases()
	local mapa = workspace:FindFirstChild("Mapa")
	local bases = mapa and mapa:FindFirstChild("Bases")
	if not bases then
		return
	end
	local agora = workspace:GetServerTimeNow()
	for _, base in ipairs(bases:GetChildren()) do
		local dono = base:GetAttribute("DonoNome") or ""
		local nivel = base:GetAttribute("Nivel") or 0
		local trancadaAte = base:GetAttribute("TrancadaAte") or 0
		local minha = base:GetAttribute("DonoId") == jogador.UserId
		local trancada = trancadaAte > agora

		local suporte = base:FindFirstChild("SuportePlaca")
		local titulo = rotuloDe(suporte, "Titulo")
		local linhaNivel = rotuloDe(suporte, "Nivel")
		if titulo then
			titulo.Text = dono ~= "" and T("base_de", string.upper(dono)) or T("base_livre")
			titulo.TextColor3 = minha and Color3.fromRGB(255, 216, 77) or Color3.new(1, 1, 1)
		end
		if linhaNivel then
			linhaNivel.Text = dono ~= "" and T("nivel_renda", nivel, nivel * 10) or ""
		end

		local botao = base:FindFirstChild("BotaoTrancar")
		local textoBotao = rotuloDe(botao)
		if textoBotao then
			textoBotao.Text = trancada and T("trancada", Format.tempo(trancadaAte - agora)) or T("trancar_base")
		end
		if botao then
			if minha and not trancada then
				botao.Transparency = 0.2 + 0.3 * (0.5 + 0.5 * math.sin(os.clock() * 5))
			else
				botao.Transparency = trancada and 0.6 or 0
			end
		end
		local textoBarreira = rotuloDe(base:FindFirstChild("Barreira"))
		if textoBarreira then
			textoBarreira.Text = trancada and T("trancada", Format.tempo(trancadaAte - agora)) or ""
		end
	end

	local ranking = mapa:FindFirstChild("Ranking")
	local telaRanking = ranking and ranking:FindFirstChild("Tela")
	if telaRanking then
		local total = ranking:GetAttribute("RTotal") or 0
		for i = 1, 10 do
			local linha = telaRanking:FindFirstChild("Linha" .. i)
			if linha then
				if i <= total then
					local nome = ranking:GetAttribute("R" .. i .. "Nome") or "?"
					local valor = ranking:GetAttribute("R" .. i .. "Valor") or 0
					linha.Text = i .. ". " .. nome .. "  —  " .. D(valor)
					linha.TextColor3 = i == 1 and Color3.fromRGB(255, 216, 77) or Color3.new(1, 1, 1)
				elseif i == 1 then
					linha.Text = T("ranking_carregando")
				else
					linha.Text = ""
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		atualizarBases()
		task.wait(0.25)
	end
end)

-- Efeitos ----------------------------------------------------------------------
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
	flash.BackgroundTransparency = 1 - (intensidade or 0.35)
	flash.BorderSizePixel = 0
	flash.Parent = telaEfeitos
	local sumir = TweenService:Create(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
	sumir:Play()
	Debris:AddItem(flash, 0.6)
end

local function explosao(posicao, cor, quantidade, tamanho)
	if typeof(posicao) ~= "Vector3" then
		return
	end
	local suporte = Instance.new("Part")
	suporte.Name = "Explosao"
	suporte.Anchored = true
	suporte.CanCollide = false
	suporte.CanQuery = false
	suporte.CanTouch = false
	suporte.Transparency = 1
	suporte.Size = Vector3.new(1, 1, 1)
	suporte.CFrame = CFrame.new(posicao)
	local emissor = Instance.new("ParticleEmitter")
	emissor.Texture = FAISCAS
	emissor.Color = ColorSequence.new(typeof(cor) == "Color3" and cor or Color3.new(1, 1, 1))
	emissor.LightEmission = 1
	emissor.Lifetime = NumberRange.new(0.6, 1.2)
	emissor.Speed = NumberRange.new(8, 18)
	emissor.SpreadAngle = Vector2.new(180, 180)
	emissor.Size = NumberSequence.new(tamanho or 0.8, 0)
	emissor.Rate = 0
	emissor.Parent = suporte
	suporte.Parent = workspace
	emissor:Emit(quantidade or 30)
	Debris:AddItem(suporte, 2)
end

local function minhaPosicao()
	local personagem = jogador.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	return raiz and raiz.Position
end

Remotos:WaitForChild("Efeito").OnClientEvent:Connect(function(tipo, posicao, cor)
	if tipo == "compra" then
		explosao(posicao, cor, 25)
		tocar("compra")
	elseif tipo == "pouso" then
		explosao(posicao, cor, 15, 0.5)
	elseif tipo == "tapa" then
		explosao(posicao, cor, 12, 0.6)
		tocar("tapa")
	elseif tipo == "melhoria" then
		explosao(posicao, cor, 60, 1.2)
		tocar("premio")
	elseif tipo == "renascer" then
		explosao(posicao, cor, 90, 1.4)
		piscarTela(Color3.fromRGB(166, 77, 255), 0.4)
		tocar("renascer")
	elseif tipo == "alarme" then
		piscarTela(Color3.fromRGB(255, 40, 40), 0.35)
		explosao(posicao, cor, 20)
		tocar("alerta")
	elseif tipo == "premio" then
		explosao(minhaPosicao(), Color3.fromRGB(255, 216, 77), 40, 1)
		piscarTela(Color3.fromRGB(255, 216, 77), 0.2)
		tocar("premio")
	elseif tipo == "caixa" then
		explosao(minhaPosicao(), cor, 80, 1.3)
		piscarTela(typeof(cor) == "Color3" and cor or Color3.new(1, 1, 1), 0.3)
		tocar("premio")
	end
end)

-- Empurrão do tapa -------------------------------------------------------------
Remotos:WaitForChild("Empurrao").OnClientEvent:Connect(function(velocidade)
	local personagem = jogador.Character
	local humanoid = personagem and personagem:FindFirstChildOfClass("Humanoid")
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not humanoid or not raiz or typeof(velocidade) ~= "Vector3" then
		return
	end
	humanoid.PlatformStand = true
	raiz.AssemblyLinearVelocity = velocidade + Vector3.new(0, 35, 0)
	tocar("tapa")
	task.delay(0.7, function()
		if humanoid.Parent then
			humanoid.PlatformStand = false
		end
	end)
end)

-- Robôs Arco-íris ----------------------------------------------------------------
local partesArcoiris = {}
for _, parte in ipairs(CollectionService:GetTagged("Arcoiris")) do
	partesArcoiris[parte] = true
end
CollectionService:GetInstanceAddedSignal("Arcoiris"):Connect(function(parte)
	partesArcoiris[parte] = true
end)
CollectionService:GetInstanceRemovedSignal("Arcoiris"):Connect(function(parte)
	partesArcoiris[parte] = nil
end)
RunService.RenderStepped:Connect(function()
	local cor = Color3.fromHSV((os.clock() * 0.25) % 1, 0.75, 1)
	for parte in pairs(partesArcoiris) do
		parte.Color = cor
	end
end)

-- Etiqueta [VIP] no chat -------------------------------------------------------
TextChatService.OnIncomingMessage = function(mensagem)
	local propriedades = Instance.new("TextChatMessageProperties")
	local fonte = mensagem.TextSource
	local autor = fonte and Players:GetPlayerByUserId(fonte.UserId)
	if autor and autor:GetAttribute("PasseVip") then
		propriedades.PrefixText = "<font color=\"#FFD84D\">[VIP]</font> " .. mensagem.PrefixText
	end
	return propriedades
end
