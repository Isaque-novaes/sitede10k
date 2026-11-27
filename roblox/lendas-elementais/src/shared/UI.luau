--[[
	Peças de interface usadas pelas telas do jogador: botões com "degrau",
	cantos arredondados, contorno no texto e o controle de tamanho.

	A interface encolhe junto com a tela. Se quiser mudar o tamanho de
	tudo, mexa em UI.ESCALA_DA_TELA (0.8 menor, 1.2 maior).
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UI = {}

UI.ESCALA_DA_TELA = 1

UI.COR = {
	painel = Color3.fromRGB(20, 23, 43),
	contorno = Color3.fromRGB(10, 12, 24),
	cartao = Color3.fromRGB(42, 46, 69),
	branco = Color3.new(1, 1, 1),
	suave = Color3.fromRGB(201, 206, 230),
	moedas = Color3.fromRGB(255, 208, 70),
	xp = Color3.fromRGB(120, 200, 255),
	vida = Color3.fromRGB(80, 220, 110),
	vidaBaixa = Color3.fromRGB(240, 70, 70),
	verde = Color3.fromRGB(34, 197, 94),
	cinza = Color3.fromRGB(107, 112, 144),
	loja = Color3.fromRGB(255, 176, 32),
	elementos = Color3.fromRGB(190, 90, 255),
	melhorar = Color3.fromRGB(34, 197, 94),
	missoes = Color3.fromRGB(255, 138, 31),
	premio = Color3.fromRGB(255, 77, 109),
	anuncio = Color3.fromRGB(20, 184, 166),
	segura = Color3.fromRGB(45, 140, 230),
	pvp = Color3.fromRGB(232, 69, 91),
}

UI.AVISO = {
	bom = Color3.fromRGB(34, 181, 115),
	ruim = Color3.fromRGB(232, 69, 91),
	alerta = Color3.fromRGB(255, 122, 26),
	info = Color3.fromRGB(61, 120, 220),
}

UI.TITULO = Enum.Font.LuckiestGuy
UI.FONTE = Enum.Font.FredokaOne
UI.ROBUX = utf8.char(0xE002)

UI.ANIM = {
	rapido = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	mola = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	suave = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

-- Tamanho dos painéis antes de caber na tela
UI.LARGURA_PAINEL, UI.ALTURA_PAINEL = 580, 430

local escalas = {}
local escalasPainel = {}
UI.escalaAtual = 1
UI.escalaPainel = 1

function UI.novo(classe, props, filhos)
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

function UI.cantos(raio)
	return UI.novo("UICorner", { CornerRadius = UDim.new(0, raio or 14) })
end

function UI.borda(espessura, cor)
	return UI.novo("UIStroke", {
		Color = cor or UI.COR.contorno,
		Thickness = espessura or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function UI.contornoTexto(espessura)
	return UI.novo("UIStroke", { Color = UI.COR.contorno, Thickness = espessura or 2 })
end

-- texto({ ... }): aceita Contorno = false/espessura e TamanhoMax = px
function UI.texto(props)
	local base = {
		BackgroundTransparency = 1,
		Font = UI.FONTE,
		TextColor3 = UI.COR.branco,
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
		table.insert(filhos, UI.contornoTexto(contorno or 2))
	end
	if maximo then
		table.insert(filhos, UI.novo("UITextSizeConstraint", { MaxTextSize = maximo }))
	end
	return UI.novo("TextLabel", base, filhos)
end

-- Botão grosso com degrau embaixo e animação de apertar
function UI.botao(pai, opcoes)
	local caixa = UI.novo("Frame", {
		Name = opcoes.nome or "Botao",
		LayoutOrder = opcoes.ordem or 1,
		Size = opcoes.tamanho or UDim2.new(1, 0, 0, 46),
		Position = opcoes.posicao or UDim2.new(),
		AnchorPoint = opcoes.ancora or Vector2.new(),
		BackgroundTransparency = 1,
		Parent = pai,
	})
	local escala = UI.novo("UIScale", { Parent = caixa })
	UI.novo("Frame", {
		Name = "Degrau",
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 4),
		BackgroundColor3 = UI.COR.contorno,
		Parent = caixa,
	}, { UI.cantos(opcoes.raio or 13) })
	local corpo = UI.novo("TextButton", {
		Name = "Corpo",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = opcoes.cor or UI.COR.verde,
		AutoButtonColor = false,
		Text = "",
		Parent = caixa,
	}, { UI.cantos(opcoes.raio or 13), UI.borda(3) })
	local rotulo = UI.texto({
		Name = "Rotulo",
		Size = UDim2.new(1, -14, 1, -10),
		Position = UDim2.new(0, 7, 0, 5),
		Text = opcoes.texto or "",
		Font = opcoes.fonte or UI.FONTE,
		TamanhoMax = opcoes.tamanhoTexto or 21,
		Parent = corpo,
	})
	corpo.MouseButton1Down:Connect(function()
		TweenService:Create(escala, UI.ANIM.rapido, { Scale = 0.92 }):Play()
	end)
	local function soltar()
		TweenService:Create(escala, UI.ANIM.mola, { Scale = 1 }):Play()
	end
	corpo.MouseButton1Up:Connect(soltar)
	corpo.MouseLeave:Connect(soltar)
	if opcoes.aoClicar then
		corpo.Activated:Connect(opcoes.aoClicar)
	end
	return caixa, corpo, rotulo
end

function UI.pulo(objeto, forca)
	local escala = objeto:FindFirstChildOfClass("UIScale") or UI.novo("UIScale", { Parent = objeto })
	escala.Scale = forca or 1.15
	TweenService:Create(escala, UI.ANIM.mola, { Scale = 1 }):Play()
end

-- Barra com preenchimento (vida, XP, recarga)
function UI.barra(pai, props)
	local fundo = UI.novo("Frame", {
		Name = props.nome or "Barra",
		Size = props.tamanho,
		Position = props.posicao,
		AnchorPoint = props.ancora or Vector2.new(),
		BackgroundColor3 = UI.COR.contorno,
		LayoutOrder = props.ordem or 1,
		ZIndex = props.zIndex or 1,
		Parent = pai,
	}, { UI.cantos(props.raio or 8), UI.borda(2) })
	local cheio = UI.novo("Frame", {
		Name = "Cheio",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = props.cor or UI.COR.vida,
		BorderSizePixel = 0,
		ZIndex = (props.zIndex or 1) + 1,
		Parent = fundo,
	}, { UI.cantos(props.raio or 8) })
	local rotulo = UI.texto({
		Name = "Texto",
		Size = UDim2.fromScale(1, 1),
		TamanhoMax = props.tamanhoTexto or 15,
		Contorno = 1.5,
		ZIndex = (props.zIndex or 1) + 2,
		Parent = fundo,
	})
	return fundo, cheio, rotulo
end

-- Escala ----------------------------------------------------------------------
-- ehPainel: janelas do meio encolhem só o necessário para caber inteiras.
function UI.escalavel(objeto, ehPainel)
	local escala = UI.novo("UIScale", {
		Scale = ehPainel and UI.escalaPainel or UI.escalaAtual,
		Parent = objeto,
	})
	table.insert(ehPainel and escalasPainel or escalas, escala)
	return escala
end

function UI.ajustarEscala(largura, altura)
	local minimo = UserInputService.TouchEnabled and 0.8 or 0.6
	local alvo = math.clamp(math.min(largura / 1100, altura / 620), minimo, 1.1) * UI.ESCALA_DA_TELA
	if math.abs(alvo - UI.escalaAtual) > 0.005 then
		UI.escalaAtual = alvo
		for _, escala in ipairs(escalas) do
			escala.Scale = alvo
		end
	end

	local cabe = math.min(largura * 0.94 / UI.LARGURA_PAINEL, altura * 0.88 / UI.ALTURA_PAINEL)
	local alvoPainel = math.clamp(math.min(cabe, 1.1 * UI.ESCALA_DA_TELA), 0.35, 1.3)
	if math.abs(alvoPainel - UI.escalaPainel) > 0.005 then
		UI.escalaPainel = alvoPainel
		for _, escala in ipairs(escalasPainel) do
			escala.Scale = alvoPainel
		end
	end
end

-- Chamado pelas telas: acompanha o tamanho da janela
function UI.acompanharTela(aoMudar)
	local function atualizar()
		local camera = workspace.CurrentCamera
		local tamanho = camera and camera.ViewportSize or Vector2.new(1280, 720)
		UI.ajustarEscala(tamanho.X, tamanho.Y)
		if aoMudar then
			aoMudar(tamanho.X, tamanho.Y)
		end
	end
	atualizar()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(atualizar)
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local camera = workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(atualizar)
			atualizar()
		end
	end)
	return atualizar
end

function UI.noCelular()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

return UI
