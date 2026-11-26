--[[
	Todos os textos do jogo em português e inglês.

	Uso: Textos.t(idioma, "comprou", nomeDoRobo)  (a chave fica na tabela abaixo)
	  {1}, {2}... no texto são trocados pelos valores.
	O idioma vem de Textos.idiomaDe(player.LocaleId): "pt" para quem usa
	português, "en" para todo o resto do mundo.
]]

local Textos = {}

local T = {
	-- avisos do servidor ------------------------------------------------------
	bemvindo = { pt = "Bem-vindo ao Rouba Robô! Compre robôs na esteira segurando E.", en = "Welcome to Robot Heist! Buy robots on the conveyor by holding E." },
	dica_tranca = { pt = "Pise no botão vermelho da sua base para trancar. Use o Tapa contra ladrões!", en = "Step on your base's red button to lock it. Slap thieves away!" },
	nao_salva = { pt = "Atenção: o progresso desta partida não será salvo.", en = "Heads up: progress in this session won't be saved." },
	base_cheia_compra = { pt = "Sua base está cheia! Venda um robô (segure E nele) ou melhore suas vagas.", en = "Your base is full! Sell a robot (hold E on it) or upgrade your slots." },
	falta_dinheiro = { pt = "Falta dinheiro: {1} custa {2}.", en = "Not enough cash: {1} costs {2}." },
	comprou = { pt = "Você comprou {1}!", en = "You bought {1}!" },
	saiu_fabrica = { pt = "Saiu da fábrica: {1} ({2})! Corre!", en = "Fresh from the factory: {1} ({2})! Run!" },
	sorte_gratis = { pt = "HORA DA SORTE! Robôs raros saem {1}x mais por {2}!", en = "LUCKY HOUR! Rare robots appear {1}x more for {2}!" },
	sorte_presente = { pt = "{1} deu SORTE para o servidor! Robôs raros {2}x mais por {3}!", en = "{1} gifted LUCK to the server! Rare robots {2}x more for {3}!" },
	ja_carregando = { pt = "Você já está carregando um robô!", en = "You're already carrying a robot!" },
	base_trancada_roubo = { pt = "Essa base está trancada! Espere a tranca acabar.", en = "That base is locked! Wait for the lock to end." },
	base_cheia_roubo = { pt = "Sua base está cheia, não cabe mais nenhum robô!", en = "Your base is full, no room for another robot!" },
	pegou = { pt = "Você pegou {1}! Corra até a SUA base!", en = "You grabbed {1}! Run to YOUR base!" },
	alerta_roubo = { pt = "ALERTA: {1} está roubando seu {2}! Dê um tapa nele!", en = "ALERT: {1} is stealing your {2}! Slap them!" },
	caiu = { pt = "Você caiu e o robô voltou para o dono.", en = "You fell and the robot went back to its owner." },
	demorou = { pt = "Demorou demais! O robô fugiu de volta para o dono.", en = "Too slow! The robot ran back to its owner." },
	voltou_base = { pt = "Seu {1} voltou para a base!", en = "Your {1} came back home!" },
	roubou = { pt = "Você roubou {1}!", en = "You stole {1}!" },
	foi_roubado = { pt = "{1} roubou seu {2}!", en = "{1} stole your {2}!" },
	sumiu = { pt = "O robô que você carregava sumiu (o dono saiu ou renasceu).", en = "The robot you carried vanished (its owner left or rebirthed)." },
	base_cheia_entrega = { pt = "Sua base está cheia! O robô voltou para o dono.", en = "Your base is full! The robot went back to its owner." },
	tapa_soltou = { pt = "Você levou um tapa de {1} e soltou o robô!", en = "{1} slapped you and you dropped the robot!" },
	tapa_acertou = { pt = "PÁ! {1} soltou {2}!", en = "SMACK! {1} dropped {2}!" },
	vendeu = { pt = "Você vendeu {1} por {2}.", en = "You sold {1} for {2}." },
	trancou = { pt = "Base trancada por {1} segundos!", en = "Base locked for {1} seconds!" },
	renascer_falta = { pt = "Para renascer você precisa de {1}.", en = "You need {1} to rebirth." },
	renascer_carregando = { pt = "Entregue o robô que você está carregando antes de renascer.", en = "Deliver the robot you're carrying before rebirthing." },
	renasceu = { pt = "{1} renasceu! Agora ganha {2} de dinheiro.", en = "{1} rebirthed! Now earning {2} cash." },
	servidor_cheio = { pt = "Este servidor está cheio. Entre em outro servidor!", en = "This server is full. Please join another server!" },
	dados_falha = { pt = "Não conseguimos carregar seu progresso. Entre de novo em alguns segundos.", en = "We couldn't load your progress. Please rejoin in a few seconds." },
	dados_ocupados = { pt = "Seu progresso ainda está sendo salvo em outro servidor. Entre de novo em alguns segundos.", en = "Your progress is still saving on another server. Please rejoin in a few seconds." },
	compra_ok = { pt = "Obrigado pela compra! +{1}", en = "Thanks for your purchase! +{1}" },
	passe_ok = { pt = "{1} ativado!", en = "{1} activated!" },
	vip_robo = { pt = "Presente VIP: {1}!", en = "VIP gift: {1}!" },
	caixa = { pt = "Caixa surpresa: {1} ({2})!", en = "Mystery Crate: {1} ({2})!" },
	premio_robo = { pt = "Você ganhou {1}!", en = "You got {1}!" },
	premio_robo_cheio = { pt = "Sua base estava cheia: {1} virou {2}.", en = "Your base was full: {1} became {2}." },
	melhorou = { pt = "Melhoria comprada: {1} nível {2}!", en = "Upgrade bought: {1} level {2}!" },
	melhoria_max = { pt = "Essa melhoria já está no máximo.", en = "That upgrade is maxed out." },
	melhoria_falta = { pt = "Falta dinheiro para a melhoria ({1}).", en = "Not enough cash for that upgrade ({1})." },
	diario_ok = { pt = "Prêmio do Dia {1}: {2}!", en = "Day {1} reward: {2}!" },
	diario_ja = { pt = "Você já pegou o prêmio de hoje. Volte amanhã!", en = "You already claimed today's reward. Come back tomorrow!" },
	missao_ok = { pt = "Missão completa! +{1}", en = "Quest complete! +{1}" },
	offline_ok = { pt = "Bem-vindo de volta! +{1}", en = "Welcome back! +{1}" },
	indice_completo = { pt = "Você completou os robôs {1}! +5% de dinheiro para sempre.", en = "You completed every {1} robot! +5% cash forever." },
	grupo_bonus = { pt = "Obrigado por entrar no grupo! +10% de dinheiro e um robô {1}.", en = "Thanks for joining the group! +10% cash and a {1} robot." },
	anuncio_ok = { pt = "Dinheiro em dobro por {1}!", en = "Double cash for {1}!" },
	anuncio_indisponivel = { pt = "Nenhum anúncio disponível agora. Tente mais tarde.", en = "No ad available right now. Try again later." },
	teste_dinheiro = { pt = "[Teste] +{1}", en = "[Test] +{1}" },

	-- nomes de passes e melhorias --------------------------------------------
	passe_dobro = { pt = "Dinheiro em dobro", en = "2x Cash" },
	passe_vip = { pt = "VIP", en = "VIP" },
	passe_vagas = { pt = "+5 vagas", en = "+5 Slots" },
	passe_tranca = { pt = "Tranca longa", en = "Long Lock" },
	desc_dobro = { pt = "Ganha x2 de dinheiro para sempre.", en = "Earn 2x cash forever." },
	desc_vip = { pt = "Etiqueta VIP, +50% de dinheiro e um robô Épico de presente.", en = "VIP tag, +50% cash and a free Epic robot." },
	desc_vagas = { pt = "Cabem mais 5 robôs na sua base.", en = "Fit 5 more robots in your base." },
	desc_tranca = { pt = "Sua tranca dura o dobro do tempo.", en = "Your lock lasts twice as long." },
	melhoria_renda = { pt = "Renda da base", en = "Base Income" },
	melhoria_vagas = { pt = "Vagas", en = "Slots" },
	melhoria_tapa = { pt = "Tapa forte", en = "Strong Slap" },
	efeito_renda = { pt = "+10% de dinheiro por nível", en = "+10% cash per level" },
	efeito_vagas = { pt = "+1 vaga na base", en = "+1 base slot" },
	efeito_tapa = { pt = "Empurra o ladrão mais longe", en = "Knocks thieves farther" },
	pacote_maleta = { pt = "Maleta", en = "Briefcase" },
	pacote_cofre = { pt = "Cofre", en = "Safe" },
	pacote_banco = { pt = "Banco", en = "Bank" },

	-- interface ---------------------------------------------------------------
	robos_contagem = { pt = "{1}/{2} robôs", en = "{1}/{2} robots" },
	base_trancada = { pt = "Base trancada {1}", en = "Base locked {1}" },
	base_aberta = { pt = "Base aberta: pise no botão", en = "Base open: step on the button" },
	sorte_faixa = { pt = "HORA DA SORTE {1}", en = "LUCKY HOUR {1}" },
	sorte_faixa_presente = { pt = "HORA DA SORTE {1} · presente de {2}", en = "LUCKY HOUR {1} · gift from {2}" },
	carregando = { pt = "Levando {1}: corra até a SUA base!", en = "Carrying {1}: run to YOUR base!" },
	dobro_ativo = { pt = "x2 por {1}", en = "x2 for {1}" },
	menu_loja = { pt = "Loja", en = "Shop" },
	menu_indice = { pt = "Índice", en = "Index" },
	menu_melhorar = { pt = "Melhorar", en = "Upgrade" },
	menu_renascer = { pt = "Renascer", en = "Rebirth" },
	menu_premio = { pt = "Prêmio", en = "Reward" },
	menu_missoes = { pt = "Missões", en = "Quests" },
	menu_gratis = { pt = "2x grátis", en = "Free 2x" },
	fechar = { pt = "Fechar", en = "Close" },
	titulo_loja = { pt = "LOJA", en = "SHOP" },
	aba_passes = { pt = "Passes", en = "Passes" },
	aba_dinheiro = { pt = "Dinheiro", en = "Cash" },
	aba_sorte = { pt = "Sorte e caixa", en = "Luck & Crate" },
	passes_info = { pt = "Compra única: vale para sempre, em todos os servidores.", en = "One-time purchase: yours forever, in every server." },
	comprado = { pt = "Comprado", en = "Owned" },
	pacote_desc = { pt = "{1} min de renda", en = "{1} min of income" },
	pacote_desc_horas = { pt = "{1} h de renda", en = "{1} h of income" },
	dinheiro_info = { pt = "Para usar na hora. O dinheiro cresce junto com a sua renda.", en = "Use right away. The cash grows with your income." },
	anuncio_titulo = { pt = "Dinheiro em dobro grátis", en = "Free 2x Cash" },
	anuncio_desc = { pt = "Assista um anúncio e ganhe x2 por {1} minutos.", en = "Watch an ad and get 2x cash for {1} minutes." },
	assistir = { pt = "Assistir", en = "Watch" },
	sorte_titulo = { pt = "Sorte do servidor", en = "Server Luck" },
	sorte_desc = { pt = "Por {1} minutos, robôs raros saem {2}x mais para TODO MUNDO no servidor. Seu nome aparece para todos.", en = "For {1} minutes, rare robots appear {2}x more for EVERYONE in the server. Everyone sees your name." },
	caixa_titulo = { pt = "Caixa surpresa", en = "Mystery Crate" },
	caixa_desc = { pt = "Sempre Épico ou melhor. Chances:", en = "Always Epic or better. Odds:" },
	titulo_indice = { pt = "ÍNDICE DE ROBÔS", en = "ROBOT INDEX" },
	indice_contagem = { pt = "Descobertos: {1}/{2}", en = "Discovered: {1}/{2}" },
	indice_premio = { pt = "Complete uma raridade: +5% de dinheiro para sempre", en = "Complete a rarity: +5% cash forever" },
	indice_completa = { pt = "Completa! +5%", en = "Complete! +5%" },
	titulo_melhorar = { pt = "MELHORAR BASE", en = "UPGRADE BASE" },
	melhorar_info = { pt = "Com o dinheiro do jogo. Nada aqui é vendido por Robux.", en = "Paid with in-game cash. Nothing here costs Robux." },
	nivel = { pt = "Nível {1}", en = "Level {1}" },
	maximo = { pt = "Máximo", en = "Max" },
	titulo_renascer = { pt = "RENASCER", en = "REBIRTH" },
	renascer_texto = { pt = "Renascer zera seu dinheiro e seus robôs. Em troca você ganha +{1}% de dinheiro para sempre e a tranca dura {2}s a mais.", en = "Rebirthing resets your cash and robots. In return you earn +{1}% cash forever and your lock lasts {2}s longer." },
	custo = { pt = "Custo: {1}", en = "Cost: {1}" },
	bonus_renascer = { pt = "Bônus: {1} → {2}", en = "Bonus: {1} → {2}" },
	renascer_agora = { pt = "Renascer agora", en = "Rebirth now" },
	falta = { pt = "Falta dinheiro", en = "Not enough cash" },
	titulo_diario = { pt = "PRÊMIO DIÁRIO", en = "DAILY REWARD" },
	diario_info = { pt = "Entre todo dia. Se faltar um dia, volta para o Dia 1.", en = "Play every day. Miss a day and you go back to Day 1." },
	dia = { pt = "Dia {1}", en = "Day {1}" },
	pegar = { pt = "Pegar", en = "Claim" },
	amanha = { pt = "Amanhã", en = "Tomorrow" },
	premio_dinheiro_min = { pt = "{1} min de renda", en = "{1} min of income" },
	premio_robo_raridade = { pt = "Robô {1}", en = "{1} Robot" },
	premio_sorte = { pt = "Sorte {1} min", en = "Luck {1} min" },
	titulo_missoes = { pt = "MISSÕES DE HOJE", en = "TODAY'S QUESTS" },
	novas_em = { pt = "novas em {1}", en = "new in {1}" },
	missao_minutos = { pt = "Jogue {1} min", en = "Play for {1} min" },
	missao_roubar = { pt = "Roube {1} robô(s)", en = "Steal {1} robot(s)" },
	missao_comprar = { pt = "Compre {1} robôs", en = "Buy {1} robots" },
	missao_comprarRaridade = { pt = "Compre um robô {1} ou melhor", en = "Buy a {1} robot or better" },
	missao_vender = { pt = "Venda {1} robôs", en = "Sell {1} robots" },
	missao_tapaLadrao = { pt = "Faça um ladrão soltar um robô", en = "Make a thief drop a robot" },
	missao_trancar = { pt = "Tranque a base {1} vezes", en = "Lock your base {1} times" },
	missao_melhorar = { pt = "Compre uma melhoria", en = "Buy an upgrade" },
	feito = { pt = "Feito", en = "Done" },
	titulo_offline = { pt = "BEM-VINDO DE VOLTA!", en = "WELCOME BACK!" },
	offline_texto = { pt = "Enquanto você estava fora, seus robôs fizeram {1}.", en = "While you were away, your robots made {1}." },
	pegar_x2 = { pt = "Pegar x2 (anúncio)", en = "Claim 2x (ad)" },
	bonus_amigos = { pt = "+{1}% de dinheiro: {2} amigo(s) aqui", en = "+{1}% cash: {2} friend(s) here" },
	teste_mais = { pt = "Teste: +$", en = "Test: +$" },
	teste_sorte = { pt = "Teste: Sorte", en = "Test: Luck" },

	-- mundo -------------------------------------------------------------------
	comprar = { pt = "Comprar", en = "Buy" },
	roubar = { pt = "Roubar", en = "Steal" },
	vender_por = { pt = "Vender por {1}", en = "Sell for {1}" },
	fabrica = { pt = "FÁBRICA DE ROBÔS", en = "ROBOT FACTORY" },
	reciclagem = { pt = "RECICLAGEM", en = "RECYCLER" },
	trancar_base = { pt = "TRANCAR BASE", en = "LOCK BASE" },
	trancada = { pt = "TRANCADA {1}", en = "LOCKED {1}" },
	base_de = { pt = "BASE DE {1}", en = "{1}'S BASE" },
	base_livre = { pt = "BASE LIVRE", en = "FREE BASE" },
	nivel_renda = { pt = "Nível {1} · +{2}% de renda", en = "Level {1} · +{2}% income" },
	ranking_titulo = { pt = "MAIS RICOS DO MUNDO", en = "RICHEST PLAYERS" },
	ranking_carregando = { pt = "Carregando...", en = "Loading..." },
	como_jogar = { pt = "COMO JOGAR", en = "HOW TO PLAY" },
	passo1 = { pt = "1. Compre robôs na esteira", en = "1. Buy robots on the conveyor" },
	passo2 = { pt = "2. Eles fazem dinheiro na sua base", en = "2. They make cash in your base" },
	passo3 = { pt = "3. Roube robôs das outras bases", en = "3. Steal robots from other bases" },
	passo4 = { pt = "4. Tranque a base e dê tapas nos ladrões", en = "4. Lock your base and slap thieves" },
}

Textos.dados = T

function Textos.idiomaDe(localeId)
	if type(localeId) == "string" and string.sub(string.lower(localeId), 1, 2) == "pt" then
		return "pt"
	end
	return "en"
end

function Textos.t(idioma, chave, ...)
	local entrada = T[chave]
	if not entrada then
		return chave
	end
	local texto = entrada[idioma] or entrada.en or entrada.pt
	local valores = { ... }
	texto = string.gsub(texto, "{(%d+)}", function(n)
		local v = valores[tonumber(n)]
		if v == nil then
			return ""
		end
		return tostring(v)
	end)
	return texto
end

return Textos
