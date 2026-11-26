--[[
	Roteiro de teste do Robot Heist / Rouba Robô no Roblox simulado.

	Jogadores: Ana (português, save antigo da versão 1, no grupo, amiga do
	Beto), Beto (inglês, VIP e +5 vagas), Caio (país sem caixa surpresa),
	e outros para testar trava de sessão, falha de dados e servidor cheio.

	ARQUIVOS (global vinda do Python): lista de { grupo, nome, classe, caminho }
]]

return function(Sim)
	local G = Sim.G
	local Instance, Vector3, CFrame, Enum = G.Instance, G.Vector3, G.CFrame, G.Enum

	local resultado = { ok = 0, falhas = {} }
	local function checar(condicao, descricao)
		if condicao then
			resultado.ok = resultado.ok + 1
		else
			table.insert(resultado.falhas, string.format("[t=%.1fs] %s", Sim.T, descricao))
		end
	end
	local function semErros(etapa)
		checar(#Sim.erros == 0, etapa .. ": sem erros de script")
	end
	local function contar(t)
		local n = 0
		for _ in pairs(t) do
			n = n + 1
		end
		return n
	end

	-- Monta a mesma árvore que o Rojo / montar_place.py criam ---------------
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

	-- 0. Loja configurada e mundo preparado ---------------------------------
	local Config = Sim.requerer(scripts["shared/Config"])
	local Format = Sim.requerer(scripts["shared/Format"])
	local Textos = Sim.requerer(scripts["shared/Textos"])
	local ids = { dobro = 1001, vip = 1002, vagas = 1003, tranca = 1004 }
	for _, passe in ipairs(Config.LOJA.PASSES) do
		passe.id = ids[passe.chave]
	end
	for i, pacote in ipairs(Config.LOJA.PACOTES) do
		pacote.id = 2000 + i
	end
	Config.LOJA.SORTE.id = 3001
	Config.LOJA.CAIXA.id = 3002
	Config.LOJA.ANUNCIO.id = 3003
	Config.GRUPO.ID = 777

	Sim.passes["2:1002"] = true -- Beto é VIP
	Sim.passes["2:1003"] = true -- Beto tem +5 vagas
	Sim.grupos["1:777"] = true -- Ana está no grupo
	Sim.amizades["1:2"] = true -- Ana e Beto são amigos
	Sim.caixaRestrita[3] = true -- Caio mora num país sem caixa paga

	local agoraUnix = 1700000000
	Sim.cofres["RoubaRobo_v1"] = {
		-- save da versão 1 (antes desta atualização), saiu há 1 hora
		jogador_1 = {
			versao = 1,
			dinheiro = 500,
			renascimentos = 0,
			robos = { { id = "bipbop", vaga = 1 } },
			descobertos = { bipbop = true },
			saida = agoraUnix - 3600,
		},
		-- jogador cujo save ainda está travado por outro servidor
		jogador_60 = {
			versao = 2,
			dinheiro = 999,
			sessao = { id = "outro-servidor", t = agoraUnix },
		},
	}

	-- 1. Servidor liga -------------------------------------------------------
	Sim.executar(scripts["server/Main"])
	Sim.avancar(1)
	semErros("início do servidor")

	local Game = Sim.requerer(scripts["server/Game"])
	local Conveyor = Sim.requerer(scripts["server/Conveyor"])
	local MapBuilder = Sim.requerer(scripts["server/MapBuilder"])
	local Progresso = Sim.requerer(scripts["server/Progresso"])
	local Remotos = RS:FindFirstChild("Remotos")
	local Lighting = Sim.servico("Lighting")

	checar(workspace:FindFirstChild("Mapa") ~= nil, "mapa criado")
	checar(#workspace.Mapa.Bases:GetChildren() == 8, "8 bases criadas")
	checar(#Game.mundo.bases[1].pedestais == Config.MAX_PEDESTAIS, "20 pedestais por base")
	checar(Conveyor.quantidade() >= 15, "esteira começa cheia (" .. Conveyor.quantidade() .. " robôs)")
	checar(Lighting:FindFirstChildOfClass("Atmosphere") ~= nil and Lighting:FindFirstChildOfClass("BloomEffect") ~= nil,
		"iluminação nova (atmosfera e brilho)")
	checar(workspace.Mapa:FindFirstChild("Ranking") ~= nil and workspace.Mapa:FindFirstChild("ComoJogar") ~= nil,
		"placar e quadro 'como jogar'")
	checar(#workspace.Mapa.Decoracao:GetChildren() > 50, "árvores e postes no mapa")

	local RobotFactory = Sim.requerer(scripts["server/RobotFactory"])
	for _, def in ipairs(Config.Robos) do
		RobotFactory.construir(def, nil).modelo:Destroy()
	end
	for _, mut in ipairs(Config.Mutacoes) do
		RobotFactory.construir(Config.Robos[1], mut.id).modelo:Destroy()
	end
	semErros("montagem de todos os robôs")

	-- 2. Ana (pt) e Beto (en) entram -----------------------------------------
	local ana = Sim.novoJogador(1, "Ana", "pt-br")
	Sim.avancar(0.5)
	local beto = Sim.novoJogador(2, "Beto", "en-us")
	Sim.avancar(0.5)
	Sim.criarPersonagem(ana, Vector3.new(0, 3, 21))
	Sim.criarPersonagem(beto, Vector3.new(0, 3, 21))
	Sim.avancar(1)
	semErros("entrada dos jogadores")

	local ea, eb = Game.estados[ana], Game.estados[beto]
	checar(ea ~= nil and eb ~= nil, "estados dos jogadores criados")
	if not ea or not eb then
		return resultado
	end
	checar(ea.idioma == "pt" and eb.idioma == "en", "idioma de cada jogador")
	checar(ea.base ~= eb.base, "cada um ganhou uma base diferente")
	checar(ea.dados.versao == 2 and ea.dados.melhorias.renda == 0, "save da versão 1 convertido")
	checar(ea.vagas[1] and ea.vagas[1].def.id == "bipbop", "robô do save antigo restaurado")
	checar(ea.noGrupo == true and ea.dados.grupoPremiado == true, "bônus do grupo")
	checar(ea.vagas[2] and ea.vagas[2].def.raridade == Config.GRUPO.RARIDADE_PREMIO, "robô Raro de presente do grupo")
	checar(ea.amigos == 1 and eb.amigos == 1, "bônus de amigos no servidor")
	checar((ana:GetAttribute("OfflinePendente") or 0) > 3000, "dinheiro ganho com o jogo fechado ("
		.. tostring(ana:GetAttribute("OfflinePendente")) .. ")")
	checar(eb.passes.vip and eb.passes.vagas and not eb.passes.dobro, "passes do Beto carregados")
	checar(Game.vagasTotais(eb) == 15, "passe +5 vagas")
	checar(eb.dados.vipPremiado and Game.vagasOcupadas(eb) == 1, "robô Épico de presente do VIP")
	local _, presenteVip = next(eb.vagas)
	checar(presenteVip and presenteVip.def.raridade == Config.LOJA.VIP_ROBO_RARIDADE, "presente VIP é Épico")
	checar(beto.Character.Head:FindFirstChild("EtiquetaVip") ~= nil, "etiqueta VIP na cabeça")
	checar(math.abs(Game.multiplicador(eb) - 1.5 * 1.1) < 1e-6, "multiplicador do Beto: VIP x1,5 e amigo +10%")
	checar(ea.base.modelo:GetAttribute("DonoNome") == "Ana", "base mostra o dono")
	checar((ana.Character.HumanoidRootPart.Position - ea.base.nascer.Position).Magnitude < 0.01, "Ana nasceu na base")
	checar(ana.Backpack:FindFirstChild("Tapa") ~= nil, "Ana recebeu o Tapa")
	for vaga, pedestal in ipairs(ea.base.pedestais) do
		checar(MapBuilder.dentroDaBase(ea.base, pedestal.Position, -2), "pedestal " .. vaga .. " dentro da base")
	end
	checar(ea.base.vagas[11].bloco.Transparency > 0.5 and ea.base.vagas[10].bloco.Transparency == 0,
		"pedestais bloqueados ficam apagados")
	checar(eb.base.vagas[15].bloco.Transparency == 0, "vagas do passe aparecem")

	-- 3. Pegar o dinheiro offline --------------------------------------------
	Sim.jogadorLocal = ana
	local pendente = ana:GetAttribute("OfflinePendente")
	local antes = ea.dinheiro
	Remotos.ColetarOffline:FireServer()
	checar(math.abs(ea.dinheiro - (antes + pendente)) < 1 and ana:GetAttribute("OfflinePendente") == 0,
		"dinheiro offline coletado")
	Remotos.ColetarOffline:FireServer()
	checar(math.abs(ea.dinheiro - (antes + pendente)) < 1, "dinheiro offline não pode ser pego duas vezes")

	-- 4. Compra na esteira ---------------------------------------------------
	local barato = nil
	for _, r in ipairs(Conveyor.robos()) do
		if Config.precoDe(r.def, r.mut) <= 300 then
			barato = r
			break
		end
	end
	if not barato then
		barato = Game.novoRobo(Config.RoboPorId.parafusinho, nil, CFrame.new(0, 1, 0))
	end
	local preco = Config.precoDe(barato.def, barato.mut)
	antes = ea.dinheiro
	Sim.disparar(barato.prompt.Triggered, ana)
	checar(ea.dinheiro == antes - preco, "compra desconta o preço")
	Sim.avancar(3)
	semErros("compra")
	checar(barato.estado == "base" and barato.dono == ea and ea.vagas[3] == barato, "robô comprado foi para a vaga 3")
	checar((barato.modelo:GetPivot().Position - ea.base.pedestais[3].Position).Magnitude < 0.01, "robô em cima do pedestal")
	checar(ea.base.vagas[3].anel.Transparency == 0, "anel do pedestal acende com a raridade")
	checar(barato.prompt:GetAttribute("DonoId") == 1 and barato.prompt:GetAttribute("Venda") == Game.valorVenda(barato),
		"prompt sabe o dono e o valor de venda")
	antes = ea.dinheiro
	Sim.avancar(5)
	checar(ea.dinheiro > antes + Game.rendaBase(ea) * 4, "renda por segundo cai na conta")
	checar(ana.leaderstats.Dinheiro.Value == math.floor(ea.dinheiro), "leaderstats acompanha o dinheiro")
	checar(ea.totalGanho > 0, "total ganho conta para o ranking")

	local caro = Game.novoRobo(Config.RoboPorId.supremo, nil, CFrame.new(10, 1, 0))
	Sim.disparar(caro.prompt.Triggered, ana)
	checar(caro.estado == "esteira", "não compra sem dinheiro")
	Game.destruirRobo(caro)

	-- 5. Missões do dia ------------------------------------------------------
	checar(#ea.missoesDoDia == 3, "3 missões no dia")
	checar(ana:GetAttribute("M1Id") == ea.missoesDoDia[1].id, "missões aparecem para a tela")
	local missoesDeNovo = Config.missoesDoDia(Progresso.diaAtual(), 1)
	checar(missoesDeNovo[1].id == ea.missoesDoDia[1].id, "missões do dia são sempre as mesmas")
	Remotos.PegarMissao:FireServer(1)
	checar(not ea.dados.missoes.pegas[ea.missoesDoDia[1].id], "não pega missão incompleta")
	for i, missao in ipairs(ea.missoesDoDia) do
		local tipo = missao.tipo == "comprarRaridade" and "comprar" or missao.tipo
		Game.emitir(ea, tipo, missao.meta, { raridade = 7 })
		checar((ana:GetAttribute("M" .. i .. "Prog") or 0) >= missao.meta, "missão " .. missao.id .. " completa")
	end
	antes = ea.dinheiro
	for i = 1, 3 do
		Sim.avancar(0.6)
		Remotos.PegarMissao:FireServer(i)
	end
	checar(ana:GetAttribute("M1Pega") and ana:GetAttribute("M2Pega") and ana:GetAttribute("M3Pega"), "prêmios das missões pegos")
	local depoisMissoes = ea.dinheiro
	Sim.avancar(0.6)
	Remotos.PegarMissao:FireServer(1)
	checar(ea.dinheiro - depoisMissoes < Game.rendaPorSegundo(ea) * 2 + 1, "missão não paga duas vezes")
	Remotos.PegarMissao:FireServer(0 / 0)
	Remotos.PegarMissao:FireServer(99)
	semErros("missões")

	-- 6. Prêmio diário -------------------------------------------------------
	checar(ana:GetAttribute("DiarioPronto") == true and ana:GetAttribute("DiarioDia") == 1, "prêmio do dia 1 disponível")
	antes = ea.dinheiro
	Sim.avancar(1.1)
	Remotos.PegarDiario:FireServer()
	checar(ea.dinheiro > antes and ana:GetAttribute("DiarioPronto") == false, "prêmio do dia 1 pego")
	Sim.avancar(1.1)
	antes = ea.dinheiro
	Remotos.PegarDiario:FireServer()
	checar(ea.dados.diario.sequencia == 1, "não pega o prêmio duas vezes no mesmo dia")
	ea.dados.diario.ultimoDia = Progresso.diaAtual() - 1 -- "voltou no dia seguinte"
	Sim.avancar(1.1)
	Remotos.PegarDiario:FireServer()
	checar(ea.dados.diario.sequencia == 2, "sequência cresce em dias seguidos")
	ea.dados.diario.ultimoDia = Progresso.diaAtual() - 3 -- "faltou dois dias"
	Sim.avancar(1.1)
	Remotos.PegarDiario:FireServer()
	checar(ea.dados.diario.sequencia == 1, "faltou um dia: volta para o Dia 1")
	ea.dados.diario.sequencia = 6
	ea.dados.diario.ultimoDia = Progresso.diaAtual() - 1
	local robosAntes = Game.vagasOcupadas(ea)
	Sim.avancar(1.1)
	Remotos.PegarDiario:FireServer()
	Sim.avancar(3)
	checar(Game.vagasOcupadas(ea) == robosAntes + 1, "dia 7: robô Lendário de prêmio")
	semErros("prêmio diário")

	-- 7. Melhorias -----------------------------------------------------------
	Game.adicionarDinheiro(ea, 1e10)
	local multAntes = Game.multiplicador(ea)
	Remotos.Melhorar:FireServer("renda")
	checar(ea.melhorias.renda == 1 and ea.base.modelo:GetAttribute("Nivel") == 1, "melhoria de renda nível 1")
	checar(math.abs(Game.multiplicador(ea) / multAntes - 1.1) < 1e-6, "+10% de renda por nível")
	for _ = 1, 12 do
		Sim.avancar(0.3)
		Remotos.Melhorar:FireServer("renda")
	end
	checar(ea.melhorias.renda == Config.MELHORIAS.renda.max, "renda para no nível máximo")
	checar(ea.base.enfeites.ouro[1].Transparency == 0 and ea.base.enfeites.coroa[1].Transparency == 0,
		"base nível 10 ganha ouro e coroa")
	local feixe = ea.base.enfeites.feixes[1]:FindFirstChildOfClass("Beam")
	checar(feixe and feixe.Enabled == true, "holofotes ligados no nível 10")
	Sim.avancar(0.3)
	Remotos.Melhorar:FireServer("vagas")
	checar(Game.vagasTotais(ea) == 11 and ea.base.vagas[11].bloco.Transparency == 0, "melhoria de vagas libera pedestal")
	Sim.avancar(0.3)
	Remotos.Melhorar:FireServer("tapa")
	checar(ea.melhorias.tapa == 1, "melhoria do tapa")
	Sim.avancar(0.3)
	Remotos.Melhorar:FireServer("hack")
	Remotos.Melhorar:FireServer(nil)
	semErros("melhorias")

	-- 8. Índice: completar a raridade Comum ---------------------------------
	local multSemIndice = Game.multiplicador(ea)
	for _, def in ipairs(Config.robosDaRaridade(1)) do
		if not ea.descobertos[def.id] then
			Game.darRobo(ea, def, nil)
		end
	end
	Sim.avancar(3)
	checar(ea.indicePremios["1"] == true, "Índice: raridade Comum completa")
	checar(math.abs(Game.multiplicador(ea) / multSemIndice - 1.05) < 1e-6, "Índice completo dá +5%")
	semErros("índice")

	-- 9. Beto rouba da Ana ---------------------------------------------------
	local alvo = ea.vagas[3]
	Sim.moverPara(beto, ea.base.saida)
	Sim.disparar(alvo.prompt.Triggered, beto)
	checar(alvo.estado == "base", "não rouba de fora da base")
	Sim.moverPara(beto, ea.base.pedestais[3] * CFrame.new(0, 3, 3))
	Sim.disparar(alvo.prompt.Triggered, beto)
	Sim.avancar(0.3)
	checar(alvo.estado == "carregado" and eb.carregando == alvo, "Beto está carregando o robô")
	checar(beto:GetAttribute("Carregando") == alvo.def.id, "tela do Beto sabe qual robô ele leva")
	checar(beto.Character.Humanoid.WalkSpeed == Config.ROUBO.VELOCIDADE_CARREGANDO, "Beto ficou mais lento")
	Sim.moverPara(beto, eb.base.nascer)
	Sim.avancar(3)
	semErros("roubo")
	checar(alvo.dono == eb and alvo.estado == "base", "roubo concluído")
	checar(ea.vagas[3] == nil, "vaga da Ana ficou livre")
	checar(beto.Character.Humanoid.WalkSpeed == Config.ROUBO.VELOCIDADE_NORMAL, "Beto voltou ao normal")

	-- tapa: Ana tenta roubar de volta e leva um tapa
	Sim.moverPara(ana, eb.base.pedestais[alvo.vaga] * CFrame.new(0, 3, 3))
	Sim.disparar(alvo.prompt.Triggered, ana)
	Sim.avancar(0.3)
	checar(ea.carregando == alvo, "Ana pegou o robô de volta")
	local posAna = ana.Character.HumanoidRootPart.Position
	Sim.moverPara(beto, CFrame.lookAt(posAna + Vector3.new(0, 0, 4), posAna))
	Sim.disparar(Sim.sinalDe(beto.Backpack.Tapa, "Activated"))
	Sim.avancar(3)
	checar(ea.carregando == nil and alvo.dono == eb and alvo.estado == "base", "tapa devolveu o robô")

	-- morrer carregando devolve o robô
	Sim.moverPara(ana, eb.base.pedestais[alvo.vaga] * CFrame.new(0, 3, 3))
	Sim.disparar(alvo.prompt.Triggered, ana)
	Sim.avancar(0.3)
	Sim.matar(ana)
	Sim.avancar(3)
	checar(ea.carregando == nil and alvo.dono == eb, "morrer carregando devolve o robô")
	Sim.criarPersonagem(ana, Vector3.new(0, 3, 21))
	Sim.avancar(1)
	semErros("tapa e morte")

	-- 10. Tranca (e o passe que dobra o tempo) --------------------------------
	Sim.disparar(Sim.sinalDe(mps, "PromptGamePassPurchaseFinished"), ana, ids.tranca, true)
	Sim.avancar(0.2)
	checar(ea.passes.tranca == true and ana:GetAttribute("PasseTranca") == true, "comprou o passe Tranca longa")
	Sim.moverPara(ana, ea.base.botao.CFrame * CFrame.new(0, 3, 0))
	Sim.avancar(0.5)
	checar(Game.trancada(ea), "Ana trancou a base")
	local duracao = ea.trancadaAte - workspace:GetServerTimeNow()
	checar(duracao > Config.duracaoTranca(0, false) + 30, "passe dobra a tranca")
	checar(ea.base.modelo:GetAttribute("TrancadaAte") == ea.trancadaAte, "base avisa até quando está trancada")
	Sim.moverPara(beto, ea.base.nascer)
	Sim.avancar(0.5)
	checar(not MapBuilder.dentroDaBase(ea.base, beto.Character.HumanoidRootPart.Position, 0), "Beto foi expulso")
	Sim.avancar(duracao + 1)
	checar(not Game.trancada(ea) and ea.base.barreira.Transparency == 1, "tranca acaba (mesmo parada no botão)")
	Sim.moverPara(ana, ea.base.nascer)
	semErros("tranca")

	-- 11. Venda e renascer (melhorias continuam) ------------------------------
	local _, meu = next(ea.vagas)
	antes = ea.dinheiro
	local valorVenda = Game.valorVenda(meu)
	Sim.disparar(meu.prompt.Triggered, ana)
	checar(meu.estado == "destruido" and ea.dinheiro == antes + valorVenda, "venda paga metade do preço")
	Sim.avancar(1.1)
	Remotos.Renascer:FireServer()
	Sim.avancar(0.5)
	checar(ea.renascimentos == 1 and next(ea.vagas) == nil, "Ana renasceu (robôs zerados)")
	checar(ea.melhorias.renda == Config.MELHORIAS.renda.max, "melhorias continuam depois de renascer")
	semErros("venda e renascer")

	-- 12. Loja: produtos ----------------------------------------------------
	local processar = Sim.internos[mps].props.ProcessReceipt
	checar(type(processar) == "function", "ProcessReceipt registrado")
	local Granted = Enum.ProductPurchaseDecision.PurchaseGranted
	local Pendente = Enum.ProductPurchaseDecision.NotProcessedYet
	antes = eb.dinheiro
	checar(processar({ PlayerId = 2, ProductId = 2001, PurchaseId = "c1" }) == Granted, "pacote de dinheiro concedido")
	local depoisPacote = eb.dinheiro
	checar(depoisPacote >= antes + Config.LOJA.PACOTES[1].minimo, "pacote entrega o dinheiro")
	checar(processar({ PlayerId = 2, ProductId = 2001, PurchaseId = "c1" }) == Granted and eb.dinheiro == depoisPacote,
		"compra repetida não entrega de novo")
	checar(processar({ PlayerId = 2, ProductId = 9999, PurchaseId = "c2" }) == Pendente, "produto desconhecido fica pendente")
	checar(processar({ PlayerId = 999, ProductId = 2001, PurchaseId = "c3" }) == Pendente, "jogador ausente fica pendente")
	checar(processar({ PlayerId = 2, ProductId = 3001, PurchaseId = "c4" }) == Granted, "sorte do servidor comprada")
	checar((RS:GetAttribute("HoraDaSorteAte") or 0) > workspace:GetServerTimeNow() + 800 and RS:GetAttribute("HoraDaSortePor") == "Beto",
		"sorte de 15 min com o nome de quem deu")
	checar(Conveyor.sorteAtual() == Config.SORTE.FORCA, "esteira usa a sorte")
	local robosBeto = Game.vagasOcupadas(eb)
	checar(processar({ PlayerId = 2, ProductId = 3002, PurchaseId = "c5" }) == Granted, "caixa surpresa comprada")
	Sim.avancar(3)
	checar(Game.vagasOcupadas(eb) == robosBeto + 1, "caixa deu um robô")
	local melhorRaridade = 0
	for _, r in pairs(eb.vagas) do
		melhorRaridade = math.max(melhorRaridade, r.def.raridade)
	end
	checar(melhorRaridade >= 4, "caixa dá Épico ou melhor")
	for _ = 1, 300 do
		local def = Config.sortearCaixa(G.Random.new())
		if def.raridade < 4 then
			checar(false, "caixa nunca dá menos que Épico")
			break
		end
	end
	-- anúncio: o Beto pede, o Roblox mostra e entrega pelo ProcessReceipt
	Sim.jogadorLocal = beto
	Remotos.VerAnuncio:FireServer("dobro")
	checar(#Sim.anuncios == 1 and Sim.anuncios[1].produto == 3003, "anúncio pedido ao Roblox")
	local multSemAnuncio = Game.multiplicador(eb)
	checar(processar({ PlayerId = 2, ProductId = 3003, PurchaseId = "ad1" }) == Granted, "prêmio do anúncio entregue")
	checar(math.abs(Game.multiplicador(eb) / multSemAnuncio - 2) < 1e-6 and (beto:GetAttribute("DobroAte") or 0) > workspace:GetServerTimeNow(),
		"anúncio dá x2 por 10 minutos")
	Remotos.VerAnuncio:FireServer("dobro")
	checar(#Sim.anuncios == 1, "anúncio tem limite de pedidos")
	checar(#eb.dados.compras == 4, "compras ficam guardadas no save")
	semErros("loja")

	-- 13. Caio: país sem caixa paga ------------------------------------------
	local caio = Sim.novoJogador(3, "Caio", "es-es")
	Sim.avancar(0.5)
	Sim.criarPersonagem(caio, Vector3.new(0, 3, 21))
	Sim.avancar(1)
	local ec = Game.estados[caio]
	checar(ec and caio:GetAttribute("SemCaixa") == true, "caixa escondida onde é proibida")
	checar(ana:GetAttribute("SemCaixa") == false, "caixa aparece onde é permitida")
	checar(ec and ec.idioma == "en", "espanhol cai no inglês")

	-- 14. Salvar e carregar ---------------------------------------------------
	Game.adicionarDinheiro(ea, 5000)
	for _ = 1, 2 do
		Game.darRobo(ea, Config.RoboPorId.torradeira, "diamante")
	end
	Sim.avancar(3)
	local dinheiroAntes = math.floor(ea.dinheiro)
	Sim.removerJogador(ana)
	Sim.avancar(1)
	checar(Game.estados[ana] == nil and ea.base.dono == nil, "Ana saiu e a base ficou livre")
	checar(ea.base.modelo:GetAttribute("DonoNome") == "" and ea.base.enfeites.ouro[1].Transparency == 1,
		"base livre volta ao visual simples")
	local salvo = Sim.cofres["RoubaRobo_v1"]["jogador_1"]
	checar(salvo and salvo.sessao == nil, "salvou e soltou a trava")
	if salvo then
		checar(salvo.versao == 2 and salvo.renascimentos == 1, "salvou versão e renascimentos")
		checar(#salvo.robos == 2 and salvo.robos[1].mut == "diamante", "salvou robôs e mutações")
		checar(salvo.melhorias.renda == Config.MELHORIAS.renda.max and salvo.melhorias.vagas == 1, "salvou melhorias")
		checar(salvo.descobertos.torradeira == true and salvo.indicePremios["1"] == true, "salvou o Índice")
		checar(salvo.diario.sequencia >= 1 and salvo.grupoPremiado == true, "salvou prêmio diário e grupo")
		checar(salvo.saida > 0 and salvo.totalGanho > 0, "salvou hora de saída e total ganho")
	end
	local ana2 = Sim.novoJogador(1, "Ana", "pt-br")
	Sim.avancar(0.5)
	Sim.criarPersonagem(ana2, Vector3.new(0, 3, 21))
	Sim.avancar(1)
	local ea2 = Game.estados[ana2]
	checar(ea2 ~= nil, "Ana voltou")
	if ea2 then
		checar(Game.vagasOcupadas(ea2) == 2 and ea2.renascimentos == 1, "robôs e renascimentos restaurados")
		checar(ea2.melhorias.renda == Config.MELHORIAS.renda.max and ea2.passes.tranca == false,
			"melhorias restauradas (o passe vem do Roblox)")
		checar((ana2:GetAttribute("OfflinePendente") or 0) == 0, "saiu agora: sem dinheiro offline")
		checar(ea2.dinheiro >= dinheiroAntes, "dinheiro restaurado")
		checar(ea2.vagas[1] ~= nil and ea2.base.enfeites.ouro[1].Transparency == 0, "visual da base restaurado")
	end
	checar(Sim.cofres["RoubaRobo_v1"]["jogador_1"].sessao ~= nil, "trava de sessão ao entrar")
	semErros("salvar e carregar")

	-- 15. Saídas no meio do roubo --------------------------------------------
	if ea2 then
		local _, roboAna = next(ea2.vagas)
		Sim.moverPara(beto, ea2.base.pedestais[roboAna.vaga] * CFrame.new(0, 3, 3))
		Sim.disparar(roboAna.prompt.Triggered, beto)
		Sim.avancar(0.3)
		checar(eb.carregando == roboAna, "Beto carregando robô da Ana")
		Sim.removerJogador(ana2)
		Sim.avancar(0.5)
		checar(eb.carregando == nil and roboAna.estado == "destruido", "dono saiu: robô some da cabeça do ladrão")
		checar(#Sim.cofres["RoubaRobo_v1"]["jogador_1"].robos == 2, "robô sendo roubado conta como da Ana")
	end
	semErros("saídas no meio do roubo")

	-- 16. Trava de sessão, falha nos dados e servidor cheio --------------------
	local travado = Sim.novoJogador(60, "Travado", "pt-br")
	Sim.avancar(45)
	checar(#Sim.expulsos >= 1 and string.find(Sim.expulsos[#Sim.expulsos].mensagem, "outro servidor", 1, true) ~= nil,
		"save travado por outro servidor: pede para entrar de novo")
	checar(Sim.cofres["RoubaRobo_v1"]["jogador_60"].dinheiro == 999, "save travado não é sobrescrito")
	Sim.removerJogador(travado)

	Sim.falharDataStore = true
	local duda = Sim.novoJogador(4, "Duda", "pt-br")
	Sim.avancar(45)
	checar(string.find(Sim.expulsos[#Sim.expulsos].mensagem, "carregar", 1, true) ~= nil, "falha ao carregar: pede para entrar de novo")
	checar(Game.estados[duda] == nil, "falha ao carregar: não joga com perfil vazio")
	Sim.removerJogador(duda)
	Sim.falharDataStore = false
	checar(Sim.cofres["RoubaRobo_v1"]["jogador_4"] == nil, "falha ao carregar: nada sobrescrito")

	local expulsosAntes = #Sim.expulsos
	local extras = {}
	for i = 10, 17 do
		table.insert(extras, Sim.novoJogador(i, "Extra" .. i))
	end
	Sim.avancar(1)
	checar(#Sim.expulsos > expulsosAntes, "servidor cheio avisa o 9º jogador")
	for _, p in ipairs(extras) do
		Sim.removerJogador(p)
	end
	Sim.avancar(1)
	semErros("trava, falha e servidor cheio")

	-- 17. Ranking --------------------------------------------------------------
	Sim.avancar(125)
	local ranking = workspace.Mapa.Ranking
	checar((ranking:GetAttribute("RTotal") or 0) >= 1, "ranking global preenchido")
	checar(ranking:GetAttribute("R1Nome") ~= nil and (ranking:GetAttribute("R1Valor") or 0) > 0, "ranking tem nome e valor")
	semErros("ranking")

	-- 18. Tela do jogador (Beto, em inglês) ------------------------------------
	Sim.jogadorLocal = beto
	Sim.definir(Players, "LocalPlayer", beto)
	Sim.executar(scripts["client/HUD"])
	Sim.executar(scripts["client/Mundo"])
	Sim.avancar(1)
	semErros("interface iniciou")
	local hud = beto.PlayerGui:FindFirstChild("RoubaRoboHUD")
	checar(hud ~= nil, "HUD criada")
	if hud then
		Sim.avancar(1)
		local textoDinheiro = hud.Topo.Placar.Dinheiro.Text
		checar(string.sub(textoDinheiro, 1, 1) == "$" and textoDinheiro ~= "$0", "HUD mostra o dinheiro (com animação): " .. textoDinheiro)
		checar(string.find(hud.Topo.Placar.Renda.Text, "robots", 1, true) ~= nil, "HUD em inglês para o Beto")
		checar(hud.Topo.Dobro.Visible == true, "faixa do x2 do anúncio aparece")
		checar(hud.Topo.Sorte.Visible == true and string.find(hud.Topo.Sorte.Texto.Text, "Beto", 1, true) ~= nil,
			"faixa da sorte mostra quem deu")
		Game.notificar(beto, "bom", "comprou", Game.nomeRobo(Config.RoboPorId.torradeira, nil))
		Sim.avancar(0.1)
		local ultimo = nil
		for _, filho in ipairs(hud.Topo.Avisos:GetChildren()) do
			if filho:IsA("TextLabel") then
				ultimo = filho
			end
		end
		checar(ultimo and ultimo.Text == "You bought Turbo Toaster!", "aviso traduzido para o inglês")

		local function clicar(caminho)
			Sim.disparar(Sim.sinalDe(caminho.Corpo, "Activated"))
			Sim.avancar(0.4)
		end
		clicar(hud.Botoes.menu_loja)
		checar(hud.Loja.Visible == true, "botão Loja abre a loja")
		checar(hud.Loja.Conteudo.Secao_passes.Visible and not hud.Loja.Conteudo.Secao_sorte.Visible, "loja abre na aba Passes")
		clicar(hud.Loja.Conteudo:FindFirstChild("Frame"):FindFirstChild("sorte") or hud.Botoes.menu_loja)
		checar(hud.Loja.Conteudo.Secao_sorte.Visible == true, "aba Sorte e caixa")
		clicar(hud.Botoes.menu_indice)
		checar(hud.Indice.Visible == true and hud.Loja.Visible == false, "abrir um painel fecha o outro")
		clicar(hud.Botoes.menu_melhorar)
		checar(hud.Melhorar.Visible == true, "painel Melhorar")
		clicar(hud.Lado.menu_premio)
		checar(hud.Diario.Visible == true, "painel Prêmio diário")
		local robosAntesDiario = Game.vagasOcupadas(eb)
		local dinheiroAntesDiario = eb.dinheiro
		clicar(hud.Diario.Conteudo.Frame:FindFirstChildWhichIsA("Frame"):FindFirstChild("Botao"))
		checar(eb.dados.diario.sequencia == 1 and eb.dinheiro > dinheiroAntesDiario - 1 and robosAntesDiario >= 0,
			"botão Pegar da tela pega o prêmio diário")
		clicar(hud.Lado.menu_missoes)
		checar(hud.Missoes.Visible == true, "painel Missões")
		clicar(hud.Botoes.menu_renascer)
		checar(hud.Renascer.Visible == true, "painel Renascer")

		-- dinheiro offline abre o "bem-vindo de volta"
		Remotos.Teste:FireServer("dia")
		Sim.avancar(0.5)
		checar(hud.Offline.Visible == true, "painel Bem-vindo de volta abre sozinho")
		clicar(hud.Offline.Conteudo.Botao)
		checar((beto:GetAttribute("OfflinePendente") or 0) == 0 and hud.Offline.Visible == false, "botão pega o dinheiro offline")

		-- textos do mundo em inglês
		local fabrica = workspace.Mapa.Fabrica.Placa.Texto
		checar(fabrica.Text == "ROBOT FACTORY", "placa da fábrica em inglês")
		local titulo = eb.base.modelo.SuportePlaca.Placa.Titulo
		checar(titulo.Text == "BETO'S BASE", "placa da base em inglês")
		local _, roboBeto = next(eb.vagas)
		local pps = Sim.servico("ProximityPromptService")
		Sim.disparar(Sim.sinalDe(pps, "PromptShown"), roboBeto.prompt)
		Sim.avancar(0.1)
		checar(string.find(roboBeto.prompt.ActionText, "Sell for", 1, true) == 1, "robô próprio mostra Sell for")
		local daEsteira = Conveyor.robos()[1]
		Sim.disparar(Sim.sinalDe(pps, "PromptShown"), daEsteira.prompt)
		Sim.avancar(0.1)
		checar(daEsteira.prompt.ActionText == "Buy", "robô da esteira mostra Buy")
		local ec2 = Game.estados[caio]
		if ec2 then
			Game.darRobo(ec2, Config.RoboPorId.lata, nil)
			Sim.avancar(3)
			local _, roboCaio = next(ec2.vagas)
			Sim.disparar(Sim.sinalDe(pps, "PromptShown"), roboCaio.prompt)
			Sim.avancar(0.1)
			checar(roboCaio.prompt.ActionText == "Steal", "robô de outro jogador mostra Steal")
		end
		local maisNovo = Conveyor.robos()[#Conveyor.robos()]
		local info = maisNovo.modelo.Raiz.Info
		daEsteira = maisNovo
		checar(info.Nome.Text == Config.nomeDe(daEsteira.def, "en"), "placa do robô em inglês")
		local linha1 = workspace.Mapa.Ranking.Tela.Linha1
		checar(string.find(linha1.Text, "1. ", 1, true) == 1, "placar desenhado na tela")

		-- etiqueta VIP no chat
		local tcs = Sim.servico("TextChatService")
		local aoReceber = Sim.internos[tcs].props.OnIncomingMessage
		checar(type(aoReceber) == "function", "etiqueta VIP registrada no chat")
		if aoReceber then
			local props = aoReceber({ TextSource = { UserId = 2 }, PrefixText = "Beto:" })
			checar(string.find(props.PrefixText, "[VIP]", 1, true) ~= nil, "mensagem do VIP ganha a etiqueta")
		end

		-- a interface cabe em telas pequenas e grandes
		local camera = Sim.novaInstancia("Camera", true)
		camera.Name = "Camera"
		Sim.definir(camera, "ViewportSize", G.Vector2.new(1280, 720))
		camera.Parent = workspace
		Sim.definir(workspace, "CurrentCamera", camera)
		Sim.avancar(0.5)
		local escalaTopo = hud.Topo:FindFirstChildOfClass("UIScale")
		local escalaLoja = hud.Loja:FindFirstChildOfClass("UIScale")
		local escalaBotoes = hud.Botoes:FindFirstChildOfClass("UIScale")
		checar(escalaTopo ~= nil and escalaLoja ~= nil and escalaBotoes ~= nil, "interface tem controle de tamanho")
		if escalaTopo and escalaLoja and escalaBotoes then
			for _, medida in ipairs({ { 386, 412 }, { 640, 480 }, { 1280, 720 }, { 1920, 1080 } }) do
				local larguraTela, alturaTela = medida[1], medida[2]
				local nome = larguraTela .. "x" .. alturaTela
				Sim.definir(camera, "ViewportSize", G.Vector2.new(larguraTela, alturaTela))
				Sim.avancar(0.3)
				local placarLargura = 232 * escalaTopo.Scale
				local placarAltura = 50 * escalaTopo.Scale
				checar(placarLargura <= larguraTela * 0.45,
					"em " .. nome .. " o placar ocupa no máximo 45% da largura (" .. math.floor(placarLargura) .. "px)")
				checar(placarAltura <= alturaTela * 0.18, "em " .. nome .. " o placar não é alto demais")
				checar(560 * escalaLoja.Scale <= larguraTela and 420 * escalaLoja.Scale <= alturaTela,
					"em " .. nome .. " a loja cabe inteira na tela")
				checar(132 * escalaBotoes.Scale <= larguraTela * 0.35, "em " .. nome .. " os botões cabem na lateral")
			end
			-- numa tela grande a interface não fica gigante
			Sim.definir(camera, "ViewportSize", G.Vector2.new(1920, 1080))
			Sim.avancar(0.3)
			checar(escalaTopo.Scale <= 1.1 and escalaLoja.Scale <= 1.15, "interface não cresce sem limite")
			Sim.definir(camera, "ViewportSize", G.Vector2.new(1280, 720))
			Sim.avancar(0.3)
		end

		-- empurrão e arco-íris
		Remotos.Empurrao:FireClient(beto, Vector3.new(70, 0, 0))
		Sim.avancar(0.1)
		checar(beto.Character.Humanoid.PlatformStand == true, "tapa derruba o jogador")
		Sim.avancar(1)
		checar(beto.Character.Humanoid.PlatformStand == false, "jogador levanta depois do tapa")
		local arco = Game.novoRobo(Config.RoboPorId.bipbop, "arcoiris", CFrame.new(0, 1, 0))
		Sim.avancar(0.5)
		local cor1 = arco.modelo.Corpo.Color
		Sim.avancar(0.5)
		checar(arco.modelo.Corpo.Color ~= cor1, "robô arco-íris muda de cor")
		Game.destruirRobo(arco)
		Game.efeito("compra", Vector3.new(0, 5, 0), Config.Raridades[3].cor)
		Remotos.Efeito:FireClient(beto, "alarme", Vector3.new(0, 5, 0), Config.Raridades[6].cor)
		Remotos.Efeito:FireClient(beto, "premio")
		Sim.avancar(1)
	end
	semErros("interface")

	-- 19. Muito tempo de jogo ------------------------------------------------
	Sim.avancar(120, 1 / 10)
	checar(Conveyor.quantidade() < 40, "esteira não acumula robôs (" .. Conveyor.quantidade() .. ")")
	checar(#workspace.Robos:GetChildren() < 80, "robôs antigos são reciclados (" .. #workspace.Robos:GetChildren() .. ")")
	checar(Textos.t("pt", "bemvindo") ~= Textos.t("en", "bemvindo"), "textos existem nos dois idiomas")
	semErros("120 segundos de jogo")

	-- 20. Fechar o servidor salva todo mundo --------------------------------
	for _, fn in ipairs(Sim.aoFechar) do
		Sim.task.spawn(fn)
	end
	Sim.avancar(4)
	local salvoBeto = Sim.cofres["RoubaRobo_v1"]["jogador_2"]
	checar(salvoBeto ~= nil and salvoBeto.vipPremiado == true, "fechar o servidor salva os jogadores")
	checar(salvoBeto ~= nil and salvoBeto.sessao == nil, "fechar o servidor solta as travas")
	semErros("fechamento")

	return resultado
end
