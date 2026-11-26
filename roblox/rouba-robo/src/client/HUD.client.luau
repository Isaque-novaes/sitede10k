--[[
	Interface do jogador (segue a prévia aprovada):
	  topo: dinheiro, estado da base, faixas (sorte, carga, x2) e avisos
	  esquerda: Loja, Índice, Melhorar, Renascer
	  direita: Prêmio diário, Missões, 2x grátis (anúncio)
	  painéis: Loja, Índice, Melhorar, Renascer, Prêmio, Missões, Bem-vindo de volta

	Dois jeitos de arrumar: "compacto" (celular/tela pequena) e "PC".
	Tudo é só desenho: quem decide compras, prêmios e dinheiro é o servidor.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Textos = require(Shared:WaitForChild("Textos"))
local Remotos = ReplicatedStorage:WaitForChild("Remotos")

local jogador = Players.LocalPlayer
local playerGui = jogador:WaitForChild("PlayerGui")
local noStudio = RunService:IsStudio()

local idioma = Textos.idiomaDe(jogador.LocaleId)
local function T(chave, ...)
	return Textos.t(idioma, chave, ...)
end
local function D(n)
	return Format.dinheiro(n, idioma)
end

-- Tema (cores e letras da prévia) --------------------------------------------
local COR = {
	painel = Color3.fromRGB(20, 23, 43),
	contorno = Color3.fromRGB(10, 12, 24),
	cartao = Color3.fromRGB(42, 46, 69),
	branco = Color3.new(1, 1, 1),
	suave = Color3.fromRGB(201, 206, 230),
	dinheiro = Color3.fromRGB(75, 240, 138),
	renda = Color3.fromRGB(255, 216, 77),
	verde = Color3.fromRGB(34, 197, 94),
	cinza = Color3.fromRGB(107, 112, 144),
	loja = Color3.fromRGB(255, 176, 32),
	indice = Color3.fromRGB(61, 165, 255),
	melhorar = Color3.fromRGB(34, 197, 94),
	renascer = Color3.fromRGB(166, 77, 255),
	premio = Color3.fromRGB(255, 77, 109),
	missoes = Color3.fromRGB(255, 138, 31),
	anuncio = Color3.fromRGB(20, 184, 166),
	trancada = Color3.fromRGB(34, 181, 115),
	aberta = Color3.fromRGB(232, 69, 91),
	sorte = Color3.fromRGB(139, 61, 255),
	carga = Color3.fromRGB(255, 122, 26),
}
local CORES_AVISO = {
	bom = Color3.fromRGB(34, 181, 115),
	ruim = Color3.fromRGB(232, 69, 91),
	alerta = Color3.fromRGB(255, 122, 26),
	info = Color3.fromRGB(61, 120, 220),
}
local TITULO = Enum.Font.LuckiestGuy
local FONTE = Enum.Font.FredokaOne
local ROBUX = utf8.char(0xE002)

local ANIM = {
	rapido = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	mola = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	suave = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

-- Ajudantes ------------------------------------------------------------------
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
	return novo("UICorner", { CornerRadius = UDim.new(0, raio or 14) })
end

local function borda(espessura, cor)
	return novo("UIStroke", {
		Color = cor or COR.contorno,
		Thickness = espessura or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function contornoTexto(espessura)
	return novo("UIStroke", { Color = COR.contorno, Thickness = espessura or 2 })
end

local function texto(props)
	local base = {
		BackgroundTransparency = 1,
		Font = FONTE,
		TextColor3 = COR.branco,
		TextScaled = true,
		Text = "",
	}
	for k, v in pairs(props) do
		base[k] = v
	end
	local contorno = base.Contorno
	base.Contorno = nil
	local maximo = base.TamanhoMax
	base.TamanhoMax = nil
	local filhos = {}
	if contorno ~= false then
		table.insert(filhos, contornoTexto(contorno or 2))
	end
	if maximo then
		table.insert(filhos, novo("UITextSizeConstraint", { MaxTextSize = maximo }))
	end
	return novo("TextLabel", base, filhos)
end

-- botão grosso com "degrau" embaixo e animação de apertar
local function botao(pai, opcoes)
	local caixa = novo("Frame", {
		Name = opcoes.nome or "Botao",
		LayoutOrder = opcoes.ordem or 1,
		Size = opcoes.tamanho or UDim2.new(1, 0, 0, 48),
		Position = opcoes.posicao or UDim2.new(),
		AnchorPoint = opcoes.ancora or Vector2.new(),
		BackgroundTransparency = 1,
		Parent = pai,
	})
	local escala = novo("UIScale", { Parent = caixa })
	local sombra = novo("Frame", {
		Name = "Degrau",
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 4),
		BackgroundColor3 = COR.contorno,
		Parent = caixa,
	}, { cantos(opcoes.raio or 14) })
	local corpo = novo("TextButton", {
		Name = "Corpo",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = opcoes.cor or COR.verde,
		AutoButtonColor = false,
		Text = "",
		Parent = caixa,
	}, { cantos(opcoes.raio or 14), borda(3) })
	local rotulo = texto({
		Name = "Rotulo",
		Size = UDim2.new(1, -16, 1, -10),
		Position = UDim2.new(0, 8, 0, 5),
		Text = opcoes.texto or "",
		Font = opcoes.fonte or FONTE,
		TamanhoMax = opcoes.tamanhoTexto or 22,
		Parent = corpo,
	})
	corpo.MouseButton1Down:Connect(function()
		TweenService:Create(escala, ANIM.rapido, { Scale = 0.92 }):Play()
	end)
	local function soltar()
		TweenService:Create(escala, ANIM.mola, { Scale = 1 }):Play()
	end
	corpo.MouseButton1Up:Connect(soltar)
	corpo.MouseLeave:Connect(soltar)
	if opcoes.aoClicar then
		corpo.Activated:Connect(opcoes.aoClicar)
	end
	sombra.Visible = true
	return caixa, corpo, rotulo
end

local function pulo(objeto)
	local escala = objeto:FindFirstChildOfClass("UIScale") or novo("UIScale", { Parent = objeto })
	escala.Scale = 1.15
	TweenService:Create(escala, ANIM.mola, { Scale = 1 }):Play()
end

-- Tela -------------------------------------------------------------------------
local tela = novo("ScreenGui", {
	Name = "RoubaRoboHUD",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

-- Tamanho da interface ---------------------------------------------------------
-- A interface encolhe sozinha em telas e janelas pequenas. Se ainda achar
-- grande (ou pequena) demais, mude só este número: 0.8 deixa menor, 1.2 maior.
local ESCALA_DA_TELA = 1

-- Tamanho dos painéis (Loja, Índice...) antes de caber na tela
local LARGURA_PAINEL, ALTURA_PAINEL = 560, 420

local escalas = {} -- cantos da tela: placar, faixas e botões
local escalasPainel = {} -- janelas do meio: encolhem só o quanto precisam para caber
local escalaAtual = 1
local escalaPainel = 1
local function escalavel(objeto, ehPainel)
	local lista = ehPainel and escalasPainel or escalas
	local escala = novo("UIScale", { Scale = ehPainel and escalaPainel or escalaAtual, Parent = objeto })
	table.insert(lista, escala)
	return escala
end

-- Coluna do topo ---------------------------------------------------------------
local topo = novo("Frame", {
	Name = "Topo",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.new(0.5, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = tela,
}, {
	novo("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 6),
	}),
	novo("UISizeConstraint", { MinSize = Vector2.new(240, 0), MaxSize = Vector2.new(400, math.huge) }),
})
escalavel(topo)

local placar = novo("Frame", {
	Name = "Placar",
	LayoutOrder = 1,
	Size = UDim2.new(0, 232, 0, 50),
	BackgroundColor3 = COR.painel,
	Parent = topo,
}, { cantos(15), borda(3) })
local moeda = novo("Frame", {
	Name = "Moeda",
	Size = UDim2.new(0, 34, 0, 34),
	Position = UDim2.new(0, 8, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	BackgroundColor3 = COR.dinheiro,
	Parent = placar,
}, { cantos(17), borda(3) })
texto({ Size = UDim2.fromScale(1, 1), Text = "$", Font = TITULO, TextColor3 = Color3.fromRGB(20, 87, 47), Contorno = false, Parent = moeda })
local rotuloDinheiro = texto({
	Name = "Dinheiro",
	Size = UDim2.new(1, -56, 0, 27),
	Position = UDim2.new(0, 48, 0, 4),
	Text = "$0",
	Font = TITULO,
	TextColor3 = COR.dinheiro,
	TextXAlignment = Enum.TextXAlignment.Left,
	TamanhoMax = 26,
	Parent = placar,
})
local rotuloRenda = texto({
	Name = "Renda",
	Size = UDim2.new(1, -56, 0, 15),
	Position = UDim2.new(0, 48, 0, 31),
	Text = "",
	TextColor3 = COR.renda,
	TextXAlignment = Enum.TextXAlignment.Left,
	Contorno = 1,
	TamanhoMax = 14,
	Parent = placar,
})

-- faixa fina que fica do tamanho do próprio texto
local function faixa(nome, ordem, cor)
	local f = novo("Frame", {
		Name = nome,
		LayoutOrder = ordem,
		Size = UDim2.new(0, 0, 0, 25),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = cor,
		Visible = false,
		Parent = topo,
	}, {
		cantos(10),
		borda(2),
		novo("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }),
		novo("UISizeConstraint", { MaxSize = Vector2.new(420, math.huge) }),
	})
	local r = texto({
		Name = "Texto",
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		TextScaled = false,
		TextSize = 14,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Contorno = 1,
		Parent = f,
	})
	return f, r
end
local faixaBase, rotuloBase = faixa("Base", 2, COR.aberta)
faixaBase.Visible = true
local faixaSorte, rotuloSorte = faixa("Sorte", 3, COR.sorte)
local faixaCarga, rotuloCarga = faixa("Carga", 4, COR.carga)
local faixaDobro, rotuloDobro = faixa("Dobro", 5, COR.anuncio)

local avisos = novo("Frame", {
	Name = "Avisos",
	LayoutOrder = 6,
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = topo,
}, {
	novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) }),
})

-- Avisos ---------------------------------------------------------------------
local MAX_AVISOS = 3
local contadorAvisos = 0

local function mostrarAviso(mensagem, tipo)
	contadorAvisos = contadorAvisos + 1
	local caixa = novo("TextLabel", {
		Name = "Aviso",
		LayoutOrder = contadorAvisos,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = CORES_AVISO[tipo] or CORES_AVISO.info,
		Font = FONTE,
		TextColor3 = COR.branco,
		TextSize = 15,
		TextWrapped = true,
		Text = mensagem,
		Parent = avisos,
	}, {
		cantos(10),
		borda(2),
		novo("UIPadding", {
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
	})
	pulo(caixa)

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
			local sumir = TweenService:Create(caixa, ANIM.suave, { BackgroundTransparency = 1, TextTransparency = 1 })
			sumir:Play()
			sumir.Completed:Wait()
			caixa:Destroy()
		end
	end)
end
Remotos:WaitForChild("Notificar").OnClientEvent:Connect(mostrarAviso)

-- Colunas de botões ------------------------------------------------------------
local colunaEsquerda = novo("Frame", {
	Name = "Botoes",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 12, 0.5, 0),
	Size = UDim2.new(0, 132, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = tela,
})
local layoutEsquerda = novo("UIGridLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	CellSize = UDim2.new(0, 132, 0, 44),
	CellPadding = UDim2.new(0, 8, 0, 8),
	Parent = colunaEsquerda,
})
escalavel(colunaEsquerda)

local colunaDireita = novo("Frame", {
	Name = "Lado",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -12, 0.5, 0),
	Size = UDim2.new(0, 132, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = tela,
})
local layoutDireita = novo("UIGridLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	CellSize = UDim2.new(0, 132, 0, 44),
	CellPadding = UDim2.new(0, 8, 0, 8),
	Parent = colunaDireita,
})
escalavel(colunaDireita)

local botoesMenu = {}
local function botaoMenu(coluna, chave, icone, cor, ordem, aoClicar)
	local caixa, corpo, rotulo = botao(coluna, {
		nome = chave,
		ordem = ordem,
		cor = cor,
		texto = "",
		aoClicar = aoClicar,
	})
	rotulo.Visible = false
	local iconeRotulo = texto({ Name = "Icone", Text = icone, Contorno = false, Parent = corpo })
	local nomeRotulo = texto({ Name = "Nome", Text = T(chave), TamanhoMax = 20, Parent = corpo })
	local selo = novo("TextLabel", {
		Name = "Selo",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -4, 0, 4),
		Size = UDim2.new(0, 26, 0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(255, 45, 85),
		Font = FONTE,
		TextSize = 15,
		TextColor3 = COR.branco,
		Text = "",
		Visible = false,
		ZIndex = 3,
		Parent = caixa,
	}, { cantos(13), borda(2), novo("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }) })
	botoesMenu[chave] = { caixa = caixa, icone = iconeRotulo, nome = nomeRotulo, selo = selo }
	return caixa
end

-- Painéis --------------------------------------------------------------------
local paineis = {}
local painelAberto = nil

local function painel(nome, titulo, corTitulo)
	local p = novo("Frame", {
		Name = nome,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(LARGURA_PAINEL, ALTURA_PAINEL),
		BackgroundColor3 = COR.painel,
		Visible = false,
		ZIndex = 10,
		Parent = tela,
	}, {
		cantos(22),
		borda(4),
	})
	local escala = escalavel(p, true)
	texto({
		Name = "Titulo",
		Size = UDim2.new(1, -80, 0, 40),
		Position = UDim2.new(0, 18, 0, 12),
		Text = titulo,
		Font = TITULO,
		TextColor3 = corTitulo or COR.renda,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11,
		Parent = p,
	})
	local fechar = botao(p, {
		nome = "Fechar",
		tamanho = UDim2.new(0, 44, 0, 44),
		posicao = UDim2.new(1, -56, 0, 10),
		cor = Color3.fromRGB(232, 69, 91),
		texto = "X",
		fonte = TITULO,
		aoClicar = function()
			p.Visible = false
			painelAberto = nil
		end,
	})
	fechar.ZIndex = 11
	local conteudo = novo("ScrollingFrame", {
		Name = "Conteudo",
		Size = UDim2.new(1, -32, 1, -76),
		Position = UDim2.new(0, 16, 0, 64),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 11,
		Parent = p,
	}, {
		novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }),
		novo("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
	})
	paineis[nome] = { frame = p, escala = escala, conteudo = conteudo }
	return paineis[nome]
end

local atualizarTudo -- definida mais abaixo

local function abrir(nome)
	for outro, info in pairs(paineis) do
		if outro ~= nome then
			info.frame.Visible = false
		end
	end
	local info = paineis[nome]
	if painelAberto == nome then
		info.frame.Visible = false
		painelAberto = nil
		return
	end
	painelAberto = nome
	info.frame.Visible = true
	info.escala.Scale = escalaPainel * 0.85
	TweenService:Create(info.escala, ANIM.mola, { Scale = escalaPainel }):Play()
	atualizarTudo()
end

local function cartao(pai, ordem, altura, cor)
	return novo("Frame", {
		LayoutOrder = ordem,
		Size = UDim2.new(1, 0, 0, altura),
		BackgroundColor3 = cor or COR.cartao,
		ZIndex = 12,
		Parent = pai,
	}, { cantos(16), borda(3) })
end

local function linhaInfo(pai, ordem, chaveTexto)
	return texto({
		LayoutOrder = ordem,
		Size = UDim2.new(1, 0, 0, 22),
		Text = T(chaveTexto),
		TextColor3 = COR.suave,
		Contorno = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TamanhoMax = 17,
		ZIndex = 12,
		Parent = pai,
	})
end

-- Loja -------------------------------------------------------------------------
local precos = {} -- [id] = preço real em Robux (carregado do Roblox)
local function textoPreco(item)
	return ROBUX .. " " .. tostring(precos[item.id] or item.preco)
end
local function carregarPreco(item, tipo)
	if item.id == 0 then
		return
	end
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfoAsync(item.id, tipo)
		end)
		if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
			precos[item.id] = info.PriceInRobux
		end
	end)
end

local function itemVisivel(item)
	return item.id ~= 0 or noStudio
end

local function comprarProduto(id)
	if id ~= 0 then
		MarketplaceService:PromptProductPurchase(jogador, id)
	end
end

local loja = painel("Loja", T("titulo_loja"), COR.renda)
local abasLoja = novo("Frame", {
	LayoutOrder = 0,
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundTransparency = 1,
	ZIndex = 12,
	Parent = loja.conteudo,
}, {
	novo("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local secoesLoja = {}
local botoesAbas = {}
local abaAtual = "passes"
local function escolherAba(id)
	abaAtual = id
	for chave, secao in pairs(secoesLoja) do
		secao.Visible = chave == id
	end
	for chave, b in pairs(botoesAbas) do
		b.BackgroundColor3 = chave == id and COR.loja or Color3.fromRGB(59, 63, 92)
	end
end
for i, aba in ipairs({ { "passes", "aba_passes" }, { "dinheiro", "aba_dinheiro" }, { "sorte", "aba_sorte" } }) do
	local _, corpo = botao(abasLoja, {
		nome = aba[1],
		ordem = i,
		tamanho = UDim2.new(0.31, 0, 1, 0),
		cor = Color3.fromRGB(59, 63, 92),
		texto = T(aba[2]),
		tamanhoTexto = 18,
		aoClicar = function()
			escolherAba(aba[1])
		end,
	})
	botoesAbas[aba[1]] = corpo
	secoesLoja[aba[1]] = novo("Frame", {
		Name = "Secao_" .. aba[1],
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 12,
		Parent = loja.conteudo,
	}, { novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }) })
end

local cartoesPasses = {}
linhaInfo(secoesLoja.passes, 0, "passes_info")
local CORES_PASSES = { dobro = COR.trancada, vip = COR.loja, vagas = COR.indice, tranca = COR.renascer }
local ICONES_PASSES = { dobro = "💰", vip = "👑", vagas = "➕", tranca = "🔒" }
for i, passe in ipairs(Config.LOJA.PASSES) do
	carregarPreco(passe, Enum.InfoType.GamePass)
	if itemVisivel(passe) then
		local c = cartao(secoesLoja.passes, i, 84, CORES_PASSES[passe.chave])
		texto({ Size = UDim2.new(0, 56, 0, 56), Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Text = ICONES_PASSES[passe.chave], Contorno = false, ZIndex = 13, Parent = c })
		texto({ Size = UDim2.new(1, -210, 0, 30), Position = UDim2.new(0, 78, 0, 10), Text = T("passe_" .. passe.chave), TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 24, ZIndex = 13, Parent = c })
		texto({ Size = UDim2.new(1, -210, 0, 34), Position = UDim2.new(0, 78, 0, 40), Text = T("desc_" .. passe.chave), TextColor3 = COR.painel, Contorno = false, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 15, ZIndex = 13, Parent = c })
		local b, corpo, rotulo = botao(c, {
			tamanho = UDim2.new(0, 110, 0, 46),
			posicao = UDim2.new(1, -122, 0.5, -2),
			ancora = Vector2.new(0, 0.5),
			cor = COR.verde,
			texto = textoPreco(passe),
			fonte = Enum.Font.BuilderSansBold,
			aoClicar = function()
				if passe.id ~= 0 and not jogador:GetAttribute("Passe" .. string.upper(string.sub(passe.chave, 1, 1)) .. string.sub(passe.chave, 2)) then
					MarketplaceService:PromptGamePassPurchase(jogador, passe.id)
				end
			end,
		})
		b.ZIndex = 13
		cartoesPasses[passe.chave] = { corpo = corpo, rotulo = rotulo, passe = passe }
	end
end

local rotulosPacotes = {}
linhaInfo(secoesLoja.dinheiro, 0, "dinheiro_info")
local gradePacotes = novo("Frame", {
	LayoutOrder = 1,
	Size = UDim2.new(1, 0, 0, 170),
	BackgroundTransparency = 1,
	ZIndex = 12,
	Parent = secoesLoja.dinheiro,
}, { novo("UIGridLayout", { CellSize = UDim2.new(0.32, 0, 0, 170), CellPadding = UDim2.new(0.02, 0, 0, 0), SortOrder = Enum.SortOrder.LayoutOrder }) })
for i, pacote in ipairs(Config.LOJA.PACOTES) do
	carregarPreco(pacote, Enum.InfoType.Product)
	if itemVisivel(pacote) then
		local c = novo("Frame", { LayoutOrder = i, BackgroundColor3 = Color3.fromRGB(31, 122, 77), ZIndex = 12, Parent = gradePacotes }, { cantos(16), borda(3) })
		texto({ Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 10), Text = string.rep("💰", i), Contorno = false, ZIndex = 13, Parent = c })
		texto({ Size = UDim2.new(1, -12, 0, 24), Position = UDim2.new(0, 6, 0, 48), Text = T("pacote_" .. pacote.chave), TamanhoMax = 22, ZIndex = 13, Parent = c })
		local desc = pacote.minutos >= 60 and T("pacote_desc_horas", pacote.minutos / 60) or T("pacote_desc", pacote.minutos)
		local valor = texto({ Size = UDim2.new(1, -12, 0, 20), Position = UDim2.new(0, 6, 0, 74), Text = desc, TextColor3 = COR.renda, TamanhoMax = 16, ZIndex = 13, Parent = c })
		local b = botao(c, {
			tamanho = UDim2.new(1, -20, 0, 44),
			posicao = UDim2.new(0, 10, 1, -56),
			cor = COR.verde,
			texto = textoPreco(pacote),
			fonte = Enum.Font.BuilderSansBold,
			aoClicar = function()
				comprarProduto(pacote.id)
			end,
		})
		b.ZIndex = 13
		rotulosPacotes[pacote.chave] = { valor = valor, pacote = pacote, botao = b }
	end
end
local anuncioLoja = nil
if itemVisivel(Config.LOJA.ANUNCIO) then
	anuncioLoja = cartao(secoesLoja.dinheiro, 2, 78, Color3.fromRGB(15, 118, 110))
	texto({ Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Text = "📺", Contorno = false, ZIndex = 13, Parent = anuncioLoja })
	texto({ Size = UDim2.new(1, -200, 0, 28), Position = UDim2.new(0, 72, 0, 10), Text = T("anuncio_titulo"), TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 22, ZIndex = 13, Parent = anuncioLoja })
	texto({ Size = UDim2.new(1, -200, 0, 30), Position = UDim2.new(0, 72, 0, 38), Text = T("anuncio_desc", Config.LOJA.ANUNCIO.minutos), TextColor3 = Color3.fromRGB(204, 251, 241), Contorno = false, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 15, ZIndex = 13, Parent = anuncioLoja })
	local b = botao(anuncioLoja, {
		tamanho = UDim2.new(0, 110, 0, 46),
		posicao = UDim2.new(1, -122, 0.5, -2),
		ancora = Vector2.new(0, 0.5),
		cor = COR.branco,
		texto = T("assistir"),
		aoClicar = function()
			Remotos.VerAnuncio:FireServer("dobro")
		end,
	})
	b.ZIndex = 13
end

local cartaoSorte = nil
if itemVisivel(Config.LOJA.SORTE) then
	carregarPreco(Config.LOJA.SORTE, Enum.InfoType.Product)
	cartaoSorte = cartao(secoesLoja.sorte, 1, 120, Color3.fromRGB(109, 40, 217))
	texto({ Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 12, 0, 12), Text = "⭐", Contorno = false, ZIndex = 13, Parent = cartaoSorte })
	texto({ Size = UDim2.new(1, -200, 0, 28), Position = UDim2.new(0, 72, 0, 12), Text = T("sorte_titulo"), TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 24, ZIndex = 13, Parent = cartaoSorte })
	texto({ Size = UDim2.new(1, -200, 0, 64), Position = UDim2.new(0, 72, 0, 42), Text = T("sorte_desc", Config.LOJA.SORTE.minutos, Config.SORTE.FORCA), TextColor3 = Color3.fromRGB(237, 228, 255), Contorno = false, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TamanhoMax = 15, ZIndex = 13, Parent = cartaoSorte })
	local b = botao(cartaoSorte, {
		tamanho = UDim2.new(0, 110, 0, 46),
		posicao = UDim2.new(1, -122, 0.5, -2),
		ancora = Vector2.new(0, 0.5),
		cor = COR.verde,
		texto = textoPreco(Config.LOJA.SORTE),
		fonte = Enum.Font.BuilderSansBold,
		aoClicar = function()
			comprarProduto(Config.LOJA.SORTE.id)
		end,
	})
	b.ZIndex = 13
end

local cartaoCaixa = nil
if itemVisivel(Config.LOJA.CAIXA) then
	carregarPreco(Config.LOJA.CAIXA, Enum.InfoType.Product)
	cartaoCaixa = cartao(secoesLoja.sorte, 2, 170, Color3.fromRGB(180, 83, 9))
	texto({ Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 12, 0, 12), Text = "🎁", Contorno = false, ZIndex = 13, Parent = cartaoCaixa })
	texto({ Size = UDim2.new(1, -200, 0, 28), Position = UDim2.new(0, 72, 0, 12), Text = T("caixa_titulo"), TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 24, ZIndex = 13, Parent = cartaoCaixa })
	texto({ Size = UDim2.new(1, -200, 0, 22), Position = UDim2.new(0, 72, 0, 42), Text = T("caixa_desc"), TextColor3 = Color3.fromRGB(255, 235, 210), Contorno = false, TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 15, ZIndex = 13, Parent = cartaoCaixa })
	local chances = novo("Frame", {
		Size = UDim2.new(1, -200, 0, 64),
		Position = UDim2.new(0, 72, 0, 72),
		BackgroundTransparency = 1,
		ZIndex = 13,
		Parent = cartaoCaixa,
	}, { novo("UIGridLayout", { CellSize = UDim2.new(0.24, 0, 1, 0), CellPadding = UDim2.new(0.013, 0, 0, 0), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local totalPeso = 0
	for _, c in ipairs(Config.LOJA.CAIXA.chances) do
		totalPeso = totalPeso + c.peso
	end
	for i, c in ipairs(Config.LOJA.CAIXA.chances) do
		local raridade = Config.Raridades[c.raridade]
		local celula = novo("Frame", { LayoutOrder = i, BackgroundColor3 = COR.painel, ZIndex = 14, Parent = chances }, { cantos(10), borda(2, raridade.cor) })
		texto({ Size = UDim2.new(1, -6, 0.45, 0), Position = UDim2.new(0, 3, 0, 4), Text = Config.nomeDe(raridade, idioma), TextColor3 = raridade.cor, TamanhoMax = 14, ZIndex = 15, Parent = celula })
		texto({ Size = UDim2.new(1, -6, 0.45, 0), Position = UDim2.new(0, 3, 0.5, 0), Text = math.floor(c.peso / totalPeso * 100 + 0.5) .. "%", TamanhoMax = 18, ZIndex = 15, Parent = celula })
	end
	local b = botao(cartaoCaixa, {
		tamanho = UDim2.new(0, 110, 0, 46),
		posicao = UDim2.new(1, -122, 0.5, -2),
		ancora = Vector2.new(0, 0.5),
		cor = COR.verde,
		texto = textoPreco(Config.LOJA.CAIXA),
		fonte = Enum.Font.BuilderSansBold,
		aoClicar = function()
			comprarProduto(Config.LOJA.CAIXA.id)
		end,
	})
	b.ZIndex = 13
end
escolherAba("passes")

-- Índice -----------------------------------------------------------------------
local indice = painel("Indice", T("titulo_indice"), COR.indice)
local rotuloContagem = linhaInfo(indice.conteudo, 0, "indice_premio")
local cartasIndice = {}
local rotulosRaridade = {}
for r, raridade in ipairs(Config.Raridades) do
	local titulo = texto({
		LayoutOrder = r * 2 - 1,
		Size = UDim2.new(1, 0, 0, 26),
		Text = Config.nomeDe(raridade, idioma),
		TextColor3 = raridade.cor,
		Font = TITULO,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 12,
		Parent = indice.conteudo,
	})
	rotulosRaridade[r] = titulo
	local grade = novo("Frame", {
		LayoutOrder = r * 2,
		Size = UDim2.new(1, 0, 0, 84),
		BackgroundTransparency = 1,
		ZIndex = 12,
		Parent = indice.conteudo,
	}, { novo("UIGridLayout", { CellSize = UDim2.new(0.32, 0, 0, 84), CellPadding = UDim2.new(0.02, 0, 0, 0), SortOrder = Enum.SortOrder.LayoutOrder }) })
	for i, def in ipairs(Config.robosDaRaridade(r)) do
		local c = novo("Frame", { Name = def.id, LayoutOrder = i, BackgroundColor3 = raridade.cor:Lerp(Color3.new(0, 0, 0), 0.6), ZIndex = 13, Parent = grade }, { cantos(12), borda(3, raridade.cor) })
		local nome = texto({ Size = UDim2.new(1, -10, 0.45, 0), Position = UDim2.new(0, 5, 0, 6), Text = "???", TamanhoMax = 18, ZIndex = 14, Parent = c })
		texto({ Size = UDim2.new(1, -10, 0.35, 0), Position = UDim2.new(0, 5, 0.55, 0), Text = D(def.renda) .. "/s", TextColor3 = COR.renda, TamanhoMax = 16, ZIndex = 14, Parent = c })
		cartasIndice[def.id] = { nome = nome, def = def }
	end
end

-- Melhorar ---------------------------------------------------------------------
local melhorar = painel("Melhorar", T("titulo_melhorar"), COR.dinheiro)
linhaInfo(melhorar.conteudo, 0, "melhorar_info")
local linhasMelhoria = {}
for i, tipo in ipairs({ "renda", "vagas", "tapa" }) do
	local c = cartao(melhorar.conteudo, i, 78)
	local titulo = texto({ Size = UDim2.new(1, -170, 0, 28), Position = UDim2.new(0, 16, 0, 10), Text = T("melhoria_" .. tipo), TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 22, ZIndex = 13, Parent = c })
	local efeito = texto({ Size = UDim2.new(1, -170, 0, 24), Position = UDim2.new(0, 16, 0, 42), Text = T("efeito_" .. tipo), TextColor3 = COR.suave, Contorno = false, TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 16, ZIndex = 13, Parent = c })
	local b, corpo, rotulo = botao(c, {
		tamanho = UDim2.new(0, 140, 0, 46),
		posicao = UDim2.new(1, -152, 0.5, -2),
		ancora = Vector2.new(0, 0.5),
		cor = COR.verde,
		texto = "",
		aoClicar = function()
			Remotos.Melhorar:FireServer(tipo)
		end,
	})
	b.ZIndex = 13
	linhasMelhoria[tipo] = { titulo = titulo, efeito = efeito, corpo = corpo, rotulo = rotulo }
end

-- Renascer ---------------------------------------------------------------------
local renascer = painel("Renascer", T("titulo_renascer"), Color3.fromRGB(214, 180, 255))
texto({
	LayoutOrder = 1,
	Size = UDim2.new(1, 0, 0, 80),
	Text = T("renascer_texto", math.floor(Config.RENASCER.BONUS * 100), Config.TRANCA.EXTRA_POR_RENASCIMENTO),
	TextScaled = false,
	TextSize = 18,
	TextWrapped = true,
	Contorno = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 12,
	Parent = renascer.conteudo,
})
local rotuloCusto = texto({ LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 32), TextColor3 = COR.dinheiro, ZIndex = 12, Parent = renascer.conteudo })
local rotuloBonus = texto({ LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 28), TextColor3 = COR.renda, ZIndex = 12, Parent = renascer.conteudo })
local _, corpoRenascer, rotuloRenascer = botao(renascer.conteudo, {
	ordem = 4,
	tamanho = UDim2.new(1, 0, 0, 56),
	cor = COR.renascer,
	texto = T("renascer_agora"),
	fonte = TITULO,
	tamanhoTexto = 28,
	aoClicar = function()
		Remotos.Renascer:FireServer()
		paineis.Renascer.frame.Visible = false
		painelAberto = nil
	end,
})

-- Prêmio diário ----------------------------------------------------------------
local diario = painel("Diario", T("titulo_diario"), Color3.fromRGB(255, 122, 147))
linhaInfo(diario.conteudo, 0, "diario_info")
local gradeDias = novo("Frame", {
	LayoutOrder = 1,
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	ZIndex = 12,
	Parent = diario.conteudo,
}, { novo("UIGridLayout", { CellSize = UDim2.new(0.235, 0, 0, 104), CellPadding = UDim2.new(0.02, 0, 0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
local cartasDias = {}
local function descricaoPremio(premio)
	local renda = jogador:GetAttribute("RendaPorSegundo") or 0
	if premio.tipo == "dinheiro" then
		return D(Config.dinheiroDe(premio, renda))
	elseif premio.tipo == "robo" then
		return T("premio_robo_raridade", Config.nomeDe(Config.Raridades[premio.raridade], idioma))
	elseif premio.tipo == "sorte" then
		return T("premio_sorte", premio.minutos)
	end
	return ""
end
for dia, premio in ipairs(Config.PREMIO_DIARIO) do
	local ultimo = dia == #Config.PREMIO_DIARIO
	local c = novo("Frame", { LayoutOrder = dia, BackgroundColor3 = ultimo and Color3.fromRGB(124, 45, 18) or COR.cartao, ZIndex = 13, Parent = gradeDias }, { cantos(14), borda(3, ultimo and COR.renda or COR.contorno) })
	texto({ Size = UDim2.new(1, -8, 0, 20), Position = UDim2.new(0, 4, 0, 6), Text = T("dia", dia), TamanhoMax = 16, ZIndex = 14, Parent = c })
	local premioRotulo = texto({ Size = UDim2.new(1, -8, 0, 36), Position = UDim2.new(0, 4, 0, 28), Text = "", TextColor3 = ultimo and COR.renda or COR.branco, TextWrapped = true, TamanhoMax = 16, ZIndex = 14, Parent = c })
	local b, corpo, rotulo = botao(c, {
		tamanho = UDim2.new(1, -14, 0, 30),
		posicao = UDim2.new(0, 7, 1, -38),
		cor = COR.verde,
		texto = T("pegar"),
		tamanhoTexto = 16,
		raio = 10,
		aoClicar = function()
			Remotos.PegarDiario:FireServer()
		end,
	})
	b.ZIndex = 14
	cartasDias[dia] = { frame = c, premio = premioRotulo, botao = b, corpo = corpo, rotulo = rotulo, def = premio }
end

-- Missões ----------------------------------------------------------------------
local missoes = painel("Missoes", T("titulo_missoes"), Color3.fromRGB(255, 170, 92))
local rotuloNovasEm = linhaInfo(missoes.conteudo, 0, "novas_em")
local linhasMissao = {}
for i = 1, Config.MISSOES_POR_DIA do
	local c = cartao(missoes.conteudo, i, 82)
	local titulo = texto({ Size = UDim2.new(1, -170, 0, 26), Position = UDim2.new(0, 16, 0, 10), Text = "", TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 20, ZIndex = 13, Parent = c })
	local premioRotulo = texto({ Size = UDim2.new(1, -170, 0, 18), Position = UDim2.new(0, 16, 0, 36), Text = "", TextColor3 = COR.renda, TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 16, ZIndex = 13, Parent = c })
	local trilho = novo("Frame", { Size = UDim2.new(1, -170, 0, 12), Position = UDim2.new(0, 16, 0, 60), BackgroundColor3 = COR.painel, ZIndex = 13, Parent = c }, { cantos(6), borda(2) })
	local barra = novo("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = COR.missoes, ZIndex = 14, Parent = trilho }, { cantos(6) })
	local b, corpo, rotulo = botao(c, {
		tamanho = UDim2.new(0, 130, 0, 44),
		posicao = UDim2.new(1, -142, 0.5, -2),
		ancora = Vector2.new(0, 0.5),
		cor = COR.verde,
		texto = T("pegar"),
		aoClicar = function()
			Remotos.PegarMissao:FireServer(i)
		end,
	})
	b.ZIndex = 13
	linhasMissao[i] = { titulo = titulo, premio = premioRotulo, barra = barra, corpo = corpo, rotulo = rotulo }
end

-- Bem-vindo de volta (dinheiro offline) ----------------------------------------
local offline = painel("Offline", T("titulo_offline"), COR.renda)
local rotuloOffline = texto({ LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 60), Text = "", TextWrapped = true, TamanhoMax = 24, ZIndex = 12, Parent = offline.conteudo })
botao(offline.conteudo, {
	ordem = 2,
	tamanho = UDim2.new(1, 0, 0, 52),
	cor = Color3.fromRGB(59, 63, 92),
	texto = T("pegar"),
	aoClicar = function()
		Remotos.ColetarOffline:FireServer()
		paineis.Offline.frame.Visible = false
		painelAberto = nil
	end,
})
if Config.LOJA.ANUNCIO.id ~= 0 then
	botao(offline.conteudo, {
		ordem = 3,
		tamanho = UDim2.new(1, 0, 0, 52),
		cor = COR.anuncio,
		texto = T("pegar_x2"),
		aoClicar = function()
			Remotos.VerAnuncio:FireServer("offline")
			paineis.Offline.frame.Visible = false
			painelAberto = nil
		end,
	})
end

-- Botões das colunas -----------------------------------------------------------
botaoMenu(colunaEsquerda, "menu_loja", "🛒", COR.loja, 1, function()
	abrir("Loja")
end)
botaoMenu(colunaEsquerda, "menu_indice", "📖", COR.indice, 2, function()
	abrir("Indice")
end)
botaoMenu(colunaEsquerda, "menu_melhorar", "⬆️", COR.melhorar, 3, function()
	abrir("Melhorar")
end)
botaoMenu(colunaEsquerda, "menu_renascer", "🔄", COR.renascer, 4, function()
	abrir("Renascer")
end)
botaoMenu(colunaDireita, "menu_premio", "🎁", COR.premio, 1, function()
	abrir("Diario")
end)
botaoMenu(colunaDireita, "menu_missoes", "📋", COR.missoes, 2, function()
	abrir("Missoes")
end)
if itemVisivel(Config.LOJA.ANUNCIO) then
	botaoMenu(colunaDireita, "menu_gratis", "📺", COR.anuncio, 3, function()
		Remotos.VerAnuncio:FireServer("dobro")
	end)
end
if noStudio then
	local teste = Remotos:WaitForChild("Teste")
	for i, acao in ipairs({ { "teste_mais", "dinheiro" }, { "teste_sorte", "sorte" } }) do
		botao(colunaEsquerda, {
			nome = acao[1],
			ordem = 10 + i,
			cor = COR.cinza,
			texto = T(acao[1]),
			tamanhoTexto = 16,
			aoClicar = function()
				teste:FireServer(acao[2])
			end,
		})
	end
	botao(colunaEsquerda, {
		nome = "teste_dia",
		ordem = 13,
		cor = COR.cinza,
		texto = "Teste: +1 dia",
		tamanhoTexto = 16,
		aoClicar = function()
			teste:FireServer("dia")
		end,
	})
end

-- Arrumação: celular x PC --------------------------------------------------------
local compactoAtual = nil
local function arrumar()
	local camera = workspace.CurrentCamera
	local tamanho = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local largura, altura = tamanho.X, tamanho.Y

	-- encolhe a interface em janelas pequenas (no toque não encolhe tanto,
	-- senão os botões ficam difíceis de acertar com o dedo)
	local minimo = UserInputService.TouchEnabled and 0.8 or 0.6
	local alvo = math.clamp(math.min(largura / 1100, altura / 620), minimo, 1.1) * ESCALA_DA_TELA
	if math.abs(alvo - escalaAtual) > 0.005 then
		escalaAtual = alvo
		for _, escala in ipairs(escalas) do
			escala.Scale = alvo
		end
	end

	-- o painel encolhe só o necessário para caber inteiro na tela
	local cabe = math.min(largura * 0.94 / LARGURA_PAINEL, altura * 0.88 / ALTURA_PAINEL)
	local alvoPainel = math.clamp(math.min(cabe, 1.1 * ESCALA_DA_TELA), 0.35, 1.3)
	if math.abs(alvoPainel - escalaPainel) > 0.005 then
		escalaPainel = alvoPainel
		for _, escala in ipairs(escalasPainel) do
			escala.Scale = alvoPainel
		end
	end

	local compacto = largura < 900 or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
	if compacto == compactoAtual then
		return
	end
	compactoAtual = compacto
	if compacto then
		layoutEsquerda.CellSize = UDim2.new(0, 58, 0, 58)
		layoutDireita.CellSize = UDim2.new(0, 58, 0, 58)
		colunaEsquerda.Size = UDim2.new(0, 124, 0, 0)
		colunaDireita.Size = UDim2.new(0, 58, 0, 0)
		colunaDireita.AnchorPoint = Vector2.new(1, 0)
		colunaDireita.Position = UDim2.new(1, -10, 0, 8)
	else
		layoutEsquerda.CellSize = UDim2.new(0, 132, 0, 44)
		layoutDireita.CellSize = UDim2.new(0, 132, 0, 44)
		colunaEsquerda.Size = UDim2.new(0, 132, 0, 0)
		colunaDireita.Size = UDim2.new(0, 132, 0, 0)
		colunaDireita.AnchorPoint = Vector2.new(1, 0.5)
		colunaDireita.Position = UDim2.new(1, -12, 0.5, 0)
	end
	for _, b in pairs(botoesMenu) do
		if compacto then
			b.icone.Size = UDim2.new(1, 0, 0.6, 0)
			b.icone.Position = UDim2.new(0, 0, 0, 2)
			b.nome.Size = UDim2.new(1, -4, 0.32, 0)
			b.nome.Position = UDim2.new(0, 2, 0.64, 0)
		else
			b.icone.Size = UDim2.new(0, 34, 1, -10)
			b.icone.Position = UDim2.new(0, 8, 0, 5)
			b.nome.Size = UDim2.new(1, -54, 1, -14)
			b.nome.Position = UDim2.new(0, 46, 0, 7)
		end
	end
	for _, filho in ipairs(colunaEsquerda:GetChildren()) do
		if filho:IsA("Frame") and string.sub(filho.Name, 1, 6) == "teste_" then
			filho.Visible = not compacto or noStudio
		end
	end
end
arrumar()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(arrumar)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(arrumar)
		arrumar()
	end
end)

-- Atualização --------------------------------------------------------------------
local valorDinheiro = nil
local valorRenascimentos = nil
local dinheiroMostrado = 0
local animacaoDinheiro = novo("NumberValue", { Name = "DinheiroAnimado", Value = 0, Parent = tela })
animacaoDinheiro.Changed:Connect(function(v)
	dinheiroMostrado = v
	rotuloDinheiro.Text = D(v)
end)

local function dinheiroAtual()
	return valorDinheiro and valorDinheiro.Value or 0
end

local function contarDinheiro()
	local alvo = dinheiroAtual()
	if math.abs(alvo - dinheiroMostrado) < 1 then
		return
	end
	TweenService:Create(animacaoDinheiro, ANIM.suave, { Value = alvo }):Play()
	if alvo > dinheiroMostrado + 1 and alvo - dinheiroMostrado > (jogador:GetAttribute("RendaPorSegundo") or 0) * 2 + 1 then
		pulo(placar)
	end
end

local function passeAtivo(chave)
	return jogador:GetAttribute("Passe" .. string.upper(string.sub(chave, 1, 1)) .. string.sub(chave, 2)) == true
end

local function atualizarLoja()
	for chave, info in pairs(cartoesPasses) do
		if passeAtivo(chave) then
			info.rotulo.Text = T("comprado")
			info.rotulo.Font = FONTE
			info.corpo.BackgroundColor3 = COR.cinza
		else
			info.rotulo.Text = info.passe.id ~= 0 and textoPreco(info.passe) or (textoPreco(info.passe) .. " (id 0)")
			info.corpo.BackgroundColor3 = COR.verde
		end
	end
	local renda = jogador:GetAttribute("RendaPorSegundo") or 0
	for _, info in pairs(rotulosPacotes) do
		info.valor.Text = D(Config.dinheiroDe(info.pacote, renda))
	end
	if cartaoCaixa then
		cartaoCaixa.Visible = noStudio or not jogador:GetAttribute("SemCaixa")
	end
end

local function atualizarIndice()
	local descobertos = {}
	local total = 0
	for id in string.gmatch(jogador:GetAttribute("Descobertos") or "", "[^,]+") do
		descobertos[id] = true
		total = total + 1
	end
	local completas = {}
	for r in string.gmatch(jogador:GetAttribute("IndicePremios") or "", "[^,]+") do
		completas[tonumber(r)] = true
	end
	for id, c in pairs(cartasIndice) do
		c.nome.Text = descobertos[id] and Config.nomeDe(c.def, idioma) or "???"
	end
	for r, rotulo in ipairs(rotulosRaridade) do
		local nome = Config.nomeDe(Config.Raridades[r], idioma)
		rotulo.Text = completas[r] and (nome .. "  ✔ " .. T("indice_completa")) or nome
	end
	rotuloContagem.Text = T("indice_contagem", total, #Config.Robos) .. "  ·  " .. T("indice_premio")
end

local function atualizarMelhorias()
	local niveis = {
		renda = jogador:GetAttribute("NivelRenda") or 0,
		vagas = jogador:GetAttribute("NivelVagas") or 0,
		tapa = jogador:GetAttribute("NivelTapa") or 0,
	}
	for tipo, linha in pairs(linhasMelhoria) do
		local nivel = niveis[tipo]
		local maximo = Config.MELHORIAS[tipo].max
		linha.titulo.Text = T("melhoria_" .. tipo) .. "  ·  " .. T("nivel", nivel .. "/" .. maximo)
		local custo = Config.custoMelhoria(tipo, nivel)
		if custo then
			linha.rotulo.Text = D(custo)
			linha.corpo.BackgroundColor3 = dinheiroAtual() >= custo and COR.verde or COR.cinza
		else
			linha.rotulo.Text = T("maximo")
			linha.corpo.BackgroundColor3 = COR.loja
		end
	end
end

local function atualizarRenascer()
	local custo = jogador:GetAttribute("CustoRenascer") or Config.custoRenascer(0)
	local r = valorRenascimentos and valorRenascimentos.Value or 0
	rotuloCusto.Text = T("custo", D(custo)) .. "  (" .. D(dinheiroAtual()) .. ")"
	rotuloBonus.Text = T("bonus_renascer", Format.multiplicador(Config.multiplicadorRenascer(r), idioma),
		Format.multiplicador(Config.multiplicadorRenascer(r + 1), idioma))
	local pode = dinheiroAtual() >= custo
	corpoRenascer.BackgroundColor3 = pode and COR.renascer or COR.cinza
	rotuloRenascer.Text = pode and T("renascer_agora") or T("falta")
end

local function atualizarDiario()
	local diaAtual = jogador:GetAttribute("DiarioDia") or 1
	local pronto = jogador:GetAttribute("DiarioPronto") == true
	for dia, c in pairs(cartasDias) do
		c.premio.Text = descricaoPremio(c.def)
		local hoje = dia == diaAtual
		c.botao.Visible = hoje
		if hoje then
			c.rotulo.Text = pronto and T("pegar") or T("amanha")
			c.corpo.BackgroundColor3 = pronto and COR.verde or COR.cinza
		end
		local pego = dia < diaAtual or (hoje and not pronto)
		c.frame.BackgroundTransparency = pego and 0.45 or 0
	end
	local b = botoesMenu.menu_premio
	if b then
		b.selo.Visible = pronto
		b.selo.Text = "!"
	end
end

local function atualizarMissoes()
	local prontas, feitas = 0, 0
	for i, linha in ipairs(linhasMissao) do
		local id = jogador:GetAttribute("M" .. i .. "Id") or ""
		local missao = Config.MissaoPorId[id]
		local progresso = jogador:GetAttribute("M" .. i .. "Prog") or 0
		local pega = jogador:GetAttribute("M" .. i .. "Pega") == true
		if missao then
			local alvo = missao.raridade and Config.nomeDe(Config.Raridades[missao.raridade], idioma) or missao.meta
			linha.titulo.Text = T("missao_" .. missao.tipo, alvo)
			linha.premio.Text = "+ " .. descricaoPremio(missao.premio)
			linha.barra.Size = UDim2.new(math.clamp(progresso / missao.meta, 0, 1), 0, 1, 0)
			if pega then
				feitas = feitas + 1
				linha.rotulo.Text = T("feito")
				linha.corpo.BackgroundColor3 = COR.cinza
			elseif progresso >= missao.meta then
				prontas = prontas + 1
				linha.rotulo.Text = T("pegar")
				linha.corpo.BackgroundColor3 = COR.verde
			else
				linha.rotulo.Text = progresso .. "/" .. missao.meta
				linha.corpo.BackgroundColor3 = Color3.fromRGB(59, 63, 92)
			end
		end
	end
	local b = botoesMenu.menu_missoes
	if b then
		b.selo.Visible = prontas > 0 or feitas < Config.MISSOES_POR_DIA
		b.selo.Text = prontas > 0 and tostring(prontas) or (feitas .. "/" .. Config.MISSOES_POR_DIA)
		b.selo.BackgroundColor3 = prontas > 0 and Color3.fromRGB(255, 45, 85) or Color3.fromRGB(59, 63, 92)
	end
end

local offlineMostrado = false
local function atualizarOffline()
	local valor = jogador:GetAttribute("OfflinePendente") or 0
	if valor > 0 then
		rotuloOffline.Text = T("offline_texto", D(valor))
		if not offlineMostrado then
			offlineMostrado = true
			abrir("Offline")
		end
	else
		offlineMostrado = false
		if paineis.Offline.frame.Visible then
			paineis.Offline.frame.Visible = false
			painelAberto = nil
		end
	end
end

function atualizarTudo()
	contarDinheiro()
	local renda = jogador:GetAttribute("RendaPorSegundo") or 0
	local mult = jogador:GetAttribute("Multiplicador") or 1
	local ocupadas = jogador:GetAttribute("VagasOcupadas") or 0
	local totais = jogador:GetAttribute("VagasTotais") or Config.VAGAS.INICIAIS
	rotuloRenda.Text = "+" .. D(renda) .. "/s  ·  " .. T("robos_contagem", ocupadas, totais) .. "  ·  " .. Format.multiplicador(mult, idioma)

	local carga = jogador:GetAttribute("Carregando")
	faixaCarga.Visible = carga ~= nil
	if carga then
		local def = Config.RoboPorId[carga]
		local mut = jogador:GetAttribute("CarregandoMut")
		if mut == "" then
			mut = nil
		end
		rotuloCarga.Text = "🤖 " .. T("carregando", def and Config.nomeCompleto(def, mut, idioma) or carga)
	end

	atualizarLoja()
	atualizarIndice()
	atualizarMelhorias()
	atualizarRenascer()
	atualizarDiario()
	atualizarMissoes()
	atualizarOffline()
end

local function atualizarContagens()
	local agora = workspace:GetServerTimeNow()
	local trancadaAte = jogador:GetAttribute("TrancadaAte") or 0
	if trancadaAte > agora then
		rotuloBase.Text = "🔒 " .. T("base_trancada", Format.tempo(trancadaAte - agora))
		faixaBase.BackgroundColor3 = COR.trancada
	else
		rotuloBase.Text = "🔓 " .. T("base_aberta")
		faixaBase.BackgroundColor3 = COR.aberta
	end

	local sorteAte = ReplicatedStorage:GetAttribute("HoraDaSorteAte") or 0
	faixaSorte.Visible = sorteAte > agora
	if faixaSorte.Visible then
		local quem = ReplicatedStorage:GetAttribute("HoraDaSortePor") or ""
		if quem ~= "" then
			rotuloSorte.Text = "⭐ " .. T("sorte_faixa_presente", Format.tempo(sorteAte - agora), quem)
		else
			rotuloSorte.Text = "⭐ " .. T("sorte_faixa", Format.tempo(sorteAte - agora))
		end
	end

	local dobroAte = jogador:GetAttribute("DobroAte") or 0
	faixaDobro.Visible = dobroAte > agora
	if faixaDobro.Visible then
		rotuloDobro.Text = "📺 " .. T("dobro_ativo", Format.tempo(dobroAte - agora))
	end

	local proximoDia = ((jogador:GetAttribute("MissoesDia") or 0) + 1) * 86400
	rotuloNovasEm.Text = T("novas_em", Format.tempo(proximoDia - agora))
end

jogador.AttributeChanged:Connect(atualizarTudo)
task.spawn(function()
	local leaderstats = jogador:WaitForChild("leaderstats")
	valorDinheiro = leaderstats:WaitForChild("Dinheiro")
	valorRenascimentos = leaderstats:WaitForChild("Renascimentos")
	animacaoDinheiro.Value = valorDinheiro.Value
	valorDinheiro.Changed:Connect(atualizarTudo)
	valorRenascimentos.Changed:Connect(atualizarTudo)
	atualizarTudo()
end)

atualizarTudo()
while true do
	atualizarContagens()
	task.wait(0.25)
end
