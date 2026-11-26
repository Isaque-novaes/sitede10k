--[[
	Roteiro de teste do Rouba Robô no Roblox simulado.
	Simula jogadores comprando, roubando, levando tapa, trancando a base,
	vendendo, renascendo, saindo e voltando (com salvamento).

	ARQUIVOS (global vinda do Python): lista de { grupo, nome, classe, caminho }
]]

return function(Sim)
	local G = Sim.G
	local Instance, Vector3, CFrame = G.Instance, G.Vector3, G.CFrame

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

	-- 1. Servidor liga -------------------------------------------------------
	Sim.executar(scripts["server/Main"])
	Sim.avancar(1)
	semErros("início do servidor")

	local Config = Sim.requerer(scripts["shared/Config"])
	local Format = Sim.requerer(scripts["shared/Format"])
	local Game = Sim.requerer(scripts["server/Game"])
	local Conveyor = Sim.requerer(scripts["server/Conveyor"])
	local MapBuilder = Sim.requerer(scripts["server/MapBuilder"])
	local Remotos = RS:FindFirstChild("Remotos")

	checar(workspace:FindFirstChild("Mapa") ~= nil, "mapa criado")
	checar(#workspace.Mapa.Bases:GetChildren() == 8, "8 bases criadas")
	checar(Conveyor.quantidade() >= 15, "esteira começa cheia (" .. Conveyor.quantidade() .. " robôs)")
	checar(Remotos ~= nil and Remotos:FindFirstChild("Notificar") ~= nil, "remotos criados")

	-- todos os robôs do catálogo e todas as mutações montam sem erro
	local RobotFactory = Sim.requerer(scripts["server/RobotFactory"])
	for _, def in ipairs(Config.Robos) do
		local visual = RobotFactory.construir(def, nil)
		visual.modelo:Destroy()
	end
	for _, mut in ipairs(Config.Mutacoes) do
		local visual = RobotFactory.construir(Config.Robos[1], mut.id)
		visual.modelo:Destroy()
	end
	semErros("montagem de todos os robôs")

	-- 2. Dois jogadores entram ----------------------------------------------
	local ana = Sim.novoJogador(1, "Ana")
	local beto = Sim.novoJogador(2, "Beto")
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
	checar(ea.base ~= eb.base, "cada um ganhou uma base diferente")
	checar(ana.leaderstats.Dinheiro.Value == Config.DINHEIRO_INICIAL, "Ana começa com $100")
	checar((ana.Character.HumanoidRootPart.Position - ea.base.nascer.Position).Magnitude < 0.01,
		"Ana nasceu dentro da própria base")
	checar(ana.Backpack:FindFirstChild("Tapa") ~= nil, "Ana recebeu o Tapa")
	checar(ea.base.rotuloDono.Text == "Base de Ana", "placa da base mostra o dono")
	checar(MapBuilder.dentroDaBase(ea.base, ea.base.nascer.Position, 0), "ponto de nascer fica dentro da base")
	checar(not MapBuilder.dentroDaBase(ea.base, ea.base.saida.Position, 0), "ponto de saída fica fora da base")
	for vaga, pedestal in ipairs(ea.base.pedestais) do
		checar(MapBuilder.dentroDaBase(ea.base, pedestal.Position, -2), "pedestal " .. vaga .. " dentro da base")
	end

	-- 3. Compra na esteira ---------------------------------------------------
	local barato = nil
	for _, r in ipairs(Conveyor.robos()) do
		if Config.precoDe(r.def, r.mut) <= ea.dinheiro then
			barato = r
			break
		end
	end
	if not barato then
		barato = Game.novoRobo(Config.RoboPorId.parafusinho, nil, CFrame.new(0, 1, 0))
	end
	local preco = Config.precoDe(barato.def, barato.mut)
	local antes = ea.dinheiro
	Sim.disparar(barato.prompt.Triggered, ana)
	checar(ea.dinheiro == antes - preco, "compra desconta o preço")
	Sim.avancar(3)
	semErros("compra")
	checar(barato.estado == "base" and barato.dono == ea and ea.vagas[1] == barato, "robô comprado foi para a vaga 1")
	checar((barato.modelo:GetPivot().Position - ea.base.pedestais[1].Position).Magnitude < 0.01,
		"robô está em cima do pedestal")
	checar(barato.prompt.Enabled == true and barato.prompt.HoldDuration == Config.ROUBO.SEGURAR,
		"prompt do robô na base está ativo")
	local renda = Config.rendaDe(barato.def, barato.mut)
	checar(ana:GetAttribute("RendaPorSegundo") == renda, "atributo de renda atualizado")
	antes = ea.dinheiro
	Sim.avancar(5)
	checar(ea.dinheiro >= antes + renda * 4, "renda por segundo cai na conta")
	checar(ana.leaderstats.Dinheiro.Value == math.floor(ea.dinheiro), "leaderstats acompanha o dinheiro")

	-- comprar sem dinheiro não funciona
	local caro = Game.novoRobo(Config.RoboPorId.supremo, nil, CFrame.new(10, 1, 0))
	Sim.disparar(caro.prompt.Triggered, beto)
	checar(caro.estado == "esteira" and eb.vagas[1] == nil, "não compra sem dinheiro")
	Game.destruirRobo(caro)

	-- 4. Beto rouba da Ana ---------------------------------------------------
	Sim.moverPara(beto, ea.base.pedestais[1] * CFrame.new(0, 3, 3))
	-- de fora da base não dá
	Sim.moverPara(beto, ea.base.saida)
	Sim.disparar(barato.prompt.Triggered, beto)
	checar(barato.estado == "base", "não rouba de fora da base")
	Sim.moverPara(beto, ea.base.pedestais[1] * CFrame.new(0, 3, 3))
	Sim.disparar(barato.prompt.Triggered, beto)
	Sim.avancar(0.3)
	semErros("início do roubo")
	checar(barato.estado == "carregado" and eb.carregando == barato, "Beto está carregando o robô")
	checar(beto.Character.Humanoid.WalkSpeed == Config.ROUBO.VELOCIDADE_CARREGANDO, "Beto ficou mais lento")
	checar(beto:GetAttribute("Carregando") ~= nil, "atributo Carregando ligado")
	checar(barato.modelo:FindFirstChild("Soldas") ~= nil, "robô soldado no Beto")
	checar(Game.rendaPorSegundo(ea) == 0, "robô carregado não rende para a Ana")
	Sim.moverPara(beto, eb.base.nascer)
	Sim.avancar(3)
	semErros("entrega do roubo")
	checar(barato.dono == eb and barato.estado == "base", "roubo concluído: robô agora é do Beto")
	checar(ea.vagas[1] == nil, "vaga da Ana ficou livre")
	checar(beto.Character.Humanoid.WalkSpeed == Config.ROUBO.VELOCIDADE_NORMAL, "Beto voltou à velocidade normal")
	checar(barato.modelo:FindFirstChild("Soldas") == nil, "soldas removidas")
	local todasAncoradas = true
	for _, item in ipairs(barato.modelo:GetDescendants()) do
		if item:IsA("BasePart") and not item.Anchored then
			todasAncoradas = false
		end
	end
	checar(todasAncoradas, "peças do robô voltaram a ficar ancoradas")
	checar(beto:GetAttribute("Carregando") == nil, "atributo Carregando desligado")

	-- 5. Ana tenta roubar de volta e leva um tapa ---------------------------
	Sim.moverPara(ana, eb.base.pedestais[barato.vaga] * CFrame.new(0, 3, 3))
	Sim.disparar(barato.prompt.Triggered, ana)
	Sim.avancar(0.3)
	checar(ea.carregando == barato, "Ana pegou o robô de volta")
	local posAna = ana.Character.HumanoidRootPart.Position
	Sim.moverPara(beto, CFrame.lookAt(posAna + Vector3.new(0, 0, 4), posAna))
	Sim.disparar(Sim.sinalDe(beto.Backpack.Tapa, "Activated"))
	Sim.avancar(3)
	semErros("tapa")
	checar(ea.carregando == nil, "tapa fez a Ana soltar")
	checar(barato.dono == eb and barato.estado == "base", "robô voltou para o Beto")
	checar(ana.Character.Humanoid.WalkSpeed == Config.ROUBO.VELOCIDADE_NORMAL, "Ana voltou à velocidade normal")

	-- roubo que demora demais volta sozinho
	Sim.moverPara(ana, eb.base.pedestais[barato.vaga] * CFrame.new(0, 3, 3))
	Sim.disparar(barato.prompt.Triggered, ana)
	Sim.avancar(0.3)
	Sim.moverPara(ana, Vector3.new(0, 3, 21))
	Sim.avancar(Config.ROUBO.TEMPO_MAXIMO + 3)
	checar(ea.carregando == nil and barato.dono == eb and barato.estado == "base", "roubo expira e o robô volta")

	-- morrer carregando devolve o robô
	Sim.moverPara(ana, eb.base.pedestais[barato.vaga] * CFrame.new(0, 3, 3))
	Sim.disparar(barato.prompt.Triggered, ana)
	Sim.avancar(0.3)
	Sim.matar(ana)
	Sim.avancar(3)
	checar(ea.carregando == nil and barato.dono == eb and barato.estado == "base", "morrer carregando devolve o robô")
	Sim.criarPersonagem(ana, Vector3.new(0, 3, 21))
	Sim.avancar(1)
	checar(ana.Backpack:FindFirstChild("Tapa") ~= nil, "Tapa volta depois de renascer o personagem")
	semErros("roubos que falham")

	-- 6. Tranca da base ------------------------------------------------------
	Sim.moverPara(beto, eb.base.botao.CFrame * CFrame.new(0, 3, 0))
	Sim.avancar(0.5)
	checar(Game.trancada(eb), "Beto trancou a base pisando no botão")
	checar(eb.base.barreira.Transparency < 1, "barreira aparece")
	Sim.moverPara(ana, eb.base.nascer)
	Sim.avancar(0.5)
	checar(not MapBuilder.dentroDaBase(eb.base, ana.Character.HumanoidRootPart.Position, 0),
		"Ana foi expulsa da base trancada")
	Sim.disparar(barato.prompt.Triggered, ana)
	checar(barato.estado == "base", "não dá para roubar de base trancada")
	-- Beto fica parado no botão: quando a tranca acaba, ela NÃO religa sozinha
	Sim.avancar(Config.duracaoTranca(0) + 1)
	checar(not Game.trancada(eb), "tranca acaba depois do tempo (mesmo parado no botão)")
	checar(eb.base.barreira.Transparency == 1, "barreira some")
	Sim.moverPara(beto, eb.base.nascer)
	Sim.avancar(0.5)
	Sim.moverPara(beto, eb.base.botao.CFrame * CFrame.new(0, 3, 0))
	Sim.avancar(0.5)
	checar(Game.trancada(eb), "pisar de novo tranca de novo")
	semErros("tranca")

	-- 7. Venda ---------------------------------------------------------------
	antes = eb.dinheiro
	local valorVenda = Game.valorVenda(barato)
	Sim.disparar(barato.prompt.Triggered, beto)
	checar(barato.estado == "destruido", "Beto vendeu o robô")
	checar(eb.dinheiro == antes + valorVenda, "venda paga metade do preço")
	checar(eb.vagas[1] == nil, "vaga liberada na venda")

	-- 8. Remotos do cliente: teste de dinheiro e renascer -------------------
	Sim.jogadorLocal = ana
	-- compra dois robôs antes de renascer
	Game.adicionarDinheiro(ea, 1000)
	for _ = 1, 2 do
		local r = Game.novoRobo(Config.RoboPorId.bipbop, "dourado", CFrame.new(0, 1, 0))
		Sim.disparar(r.prompt.Triggered, ana)
	end
	Sim.avancar(3)
	Remotos.Teste:FireServer("dinheiro")
	Sim.avancar(0.2)
	checar(ea.dinheiro >= Config.custoRenascer(0), "botão de teste deu dinheiro no Studio")
	local ocupadas = 0
	for _ in pairs(ea.vagas) do
		ocupadas = ocupadas + 1
	end
	checar(ocupadas == 2, "Ana tem 2 robôs")
	Remotos.Renascer:FireServer()
	Sim.avancar(0.5)
	checar(ea.renascimentos == 1 and ana.leaderstats.Renascimentos.Value == 1, "Ana renasceu")
	checar(ea.dinheiro == Config.DINHEIRO_INICIAL, "dinheiro voltou ao inicial")
	checar(next(ea.vagas) == nil, "robôs zerados ao renascer")
	checar(Game.multiplicador(ea) == Config.multiplicador(1), "multiplicador aumentou")
	Remotos.Renascer:FireServer()
	Sim.avancar(0.2)
	checar(ea.renascimentos == 1, "não renasce sem dinheiro")
	Remotos.Teste:FireServer("sorte")
	Sim.avancar(0.2)
	checar((RS:GetAttribute("HoraDaSorteAte") or 0) > workspace:GetServerTimeNow(), "Hora da Sorte começou")
	semErros("renascer e testes")

	-- 9. Salvar e carregar ---------------------------------------------------
	Game.adicionarDinheiro(ea, 5000)
	for _ = 1, 2 do
		local r = Game.novoRobo(Config.RoboPorId.torradeira, "diamante", CFrame.new(0, 1, 0))
		Sim.disparar(r.prompt.Triggered, ana)
	end
	Sim.avancar(3)
	local dinheiroAntes = math.floor(ea.dinheiro)
	Sim.removerJogador(ana)
	Sim.avancar(1)
	checar(Game.estados[ana] == nil, "Ana saiu do jogo")
	checar(ea.base.dono == nil and ea.base.rotuloDono.Text == "Base livre", "base da Ana ficou livre")
	local cofre = Sim.cofres["RoubaRobo_v1"] or {}
	local salvo = cofre["jogador_1"]
	checar(salvo ~= nil, "progresso da Ana foi salvo")
	if salvo then
		checar(salvo.renascimentos == 1, "salvou renascimentos")
		checar(#salvo.robos == 2 and salvo.robos[1].mut == "diamante", "salvou robôs e mutações")
		checar(salvo.descobertos.torradeira == true, "salvou o índice")
	end

	local ana2 = Sim.novoJogador(1, "Ana")
	Sim.avancar(0.5)
	Sim.criarPersonagem(ana2, Vector3.new(0, 3, 21))
	Sim.avancar(1)
	local ea2 = Game.estados[ana2]
	checar(ea2 ~= nil, "Ana voltou")
	if ea2 then
		local n = 0
		for _, r in pairs(ea2.vagas) do
			n = n + 1
			checar(r.estado == "base" and r.mut == "diamante", "robô restaurado no pedestal")
		end
		checar(n == 2, "2 robôs restaurados")
		checar(ea2.renascimentos == 1, "renascimentos restaurados")
		local ganhoDesdeQueVoltou = ea2.dinheiro - dinheiroAntes
		checar(ganhoDesdeQueVoltou >= 0 and ganhoDesdeQueVoltou <= Game.rendaPorSegundo(ea2) * 3,
			"dinheiro restaurado (mais a renda desde que voltou)")
	end
	semErros("salvar e carregar")

	-- 10. Saídas no meio do roubo -------------------------------------------
	if ea2 then
		local _, roboAna = next(ea2.vagas)
		checar(roboAna ~= nil, "Ana tem robô para ser roubado")
		if not roboAna then
			return resultado
		end
		Sim.moverPara(beto, ea2.base.pedestais[roboAna.vaga] * CFrame.new(0, 3, 3))
		Sim.disparar(roboAna.prompt.Triggered, beto)
		Sim.avancar(0.3)
		checar(eb.carregando == roboAna, "Beto carregando robô da Ana")
		Sim.removerJogador(ana2)
		Sim.avancar(0.5)
		checar(eb.carregando == nil and roboAna.estado == "destruido", "dono saiu: robô some da cabeça do ladrão")
		checar(beto.Character.Humanoid.WalkSpeed == Config.ROUBO.VELOCIDADE_NORMAL, "ladrão volta ao normal")
		local salvoDeNovo = (Sim.cofres["RoubaRobo_v1"] or {})["jogador_1"]
		checar(salvoDeNovo and #salvoDeNovo.robos == 2, "robô sendo roubado conta como da Ana ao salvar")
	end

	local caio = Sim.novoJogador(3, "Caio")
	Sim.avancar(0.5)
	Sim.criarPersonagem(caio, Vector3.new(0, 3, 21))
	Sim.avancar(1)
	local ec = Game.estados[caio]
	local r = Game.novoRobo(Config.RoboPorId.parafusinho, nil, CFrame.new(0, 1, 0))
	Sim.disparar(r.prompt.Triggered, caio)
	Sim.avancar(3)
	Sim.moverPara(beto, ec.base.pedestais[1] * CFrame.new(0, 3, 3))
	Sim.disparar(r.prompt.Triggered, beto)
	Sim.avancar(0.3)
	Sim.removerJogador(beto)
	Sim.avancar(3)
	checar(r.dono == ec and r.estado == "base", "ladrão saiu: robô volta para o dono")
	semErros("saídas no meio do roubo")

	-- 11. Falha no DataStore: não salva por cima ----------------------------
	Sim.falharDataStore = true
	local duda = Sim.novoJogador(4, "Duda")
	Sim.avancar(8)
	local ed = Game.estados[duda]
	checar(ed ~= nil and ed.podeSalvar == false, "falha ao carregar: entra sem salvar")
	Sim.removerJogador(duda)
	Sim.avancar(1)
	Sim.falharDataStore = false
	checar(((Sim.cofres["RoubaRobo_v1"] or {})["jogador_4"]) == nil, "falha ao carregar: não sobrescreve dados")

	-- 12. Servidor cheio -----------------------------------------------------
	local extras = {}
	for i = 10, 18 do
		table.insert(extras, Sim.novoJogador(i, "Extra" .. i))
	end
	Sim.avancar(1)
	checar(#Sim.expulsos >= 1, "9º jogador é avisado que o servidor está cheio")
	for _, p in ipairs(extras) do
		Sim.removerJogador(p)
	end
	Sim.avancar(1)

	-- 13. Loja: produto de dinheiro -----------------------------------------
	Config.Loja.PACOTES[1].id = 111
	local beto2 = Sim.novoJogador(2, "Beto")
	Sim.avancar(0.5)
	Sim.criarPersonagem(beto2, Vector3.new(0, 3, 21))
	Sim.avancar(1)
	local eb2 = Game.estados[beto2]
	local mps = Sim.servico("MarketplaceService")
	local processar = Sim.internos[mps].props.ProcessReceipt
	checar(type(processar) == "function", "ProcessReceipt registrado")
	if processar and eb2 then
		antes = eb2.dinheiro
		local d1 = processar({ PlayerId = 2, ProductId = 111, PurchaseId = "compra-1" })
		local d2 = processar({ PlayerId = 2, ProductId = 111, PurchaseId = "compra-1" })
		checar(d1 == G.Enum.ProductPurchaseDecision.PurchaseGranted, "compra concedida")
		checar(d2 == G.Enum.ProductPurchaseDecision.PurchaseGranted, "compra repetida não falha")
		checar(eb2.dinheiro == antes + Config.Loja.PACOTES[1].minimo, "compra entrega o dinheiro uma vez só")
		local d3 = processar({ PlayerId = 999, ProductId = 111, PurchaseId = "compra-2" })
		checar(d3 == G.Enum.ProductPurchaseDecision.NotProcessedYet, "compra de jogador ausente fica pendente")
	end
	semErros("loja")

	-- 14. Lado do jogador (interface) ---------------------------------------
	Sim.jogadorLocal = beto2
	Sim.definir(Players, "LocalPlayer", beto2)
	Sim.executar(scripts["client/HUD"])
	Sim.executar(scripts["client/Efeitos"])
	Sim.avancar(1)
	semErros("interface iniciou")
	local hud = beto2.PlayerGui:FindFirstChild("RoubaRoboHUD")
	checar(hud ~= nil, "HUD criada")
	if hud and eb2 then
		local placar = hud.Topo.Placar
		checar(placar.Dinheiro.Text == Format.dinheiro(beto2.leaderstats.Dinheiro.Value), "HUD mostra o dinheiro")
		Game.notificar(beto2, "Teste de aviso", "bom")
		Sim.avancar(0.1)
		local avisosVisiveis = 0
		for _, filho in ipairs(hud.Topo.Avisos:GetChildren()) do
			if filho:IsA("TextLabel") then
				avisosVisiveis = avisosVisiveis + 1
			end
		end
		checar(avisosVisiveis >= 1 and avisosVisiveis <= 4, "avisos aparecem (máx. 4)")
		Sim.avancar(6)
		local restantes = 0
		for _, filho in ipairs(hud.Topo.Avisos:GetChildren()) do
			if filho:IsA("TextLabel") then
				restantes = restantes + 1
			end
		end
		checar(restantes == 0, "avisos somem sozinhos")

		-- botões abrem os painéis
		Sim.disparar(Sim.sinalDe(hud.Botoes["Índice"], "Activated"))
		Sim.avancar(0.1)
		checar(hud.Indice.Visible == true, "botão Índice abre o painel")
		Sim.disparar(Sim.sinalDe(hud.Botoes.Renascer, "Activated"))
		Sim.avancar(0.1)
		checar(hud.Renascer.Visible == true and hud.Indice.Visible == false, "abrir um painel fecha o outro")
		checar(hud.Botoes:FindFirstChild("Loja") ~= nil, "botão Loja aparece quando há produto")

		-- texto do segure-E
		local meu = Game.novoRobo(Config.RoboPorId.parafusinho, nil, CFrame.new(0, 1, 0))
		Sim.disparar(meu.prompt.Triggered, beto2)
		Sim.avancar(3)
		local pps = Sim.servico("ProximityPromptService")
		Sim.disparar(Sim.sinalDe(pps, "PromptShown"), meu.prompt)
		Sim.avancar(0.1)
		checar(string.find(meu.prompt.ActionText, "Vender", 1, true) == 1, "robô próprio mostra Vender")
		local daEsteira = Conveyor.robos()[1]
		Sim.disparar(Sim.sinalDe(pps, "PromptShown"), daEsteira.prompt)
		Sim.avancar(0.1)
		checar(daEsteira.prompt.ActionText == "Comprar", "robô da esteira mostra Comprar")

		-- carregar mostra a faixa
		beto2:SetAttribute("Carregando", "Teste")
		Sim.avancar(0.1)
		checar(hud.Topo.Carga.Visible == true, "faixa de carga aparece")
		beto2:SetAttribute("Carregando", nil)
		Sim.avancar(0.1)
		checar(hud.Topo.Carga.Visible == false, "faixa de carga some")

		-- tapa empurra o jogador local
		Remotos.Empurrao:FireClient(beto2, Vector3.new(70, 0, 0))
		Sim.avancar(0.1)
		checar(beto2.Character.Humanoid.PlatformStand == true, "tapa derruba o jogador")
		Sim.avancar(1)
		checar(beto2.Character.Humanoid.PlatformStand == false, "jogador levanta depois do tapa")

		-- arco-íris muda de cor
		local arco = Game.novoRobo(Config.RoboPorId.bipbop, "arcoiris", CFrame.new(0, 1, 0))
		local corpo = arco.modelo.Corpo
		Sim.avancar(0.5)
		local cor1 = corpo.Color
		Sim.avancar(0.5)
		checar(corpo.Color ~= cor1, "robô arco-íris muda de cor")
		Game.destruirRobo(arco)
	end
	semErros("interface")

	-- 15. Muito tempo de jogo ------------------------------------------------
	Sim.avancar(120, 1 / 10)
	checar(Conveyor.quantidade() < 40, "esteira não acumula robôs (" .. Conveyor.quantidade() .. ")")
	local robosNoMundo = #workspace.Robos:GetChildren()
	checar(robosNoMundo < 60, "robôs antigos são reciclados (" .. robosNoMundo .. " no mundo)")
	semErros("120 segundos de jogo")

	-- 16. Fechar o servidor salva todo mundo --------------------------------
	for _, fn in ipairs(Sim.aoFechar) do
		Sim.task.spawn(fn)
	end
	Sim.avancar(2)
	checar(((Sim.cofres["RoubaRobo_v1"] or {})["jogador_2"]) ~= nil, "fechar o servidor salva os jogadores")
	semErros("fechamento")

	return resultado
end
