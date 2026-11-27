--[[
	Combate: golpes dos elementos, tiros, dano e efeitos.

	Quem decide tudo é o servidor. O jogador só manda "quero usar o golpe
	2 nesta direção"; aqui a gente confere se ele está vivo, se a recarga
	já passou e se a direção é válida, e só então o tiro existe.

	Os tiros são peças criadas no servidor e movidas a cada quadro, então
	todo mundo vê a mesma coisa e ninguém consegue forjar um acerto.
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Jogador = require(script.Parent:WaitForChild("Jogador"))

local Combate = {}

local Monstros = nil -- ligado pelo Main (evita um módulo pedir o outro em círculo)
local tiros = {}
local FAISCAS = "rbxasset://textures/particles/sparkles_main.dds"
local RAIO_JOGADOR = 3

function Combate.ligarMonstros(modulo)
	Monstros = modulo
end

local function agora()
	return workspace:GetServerTimeNow()
end

-- Peças e efeitos ---------------------------------------------------------------
local function novaParte(nome, tamanho, cframe, cor, material)
	local parte = Instance.new("Part")
	parte.Name = nome
	parte.Size = tamanho
	parte.CFrame = cframe
	parte.Color = cor
	parte.Material = material or Enum.Material.Neon
	parte.Anchored = true
	parte.CanCollide = false
	parte.CanTouch = false
	parte.CanQuery = false
	return parte
end

local function explosao(posicao, cor, raio, quantidade)
	local suporte = novaParte("Explosao", Vector3.new(1, 1, 1), CFrame.new(posicao), cor)
	suporte.Transparency = 1
	local emissor = Instance.new("ParticleEmitter")
	emissor.Texture = FAISCAS
	emissor.Color = ColorSequence.new(cor)
	emissor.LightEmission = 1
	emissor.LightInfluence = 0
	emissor.Lifetime = NumberRange.new(0.3, 0.7)
	emissor.Speed = NumberRange.new(raio * 1.5, raio * 3)
	emissor.SpreadAngle = Vector2.new(180, 180)
	emissor.Size = NumberSequence.new(math.max(0.6, raio / 6), 0)
	emissor.Rate = 0
	emissor.Parent = suporte
	local luz = Instance.new("PointLight")
	luz.Color = cor
	luz.Range = math.max(10, raio * 2)
	luz.Brightness = 3
	luz.Parent = suporte
	suporte.Parent = workspace
	emissor:Emit(quantidade or 24)
	Debris:AddItem(suporte, 1.2)

	if raio > 2 then
		local onda = novaParte("Onda", Vector3.new(raio * 2, raio * 2, raio * 2), CFrame.new(posicao), cor)
		onda.Shape = Enum.PartType.Ball
		onda.Transparency = 0.45
		onda.Parent = workspace
		Debris:AddItem(onda, 0.25)
	end
end
Combate.explosao = explosao

-- Alvos ---------------------------------------------------------------------------
-- Devolve a lista de quem pode ser acertado por este tiro.
local function alvosDe(tiro)
	local lista = {}
	if tiro.deMonstro then
		for _, estado in pairs(Jogador.estados) do
			local posicao = Jogador.posicaoDe(estado)
			if posicao and not estado.morto then
				table.insert(lista, { posicao = posicao, raio = RAIO_JOGADOR, jogador = estado })
			end
		end
	else
		if Monstros then
			for _, monstro in ipairs(Monstros.ativos()) do
				table.insert(lista, { posicao = monstro.posicao, raio = monstro.raio, monstro = monstro })
			end
		end
		local dono = tiro.dono
		for _, estado in pairs(Jogador.estados) do
			if estado ~= dono and Jogador.podeAtacar(dono, estado) then
				local posicao = Jogador.posicaoDe(estado)
				if posicao then
					table.insert(lista, { posicao = posicao, raio = RAIO_JOGADOR, jogador = estado })
				end
			end
		end
	end
	return lista
end

-- Dano ------------------------------------------------------------------------------
local function aplicarEfeitos(tiro, alvo)
	local golpe = tiro.golpe
	if golpe.efeito == "lentidao" then
		if alvo.jogador then
			alvo.jogador.lentoAte = agora() + Config.EFEITOS.LENTIDAO.duracao
		elseif alvo.monstro and Monstros then
			Monstros.deixarLento(alvo.monstro, Config.EFEITOS.LENTIDAO.duracao)
		end
	end
	if golpe.empurrao and alvo.jogador then
		local direcao = (alvo.posicao - tiro.posicao)
		direcao = Vector3.new(direcao.X, 0, direcao.Z)
		if direcao.Magnitude < 0.1 then
			direcao = tiro.direcao
		end
		Jogador.remotos.Empurrao:FireClient(alvo.jogador.player, direcao.Unit * golpe.empurrao + Vector3.new(0, 40, 0))
	end
end

local function machucarAlvo(tiro, alvo, dano)
	if alvo.monstro and Monstros then
		Monstros.machucar(alvo.monstro, dano, tiro.dono)
	elseif alvo.jogador then
		if tiro.deMonstro then
			Jogador.machucar(alvo.jogador, dano, nil, tiro.nomeDoMonstro)
		else
			Jogador.machucar(alvo.jogador, dano, tiro.dono, nil)
		end
	end
	aplicarEfeitos(tiro, alvo)
	if tiro.dono and not tiro.deMonstro then
		Jogador.remotos.Efeito:FireClient(tiro.dono.player, "dano", alvo.posicao, tiro.cor, math.floor(dano))
	end
end

-- Acerto: explode em área ou acerta só um ---------------------------------------
local function acertar(tiro, alvoDireto)
	local golpe = tiro.golpe
	explosao(tiro.posicao, tiro.cor, math.max(2, golpe.raio or 0), golpe.raio > 0 and 40 or 18)
	if golpe.raio and golpe.raio > 0 then
		for _, alvo in ipairs(alvosDe(tiro)) do
			if (alvo.posicao - tiro.posicao).Magnitude <= golpe.raio + alvo.raio then
				machucarAlvo(tiro, alvo, tiro.dano)
			end
		end
	elseif alvoDireto then
		machucarAlvo(tiro, alvoDireto, tiro.dano)
	end
end

-- Movimento dos tiros, a cada quadro --------------------------------------------
local function passo(dt)
	for i = #tiros, 1, -1 do
		local tiro = tiros[i]
		local morreu = false

		if tiro.parte.Parent == nil then
			morreu = true
		else
			-- míssil teleguiado: vai virando para o alvo mais perto
			if tiro.golpe.teleguiado then
				local melhor, menor = nil, 90
				for _, alvo in ipairs(alvosDe(tiro)) do
					local distancia = (alvo.posicao - tiro.posicao).Magnitude
					if distancia < menor then
						melhor, menor = alvo, distancia
					end
				end
				if melhor then
					local desejada = (melhor.posicao - tiro.posicao).Unit
					tiro.direcao = (tiro.direcao + (desejada - tiro.direcao) * math.min(1, dt * 4)).Unit
				end
			end

			local avanco = tiro.golpe.velocidade * dt
			tiro.posicao = tiro.posicao + tiro.direcao * avanco
			tiro.andou = tiro.andou + avanco
			tiro.parte.CFrame = CFrame.new(tiro.posicao, tiro.posicao + tiro.direcao)

			-- acertou alguém?
			local raioTiro = (tiro.golpe.tamanho or 1) + 1
			for _, alvo in ipairs(alvosDe(tiro)) do
				if (alvo.posicao - tiro.posicao).Magnitude <= raioTiro + alvo.raio then
					acertar(tiro, alvo)
					morreu = true
					break
				end
			end

			-- bateu no chão ou acabou o alcance
			if not morreu and (tiro.posicao.Y <= 1 or tiro.andou >= tiro.golpe.alcance) then
				acertar(tiro, nil)
				morreu = true
			end
		end

		if morreu then
			table.remove(tiros, i)
			if tiro.parte.Parent then
				tiro.parte:Destroy()
			end
		end
	end
end

-- Cria um tiro ---------------------------------------------------------------------
local function criarTiro(dados)
	local golpe = dados.golpe
	local tamanho = golpe.tamanho or 1.5
	local parte = novaParte("Tiro", Vector3.new(tamanho, tamanho, tamanho * 1.8),
		CFrame.new(dados.posicao, dados.posicao + dados.direcao), dados.cor)
	parte.Shape = Enum.PartType.Ball
	local luz = Instance.new("PointLight")
	luz.Color = dados.cor
	luz.Range = 14
	luz.Brightness = 2
	luz.Parent = parte
	local rastro = Instance.new("ParticleEmitter")
	rastro.Texture = FAISCAS
	rastro.Color = ColorSequence.new(dados.cor)
	rastro.LightEmission = 1
	rastro.LightInfluence = 0
	rastro.Rate = 60
	rastro.Lifetime = NumberRange.new(0.2, 0.4)
	rastro.Speed = NumberRange.new(0, 1)
	rastro.Size = NumberSequence.new(tamanho * 0.7, 0)
	rastro.Parent = parte
	parte.Parent = Jogador.mundo.pastaTiros

	table.insert(tiros, {
		parte = parte,
		posicao = dados.posicao,
		direcao = dados.direcao,
		golpe = golpe,
		dano = dados.dano,
		cor = dados.cor,
		dono = dados.dono,
		deMonstro = dados.deMonstro,
		nomeDoMonstro = dados.nomeDoMonstro,
		andou = 0,
	})
end

-- Golpes do jogador -------------------------------------------------------------------
local function direcaoValida(direcao)
	if typeof(direcao) ~= "Vector3" then
		return nil
	end
	local tamanho = direcao.Magnitude
	if tamanho ~= tamanho or tamanho < 0.1 or tamanho > 100 then
		return nil -- NaN, zero ou absurdo
	end
	return direcao.Unit
end

-- Gira a direção alguns graus para o lado (tiros em leque)
local function girar(direcao, graus)
	return (CFrame.Angles(0, math.rad(graus), 0) * direcao).Unit
end

function Combate.usar(estado, indice, direcao)
	if estado.morto then
		return false
	end
	local nomeGolpe = Config.GOLPES[indice]
	if not nomeGolpe then
		return false
	end
	local raiz = Jogador.personagemDe(estado.player)
	if not raiz then
		return false
	end
	local unitaria = direcaoValida(direcao)
	if not unitaria then
		return false
	end

	local elemento = Jogador.elementoAtual(estado)
	local golpe = elemento[nomeGolpe]
	local instante = agora()
	if (estado.recargas[nomeGolpe] or 0) > instante then
		return false
	end
	estado.recargas[nomeGolpe] = instante + golpe.recarga
	Jogador.remotos.Recarga:FireClient(estado.player, indice, golpe.recarga)

	local dano = Jogador.dano(estado) * (golpe.dano or 0)
	local origem = raiz.Position + Vector3.new(0, 1.5, 0) + unitaria * 3

	-- golpes que não são tiro
	if golpe.efeito == "escudo" then
		estado.escudoAte = instante + (golpe.duracao or 6)
		estado.escudoReducao = golpe.reducao or 0.5
		explosao(raiz.Position, elemento.cor, 6, 30)
		Jogador.remotos.Efeito:FireClient(estado.player, "escudo", nil, elemento.cor, golpe.duracao)
	elseif golpe.efeito == "sumir" then
		estado.invisivelAte = instante + (golpe.duracao or 5)
		Jogador.mostrarPersonagem(estado, false)
		explosao(raiz.Position, elemento.cor, 6, 30)
	elseif golpe.efeito == "impulso" then
		Jogador.remotos.Empurrao:FireClient(estado.player,
			unitaria * Config.EFEITOS.IMPULSO.forca + Vector3.new(0, Config.EFEITOS.IMPULSO.altura, 0))
		criarTiro({ posicao = origem, direcao = unitaria, golpe = golpe, dano = dano, cor = elemento.cor, dono = estado })
	elseif golpe.alcance == 0 and (golpe.raio or 0) > 0 then
		-- golpe que explode em volta do próprio jogador (terremoto)
		local centro = raiz.Position
		local tiroFalso = { posicao = centro, direcao = unitaria, golpe = golpe, dano = dano, cor = elemento.cor, dono = estado }
		acertar(tiroFalso, nil)
	else
		local quantos = golpe.tiros or 1
		local abertura = golpe.abertura or (quantos > 1 and 9 or 0)
		for i = 1, quantos do
			local deslocamento = (i - (quantos + 1) / 2) * abertura
			local direcaoTiro = abertura > 0 and girar(unitaria, deslocamento) or unitaria
			criarTiro({ posicao = origem, direcao = direcaoTiro, golpe = golpe, dano = dano, cor = elemento.cor, dono = estado })
		end
	end

	if indice == 3 then
		Jogador.emitir(estado, "usarSupremo", 1)
	end
	return true
end

-- Tiro de monstro -------------------------------------------------------------------
function Combate.tiroDeMonstro(monstro, posicao, direcao, dano)
	local unitaria = direcaoValida(direcao)
	if not unitaria then
		return
	end
	criarTiro({
		posicao = posicao,
		direcao = unitaria,
		golpe = { velocidade = Config.MONSTRO.VELOCIDADE_TIRO, alcance = Config.MONSTRO.ALCANCE_TIRO + 30, raio = 0, tamanho = 1.8 },
		dano = dano,
		cor = monstro.def.detalhe,
		deMonstro = true,
		nomeDoMonstro = Jogador.nomeDe(monstro.def),
	})
end

function Combate.quantidadeDeTiros()
	return #tiros
end

function Combate.iniciar()
	RunService.Heartbeat:Connect(passo)
end

return Combate
