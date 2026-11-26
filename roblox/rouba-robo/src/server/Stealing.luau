--[[
	Roubo, venda e o Tapa.

	Como funciona o roubo:
	  1. O ladrão entra numa base destrancada e segura E num robô.
	  2. O robô vai para cima da cabeça dele e ele fica mais lento.
	  3. Se chegar na PRÓPRIA base, o robô passa a ser dele.
	  4. Se levar um tapa, morrer, sair do jogo ou demorar demais,
	     o robô volta voando para o dono.
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Game = require(script.Parent:WaitForChild("Game"))
local MapBuilder = require(script.Parent:WaitForChild("MapBuilder"))

local Stealing = {}

local ladroes = {} -- [estadoDoLadrao] = true

local function partesDo(robo)
	local partes = {}
	for _, item in ipairs(robo.modelo:GetDescendants()) do
		if item:IsA("BasePart") then
			table.insert(partes, item)
		end
	end
	return partes
end

local function nomeDo(robo)
	return Game.nomeRobo(robo.def, robo.mut)
end

-- Venda ------------------------------------------------------------------------

function Stealing.vender(estado, robo)
	local valor = Game.valorVenda(robo)
	local nome = nomeDo(robo)
	Game.destruirRobo(robo)
	Game.adicionarDinheiro(estado, valor)
	Game.atualizarAtributos(estado)
	Game.notificar(estado.player, "info", "vendeu", nome, Game.dinheiroTexto(valor))
	Game.emitir(estado, "vender", 1)
end

-- Roubo ------------------------------------------------------------------------

function Stealing.roubar(ladrao, robo)
	local dono = robo.dono
	local player = ladrao.player
	local raiz, humanoid = Game.raizDe(player)
	if not raiz or not dono then
		return
	end
	if ladrao.carregando then
		Game.notificar(player, "ruim", "ja_carregando")
		return
	end
	if Game.trancada(dono) then
		Game.notificar(player, "ruim", "base_trancada_roubo")
		return
	end
	if not MapBuilder.dentroDaBase(dono.base, raiz.Position, 2) then
		return
	end
	if not Game.vagaLivre(ladrao) then
		Game.notificar(player, "ruim", "base_cheia_roubo")
		return
	end

	robo.estado = "carregado"
	robo.ladrao = ladrao
	robo.inicioRoubo = os.clock()
	robo.voo = robo.voo + 1
	robo.prompt.Enabled = false
	ladrao.carregando = robo
	ladroes[ladrao] = true

	-- prende o robô em cima da cabeça do ladrão
	local partes = partesDo(robo)
	local raizRobo = robo.visual.raiz
	robo.modelo:PivotTo(raiz.CFrame * CFrame.new(0, 3.2, 0))
	local soldas = Instance.new("Folder")
	soldas.Name = "Soldas"
	for _, parte in ipairs(partes) do
		if parte ~= raizRobo then
			local solda = Instance.new("WeldConstraint")
			solda.Part0 = raizRobo
			solda.Part1 = parte
			solda.Parent = soldas
		end
	end
	local soldaNaCabeca = Instance.new("WeldConstraint")
	soldaNaCabeca.Part0 = raiz
	soldaNaCabeca.Part1 = raizRobo
	soldaNaCabeca.Parent = soldas
	soldas.Parent = robo.modelo
	for _, parte in ipairs(partes) do
		parte.Massless = true
		parte.Anchored = false
	end

	humanoid.WalkSpeed = Config.ROUBO.VELOCIDADE_CARREGANDO
	player:SetAttribute("Carregando", robo.def.id)
	player:SetAttribute("CarregandoMut", robo.mut or "")
	robo.conexaoMorte = humanoid.Died:Connect(function()
		Stealing.falhar(ladrao, "caiu")
	end)

	Game.notificar(player, "bom", "pegou", nomeDo(robo))
	Game.notificar(dono.player, "alerta", "alerta_roubo", player.DisplayName, nomeDo(robo))
	Game.remotos.Efeito:FireClient(dono.player, "alarme", dono.base.barreira.Position, Color3.fromRGB(255, 59, 59))
end

-- Solta o robô da cabeça do ladrão (não decide para onde ele vai).
function Stealing.desprender(robo)
	if robo.conexaoMorte then
		robo.conexaoMorte:Disconnect()
		robo.conexaoMorte = nil
	end
	for _, parte in ipairs(partesDo(robo)) do
		parte.Anchored = true
		parte.Massless = false
	end
	local soldas = robo.modelo:FindFirstChild("Soldas")
	if soldas then
		soldas:Destroy()
	end

	local ladrao = robo.ladrao
	if ladrao then
		ladrao.carregando = nil
		ladroes[ladrao] = nil
		ladrao.player:SetAttribute("Carregando", nil)
		ladrao.player:SetAttribute("CarregandoMut", nil)
		local _, humanoid = Game.raizDe(ladrao.player)
		if humanoid then
			humanoid.WalkSpeed = Config.ROUBO.VELOCIDADE_NORMAL
		end
	end
	robo.ladrao = nil
	if robo.estado == "carregado" then
		robo.estado = "solto"
	end
end

-- O roubo deu errado: o robô volta para o dono. motivo = chave de texto (ou nil)
function Stealing.falhar(ladrao, motivo, ...)
	local robo = ladrao.carregando
	if not robo then
		return
	end
	Stealing.desprender(robo)

	local dono = robo.dono
	if dono and not dono.saindo and robo.vaga and dono.vagas[robo.vaga] == robo then
		Game.colocarNaBase(dono, robo, robo.vaga, false)
		Game.notificar(dono.player, "bom", "voltou_base", nomeDo(robo))
	else
		Game.destruirRobo(robo)
	end
	if motivo then
		Game.notificar(ladrao.player, "ruim", motivo, ...)
	end
end

-- O ladrão chegou na própria base.
function Stealing.entregar(ladrao)
	local robo = ladrao.carregando
	if not robo then
		return
	end
	local vaga = Game.vagaLivre(ladrao)
	if not vaga then
		Stealing.falhar(ladrao, "base_cheia_entrega")
		return
	end
	local dono = robo.dono
	local nome = nomeDo(robo)
	Stealing.desprender(robo)
	Game.tirarDaBase(robo)
	Game.colocarNaBase(ladrao, robo, vaga, false)

	Game.notificar(ladrao.player, "bom", "roubou", nome)
	Game.emitir(ladrao, "roubar", 1)
	if dono then
		Game.notificar(dono.player, "ruim", "foi_roubado", ladrao.player.DisplayName, nome)
	end
end

function Stealing.vigiar()
	for ladrao in pairs(ladroes) do
		local robo = ladrao.carregando
		if not robo then
			ladroes[ladrao] = nil
		else
			local raiz = Game.raizDe(ladrao.player)
			if not raiz then
				Stealing.falhar(ladrao, "caiu")
			elseif os.clock() - robo.inicioRoubo > Config.ROUBO.TEMPO_MAXIMO then
				Stealing.falhar(ladrao, "demorou")
			elseif MapBuilder.dentroDaBase(ladrao.base, raiz.Position, -1) then
				Stealing.entregar(ladrao)
			end
		end
	end
end

-- Tapa -------------------------------------------------------------------------

function Stealing.darTapa(player)
	local mochila = player:FindFirstChildOfClass("Backpack")
	local personagem = player.Character
	if not mochila then
		return
	end
	if mochila:FindFirstChild("Tapa") or (personagem and personagem:FindFirstChild("Tapa")) then
		return
	end

	local ferramenta = Instance.new("Tool")
	ferramenta.Name = "Tapa"
	ferramenta.ToolTip = "Slap! / Tapa!"
	ferramenta.CanBeDropped = false
	ferramenta.RequiresHandle = true

	local mao = Instance.new("Part")
	mao.Name = "Handle"
	mao.Shape = Enum.PartType.Ball
	mao.Size = Vector3.new(1.3, 1.3, 1.3)
	mao.Color = Color3.fromRGB(230, 50, 50)
	mao.Material = Enum.Material.SmoothPlastic
	mao.CanCollide = false
	mao.Massless = true
	mao.Parent = ferramenta

	ferramenta.Activated:Connect(function()
		Stealing.tapa(player)
	end)
	ferramenta.Parent = mochila
end

local function efeitoDeTapa(posicao)
	local estouro = Instance.new("Part")
	estouro.Name = "Pa"
	estouro.Shape = Enum.PartType.Ball
	estouro.Size = Vector3.new(3, 3, 3)
	estouro.CFrame = CFrame.new(posicao)
	estouro.Anchored = true
	estouro.CanCollide = false
	estouro.CanTouch = false
	estouro.CanQuery = false
	estouro.Material = Enum.Material.Neon
	estouro.Color = Color3.fromRGB(255, 255, 200)
	estouro.Transparency = 0.3
	estouro.Parent = workspace
	Debris:AddItem(estouro, 0.2)
end

function Stealing.tapa(player)
	local estado = Game.estados[player]
	if not estado then
		return
	end
	local instante = os.clock()
	if instante - estado.ultimoTapa < Config.TAPA.RECARGA then
		return
	end
	estado.ultimoTapa = instante

	local raiz = Game.raizDe(player)
	if not raiz then
		return
	end

	local alvo, raizAlvo, melhor = nil, nil, math.huge
	for outroPlayer, outro in pairs(Game.estados) do
		if outro ~= estado then
			local outraRaiz = Game.raizDe(outroPlayer)
			if outraRaiz then
				local delta = outraRaiz.Position - raiz.Position
				local distancia = delta.Magnitude
				if distancia <= Config.TAPA.ALCANCE and distancia < melhor then
					if distancia < 3 or raiz.CFrame.LookVector:Dot(delta.Unit) > 0.2 then
						alvo, raizAlvo, melhor = outro, outraRaiz, distancia
					end
				end
			end
		end
	end
	if not alvo then
		return
	end

	local direcao = (raizAlvo.Position - raiz.Position) * Vector3.new(1, 0, 1)
	if direcao.Magnitude < 0.1 then
		direcao = raiz.CFrame.LookVector
	end
	direcao = direcao.Unit
	local forca = Config.TAPA.FORCA + Config.TAPA.FORCA_POR_NIVEL * estado.melhorias.tapa
	Game.remotos.Empurrao:FireClient(alvo.player, direcao * forca)
	efeitoDeTapa(raizAlvo.Position)
	Game.efeito("tapa", raizAlvo.Position, Color3.fromRGB(255, 255, 200))

	if alvo.carregando then
		local nome = nomeDo(alvo.carregando)
		Stealing.falhar(alvo, "tapa_soltou", player.DisplayName)
		Game.notificar(player, "bom", "tapa_acertou", alvo.player.DisplayName, nome)
		Game.emitir(estado, "tapaLadrao", 1)
	end
end

-- Liga tudo ------------------------------------------------------------------

function Stealing.iniciar()
	Game.acoes.base = function(robo, player)
		local estado = Game.estados[player]
		if not estado or robo.estado ~= "base" then
			return
		end
		if robo.dono == estado then
			Stealing.vender(estado, robo)
		else
			Stealing.roubar(estado, robo)
		end
	end

	-- o robô vai sumir enquanto alguém carrega (dono saiu ou renasceu)
	Game.aoDestruirCarregado = function(robo)
		local ladrao = robo.ladrao
		Stealing.desprender(robo)
		if ladrao then
			Game.notificar(ladrao.player, "info", "sumiu")
		end
	end

	-- o ladrão saiu do jogo com o robô na cabeça
	Game.aoSairComCarga = function(ladrao)
		Stealing.falhar(ladrao, nil)
	end
end

return Stealing
