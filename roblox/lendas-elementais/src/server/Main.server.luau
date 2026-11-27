--[[
	Elemental Legends / Lendas Elementais — script principal do servidor.
	Monta o mundo, liga os sistemas e cuida da entrada e saída de jogadores.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Textos = require(Shared:WaitForChild("Textos"))

local pasta = script.Parent
local Mundo = require(pasta:WaitForChild("Mundo"))
local Data = require(pasta:WaitForChild("Data"))
local Jogador = require(pasta:WaitForChild("Jogador"))
local Combate = require(pasta:WaitForChild("Combate"))
local Monstros = require(pasta:WaitForChild("Monstros"))
local Loja = require(pasta:WaitForChild("Loja"))
local Progresso = require(pasta:WaitForChild("Progresso"))
local Robux = require(pasta:WaitForChild("Robux"))
local Ranking = require(pasta:WaitForChild("Ranking"))

-- Canais de conversa com os jogadores ---------------------------------------
local remotos = Instance.new("Folder")
remotos.Name = "Remotos"
local function remoto(nome)
	local evento = Instance.new("RemoteEvent")
	evento.Name = nome
	evento.Parent = remotos
	return evento
end
-- servidor -> jogador
local Aviso = remoto("Aviso")
local Efeito = remoto("Efeito")
local Empurrao = remoto("Empurrao")
local Recarga = remoto("Recarga")
-- jogador -> servidor (o servidor confere tudo)
local Atacar = remoto("Atacar")
local Equipar = remoto("Equipar")
local ComprarElemento = remoto("ComprarElemento")
local Melhorar = remoto("Melhorar")
local Aura = remoto("Aura")
local PegarDiario = remoto("PegarDiario")
local PegarMissao = remoto("PegarMissao")
local VerAnuncio = remoto("VerAnuncio")
local Viajar = remoto("Viajar")
local Teste = remoto("Teste")
remotos.Parent = ReplicatedStorage

-- Liga os sistemas -------------------------------------------------------------
local mundo = Mundo.construir()
Jogador.iniciar(mundo, {
	Aviso = Aviso,
	Efeito = Efeito,
	Empurrao = Empurrao,
	Recarga = Recarga,
})
Combate.ligarMonstros(Monstros)
Monstros.ligarCombate(Combate)
Jogador.aoDerrotarJogador = Progresso.derrotouJogador
Combate.iniciar()
Progresso.iniciar()
Robux.iniciar()
Monstros.prepararBonecos()
Monstros.povoar()

local function salvar(estado, liberar)
	if estado.podeSalvar then
		Data.salvar(estado.player, Jogador.guardar(estado), liberar)
		Ranking.registrar(estado.player, estado.nivel, estado.xp)
	end
end
Robux.aoComprar = function(estado)
	task.spawn(salvar, estado, false)
end

-- Limite de pedidos por jogador ---------------------------------------------------
local ultimosPedidos = {}
local function permitir(player, nome, intervalo)
	local porJogador = ultimosPedidos[player]
	if not porJogador then
		porJogador = {}
		ultimosPedidos[player] = porJogador
	end
	local instante = os.clock()
	if porJogador[nome] and instante - porJogador[nome] < intervalo then
		return false
	end
	porJogador[nome] = instante
	return true
end

local function estadoDe(player, nome, intervalo)
	if not permitir(player, nome, intervalo) then
		return nil
	end
	return Jogador.estados[player]
end

-- Etiqueta VIP em cima da cabeça --------------------------------------------------
local function etiquetaVip(estado)
	local personagem = estado.player.Character
	local cabeca = personagem and personagem:FindFirstChild("Head")
	if not estado.passes.vip or not cabeca or cabeca:FindFirstChild("EtiquetaVip") then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "EtiquetaVip"
	gui.Size = UDim2.fromOffset(80, 30)
	gui.StudsOffset = Vector3.new(0, 2.8, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	gui.Adornee = cabeca
	local texto = Instance.new("TextLabel")
	texto.Size = UDim2.fromScale(1, 1)
	texto.BackgroundTransparency = 1
	texto.Font = Enum.Font.LuckiestGuy
	texto.TextScaled = true
	texto.Text = "VIP"
	texto.TextColor3 = Color3.fromRGB(255, 216, 77)
	texto.TextStrokeTransparency = 0
	texto.TextStrokeColor3 = Color3.fromRGB(20, 23, 43)
	texto.Parent = gui
	gui.Parent = cabeca
end

-- Jogadores ------------------------------------------------------------------------
local function aoEntrar(player)
	local dados, situacao = Data.carregar(player)
	if player.Parent == nil then
		if situacao == "ok" then
			Data.salvar(player, dados, true)
		end
		return
	end
	local idioma = Textos.idiomaDe(player.LocaleId)
	if situacao == "falha" or situacao == "ocupado" then
		player:Kick(Textos.t(idioma, situacao == "ocupado" and "dados_ocupados" or "dados_falha"))
		return
	end
	local podeSalvar = situacao == "ok"
	local estado = Jogador.adicionar(player, dados, podeSalvar)

	Robux.verificarPasses(estado)
	if Jogador.estados[player] ~= estado then
		return -- saiu enquanto carregava
	end
	Robux.aplicarPasses(estado)
	Progresso.aoEntrar(estado)

	player.CharacterAdded:Connect(function(personagem)
		task.spawn(function()
			Jogador.aoNascer(estado, personagem)
			etiquetaVip(estado)
		end)
	end)
	if player.Character then
		task.spawn(function()
			Jogador.aoNascer(estado, player.Character)
			etiquetaVip(estado)
		end)
	end

	Jogador.avisar(player, "info", "bemvindo")
	Jogador.avisar(player, "info", "dica_golpes")
	Jogador.avisar(player, "info", "dica_zonas")
	if not podeSalvar then
		Jogador.avisar(player, "alerta", "nao_salva")
	end
end

Players.PlayerAdded:Connect(aoEntrar)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(aoEntrar, player)
end

Players.PlayerRemoving:Connect(function(player)
	ultimosPedidos[player] = nil
	local estado, dados = Jogador.remover(player)
	if estado then
		task.spawn(Progresso.atualizarAmigos)
		if estado.podeSalvar then
			Data.salvar(player, dados, true)
			Ranking.registrar(player, estado.nivel, estado.xp)
		end
	end
end)

game:BindToClose(function()
	local pendentes = 0
	for _, estado in pairs(Jogador.estados) do
		if estado.podeSalvar then
			pendentes = pendentes + 1
			task.spawn(function()
				salvar(estado, true)
				pendentes = pendentes - 1
			end)
		end
	end
	local limite = os.clock() + (RunService:IsStudio() and 3 or 25)
	while pendentes > 0 and os.clock() < limite do
		task.wait(0.1)
	end
end)

-- Pedidos dos jogadores ----------------------------------------------------------
Atacar.OnServerEvent:Connect(function(player, indice, direcao)
	-- a recarga de cada golpe já segura o ritmo; aqui só barramos spam absurdo
	local estado = estadoDe(player, "Atacar", 0.08)
	if estado and type(indice) == "number" then
		Combate.usar(estado, indice, direcao)
	end
end)

Equipar.OnServerEvent:Connect(function(player, id)
	local estado = estadoDe(player, "Equipar", 0.3)
	if estado and type(id) == "string" then
		Loja.equipar(estado, id)
	end
end)

ComprarElemento.OnServerEvent:Connect(function(player, id)
	local estado = estadoDe(player, "ComprarElemento", 0.5)
	if estado and type(id) == "string" then
		Loja.comprarElemento(estado, id)
	end
end)

Melhorar.OnServerEvent:Connect(function(player, tipo)
	local estado = estadoDe(player, "Melhorar", 0.25)
	if estado and type(tipo) == "string" then
		Loja.melhorar(estado, tipo)
	end
end)

Aura.OnServerEvent:Connect(function(player, id)
	local estado = estadoDe(player, "Aura", 0.3)
	if estado and type(id) == "string" then
		Loja.escolherAura(estado, id)
	end
end)

PegarDiario.OnServerEvent:Connect(function(player)
	local estado = estadoDe(player, "PegarDiario", 1)
	if estado then
		Progresso.pegarDiario(estado)
	end
end)

PegarMissao.OnServerEvent:Connect(function(player, indice)
	local estado = estadoDe(player, "PegarMissao", 0.5)
	if estado and type(indice) == "number" then
		Progresso.pegarMissao(estado, indice)
	end
end)

VerAnuncio.OnServerEvent:Connect(function(player)
	local estado = estadoDe(player, "VerAnuncio", 5)
	if estado then
		Robux.verAnuncio(estado)
	end
end)

-- Viajar pelos portais: o servidor confere o nível e leva o jogador.
Viajar.OnServerEvent:Connect(function(player, destinoId)
	local estado = estadoDe(player, "Viajar", 1)
	if not estado or type(destinoId) ~= "string" then
		return
	end
	local zona = Config.ZonaPorId[destinoId]
	local raiz, _, personagem = Jogador.personagemDe(player)
	if not zona or not raiz then
		return
	end
	-- precisa estar perto de um portal que leve para lá
	local perto = false
	for _, portal in ipairs(mundo.portais) do
		if portal.zona.id == destinoId and (portal.base.Position - raiz.Position).Magnitude < 20 then
			perto = true
			break
		end
	end
	if not perto then
		return
	end
	if estado.nivel < zona.nivelMinimo then
		Jogador.avisar(player, "ruim", "zona_nivel", zona.nivelMinimo, Jogador.nomeDe(zona))
		return
	end
	local destino = destinoId == "vila" and mundo.nascer or CFrame.new(mundo.zonas[destinoId].entrada)
	personagem:PivotTo(destino)
	Jogador.avisar(player, "info", "portal_usado", Jogador.nomeDe(zona))
end)

Teste.OnServerEvent:Connect(function(player, acao)
	if not RunService:IsStudio() then
		return -- os botões de teste só funcionam no Roblox Studio
	end
	local estado = Jogador.estados[player]
	if not estado then
		return
	end
	if acao == "xp" then
		local valor = Config.xpDoNivel(estado.nivel) * 3
		Jogador.darXP(estado, valor, true)
		Jogador.darMoedas(estado, valor, true)
		Jogador.avisar(player, "info", "teste_xp", Jogador.numero(math.floor(valor)))
		Jogador.atualizarAtributos(estado)
	elseif acao == "dia" then
		estado.dados.diario.ultimoDia = Progresso.diaAtual() - 1
		estado.dados.missoes.dia = -1
		estado.diaMissoes = nil
		Progresso.atualizarAtributos(estado)
	end
end)

-- Laços do jogo -------------------------------------------------------------------
task.spawn(function()
	while true do
		local dt = task.wait(0.2)
		Monstros.passo(dt)
		Jogador.vigiar()
	end
end)

task.spawn(function()
	while true do
		task.wait(60)
		Progresso.cadaMinuto()
	end
end)

task.spawn(function()
	task.wait(5)
	while true do
		Ranking.atualizar(mundo.vila.placar)
		task.wait(120)
	end
end)

task.spawn(function()
	while true do
		task.wait(90)
		for _, estado in pairs(Jogador.estados) do
			task.spawn(salvar, estado, false)
		end
	end
end)

print("[Elemental Legends] Servidor pronto!")
