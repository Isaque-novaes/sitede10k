--[[
	Roteiro de teste das Lendas Elementais no Roblox simulado.

	Joga o jogo de verdade: atacar bonecos e monstros, subir de nível,
	comprar elementos, melhorar, viajar pelos portais, PvP nas zonas
	vermelhas, chefes, missões, prêmio diário, loja, salvar e carregar,
	e a tela do jogador nos dois idiomas.

	ARQUIVOS (global vinda do Python): lista de { grupo, nome, classe, caminho }
]]

return function(Sim)
	local G = Sim.G
	local Instance, Vector3, CFrame, Enum = G.Instance, G.Vector3, G.CFrame, G.Enum

	local resultado = { ok = 0, falhas = {} }
	Sim.resultado = resultado -- se o roteiro parar no meio, o verificador mostra o que já passou
	local function checar(condicao, descricao)
		if condicao then
			resultado.ok = resultado.ok + 1
		else
			table.insert(resultado.falhas, string.format("[t=%.1fs] %s", Sim.T, descricao))
		end
	end
	-- o roteiro roda fora do Roblox: table.clear não existe aqui
	local function limpar(t)
		for k in pairs(t) do
			t[k] = nil
		end
	end
	-- espera o jogador voltar (os monstros podem derrubá-lo no meio do teste)
	local function garantirVivo(player, estado)
		for _ = 1, 20 do
			if not estado.morto and player.Character and player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid.Health = player.Character.Humanoid.MaxHealth
				return true
			end
			Sim.avancar(1)
		end
		return false
	end
	local function semErros(etapa)
		checar(#Sim.erros == 0, etapa .. ": sem erros de script")
	end

	-- Árvore igual à que o Rojo monta -------------------------------------
	local RS = Sim.servico("ReplicatedStorage")
	local SSS = Sim.servico("ServerScriptService")
	local SP = Sim.servico("StarterPlayer")
	local SPS = Sim.novaInstancia("StarterPlayerScripts", true)
	SPS.Name = "StarterPlayerScripts"
	SPS.Parent = SP
	local function pasta(pai, nome)
		local f = Instance.new("Folder")
		f.Name = nome
		f.Parent = pai
		return f
	end
	local destinos = {
		shared = pasta(RS, "Shared"),
		server = pasta(SSS, "Server"),
		client = pasta(SPS, "Client"),
	}
	local scripts = {}
	for _, a in ipairs(ARQUIVOS) do
		scripts[a[1] .. "/" .. a[2]] = Sim.criarScript(a[3], a[2], a[4], destinos[a[1]])
	end
	local Players = Sim.servico("Players")
	local workspace = G.workspace
	local mps = Sim.servico("MarketplaceService")

	-- 0. Loja configurada e um save antigo esperando -----------------------
	local Config = Sim.requerer(scripts["shared/Config"])
	local Textos = Sim.requerer(scripts["shared/Textos"])
	local ids = { xp2 = 1001, moedas2 = 1002, vip = 1003, aura = 1004 }
	for _, passe in ipairs(Config.LOJA.PASSES) do
		passe.id = ids[passe.chave]
	end
	for i, pacote in ipairs(Config.LOJA.PACOTES) do
		pacote.id = 2000 + i
	end
	Config.LOJA.ANUNCIO.id = 3001
	Config.GRUPO.ID = 777

	Sim.passes["2:1003"] = true -- Beto é VIP
	Sim.grupos["1:777"] = true -- Ana está no grupo
	Sim.amizades["1:2"] = true -- Ana e Beto são amigos

	Sim.cofres["LendasElementais_v1"] = {
		jogador_1 = { versao = 1, nivel = 4, xp = 10, moedas = 900, elementos = { "fogo" }, equipado = "fogo" },
		jogador_60 = { versao = 1, nivel = 9, sessao = { id = "outro-servidor", t = 1700000000 } },
	}

	-- 1. Servidor liga -----------------------------------------------------
	Sim.executar(scripts["server/Main"])
	Sim.avancar(1)
	semErros("início do servidor")

	local Jogador = Sim.requerer(scripts["server/Jogador"])
	local Combate = Sim.requerer(scripts["server/Combate"])
	local Monstros = Sim.requerer(scripts["server/Monstros"])
	local Progresso = Sim.requerer(scripts["server/Progresso"])
	local Remotos = RS:FindFirstChild("Remotos")
	local Lighting = Sim.servico("Lighting")

	checar(workspace:FindFirstChild("Mapa") ~= nil, "mapa criado")
	checar(workspace.Mapa.Zonas:FindFirstChild("Vila") ~= nil, "vila criada")
	for _, zona in ipairs(Config.Zonas) do
		if zona.id ~= "vila" then
			checar(workspace.Mapa.Zonas:FindFirstChild("Zona_" .. zona.id) ~= nil, "zona " .. zona.id .. " criada")
		end
	end
	checar(#workspace.Mapa.Zonas.Vila:GetChildren() > 40, "vila tem casas, fonte e portais")
	checar(Lighting:FindFirstChildOfClass("Atmosphere") ~= nil, "iluminação montada")
	checar(#Jogador.mundo.portais == 8, "8 portais (4 de ida, 4 de volta)")
	local totalMonstros = Monstros.quantidade()
	checar(totalMonstros > 70, "monstros nasceram (" .. totalMonstros .. ")")
	local chefes = 0
	for _, m in ipairs(Monstros.ativos()) do
		if m.chefe then
			chefes = chefes + 1
		end
	end
	checar(chefes == 4, "4 chefes, um por zona")
	semErros("mundo")

	-- 2. Ana (pt) e Beto (en) entram ---------------------------------------
	local ana = Sim.novoJogador(1, "Ana", "pt-br")
	Sim.avancar(0.5)
	local beto = Sim.novoJogador(2, "Beto", "en-us")
	Sim.avancar(0.5)
	Sim.criarPersonagem(ana, Vector3.new(0, 5, 34))
	Sim.criarPersonagem(beto, Vector3.new(0, 5, 34))
	Sim.avancar(1.5)
	semErros("entrada dos jogadores")

	local ea, eb = Jogador.estados[ana], Jogador.estados[beto]
	checar(ea ~= nil and eb ~= nil, "estados criados")
	if not ea or not eb then
		return resultado
	end
	checar(ea.idioma == "pt" and eb.idioma == "en", "idioma de cada um")
	checar(ea.nivel == 4 and ea.moedas >= 900, "save antigo da Ana carregado")
	checar(eb.nivel == 1 and eb.moedas == Config.MOEDAS_INICIAIS, "Beto começa do zero")
	checar(ea.noGrupo == true and ea.dados.grupoPremiado == true, "bônus do grupo pago")
	checar(ea.amigos == 1 and eb.amigos == 1, "bônus de amigos")
	checar(eb.passes.vip == true and eb.aura == "dourada", "VIP ganha a aura dourada")
	checar(Jogador.multiplicadorXP(eb) > 1.2, "VIP multiplica o XP")
	local vidaAna = ana.Character.Humanoid.MaxHealth
	checar(vidaAna == Config.vidaMaxima(4, 0), "vida do personagem conforme o nível")
	checar(ana.Character.Humanoid.WalkSpeed == Config.VELOCIDADE_BASE, "velocidade inicial")
	checar(ea.zonaAtual == "vila" and ana:GetAttribute("ZonaPvp") == false, "começa na vila, zona segura")
	checar(ana:GetAttribute("Equipado") == "fogo", "começa com o elemento Fogo")

	-- 3. Bater no boneco de treino ------------------------------------------
	Sim.jogadorLocal = ana
	local fogo = Config.ElementoPorId.fogo
	local boneco
	for _, m in ipairs(Monstros.ativos()) do
		if m.boneco then
			boneco = m
		end
	end
	checar(boneco ~= nil, "bonecos de treino existem")
	if boneco then
		Sim.moverPara(ana, CFrame.new(boneco.posicao + Vector3.new(0, 0, 14)))
		Sim.avancar(0.3)
		local direcao = (boneco.posicao - ana.Character.HumanoidRootPart.Position).Unit
		Remotos.Atacar:FireServer(1, direcao)
		checar(Combate.quantidadeDeTiros() == 1, "o tiro saiu")
		Sim.avancar(1.5)
		checar(Combate.quantidadeDeTiros() == 0, "o tiro acertou e sumiu")
		checar(boneco.vida == math.huge, "boneco não morre")
		-- a recarga segura o próximo tiro (espera passar o limite de pedidos,
		-- senão seria ele barrando e não a recarga do golpe)
		Remotos.Atacar:FireServer(1, direcao)
		Sim.avancar(0.15)
		local depoisDoPrimeiro = Combate.quantidadeDeTiros()
		Remotos.Atacar:FireServer(1, direcao)
		checar(Combate.quantidadeDeTiros() == depoisDoPrimeiro, "respeitou a recarga")
		Sim.avancar(fogo.basico.recarga + 0.1)
		Remotos.Atacar:FireServer(1, direcao)
		checar(Combate.quantidadeDeTiros() > 0, "atira de novo depois da recarga")
		Sim.avancar(1.5)
	end
	-- direção inválida não faz nada
	Remotos.Atacar:FireServer(1, Vector3.new(0, 0, 0))
	Remotos.Atacar:FireServer(1, "para frente")
	Remotos.Atacar:FireServer(99, Vector3.new(1, 0, 0))
	Remotos.Atacar:FireServer(1, Vector3.new(0 / 0, 0, 0))
	checar(Combate.quantidadeDeTiros() == 0, "pedido inválido é ignorado")
	semErros("boneco de treino")

	-- 4. Matar um monstro de verdade -----------------------------------------
	local function monstroDaZona(zonaId, chefe)
		for _, m in ipairs(Monstros.ativos()) do
			if m.zonaId == zonaId and not m.boneco and (chefe == nil or m.chefe == chefe) then
				return m
			end
		end
		return nil
	end

	local function atacarAte(estado, player, monstro, golpes, indice, imortal)
		for _ = 1, golpes do
			if monstro.morto then
				break
			end
			if imortal then
				player.Character.Humanoid.Health = player.Character.Humanoid.MaxHealth
			end
			local raiz = player.Character.HumanoidRootPart
			local direcao = (monstro.posicao + Vector3.new(0, 1, 0) - raiz.Position).Unit
			Remotos.Atacar:FireServer(indice or 1, direcao)
			Sim.avancar(0.7)
		end
	end

	local alvo = monstroDaZona("campo")
	checar(alvo ~= nil, "achei um monstro no Campo Verde")
	if alvo then
		Sim.moverPara(ana, CFrame.new(alvo.posicao + Vector3.new(0, 0, 18)))
		Sim.avancar(0.3)
		checar(ea.zonaAtual == "campo", "Ana está no Campo Verde")
		local vidaAntes = alvo.vida
		atacarAte(ea, ana, alvo, 1)
		checar(alvo.vida < vidaAntes, "o monstro levou dano")
		checar(alvo.alvo == ea, "o monstro veio atrás de quem bateu")
		local xpAntes, moedasAntes, nivelAntes = ea.xp, ea.moedas, ea.nivel
		atacarAte(ea, ana, alvo, 12)
		checar(alvo.morto == true, "monstro derrotado")
		checar(ea.moedas > moedasAntes, "ganhou moedas")
		checar(ea.xp ~= xpAntes or ea.nivel > nivelAntes, "ganhou XP")
		checar(Monstros.quantidade() == totalMonstros - 1, "o monstro saiu do mundo")
		Sim.avancar(Config.MONSTRO.RENASCER + 1)
		checar(Monstros.quantidade() == totalMonstros, "o monstro voltou depois de um tempo")
	end
	semErros("matar monstro")

	-- 5. Subir de nível --------------------------------------------------------
	local nivelAntes = ea.nivel
	local vidaAntes = Jogador.vidaMaxima(ea)
	Jogador.darXP(ea, Config.xpDoNivel(ea.nivel) * 2, true)
	Sim.avancar(0.3)
	checar(ea.nivel > nivelAntes, "subiu de nível")
	checar(Jogador.vidaMaxima(ea) > vidaAntes, "ganhou vida ao subir")
	checar(ana.Character.Humanoid.MaxHealth == Jogador.vidaMaxima(ea), "o personagem recebeu a vida nova")
	checar(ana:GetAttribute("Nivel") == ea.nivel, "a tela sabe o nível novo")
	-- o XP que sobra continua contando
	local sobra = ea.xp
	checar(sobra < Config.xpDoNivel(ea.nivel), "o XP que sobrou ficou guardado")

	-- 6. Comprar e equipar elementos --------------------------------------------
	local gelo = Config.ElementoPorId.gelo
	Remotos.ComprarElemento:FireServer("gelo")
	Sim.avancar(0.6)
	local temGelo = Jogador.temElemento(ea, "gelo")
	checar(temGelo == (ea.nivel >= gelo.nivel), "só compra elemento com o nível certo")
	if not temGelo then
		Jogador.darXP(ea, Config.xpDoNivel(ea.nivel) * 3, true)
		Sim.avancar(0.6)
		Remotos.ComprarElemento:FireServer("gelo")
		Sim.avancar(0.6)
	end
	checar(Jogador.temElemento(ea, "gelo"), "comprou o Gelo")
	checar(ea.equipado == "gelo", "o elemento comprado já fica equipado")
	Remotos.Equipar:FireServer("fogo")
	Sim.avancar(0.6)
	checar(ea.equipado == "fogo", "trocou de volta para o Fogo")
	Remotos.Equipar:FireServer("sombra")
	Sim.avancar(0.6)
	checar(ea.equipado == "fogo", "não equipa elemento que não tem")
	-- sem o nível não compra, nem com dinheiro de sobra
	Jogador.darMoedas(ea, 1000000, true)
	local moedasAntes = ea.moedas
	Remotos.ComprarElemento:FireServer("sombra") -- precisa do nível 75
	Sim.avancar(0.6)
	checar(not Jogador.temElemento(ea, "sombra") and ea.moedas == moedasAntes,
		"não compra elemento sem o nível, mesmo com dinheiro")
	-- com o nível mas sem moedas, também não
	local nivelGuardado = ea.nivel
	ea.nivel = Config.ElementoPorId.pedra.nivel
	ea.moedas = 10
	Remotos.ComprarElemento:FireServer("pedra")
	Sim.avancar(0.6)
	checar(not Jogador.temElemento(ea, "pedra"), "não compra elemento sem moedas")
	ea.nivel = nivelGuardado
	Jogador.darMoedas(ea, 20000, true)
	semErros("elementos")

	-- 7. Golpes especiais -------------------------------------------------------
	Sim.moverPara(ana, CFrame.new(0, 5, 34))
	Sim.avancar(0.3)
	local pedra = Config.ElementoPorId.pedra
	table.insert(ea.elementos, "pedra")
	ea.equipado = "pedra"
	limpar(ea.recargas)
	Remotos.Atacar:FireServer(2, Vector3.new(1, 0, 0)) -- Pele de Pedra
	Sim.avancar(0.2)
	checar(ea.escudoAte ~= nil and ea.escudoAte > workspace:GetServerTimeNow(), "escudo ligado")
	local vidaCheia = ana.Character.Humanoid.Health
	Jogador.machucar(ea, 100)
	checar(vidaCheia - ana.Character.Humanoid.Health <= 51, "escudo reduziu o dano pela metade")
	Sim.avancar(pedra.especial.duracao + 0.5)
	Remotos.Atacar:FireServer(3, Vector3.new(1, 0, 0)) -- Terremoto (área em volta)
	Sim.avancar(0.3)
	checar(Combate.quantidadeDeTiros() == 0, "terremoto não vira tiro, explode em volta")

	table.insert(ea.elementos, "sombra")
	ea.equipado = "sombra"
	limpar(ea.recargas)
	Remotos.Atacar:FireServer(2, Vector3.new(1, 0, 0)) -- Sumir
	Sim.avancar(0.2)
	checar(ea.invisivelAte ~= nil, "ficou invisível")
	local corpoAna
	for _, item in ipairs(ana.Character:GetChildren()) do
		if item:IsA("BasePart") and item.Name == "Head" then
			corpoAna = item
		end
	end
	checar(corpoAna and corpoAna.Transparency > 0.5, "o personagem some de verdade")
	Sim.avancar(Config.ElementoPorId.sombra.especial.duracao + 1)
	checar(ea.invisivelAte == nil and corpoAna.Transparency == 0, "voltou a aparecer")

	ea.equipado = "vento"
	table.insert(ea.elementos, "vento")
	limpar(ea.recargas)
	Remotos.Atacar:FireServer(1, Vector3.new(0, 0, -1)) -- 3 lâminas
	Sim.avancar(0.1)
	checar(Combate.quantidadeDeTiros() == 3, "o Vento atira 3 lâminas de uma vez")
	Sim.avancar(3)
	ea.equipado = "fogo"
	limpar(ea.recargas)
	semErros("golpes especiais")

	-- 8. Melhorias ----------------------------------------------------------------
	Jogador.darMoedas(ea, 500000, true)
	local vidaMelhoriaAntes = Jogador.vidaMaxima(ea)
	Remotos.Melhorar:FireServer("vida")
	Sim.avancar(0.4)
	checar(ea.melhorias.vida == 1 and Jogador.vidaMaxima(ea) > vidaMelhoriaAntes, "melhoria de vida")
	local danoAntes = Jogador.dano(ea)
	Remotos.Melhorar:FireServer("dano")
	Sim.avancar(0.4)
	checar(Jogador.dano(ea) > danoAntes, "melhoria de dano")
	Remotos.Melhorar:FireServer("velocidade")
	Sim.avancar(0.4)
	checar(ana.Character.Humanoid.WalkSpeed > Config.VELOCIDADE_BASE, "melhoria de velocidade")
	for _ = 1, 12 do
		Remotos.Melhorar:FireServer("vida")
		Sim.avancar(0.3)
	end
	checar(ea.melhorias.vida == Config.MELHORIAS.vida.max, "melhoria para no máximo")
	Remotos.Melhorar:FireServer("voar")
	Sim.avancar(0.3)
	semErros("melhorias")

	-- 9. Portais e zonas ------------------------------------------------------------
	local portalDeserto
	for _, p in ipairs(Jogador.mundo.portais) do
		if p.zona.id == "deserto" then
			portalDeserto = p
		end
	end
	checar(portalDeserto ~= nil, "portal para o deserto existe")
	while ea.nivel < Config.ZonaPorId.deserto.nivelMinimo do
		Jogador.darXP(ea, Config.xpDoNivel(ea.nivel), true)
		Sim.avancar(0.2)
	end
	if portalDeserto then
		-- longe do portal não viaja
		Sim.moverPara(ana, CFrame.new(0, 5, 34))
		Remotos.Viajar:FireServer("deserto")
		Sim.avancar(0.3)
		checar(Config.zonaDe(ana.Character.HumanoidRootPart.Position).id ~= "deserto", "não viaja de longe")
		-- perto do portal, com nível, viaja
		Sim.moverPara(ana, CFrame.new(portalDeserto.base.Position + Vector3.new(0, 5, 6)))
		Sim.avancar(1.2)
		Remotos.Viajar:FireServer("deserto")
		Sim.avancar(0.6)
		checar(Config.zonaDe(ana.Character.HumanoidRootPart.Position).id == "deserto", "viajou para o deserto")
		Sim.avancar(0.5)
		checar(ana:GetAttribute("ZonaPvp") == true, "o deserto é zona de PvP")
	end
	-- Beto é nível 1: não entra
	Sim.jogadorLocal = beto
	local portalPico
	for _, p in ipairs(Jogador.mundo.portais) do
		if p.zona.id == "pico" then
			portalPico = p
		end
	end
	Sim.moverPara(beto, CFrame.new(portalPico.base.Position + Vector3.new(0, 5, 6)))
	Sim.avancar(0.5)
	Remotos.Viajar:FireServer("pico")
	Sim.avancar(0.5)
	checar(Config.zonaDe(beto.Character.HumanoidRootPart.Position).id ~= "pico", "nível baixo não entra no Pico")
	Sim.jogadorLocal = ana
	semErros("portais")

	-- 10. PvP ------------------------------------------------------------------------
	-- na vila ninguém se machuca
	Sim.moverPara(ana, CFrame.new(0, 5, 20))
	Sim.moverPara(beto, CFrame.new(0, 5, 26))
	Sim.avancar(0.6)
	checar(Jogador.podeAtacar(ea, eb) == false, "na vila um não ataca o outro")
	-- no deserto, pode
	local deserto = Config.ZonaPorId.deserto
	local centroDeserto = Vector3.new(deserto.centro.X, 5, deserto.centro.Y)
	Sim.moverPara(ana, CFrame.new(centroDeserto))
	Sim.moverPara(beto, CFrame.new(centroDeserto + Vector3.new(0, 0, 12)))
	Sim.avancar(0.6)
	checar(Jogador.podeAtacar(ea, eb) == true, "no deserto pode atacar")
	eb.nivel = ea.nivel -- níveis parecidos para valer recompensa
	local vidaBeto = beto.Character.Humanoid.Health
	local direcaoBeto = (beto.Character.HumanoidRootPart.Position - ana.Character.HumanoidRootPart.Position).Unit
	limpar(ea.recargas)
	Remotos.Atacar:FireServer(1, direcaoBeto)
	Sim.avancar(0.8)
	checar(beto.Character.Humanoid.Health < vidaBeto, "o tiro da Ana acertou o Beto")
	-- derrubar o Beto dá recompensa (direto, sem depender dos monstros em volta)
	checar(garantirVivo(beto, eb), "o Beto está de pé para o teste de PvP")
	Sim.moverPara(beto, CFrame.new(centroDeserto + Vector3.new(0, 0, 12)))
	Sim.avancar(0.3)
	local xpAna, moedasAna = ea.xp, ea.moedas
	Jogador.machucar(eb, 9999, ea)
	Sim.avancar(0.6)
	checar(eb.morto == true, "o Beto caiu")
	checar(ea.moedas > moedasAna or ea.xp ~= xpAna, "quem derrubou ganhou recompensa")
	checar(eb.moedas > 0, "quem caiu não perdeu moedas")
	Sim.avancar(Config.RESPAWN + 1.5)
	checar(eb.morto == false and beto.Character.Humanoid.Health > 1, "o Beto voltou com vida cheia")
	-- derrubar o mesmo de novo logo em seguida não paga
	local moedasDepois = ea.moedas
	garantirVivo(beto, eb)
	Sim.moverPara(beto, CFrame.new(centroDeserto + Vector3.new(0, 0, 12)))
	Sim.avancar(0.5)
	Jogador.machucar(eb, 9999, ea)
	Sim.avancar(0.6)
	checar(ea.moedas - moedasDepois < 10, "não paga por derrubar o mesmo jogador de novo")
	Sim.avancar(Config.RESPAWN + 1.5)
	garantirVivo(beto, eb)
	Sim.moverPara(beto, CFrame.new(0, 5, 34)) -- de volta para a vila, longe dos monstros
	Sim.avancar(0.5)
	semErros("PvP")

	-- 11. Monstro ataca o jogador ----------------------------------------------------
	local bravo = monstroDaZona("deserto", false)
	checar(bravo ~= nil, "monstro do deserto")
	if bravo then
		Sim.moverPara(ana, CFrame.new(bravo.posicao + Vector3.new(0, 0, 6)))
		local vidaDaAna = ana.Character.Humanoid.Health
		Sim.avancar(6)
		checar(ana.Character.Humanoid.Health < vidaDaAna, "o monstro machucou a Ana")
		checar(bravo.alvo == ea, "o monstro escolheu a Ana como alvo")
		-- fugir faz o monstro voltar para casa
		Sim.moverPara(ana, CFrame.new(0, 5, 34))
		Sim.avancar(12)
		checar(bravo.alvo == nil or (bravo.posicao - bravo.casa).Magnitude < 40, "o monstro desistiu e voltou")
	end
	-- morrer para um monstro
	Sim.moverPara(ana, CFrame.new(centroDeserto))
	Sim.avancar(0.5)
	ana.Character.Humanoid.Health = 1
	Jogador.machucar(ea, 50, nil, function()
		return "Monstro"
	end)
	Sim.avancar(0.3)
	checar(ea.morto == true and ana:GetAttribute("Morto") == true, "a Ana caiu")
	Sim.avancar(Config.RESPAWN + 1.5)
	checar(ea.morto == false, "a Ana voltou")
	checar(ea.moedas > 0 and ea.nivel > 1, "morrer não tira nada")
	semErros("monstros atacando")

	-- 12. Chefe ------------------------------------------------------------------------
	local chefe = monstroDaZona("campo", true)
	checar(chefe ~= nil and chefe.vidaMaxima > Config.vidaMonstro(chefe.nivel, false) * 5, "o chefe tem muito mais vida")
	if chefe then
		local moedasChefe = ea.moedas
		ea.nivel = 60
		ea.melhorias.dano = Config.MELHORIAS.dano.max
		Sim.moverPara(ana, CFrame.new(chefe.posicao + Vector3.new(0, 0, 20)))
		Sim.avancar(0.5)
		atacarAte(ea, ana, chefe, 60, 1, true)
		checar(chefe.morto == true, "chefe derrotado")
		checar(ea.moedas - moedasChefe > Config.moedasMonstro(chefe.nivel, false) * 5, "o chefe pagou bem mais")
		checar(ea.dados.chefesDerrotados == 1, "contou o chefe derrotado")
	end
	semErros("chefe")

	-- 13. Missões e prêmio diário -------------------------------------------------------
	checar(#ea.missoesDoDia == Config.MISSOES_POR_DIA, "3 missões no dia")
	for i, missao in ipairs(ea.missoesDoDia) do
		Jogador.emitir(ea, missao.tipo, missao.meta)
		checar((ana:GetAttribute("M" .. i .. "Prog") or 0) >= missao.meta, "missão " .. missao.id .. " completa")
	end
	local moedasMissao = ea.moedas
	for i = 1, 3 do
		Sim.avancar(0.6)
		Remotos.PegarMissao:FireServer(i)
	end
	checar(ana:GetAttribute("M1Pega") == true, "prêmio da missão pego")
	local depoisMissoes = ea.moedas
	Sim.avancar(0.6)
	Remotos.PegarMissao:FireServer(1)
	checar(ea.moedas == depoisMissoes, "missão não paga duas vezes")
	checar(depoisMissoes > moedasMissao, "as missões pagaram")
	Remotos.PegarMissao:FireServer(0 / 0)
	Remotos.PegarMissao:FireServer(42)

	checar(ana:GetAttribute("DiarioPronto") == true, "prêmio diário disponível")
	local moedasDiario = ea.moedas
	Sim.avancar(1.1)
	Remotos.PegarDiario:FireServer()
	checar(ea.dados.diario.sequencia == 1 and ea.moedas > moedasDiario, "prêmio do dia 1 pego")
	Sim.avancar(1.1)
	Remotos.PegarDiario:FireServer()
	checar(ea.dados.diario.sequencia == 1, "não pega duas vezes no mesmo dia")
	ea.dados.diario.ultimoDia = Progresso.diaAtual() - 1
	Sim.avancar(1.1)
	Remotos.PegarDiario:FireServer()
	checar(ea.dados.diario.sequencia == 2, "sequência cresce em dias seguidos")
	ea.dados.diario.ultimoDia = Progresso.diaAtual() - 4
	Sim.avancar(1.1)
	Remotos.PegarDiario:FireServer()
	checar(ea.dados.diario.sequencia == 1, "faltou um dia: volta ao Dia 1")
	semErros("missões e prêmio")

	-- 14. Loja com Robux ------------------------------------------------------------------
	local processar = Sim.internos[mps].props.ProcessReceipt
	checar(type(processar) == "function", "ProcessReceipt registrado")
	local Granted = Enum.ProductPurchaseDecision.PurchaseGranted
	local Pendente = Enum.ProductPurchaseDecision.NotProcessedYet
	local moedasCompra = eb.moedas
	checar(processar({ PlayerId = 2, ProductId = 2001, PurchaseId = "c1" }) == Granted, "pacote de moedas entregue")
	checar(eb.moedas == moedasCompra + Config.LOJA.PACOTES[1].moedas, "o pacote dá o valor exato, sem bônus")
	local depoisPacote = eb.moedas
	checar(processar({ PlayerId = 2, ProductId = 2001, PurchaseId = "c1" }) == Granted and eb.moedas == depoisPacote,
		"compra repetida não entrega de novo")
	checar(processar({ PlayerId = 2, ProductId = 7777, PurchaseId = "c2" }) == Pendente, "produto desconhecido fica pendente")
	checar(processar({ PlayerId = 999, ProductId = 2001, PurchaseId = "c3" }) == Pendente, "jogador ausente fica pendente")
	-- anúncio com prêmio
	Sim.jogadorLocal = beto
	Remotos.VerAnuncio:FireServer()
	Sim.avancar(0.3)
	checar(#Sim.anuncios == 1, "o anúncio foi pedido ao Roblox")
	local multAntes = Jogador.multiplicadorXP(eb)
	checar(processar({ PlayerId = 2, ProductId = 3001, PurchaseId = "ad1" }) == Granted, "prêmio do anúncio entregue")
	checar(Jogador.multiplicadorXP(eb) > multAntes, "o anúncio dobrou o XP")
	-- passe comprado na hora
	Sim.disparar(Sim.sinalDe(mps, "PromptGamePassPurchaseFinished"), ana, ids.xp2, true)
	Sim.avancar(0.3)
	checar(ea.passes.xp2 == true and ana:GetAttribute("Passe_xp2") == true, "passe de XP comprado")
	-- auras
	Sim.jogadorLocal = ana
	Remotos.Aura:FireServer("fogo")
	Sim.avancar(0.4)
	checar(ea.aura == "nenhuma", "aura bloqueada sem o passe")
	Sim.disparar(Sim.sinalDe(mps, "PromptGamePassPurchaseFinished"), ana, ids.aura, true)
	Sim.avancar(0.4)
	Remotos.Aura:FireServer("fogo")
	Sim.avancar(0.4)
	checar(ea.aura == "fogo", "com o passe, a aura funciona")
	semErros("loja")

	-- 15. Salvar e carregar ------------------------------------------------------------
	local nivelAna, moedasFinais = ea.nivel, math.floor(ea.moedas)
	Sim.removerJogador(ana)
	Sim.avancar(1)
	local salvo = Sim.cofres["LendasElementais_v1"]["jogador_1"]
	checar(salvo ~= nil and salvo.sessao == nil, "salvou e soltou a trava")
	if salvo then
		checar(salvo.nivel == nivelAna and salvo.moedas == moedasFinais, "salvou nível e moedas")
		checar(#salvo.elementos >= 4 and salvo.equipado == "fogo", "salvou os elementos")
		checar(salvo.melhorias.vida == Config.MELHORIAS.vida.max, "salvou as melhorias")
		checar(salvo.aura == "fogo" and salvo.diario.sequencia == 1, "salvou aura e prêmio diário")
		checar(salvo.chefesDerrotados == 1, "salvou os chefes derrotados")
	end
	local ana2 = Sim.novoJogador(1, "Ana", "pt-br")
	Sim.avancar(0.6)
	Sim.criarPersonagem(ana2, Vector3.new(0, 5, 34))
	Sim.avancar(1.2)
	local ea2 = Jogador.estados[ana2]
	checar(ea2 ~= nil, "a Ana voltou")
	if ea2 then
		checar(ea2.nivel == nivelAna and ea2.moedas == moedasFinais, "nível e moedas restaurados")
		checar(Jogador.temElemento(ea2, "gelo") and ea2.aura == "fogo", "elementos e aura restaurados")
		checar(ea2.melhorias.vida == Config.MELHORIAS.vida.max, "melhorias restauradas")
		checar(ana2.Character.Humanoid.MaxHealth == Jogador.vidaMaxima(ea2), "vida conforme o save")
	end
	checar(Sim.cofres["LendasElementais_v1"]["jogador_1"].sessao ~= nil, "trava de sessão ao entrar")

	-- trava de outro servidor e falha de dados
	local travado = Sim.novoJogador(60, "Travado", "pt-br")
	Sim.avancar(45)
	checar(#Sim.expulsos >= 1 and string.find(Sim.expulsos[#Sim.expulsos].mensagem, "outro servidor", 1, true) ~= nil,
		"save travado: pede para entrar de novo")
	checar(Sim.cofres["LendasElementais_v1"]["jogador_60"].nivel == 9, "save travado não é sobrescrito")
	Sim.removerJogador(travado)
	Sim.falharDataStore = true
	local duda = Sim.novoJogador(4, "Duda", "pt-br")
	Sim.avancar(45)
	checar(Jogador.estados[duda] == nil, "falha ao carregar: não joga com perfil vazio")
	Sim.removerJogador(duda)
	Sim.falharDataStore = false
	checar(Sim.cofres["LendasElementais_v1"]["jogador_4"] == nil, "falha ao carregar: nada sobrescrito")
	semErros("salvar e carregar")

	-- 16. A tela do jogador (Beto, em inglês) -----------------------------------------
	Sim.jogadorLocal = beto
	Sim.definir(Players, "LocalPlayer", beto)
	local camera = Sim.novaInstancia("Camera", true)
	camera.Name = "Camera"
	Sim.definir(camera, "ViewportSize", G.Vector2.new(1280, 720))
	camera.Parent = workspace
	Sim.definir(workspace, "CurrentCamera", camera)
	Sim.executar(scripts["client/HUD"])
	Sim.executar(scripts["client/Combate"])
	Sim.executar(scripts["client/Mundo"])
	Sim.avancar(1.5)
	semErros("telas do jogador iniciaram")

	local hud = beto.PlayerGui:FindFirstChild("LendasHUD")
	local barraGolpes = beto.PlayerGui:FindFirstChild("BarraDeGolpes")
	checar(hud ~= nil and barraGolpes ~= nil, "HUD e barra de golpes criadas")
	if hud and barraGolpes then
		checar(hud.Jogador.Medalha.Nivel.Text == tostring(eb.nivel), "a medalha mostra o nível")
		checar(string.find(hud.Topo.Zona.Texto.Text, "Village", 1, true) ~= nil, "a faixa da zona em inglês")
		checar(hud.Topo.XP2.Visible == true, "faixa de XP em dobro aparece")
		local golpe1 = barraGolpes.Golpes.Golpe1.Corpo
		checar(golpe1.Nome.Text == Config.ElementoPorId[eb.equipado].basico.en, "o botão mostra o golpe em inglês")

		Jogador.avisar(beto, "bom", "subiu_nivel", 7)
		Sim.avancar(0.2)
		local ultimo
		for _, filho in ipairs(hud.Topo.Avisos:GetChildren()) do
			if filho:IsA("TextLabel") then
				ultimo = filho
			end
		end
		checar(ultimo and ultimo.Text == "Level 7! More health and damage.", "aviso traduzido para o inglês")

		local function clicar(caixa)
			Sim.disparar(Sim.sinalDe(caixa.Corpo, "Activated"))
			Sim.avancar(0.4)
		end
		clicar(hud.Menu.menu_elementos)
		checar(hud.Elementos.Visible == true, "painel de Elementos abre")
		clicar(hud.Menu.menu_melhorar)
		checar(hud.Melhorar.Visible == true and hud.Elementos.Visible == false, "abrir um painel fecha o outro")
		clicar(hud.Menu.menu_loja)
		checar(hud.Loja.Visible == true, "painel da Loja")
		clicar(hud.Menu.menu_missoes)
		checar(hud.Missoes.Visible == true, "painel de Missões")
		clicar(hud.Menu.menu_premio)
		checar(hud.Diario.Visible == true, "painel do Prêmio diário")

		-- comprar uma melhoria pela tela
		local moedasTela = eb.moedas
		clicar(hud.Menu.menu_melhorar)
		clicar(hud.Melhorar.Conteudo.Melhoria_vida.Botao)
		checar(eb.moedas < moedasTela and eb.melhorias.vida == 1, "o botão da tela comprou a melhoria")

		-- atacar pelo botão da barra
		limpar(eb.recargas)
		garantirVivo(beto, eb)
		Sim.moverPara(beto, CFrame.new(0, 5, -34))
		Sim.avancar(0.3)
		local tirosAntes = Combate.quantidadeDeTiros()
		Sim.disparar(Sim.sinalDe(golpe1, "Activated"))
		-- confere na hora: o tiro é rápido e pode acertar o boneco logo em seguida
		checar(Combate.quantidadeDeTiros() > tirosAntes, "o botão da barra dispara o golpe")
		Sim.avancar(2)

		-- a interface cabe em telas pequenas e grandes
		local escalaTopo = hud.Topo:FindFirstChildOfClass("UIScale")
		local escalaLoja = hud.Loja:FindFirstChildOfClass("UIScale")
		for _, medida in ipairs({ { 386, 412 }, { 640, 480 }, { 1280, 720 }, { 1920, 1080 } }) do
			local largura, altura = medida[1], medida[2]
			Sim.definir(camera, "ViewportSize", G.Vector2.new(largura, altura))
			Sim.avancar(0.3)
			checar(250 * escalaTopo.Scale <= largura * 0.5,
				"em " .. largura .. "x" .. altura .. " o painel do jogador cabe")
			checar(580 * escalaLoja.Scale <= largura and 430 * escalaLoja.Scale <= altura,
				"em " .. largura .. "x" .. altura .. " a loja cabe inteira")
		end
		Sim.definir(camera, "ViewportSize", G.Vector2.new(1280, 720))
		Sim.avancar(0.3)

		-- nome do monstro e placas no idioma
		local qualquerMonstro
		for _, modelo in ipairs(workspace.Monstros:GetChildren()) do
			local barra = modelo:FindFirstChild("Raiz") and modelo.Raiz:FindFirstChild("Barra")
			if barra and barra.Nome:GetAttribute("Monstro") ~= "boneco" then
				qualquerMonstro = barra.Nome
				break
			end
		end
		checar(qualquerMonstro and qualquerMonstro.Text ~= "", "o monstro tem nome na tela: " .. tostring(qualquerMonstro and qualquerMonstro.Text))
		local placaVila = workspace.Mapa.Zonas.Vila.Cristal.Placa.Texto
		checar(placaVila.Text == "CENTRAL VILLAGE", "placa da vila em inglês")

		-- efeitos não quebram
		Remotos.Efeito:FireClient(beto, "dano", Vector3.new(0, 5, 0), Config.ElementoPorId.fogo.cor, 123)
		Remotos.Efeito:FireClient(beto, "subirNivel")
		Remotos.Efeito:FireClient(beto, "premio")
		Remotos.Empurrao:FireClient(beto, Vector3.new(0, 50, 0))
		Sim.avancar(1.5)
	end
	semErros("tela do jogador")

	-- 17. Um tempo rodando sem vazar nada ---------------------------------------------
	local tirosAntes = Combate.quantidadeDeTiros()
	Sim.avancar(60, 1 / 12)
	checar(Combate.quantidadeDeTiros() <= tirosAntes + 5, "os tiros somem depois de usados")
	checar(Monstros.quantidade() <= totalMonstros + 2,
		"os monstros não se multiplicam (" .. Monstros.quantidade() .. ")")
	checar(Textos.t("pt", "bemvindo") ~= Textos.t("en", "bemvindo"), "textos existem nos dois idiomas")
	semErros("60 segundos de jogo")

	-- 18. Fechar o servidor salva todo mundo --------------------------------------------
	for _, fn in ipairs(Sim.aoFechar) do
		Sim.task.spawn(fn)
	end
	Sim.avancar(4)
	local salvoBeto = Sim.cofres["LendasElementais_v1"]["jogador_2"]
	checar(salvoBeto ~= nil and salvoBeto.sessao == nil, "fechar o servidor salva e solta as travas")
	semErros("fechamento")

	return resultado
end
