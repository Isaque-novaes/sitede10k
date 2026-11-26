--[[
	Interface do jogador: dinheiro, renda, avisos, estado da base,
	painéis de Renascer, Índice e Loja, e botões de teste no Studio.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotos = ReplicatedStorage:WaitForChild("Remotos")

local jogador = Players.LocalPlayer
local playerGui = jogador:WaitForChild("PlayerGui")

local FONTE = Enum.Font.FredokaOne
local BRANCO = Color3.new(1, 1, 1)
local FUNDO = Color3.fromRGB(22, 24, 34)
local CORES_AVISO = {
	bom = Color3.fromRGB(40, 160, 70),
	ruim = Color3.fromRGB(190, 50, 50),
	alerta = Color3.fromRGB(230, 140, 20),
	info = Color3.fromRGB(40, 90, 170),
}

-- Ajudante para criar objetos com propriedades e filhos ---------------------
local function novo(classe, props, filhos)
	local objeto = Instance.new(classe)
	for nome, valor in pairs(props or {}) do
		if nome ~= "Parent" then
			objeto[nome] = valor
		end
	end
	for _, filho in ipairs(filhos or {}) do
		filho.Parent = objeto
	end
	if props and props.Parent then
		objeto.Parent = props.Parent
	end
	return objeto
end

local function cantos(raio)
	return novo("UICorner", { CornerRadius = UDim.new(0, raio or 10) })
end

local function borda(cor, espessura)
	return novo("UIStroke", { Color = cor or Color3.fromRGB(0, 0, 0), Thickness = espessura or 2, Transparency = 0.3 })
end

local function texto(props)
	local base = {
		BackgroundTransparency = 1,
		Font = FONTE,
		TextColor3 = BRANCO,
		TextScaled = true,
		Text = "",
	}
	for k, v in pairs(props) do
		base[k] = v
	end
	return novo("TextLabel", base)
end

local tela = novo("ScreenGui", {
	Name = "RoubaRoboHUD",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

-- Coluna do topo: dinheiro, estado da base, carga, sorte e avisos -----------
local topo = novo("Frame", {
	Name = "Topo",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.new(0.92, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = tela,
}, {
	novo("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 6),
	}),
	novo("UISizeConstraint", { MaxSize = Vector2.new(440, math.huge) }),
})

local placar = novo("Frame", {
	Name = "Placar",
	LayoutOrder = 1,
	Size = UDim2.new(0, 300, 0, 72),
	BackgroundColor3 = FUNDO,
	BackgroundTransparency = 0.2,
	Parent = topo,
}, { cantos(14), borda(Color3.fromRGB(120, 255, 140), 2) })

local rotuloDinheiro = texto({
	Name = "Dinheiro",
	Size = UDim2.new(1, -16, 0.6, 0),
	Position = UDim2.new(0, 8, 0, 4),
	Text = "$0",
	TextColor3 = Color3.fromRGB(140, 255, 150),
	Parent = placar,
})
local rotuloRenda = texto({
	Name = "Renda",
	Size = UDim2.new(1, -16, 0.32, 0),
	Position = UDim2.new(0, 8, 0.62, 0),
	Text = "+$0/s",
	TextColor3 = Color3.fromRGB(255, 230, 110),
	Parent = placar,
})

local function faixa(nome, ordem, cor)
	local f = novo("Frame", {
		Name = nome,
		LayoutOrder = ordem,
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = cor,
		BackgroundTransparency = 0.15,
		Visible = false,
		Parent = topo,
	}, { cantos(10) })
	local r = texto({
		Size = UDim2.new(1, -16, 1, -6),
		Position = UDim2.new(0, 8, 0, 3),
		Parent = f,
	})
	return f, r
end

local faixaBase, rotuloBase = faixa("Base", 2, FUNDO)
faixaBase.Visible = true
local faixaCarga, rotuloCarga = faixa("Carga", 3, Color3.fromRGB(230, 120, 20))
local faixaSorte, rotuloSorte = faixa("Sorte", 4, Color3.fromRGB(150, 60, 230))

local avisos = novo("Frame", {
	Name = "Avisos",
	LayoutOrder = 5,
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = topo,
}, {
	novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
})

-- Avisos ---------------------------------------------------------------------
local MAX_AVISOS = 4
local contadorAvisos = 0

local function mostrarAviso(mensagem, tipo)
	contadorAvisos = contadorAvisos + 1
	local caixa = novo("TextLabel", {
		Name = "Aviso",
		LayoutOrder = contadorAvisos,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = CORES_AVISO[tipo] or CORES_AVISO.info,
		BackgroundTransparency = 0.1,
		Font = FONTE,
		TextColor3 = BRANCO,
		TextSize = 18,
		TextWrapped = true,
		Text = mensagem,
		Parent = avisos,
	}, {
		cantos(8),
		novo("UIPadding", {
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
	})

	local lista = {}
	for _, filho in ipairs(avisos:GetChildren()) do
		if filho:IsA("TextLabel") then
			table.insert(lista, filho)
		end
	end
	table.sort(lista, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = 1, #lista - MAX_AVISOS do
		lista[i]:Destroy()
	end

	task.delay(4.5, function()
		if caixa.Parent then
			local sumir = TweenService:Create(caixa, TweenInfo.new(0.4),
				{ BackgroundTransparency = 1, TextTransparency = 1 })
			sumir:Play()
			sumir.Completed:Wait()
			caixa:Destroy()
		end
	end)
end

Remotos:WaitForChild("Notificar").OnClientEvent:Connect(mostrarAviso)

-- Botões da esquerda ---------------------------------------------------------
local coluna = novo("Frame", {
	Name = "Botoes",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 12, 0.5, 0),
	Size = UDim2.new(0, 150, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = tela,
}, {
	novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
})

local function botao(pai, rotulo, cor, ordem, largura)
	return novo("TextButton", {
		Name = rotulo,
		LayoutOrder = ordem or 1,
		Size = largura or UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = cor,
		AutoButtonColor = true,
		Font = FONTE,
		TextColor3 = BRANCO,
		TextScaled = true,
		Text = rotulo,
		Parent = pai,
	}, {
		cantos(10),
		borda(Color3.new(0, 0, 0), 2),
		novo("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
	})
end

-- Painéis --------------------------------------------------------------------
local paineis = {}

local function painel(nome, titulo)
	local p = novo("Frame", {
		Name = nome,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0, 360),
		BackgroundColor3 = FUNDO,
		BackgroundTransparency = 0.05,
		Visible = false,
		ZIndex = 5,
		Parent = tela,
	}, {
		cantos(16),
		borda(Color3.fromRGB(255, 255, 255), 2),
		novo("UISizeConstraint", { MaxSize = Vector2.new(520, 420) }),
	})
	texto({
		Name = "Titulo",
		Size = UDim2.new(1, -70, 0, 40),
		Position = UDim2.new(0, 16, 0, 10),
		Text = titulo,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
		Parent = p,
	})
	local fechar = botao(p, "X", Color3.fromRGB(190, 50, 50), 1, UDim2.new(0, 40, 0, 40))
	fechar.Position = UDim2.new(1, -50, 0, 10)
	fechar.ZIndex = 6
	fechar.Activated:Connect(function()
		p.Visible = false
	end)
	paineis[nome] = p
	return p
end

local function abrir(nome)
	for outro, p in pairs(paineis) do
		p.Visible = (outro == nome) and not p.Visible
	end
end

-- Painel Renascer
local painelRenascer = painel("Renascer", "Renascer")
local explicacao = texto({
	Size = UDim2.new(1, -32, 0, 110),
	Position = UDim2.new(0, 16, 0, 58),
	TextScaled = false,
	TextSize = 20,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 6,
	Text = "Renascer zera seu dinheiro e seus robôs. Em troca você ganha +"
		.. math.floor(Config.RENASCER.BONUS * 100) .. "% de dinheiro para sempre e a tranca da base dura "
		.. Config.TRANCA.EXTRA_POR_RENASCIMENTO .. "s a mais.",
	Parent = painelRenascer,
})
local rotuloCusto = texto({
	Size = UDim2.new(1, -32, 0, 34),
	Position = UDim2.new(0, 16, 0, 176),
	TextColor3 = Color3.fromRGB(140, 255, 150),
	ZIndex = 6,
	Parent = painelRenascer,
})
local rotuloBonus = texto({
	Size = UDim2.new(1, -32, 0, 30),
	Position = UDim2.new(0, 16, 0, 214),
	TextColor3 = Color3.fromRGB(255, 230, 110),
	ZIndex = 6,
	Parent = painelRenascer,
})
local botaoRenascer = botao(painelRenascer, "Renascer agora", Color3.fromRGB(150, 60, 230), 1,
	UDim2.new(1, -32, 0, 56))
botaoRenascer.Position = UDim2.new(0, 16, 1, -72)
botaoRenascer.ZIndex = 6
botaoRenascer.Activated:Connect(function()
	Remotos:WaitForChild("Renascer"):FireServer()
	painelRenascer.Visible = false
end)

-- Painel Índice
local painelIndice = painel("Indice", "Índice de Robôs")
local rotuloContagem = texto({
	Size = UDim2.new(1, -32, 0, 24),
	Position = UDim2.new(0, 16, 0, 52),
	TextColor3 = Color3.fromRGB(200, 200, 220),
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 6,
	Parent = painelIndice,
})
local grade = novo("ScrollingFrame", {
	Size = UDim2.new(1, -32, 1, -96),
	Position = UDim2.new(0, 16, 0, 84),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ZIndex = 6,
	Parent = painelIndice,
}, {
	novo("UIGridLayout", {
		CellSize = UDim2.new(0, 140, 0, 74),
		CellPadding = UDim2.new(0, 8, 0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local cartas = {}
for i, def in ipairs(Config.Robos) do
	local raridade = Config.Raridades[def.raridade]
	local carta = novo("Frame", {
		Name = def.id,
		LayoutOrder = i,
		BackgroundColor3 = raridade.cor:Lerp(Color3.new(0, 0, 0), 0.55),
		ZIndex = 7,
		Parent = grade,
	}, { cantos(8), borda(raridade.cor, 2) })
	local nome = texto({
		Size = UDim2.new(1, -8, 0.45, 0),
		Position = UDim2.new(0, 4, 0, 4),
		Text = "???",
		ZIndex = 8,
		Parent = carta,
	})
	texto({
		Size = UDim2.new(1, -8, 0.25, 0),
		Position = UDim2.new(0, 4, 0.48, 0),
		Text = raridade.nome,
		TextColor3 = raridade.cor:Lerp(BRANCO, 0.4),
		ZIndex = 8,
		Parent = carta,
	})
	texto({
		Size = UDim2.new(1, -8, 0.22, 0),
		Position = UDim2.new(0, 4, 0.75, 0),
		Text = Format.dinheiro(def.renda) .. "/s",
		TextColor3 = Color3.fromRGB(255, 230, 110),
		ZIndex = 8,
		Parent = carta,
	})
	cartas[def.id] = { carta = carta, nome = nome, def = def }
end

local function atualizarIndice()
	local lista = jogador:GetAttribute("Descobertos") or ""
	local descobertos = {}
	for id in string.gmatch(lista, "[^,]+") do
		descobertos[id] = true
	end
	local total = 0
	for id, c in pairs(cartas) do
		if descobertos[id] then
			total = total + 1
			c.nome.Text = c.def.nome
		else
			c.nome.Text = "???"
		end
	end
	rotuloContagem.Text = "Descobertos: " .. total .. "/" .. #Config.Robos
end

-- Painel Loja (só aparece se houver itens configurados)
local itensLoja = {}
if Config.Loja.PASSE_DINHEIRO_EM_DOBRO ~= 0 then
	table.insert(itensLoja, { nome = "Dinheiro em dobro (para sempre)", passe = Config.Loja.PASSE_DINHEIRO_EM_DOBRO })
end
for _, pacote in ipairs(Config.Loja.PACOTES) do
	if pacote.id ~= 0 then
		table.insert(itensLoja, {
			nome = pacote.nome .. " (" .. pacote.minutos .. " min de renda)",
			produto = pacote.id,
		})
	end
end

local painelLoja = nil
if #itensLoja > 0 then
	painelLoja = painel("Loja", "Loja")
	local listaLoja = novo("Frame", {
		Size = UDim2.new(1, -32, 1, -70),
		Position = UDim2.new(0, 16, 0, 60),
		BackgroundTransparency = 1,
		ZIndex = 6,
		Parent = painelLoja,
	}, {
		novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
	})
	for i, item in ipairs(itensLoja) do
		local b = botao(listaLoja, item.nome, Color3.fromRGB(220, 160, 20), i, UDim2.new(1, 0, 0, 52))
		b.ZIndex = 7
		b.Activated:Connect(function()
			if item.passe then
				MarketplaceService:PromptGamePassPurchase(jogador, item.passe)
			else
				MarketplaceService:PromptProductPurchase(jogador, item.produto)
			end
		end)
	end
end

-- Botões
botao(coluna, "Renascer", Color3.fromRGB(150, 60, 230), 1).Activated:Connect(function()
	abrir("Renascer")
end)
botao(coluna, "Índice", Color3.fromRGB(40, 110, 210), 2).Activated:Connect(function()
	atualizarIndice()
	abrir("Indice")
end)
if painelLoja then
	botao(coluna, "Loja", Color3.fromRGB(220, 160, 20), 3).Activated:Connect(function()
		abrir("Loja")
	end)
end
if RunService:IsStudio() then
	local teste = Remotos:WaitForChild("Teste")
	botao(coluna, "Teste: +$", Color3.fromRGB(90, 90, 100), 10).Activated:Connect(function()
		teste:FireServer("dinheiro")
	end)
	botao(coluna, "Teste: Sorte", Color3.fromRGB(90, 90, 100), 11).Activated:Connect(function()
		teste:FireServer("sorte")
	end)
end

-- Atualização da tela --------------------------------------------------------
local valorDinheiro = nil
local valorRenascimentos = nil

local function dinheiroAtual()
	return valorDinheiro and valorDinheiro.Value or 0
end

local function atualizar()
	rotuloDinheiro.Text = Format.dinheiro(dinheiroAtual())
	local renda = jogador:GetAttribute("RendaPorSegundo") or 0
	local mult = jogador:GetAttribute("Multiplicador") or 1
	local vagas = jogador:GetAttribute("Vagas") or ("0/" .. Config.VAGAS_POR_BASE)
	rotuloRenda.Text = "+" .. Format.dinheiro(renda) .. "/s   ·   Robôs " .. vagas .. "   ·   " .. Format.multiplicador(mult)

	local custo = jogador:GetAttribute("CustoRenascer") or Config.custoRenascer(0)
	rotuloCusto.Text = "Custo: " .. Format.dinheiro(custo) .. "  (você tem " .. Format.dinheiro(dinheiroAtual()) .. ")"
	local renascimentos = valorRenascimentos and valorRenascimentos.Value or 0
	rotuloBonus.Text = "Bônus de renascimento: " .. Format.multiplicador(Config.multiplicador(renascimentos))
		.. "  →  " .. Format.multiplicador(Config.multiplicador(renascimentos + 1))
	local podeRenascer = dinheiroAtual() >= custo
	botaoRenascer.BackgroundColor3 = podeRenascer and Color3.fromRGB(150, 60, 230) or Color3.fromRGB(80, 80, 90)
	botaoRenascer.Text = podeRenascer and "Renascer agora" or "Falta dinheiro"

	local carga = jogador:GetAttribute("Carregando")
	faixaCarga.Visible = carga ~= nil
	if carga then
		rotuloCarga.Text = "Levando " .. carga .. " — corra até a SUA base!"
	end

	if painelIndice.Visible then
		atualizarIndice()
	end
end

local function atualizarContagens()
	local agora = workspace:GetServerTimeNow()
	local trancadaAte = jogador:GetAttribute("TrancadaAte") or 0
	if trancadaAte > agora then
		rotuloBase.Text = "Sua base está TRANCADA: " .. Format.tempo(trancadaAte - agora)
		faixaBase.BackgroundColor3 = Color3.fromRGB(40, 140, 70)
	else
		rotuloBase.Text = "Base aberta! Pise no botão vermelho dela para trancar."
		faixaBase.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	end

	local sorteAte = ReplicatedStorage:GetAttribute("HoraDaSorteAte") or 0
	faixaSorte.Visible = sorteAte > agora
	if faixaSorte.Visible then
		rotuloSorte.Text = "HORA DA SORTE! " .. Format.tempo(sorteAte - agora)
	end
end

jogador.AttributeChanged:Connect(atualizar)
task.spawn(function()
	local leaderstats = jogador:WaitForChild("leaderstats")
	valorDinheiro = leaderstats:WaitForChild("Dinheiro")
	valorRenascimentos = leaderstats:WaitForChild("Renascimentos")
	valorDinheiro.Changed:Connect(atualizar)
	valorRenascimentos.Changed:Connect(atualizar)
	atualizar()
end)

atualizar()
while true do
	atualizarContagens()
	task.wait(0.25)
end
