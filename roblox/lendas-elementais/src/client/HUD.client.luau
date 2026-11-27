--[[
	A tela do jogador: vida, XP, nível, moedas, zona, avisos e os painéis
	de Elementos, Melhorar, Loja, Missões e Prêmio diário.

	Tudo aqui é só desenho. Quem decide compras, prêmios e números é o
	servidor; esta tela mostra o que ele mandou.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Textos = require(Shared:WaitForChild("Textos"))
local UI = require(Shared:WaitForChild("UI"))
local Remotos = ReplicatedStorage:WaitForChild("Remotos")

local jogador = Players.LocalPlayer
local playerGui = jogador:WaitForChild("PlayerGui")
local noStudio = RunService:IsStudio()
local idioma = Textos.idiomaDe(jogador.LocaleId)

local function T(chave, ...)
	return Textos.t(idioma, chave, ...)
end
local function N(valor)
	return Format.numero(valor, idioma)
end

local novo, texto, botao, cantos, borda = UI.novo, UI.texto, UI.botao, UI.cantos, UI.borda
local COR = UI.COR

local tela = novo("ScreenGui", {
	Name = "LendasHUD",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

-- Canto de cima à esquerda: nível, vida, XP e moedas -------------------------
local painelJogador = novo("Frame", {
	Name = "Jogador",
	Position = UDim2.new(0, 12, 0, 10),
	Size = UDim2.new(0, 250, 0, 92),
	BackgroundColor3 = COR.painel,
	Parent = tela,
}, { cantos(16), borda(3) })
UI.escalavel(painelJogador)

local medalha = novo("Frame", {
	Name = "Medalha",
	Size = UDim2.new(0, 52, 0, 52),
	Position = UDim2.new(0, 10, 0, 10),
	BackgroundColor3 = COR.elementos,
	Parent = painelJogador,
}, { cantos(26), borda(3) })
local rotuloNivel = texto({
	Name = "Nivel",
	Size = UDim2.new(1, -6, 0.55, 0),
	Position = UDim2.new(0, 3, 0, 4),
	Text = "1",
	Font = UI.TITULO,
	TamanhoMax = 26,
	Parent = medalha,
})
texto({
	Name = "Rotulo",
	Size = UDim2.new(1, -6, 0.35, 0),
	Position = UDim2.new(0, 3, 0.58, 0),
	Text = T("nivel_curto", ""),
	TamanhoMax = 12,
	Contorno = 1.5,
	Parent = medalha,
})

local _, barraVida, textoVida = UI.barra(painelJogador, {
	nome = "Vida",
	tamanho = UDim2.new(1, -78, 0, 24),
	posicao = UDim2.new(0, 70, 0, 10),
	cor = COR.vida,
})
local _, barraXP, textoXP = UI.barra(painelJogador, {
	nome = "XP",
	tamanho = UDim2.new(1, -78, 0, 18),
	posicao = UDim2.new(0, 70, 0, 38),
	cor = COR.xp,
	tamanhoTexto = 13,
})

local linhaMoedas = novo("Frame", {
	Name = "Moedas",
	Size = UDim2.new(1, -20, 0, 22),
	Position = UDim2.new(0, 10, 0, 64),
	BackgroundTransparency = 1,
	Parent = painelJogador,
})
novo("Frame", {
	Name = "Moeda",
	Size = UDim2.new(0, 20, 0, 20),
	BackgroundColor3 = COR.moedas,
	Parent = linhaMoedas,
}, { cantos(10), borda(2) })
local rotuloMoedas = texto({
	Name = "Valor",
	Size = UDim2.new(1, -26, 1, 0),
	Position = UDim2.new(0, 26, 0, 0),
	Text = "0",
	TextColor3 = COR.moedas,
	TextXAlignment = Enum.TextXAlignment.Left,
	TamanhoMax = 19,
	Parent = linhaMoedas,
})

-- Topo do meio: zona, XP em dobro e avisos -----------------------------------
local topo = novo("Frame", {
	Name = "Topo",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
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
UI.escalavel(topo)

local function faixa(nome, ordem, cor)
	local f = novo("Frame", {
		Name = nome,
		LayoutOrder = ordem,
		Size = UDim2.new(0, 0, 0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = cor,
		Visible = false,
		Parent = topo,
	}, {
		cantos(10),
		borda(2),
		novo("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
		novo("UISizeConstraint", { MaxSize = Vector2.new(420, math.huge) }),
	})
	local r = texto({
		Name = "Texto",
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		TextScaled = false,
		TextSize = 15,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Contorno = 1.5,
		Parent = f,
	})
	return f, r
end

local faixaZona, textoZona = faixa("Zona", 1, COR.segura)
faixaZona.Visible = true
local faixaXP2, textoXP2 = faixa("XP2", 2, COR.anuncio)

local avisos = novo("Frame", {
	Name = "Avisos",
	LayoutOrder = 3,
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = topo,
}, { novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) }) })

local MAX_AVISOS = 3
local contador = 0
local function mostrarAviso(mensagem, tipo)
	contador = contador + 1
	local caixa = novo("TextLabel", {
		Name = "Aviso",
		LayoutOrder = contador,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = UI.AVISO[tipo] or UI.AVISO.info,
		Font = UI.FONTE,
		TextColor3 = COR.branco,
		TextSize = 15,
		TextWrapped = true,
		Text = mensagem,
		Parent = avisos,
	}, {
		cantos(10),
		borda(2),
		novo("UIPadding", {
			PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
			PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
		}),
	})
	UI.pulo(caixa)
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
			local sumir = TweenService:Create(caixa, UI.ANIM.suave, { BackgroundTransparency = 1, TextTransparency = 1 })
			sumir:Play()
			sumir.Completed:Wait()
			caixa:Destroy()
		end
	end)
end
Remotos:WaitForChild("Aviso").OnClientEvent:Connect(mostrarAviso)

-- Tela de morte ----------------------------------------------------------------
local morte = novo("Frame", {
	Name = "Morte",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(80, 0, 0),
	BackgroundTransparency = 0.45,
	Visible = false,
	ZIndex = 20,
	Parent = tela,
})
texto({
	Name = "Titulo",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.new(0.6, 0, 0, 60),
	Text = T("morreu_titulo"),
	Font = UI.TITULO,
	TamanhoMax = 54,
	ZIndex = 21,
	Parent = morte,
})
local textoVoltando = texto({
	Name = "Voltando",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.54),
	Size = UDim2.new(0.6, 0, 0, 34),
	TamanhoMax = 26,
	ZIndex = 21,
	Parent = morte,
})

-- Botões do menu ------------------------------------------------------------------
local coluna = novo("Frame", {
	Name = "Menu",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 12, 0.5, 0),
	Size = UDim2.new(0, 132, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = tela,
})
local layoutMenu = novo("UIGridLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	CellSize = UDim2.new(0, 132, 0, 44),
	CellPadding = UDim2.new(0, 8, 0, 8),
	Parent = coluna,
})
UI.escalavel(coluna)

local botoesMenu = {}
local paineis = {}
local painelAberto = nil
local atualizarTudo

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
	info.escala.Scale = UI.escalaPainel * 0.85
	TweenService:Create(info.escala, UI.ANIM.mola, { Scale = UI.escalaPainel }):Play()
	atualizarTudo()
end

local function painel(nome, titulo, corTitulo)
	local p = novo("Frame", {
		Name = nome,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(UI.LARGURA_PAINEL, UI.ALTURA_PAINEL),
		BackgroundColor3 = COR.painel,
		Visible = false,
		ZIndex = 10,
		Parent = tela,
	}, { cantos(22), borda(4) })
	local escala = UI.escalavel(p, true)
	texto({
		Name = "Titulo",
		Size = UDim2.new(1, -80, 0, 40),
		Position = UDim2.new(0, 18, 0, 12),
		Text = titulo,
		Font = UI.TITULO,
		TextColor3 = corTitulo or COR.moedas,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11,
		Parent = p,
	})
	local fechar = botao(p, {
		nome = "Fechar",
		tamanho = UDim2.new(0, 44, 0, 44),
		posicao = UDim2.new(1, -56, 0, 10),
		cor = COR.pvp,
		texto = "X",
		fonte = UI.TITULO,
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

local function botaoMenu(chave, icone, cor, ordem, aoClicar)
	local caixa, corpo, rotulo = botao(coluna, { nome = chave, ordem = ordem, cor = cor, texto = "", aoClicar = aoClicar })
	rotulo.Visible = false
	local iconeRotulo = texto({ Name = "Icone", Text = icone, Contorno = false, Parent = corpo })
	local nomeRotulo = texto({ Name = "Nome", Text = T(chave), TamanhoMax = 19, Parent = corpo })
	local selo = novo("TextLabel", {
		Name = "Selo",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -4, 0, 4),
		Size = UDim2.new(0, 26, 0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(255, 45, 85),
		Font = UI.FONTE,
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

local function cartao(pai, ordem, altura, cor)
	return novo("Frame", {
		LayoutOrder = ordem,
		Size = UDim2.new(1, 0, 0, altura),
		BackgroundColor3 = cor or COR.cartao,
		ZIndex = 12,
		Parent = pai,
	}, { cantos(16), borda(3) })
end

local function linhaInfo(pai, ordem, chave)
	return texto({
		LayoutOrder = ordem,
		Size = UDim2.new(1, 0, 0, 22),
		Text = T(chave),
		TextColor3 = COR.suave,
		Contorno = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TamanhoMax = 16,
		ZIndex = 12,
		Parent = pai,
	})
end

-- Painel: Elementos ----------------------------------------------------------------
local ICONES = { fogo = "🔥", gelo = "❄️", raio = "⚡", pedra = "🪨", vento = "🌪️", sombra = "🌑" }
local painelElementos = painel("Elementos", T("titulo_elementos"), COR.elementos)
linhaInfo(painelElementos.conteudo, 0, "elementos_info")
local cartoesElemento = {}
for i, elemento in ipairs(Config.Elementos) do
	local c = cartao(painelElementos.conteudo, i, 96, elemento.cor:Lerp(COR.painel, 0.55))
	texto({ Size = UDim2.new(0, 48, 0, 48), Position = UDim2.new(0, 12, 0, 10), Text = ICONES[elemento.id] or "✨",
		Contorno = false, ZIndex = 13, Parent = c })
	texto({ Size = UDim2.new(1, -200, 0, 28), Position = UDim2.new(0, 66, 0, 8),
		Text = Config.nomeDe(elemento, idioma), TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 24, ZIndex = 13, Parent = c })
	local golpes = {}
	for g, nomeGolpe in ipairs(Config.GOLPES) do
		local golpe = elemento[nomeGolpe]
		golpes[g] = T("golpe_" .. nomeGolpe) .. ": " .. Config.nomeDe(golpe, idioma)
	end
	texto({ Size = UDim2.new(1, -200, 0, 52), Position = UDim2.new(0, 66, 0, 38),
		Text = table.concat(golpes, "   ·   "), TextColor3 = COR.suave, Contorno = false, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TamanhoMax = 14, ZIndex = 13, Parent = c })
	local b, corpo, rotulo = botao(c, {
		tamanho = UDim2.new(0, 124, 0, 46),
		posicao = UDim2.new(1, -136, 0.5, -2),
		ancora = Vector2.new(0, 0.5),
		cor = COR.verde,
		texto = "",
		aoClicar = function()
			if jogador:GetAttribute("Elementos") and string.find("," .. jogador:GetAttribute("Elementos") .. ",", "," .. elemento.id .. ",", 1, true) then
				Remotos.Equipar:FireServer(elemento.id)
			else
				Remotos.ComprarElemento:FireServer(elemento.id)
			end
		end,
	})
	b.ZIndex = 13
	cartoesElemento[elemento.id] = { corpo = corpo, rotulo = rotulo, elemento = elemento }
end

-- Painel: Melhorar -------------------------------------------------------------------
local painelMelhorar = painel("Melhorar", T("titulo_melhorar"), COR.melhorar)
linhaInfo(painelMelhorar.conteudo, 0, "melhorar_info")
local linhasMelhoria = {}
for i, tipo in ipairs({ "vida", "dano", "velocidade" }) do
	local c = cartao(painelMelhorar.conteudo, i, 76)
	c.Name = "Melhoria_" .. tipo
	local titulo = texto({ Size = UDim2.new(1, -170, 0, 28), Position = UDim2.new(0, 16, 0, 8),
		TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 22, ZIndex = 13, Parent = c })
	texto({ Size = UDim2.new(1, -170, 0, 24), Position = UDim2.new(0, 16, 0, 40), Text = T("efeito_" .. tipo),
		TextColor3 = COR.suave, Contorno = false, TextXAlignment = Enum.TextXAlignment.Left,
		TamanhoMax = 15, ZIndex = 13, Parent = c })
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
	linhasMelhoria[tipo] = { titulo = titulo, corpo = corpo, rotulo = rotulo }
end

-- Painel: Loja (Robux) ------------------------------------------------------------------
local precos = {}
local function textoPreco(item)
	return UI.ROBUX .. " " .. tostring(precos[item.id] or item.preco)
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
local function visivel(item)
	return item.id ~= 0 or noStudio
end

local painelLoja = painel("Loja", T("titulo_loja"), COR.loja)
linhaInfo(painelLoja.conteudo, 0, "loja_info")
local cartoesPasse = {}
local CORES_PASSE = { xp2 = COR.xp, moedas2 = COR.moedas, vip = COR.loja, aura = COR.elementos }
local ICONES_PASSE = { xp2 = "⚡", moedas2 = "💰", vip = "👑", aura = "✨" }
for i, passe in ipairs(Config.LOJA.PASSES) do
	carregarPreco(passe, Enum.InfoType.GamePass)
	if visivel(passe) then
		local c = cartao(painelLoja.conteudo, i, 82, CORES_PASSE[passe.chave])
		texto({ Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
			Text = ICONES_PASSE[passe.chave], Contorno = false, ZIndex = 13, Parent = c })
		texto({ Size = UDim2.new(1, -210, 0, 28), Position = UDim2.new(0, 70, 0, 8), Text = T("passe_" .. passe.chave),
			TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 23, ZIndex = 13, Parent = c })
		texto({ Size = UDim2.new(1, -210, 0, 34), Position = UDim2.new(0, 70, 0, 38), Text = T("desc_" .. passe.chave),
			TextColor3 = COR.painel, Contorno = false, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
			TamanhoMax = 15, ZIndex = 13, Parent = c })
		local b, corpo, rotulo = botao(c, {
			tamanho = UDim2.new(0, 112, 0, 46),
			posicao = UDim2.new(1, -124, 0.5, -2),
			ancora = Vector2.new(0, 0.5),
			cor = COR.verde,
			texto = textoPreco(passe),
			fonte = Enum.Font.BuilderSansBold,
			aoClicar = function()
				if passe.id ~= 0 and not jogador:GetAttribute("Passe_" .. passe.chave) then
					MarketplaceService:PromptGamePassPurchase(jogador, passe.id)
				end
			end,
		})
		b.ZIndex = 13
		cartoesPasse[passe.chave] = { corpo = corpo, rotulo = rotulo, passe = passe }
	end
end
local gradePacotes = novo("Frame", {
	LayoutOrder = 20,
	Size = UDim2.new(1, 0, 0, 150),
	BackgroundTransparency = 1,
	ZIndex = 12,
	Parent = painelLoja.conteudo,
}, { novo("UIGridLayout", { CellSize = UDim2.new(0.32, 0, 0, 150), CellPadding = UDim2.new(0.02, 0, 0, 0), SortOrder = Enum.SortOrder.LayoutOrder }) })
for i, pacote in ipairs(Config.LOJA.PACOTES) do
	carregarPreco(pacote, Enum.InfoType.Product)
	if visivel(pacote) then
		local c = novo("Frame", { LayoutOrder = i, BackgroundColor3 = Color3.fromRGB(150, 110, 20), ZIndex = 12, Parent = gradePacotes },
			{ cantos(16), borda(3) })
		texto({ Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0, 8), Text = string.rep("💰", i),
			Contorno = false, ZIndex = 13, Parent = c })
		texto({ Size = UDim2.new(1, -12, 0, 24), Position = UDim2.new(0, 6, 0, 44), Text = T("pacote_" .. pacote.chave),
			TamanhoMax = 20, ZIndex = 13, Parent = c })
		texto({ Size = UDim2.new(1, -12, 0, 22), Position = UDim2.new(0, 6, 0, 70), Text = N(pacote.moedas),
			TextColor3 = COR.moedas, TamanhoMax = 20, ZIndex = 13, Parent = c })
		local b = botao(c, {
			tamanho = UDim2.new(1, -20, 0, 42),
			posicao = UDim2.new(0, 10, 1, -52),
			cor = COR.verde,
			texto = textoPreco(pacote),
			fonte = Enum.Font.BuilderSansBold,
			aoClicar = function()
				if pacote.id ~= 0 then
					MarketplaceService:PromptProductPurchase(jogador, pacote.id)
				end
			end,
		})
		b.ZIndex = 13
	end
end
if visivel(Config.LOJA.ANUNCIO) then
	local c = cartao(painelLoja.conteudo, 21, 76, Color3.fromRGB(15, 118, 110))
	texto({ Size = UDim2.new(0, 46, 0, 46), Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
		Text = "📺", Contorno = false, ZIndex = 13, Parent = c })
	texto({ Size = UDim2.new(1, -190, 0, 26), Position = UDim2.new(0, 66, 0, 10), Text = T("anuncio_titulo"),
		TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 21, ZIndex = 13, Parent = c })
	texto({ Size = UDim2.new(1, -190, 0, 30), Position = UDim2.new(0, 66, 0, 36),
		Text = T("anuncio_desc", Config.LOJA.ANUNCIO.minutos), TextColor3 = Color3.fromRGB(204, 251, 241),
		Contorno = false, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 14, ZIndex = 13, Parent = c })
	local b = botao(c, {
		tamanho = UDim2.new(0, 104, 0, 44),
		posicao = UDim2.new(1, -116, 0.5, -2),
		ancora = Vector2.new(0, 0.5),
		cor = COR.branco,
		texto = T("assistir"),
		aoClicar = function()
			Remotos.VerAnuncio:FireServer()
		end,
	})
	b.ZIndex = 13
	b.Corpo.Rotulo.TextColor3 = Color3.fromRGB(15, 118, 110)
end

-- auras dentro da loja
local tituloAuras = texto({
	LayoutOrder = 30,
	Size = UDim2.new(1, 0, 0, 30),
	Text = T("titulo_auras"),
	Font = UI.TITULO,
	TextColor3 = COR.elementos,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
	Parent = painelLoja.conteudo,
})
local gradeAuras = novo("Frame", {
	LayoutOrder = 31,
	Size = UDim2.new(1, 0, 0, 64),
	BackgroundTransparency = 1,
	ZIndex = 12,
	Parent = painelLoja.conteudo,
}, { novo("UIGridLayout", { CellSize = UDim2.new(0.155, 0, 0, 64), CellPadding = UDim2.new(0.014, 0, 0, 0), SortOrder = Enum.SortOrder.LayoutOrder }) })
local botoesAura = {}
for i, aura in ipairs(Config.Auras) do
	local _, corpo, rotulo = botao(gradeAuras, {
		nome = aura.id,
		ordem = i,
		tamanho = UDim2.new(1, 0, 1, 0),
		cor = aura.cor,
		texto = Config.nomeDe(aura, idioma),
		tamanhoTexto = 14,
		aoClicar = function()
			Remotos.Aura:FireServer(aura.id)
		end,
	})
	corpo.ZIndex = 13
	botoesAura[aura.id] = { corpo = corpo, rotulo = rotulo, aura = aura }
end
_ = tituloAuras

-- Painel: Missões -------------------------------------------------------------------
local painelMissoes = painel("Missoes", T("titulo_missoes"), COR.missoes)
local rotuloNovas = linhaInfo(painelMissoes.conteudo, 0, "novas_em")
local linhasMissao = {}
for i = 1, Config.MISSOES_POR_DIA do
	local c = cartao(painelMissoes.conteudo, i, 80)
	local titulo = texto({ Size = UDim2.new(1, -160, 0, 26), Position = UDim2.new(0, 16, 0, 8),
		TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 20, ZIndex = 13, Parent = c })
	local premio = texto({ Size = UDim2.new(1, -160, 0, 18), Position = UDim2.new(0, 16, 0, 34),
		TextColor3 = COR.moedas, TextXAlignment = Enum.TextXAlignment.Left, TamanhoMax = 15, ZIndex = 13, Parent = c })
	local _, cheio = UI.barra(c, {
		nome = "Progresso",
		tamanho = UDim2.new(1, -160, 0, 12),
		posicao = UDim2.new(0, 16, 0, 58),
		cor = COR.missoes,
		zIndex = 13,
		raio = 6,
	})
	local b, corpo, rotulo = botao(c, {
		tamanho = UDim2.new(0, 124, 0, 44),
		posicao = UDim2.new(1, -136, 0.5, -2),
		ancora = Vector2.new(0, 0.5),
		cor = COR.verde,
		texto = T("pegar"),
		aoClicar = function()
			Remotos.PegarMissao:FireServer(i)
		end,
	})
	b.ZIndex = 13
	linhasMissao[i] = { titulo = titulo, premio = premio, barra = cheio, corpo = corpo, rotulo = rotulo }
end

-- Painel: Prêmio diário ---------------------------------------------------------------
local painelDiario = painel("Diario", T("titulo_diario"), COR.premio)
linhaInfo(painelDiario.conteudo, 0, "diario_info")
local gradeDias = novo("Frame", {
	LayoutOrder = 1,
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	ZIndex = 12,
	Parent = painelDiario.conteudo,
}, { novo("UIGridLayout", { CellSize = UDim2.new(0.235, 0, 0, 100), CellPadding = UDim2.new(0.02, 0, 0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })

local function descricaoPremio(premio)
	if premio.tipo == "moedas" then
		return T("premio_moedas", N(premio.valor))
	elseif premio.tipo == "xp" then
		local nivel = jogador:GetAttribute("Nivel") or 1
		return T("premio_xp", N(math.floor(Config.xpDoNivel(nivel) * premio.nivelFracao)))
	elseif premio.tipo == "xp2" then
		return T("premio_xp2", premio.minutos)
	end
	return ""
end

local cartasDias = {}
for dia, premio in ipairs(Config.PREMIO_DIARIO) do
	local ultimo = dia == #Config.PREMIO_DIARIO
	local c = novo("Frame", { LayoutOrder = dia, BackgroundColor3 = ultimo and Color3.fromRGB(124, 45, 18) or COR.cartao,
		ZIndex = 13, Parent = gradeDias }, { cantos(14), borda(3, ultimo and COR.moedas or COR.contorno) })
	texto({ Size = UDim2.new(1, -8, 0, 20), Position = UDim2.new(0, 4, 0, 6), Text = T("dia", dia), TamanhoMax = 16, ZIndex = 14, Parent = c })
	local rotuloPremio = texto({ Size = UDim2.new(1, -8, 0, 34), Position = UDim2.new(0, 4, 0, 26), Text = "",
		TextColor3 = ultimo and COR.moedas or COR.branco, TextWrapped = true, TamanhoMax = 15, ZIndex = 14, Parent = c })
	local b, corpo, rotulo = botao(c, {
		tamanho = UDim2.new(1, -14, 0, 30),
		posicao = UDim2.new(0, 7, 1, -38),
		cor = COR.verde,
		texto = T("pegar"),
		tamanhoTexto = 15,
		raio = 10,
		aoClicar = function()
			Remotos.PegarDiario:FireServer()
		end,
	})
	b.ZIndex = 14
	cartasDias[dia] = { frame = c, premio = rotuloPremio, botao = b, corpo = corpo, rotulo = rotulo, def = premio }
end

-- Botões do menu -----------------------------------------------------------------------
botaoMenu("menu_elementos", "✨", COR.elementos, 1, function()
	abrir("Elementos")
end)
botaoMenu("menu_melhorar", "⬆️", COR.melhorar, 2, function()
	abrir("Melhorar")
end)
botaoMenu("menu_loja", "🛒", COR.loja, 3, function()
	abrir("Loja")
end)
botaoMenu("menu_missoes", "📋", COR.missoes, 4, function()
	abrir("Missoes")
end)
botaoMenu("menu_premio", "🎁", COR.premio, 5, function()
	abrir("Diario")
end)
if visivel(Config.LOJA.ANUNCIO) then
	botaoMenu("menu_gratis", "📺", COR.anuncio, 6, function()
		Remotos.VerAnuncio:FireServer()
	end)
end
if noStudio then
	local teste = Remotos:WaitForChild("Teste")
	botao(coluna, { nome = "teste_xp", ordem = 10, cor = COR.cinza, texto = T("teste_mais"), tamanhoTexto = 15,
		aoClicar = function()
			teste:FireServer("xp")
		end })
	botao(coluna, { nome = "teste_dia", ordem = 11, cor = COR.cinza, texto = T("teste_dia"), tamanhoTexto = 15,
		aoClicar = function()
			teste:FireServer("dia")
		end })
end

-- Desenho ---------------------------------------------------------------------------------
local function temElemento(id)
	local lista = jogador:GetAttribute("Elementos") or ""
	return string.find("," .. lista .. ",", "," .. id .. ",", 1, true) ~= nil
end

local function atualizarElementos()
	local equipado = jogador:GetAttribute("Equipado")
	local nivel = jogador:GetAttribute("Nivel") or 1
	local moedas = jogador:GetAttribute("Moedas") or 0
	for id, info in pairs(cartoesElemento) do
		local elemento = info.elemento
		if equipado == id then
			info.rotulo.Text = T("equipado")
			info.corpo.BackgroundColor3 = COR.cinza
		elseif temElemento(id) then
			info.rotulo.Text = T("equipar")
			info.corpo.BackgroundColor3 = COR.verde
		elseif nivel < elemento.nivel then
			info.rotulo.Text = T("precisa_nivel", elemento.nivel)
			info.corpo.BackgroundColor3 = COR.cinza
		else
			info.rotulo.Text = N(elemento.custo)
			info.corpo.BackgroundColor3 = moedas >= elemento.custo and COR.loja or COR.cinza
		end
	end
end

local function atualizarMelhorias()
	local moedas = jogador:GetAttribute("Moedas") or 0
	for tipo, linha in pairs(linhasMelhoria) do
		local nivel = jogador:GetAttribute("Melhoria_" .. tipo) or 0
		local maximo = Config.MELHORIAS[tipo].max
		linha.titulo.Text = T("melhoria_" .. tipo) .. "  ·  " .. nivel .. "/" .. maximo
		local custo = Config.custoMelhoria(tipo, nivel)
		if custo then
			linha.rotulo.Text = N(custo)
			linha.corpo.BackgroundColor3 = moedas >= custo and COR.verde or COR.cinza
		else
			linha.rotulo.Text = T("maximo")
			linha.corpo.BackgroundColor3 = COR.loja
		end
	end
end

local function atualizarLoja()
	for chave, info in pairs(cartoesPasse) do
		if jogador:GetAttribute("Passe_" .. chave) then
			info.rotulo.Text = T("comprado")
			info.corpo.BackgroundColor3 = COR.cinza
		else
			info.rotulo.Text = textoPreco(info.passe)
			info.corpo.BackgroundColor3 = COR.verde
		end
	end
	local auraAtual = jogador:GetAttribute("Aura")
	local temVip = jogador:GetAttribute("Passe_vip")
	local temPacote = jogador:GetAttribute("Passe_aura")
	for id, info in pairs(botoesAura) do
		local aura = info.aura
		local liberada = not aura.vip and not aura.passe
		if aura.vip and temVip then
			liberada = true
		end
		if aura.passe and (temPacote or temVip) then
			liberada = true
		end
		info.corpo.BackgroundColor3 = liberada and aura.cor or COR.cinza
		info.rotulo.Text = (auraAtual == id and "✔ " or "") .. Config.nomeDe(aura, idioma)
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
			linha.titulo.Text = T("missao_" .. missao.tipo, missao.meta)
			linha.premio.Text = "+ " .. descricaoPremio(missao.premio)
			linha.barra.Size = UDim2.fromScale(math.clamp(progresso / missao.meta, 0, 1), 1)
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
		c.frame.BackgroundTransparency = (dia < diaAtual or (hoje and not pronto)) and 0.45 or 0
	end
	local b = botoesMenu.menu_premio
	if b then
		b.selo.Visible = pronto
		b.selo.Text = "!"
		b.selo.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
	end
end

local nivelMostrado = 0
function atualizarTudo()
	local nivel = jogador:GetAttribute("Nivel") or 1
	local xp = jogador:GetAttribute("XP") or 0
	local xpDoNivel = jogador:GetAttribute("XPDoNivel") or 1
	local moedas = jogador:GetAttribute("Moedas") or 0

	rotuloNivel.Text = tostring(nivel)
	if nivel > nivelMostrado then
		if nivelMostrado > 0 then
			UI.pulo(medalha, 1.4)
		end
		nivelMostrado = nivel
	end
	if nivel >= Config.NIVEL_MAXIMO then
		barraXP.Size = UDim2.fromScale(1, 1)
		textoXP.Text = T("nivel_maximo")
	else
		barraXP.Size = UDim2.fromScale(math.clamp(xp / xpDoNivel, 0, 1), 1)
		textoXP.Text = N(xp) .. " / " .. N(xpDoNivel)
	end
	rotuloMoedas.Text = N(moedas)

	atualizarElementos()
	atualizarMelhorias()
	atualizarLoja()
	atualizarMissoes()
	atualizarDiario()
end

local function atualizarVida()
	local personagem = jogador.Character
	local humanoid = personagem and personagem:FindFirstChildOfClass("Humanoid")
	local maxima = jogador:GetAttribute("VidaMaxima") or 100
	local atual = humanoid and humanoid.Health or 0
	local fracao = math.clamp(atual / math.max(1, maxima), 0, 1)
	barraVida.Size = UDim2.fromScale(fracao, 1)
	barraVida.BackgroundColor3 = fracao > 0.3 and COR.vida or COR.vidaBaixa
	textoVida.Text = math.floor(atual) .. " / " .. math.floor(maxima)
end

local function ligarVida()
	local personagem = jogador.Character
	local humanoid = personagem and personagem:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.HealthChanged:Connect(atualizarVida)
		atualizarVida()
	end
end
jogador.CharacterAdded:Connect(function()
	task.wait(0.2)
	ligarVida()
end)
ligarVida()

local function atualizarContagens()
	local instante = workspace:GetServerTimeNow()
	local zonaId = jogador:GetAttribute("Zona") or "vila"
	local zona = Config.ZonaPorId[zonaId]
	local pvp = jogador:GetAttribute("ZonaPvp") == true
	if zona then
		textoZona.Text = (pvp and "⚔️ " or "🛡️ ") .. Config.nomeDe(zona, idioma) .. " · " .. T(pvp and "zona_pvp" or "zona_segura")
		faixaZona.BackgroundColor3 = pvp and COR.pvp or COR.segura
	end

	local xp2Ate = jogador:GetAttribute("XP2Ate") or 0
	faixaXP2.Visible = xp2Ate > instante
	if faixaXP2.Visible then
		textoXP2.Text = "⚡ " .. T("xp2_ativo", Format.tempo(xp2Ate - instante))
	end

	local morto = jogador:GetAttribute("Morto") == true
	morte.Visible = morto
	if morto then
		textoVoltando.Text = T("morreu_voltando", Config.RESPAWN .. "s")
	end

	local proximoDia = ((jogador:GetAttribute("MissoesDia") or 0) + 1) * 86400
	rotuloNovas.Text = T("novas_em", Format.tempo(proximoDia - instante))
end

jogador.AttributeChanged:Connect(atualizarTudo)
atualizarTudo()

UI.acompanharTela(function(largura)
	local compacto = largura < 900 or UI.noCelular()
	layoutMenu.CellSize = compacto and UDim2.new(0, 58, 0, 58) or UDim2.new(0, 132, 0, 44)
	coluna.Size = compacto and UDim2.new(0, 124, 0, 0) or UDim2.new(0, 132, 0, 0)
	for _, b in pairs(botoesMenu) do
		if compacto then
			b.icone.Size = UDim2.new(1, 0, 0.6, 0)
			b.icone.Position = UDim2.new(0, 0, 0, 2)
			b.nome.Size = UDim2.new(1, -4, 0.32, 0)
			b.nome.Position = UDim2.new(0, 2, 0.64, 0)
		else
			b.icone.Size = UDim2.new(0, 32, 1, -10)
			b.icone.Position = UDim2.new(0, 8, 0, 5)
			b.nome.Size = UDim2.new(1, -50, 1, -14)
			b.nome.Position = UDim2.new(0, 44, 0, 7)
		end
	end
end)

while true do
	atualizarContagens()
	atualizarVida()
	task.wait(0.25)
end
