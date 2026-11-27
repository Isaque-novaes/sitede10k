--[[
	Todos os textos do jogo em português e inglês.

	Uso: Textos.t(idioma, "subiu_nivel", 12)  (a chave fica na tabela abaixo)
	  {1}, {2}... no texto são trocados pelos valores.
	O idioma vem de Textos.idiomaDe(player.LocaleId): "pt" para quem usa
	português, "en" para todo o resto do mundo.
]]

local Textos = {}

local T = {
	-- avisos do servidor ------------------------------------------------------
	bemvindo = { pt = "Bem-vindo às Lendas Elementais! Clique para atacar os monstros do Campo Verde.", en = "Welcome to Elemental Legends! Click to attack the monsters in the Green Fields." },
	dica_golpes = { pt = "Q e E são seus golpes especiais. No celular, use os botões embaixo.", en = "Q and E are your special moves. On mobile, use the buttons at the bottom." },
	dica_zonas = { pt = "Zonas azuis são seguras. Nas vermelhas, outros jogadores podem te atacar.", en = "Blue zones are safe. In red ones, other players can attack you." },
	nao_salva = { pt = "Atenção: o progresso desta partida não será salvo.", en = "Heads up: progress in this session won't be saved." },
	dados_falha = { pt = "Não conseguimos carregar seu progresso. Entre de novo em alguns segundos.", en = "We couldn't load your progress. Please rejoin in a few seconds." },
	dados_ocupados = { pt = "Seu progresso ainda está sendo salvo em outro servidor. Entre de novo em alguns segundos.", en = "Your progress is still saving on another server. Please rejoin in a few seconds." },
	servidor_cheio = { pt = "Este servidor está cheio. Entre em outro!", en = "This server is full. Please join another one!" },

	subiu_nivel = { pt = "Nível {1}! Mais vida e mais dano.", en = "Level {1}! More health and damage." },
	novo_elemento = { pt = "Nível {1}: o elemento {2} liberou na loja!", en = "Level {1}: the {2} element is now available in the shop!" },
	derrotou_monstro = { pt = "{1} derrotado: +{2} XP, +{3} moedas", en = "{1} defeated: +{2} XP, +{3} coins" },
	chefe_derrotado = { pt = "{1} derrotou {2}!", en = "{1} defeated {2}!" },
	chefe_voltou = { pt = "{1} apareceu em {2}!", en = "{1} has appeared in {2}!" },
	voce_morreu = { pt = "Você foi derrotado por {1}. Voltando em {2}s.", en = "You were defeated by {1}. Respawning in {2}s." },
	voce_morreu_monstro = { pt = "{1} derrubou você. Voltando em {2}s.", en = "{1} took you down. Respawning in {2}s." },
	derrotou_jogador = { pt = "Você derrotou {1}: +{2} XP, +{3} moedas", en = "You defeated {1}: +{2} XP, +{3} coins" },
	derrotou_sem_premio = { pt = "Você derrotou {1}, mas sem recompensa (nível muito diferente ou repetido).", en = "You defeated {1}, but no reward (level gap too big, or too soon)." },

	zona_entrou_segura = { pt = "{1} · zona segura", en = "{1} · safe zone" },
	zona_entrou_pvp = { pt = "{1} · cuidado: outros jogadores podem te atacar!", en = "{1} · careful: other players can attack you!" },
	zona_nivel = { pt = "Você precisa do nível {1} para entrar em {2}.", en = "You need level {1} to enter {2}." },
	portal_usado = { pt = "Você viajou para {1}.", en = "You traveled to {1}." },

	elemento_comprado = { pt = "Você aprendeu {1}!", en = "You learned {1}!" },
	elemento_equipado = { pt = "{1} equipado.", en = "{1} equipped." },
	elemento_falta_nivel = { pt = "{1} precisa do nível {2}.", en = "{1} requires level {2}." },
	elemento_falta_moedas = { pt = "Faltam moedas: {1} custa {2}.", en = "Not enough coins: {1} costs {2}." },
	melhorou = { pt = "{1} no nível {2}!", en = "{1} is now level {2}!" },
	melhoria_max = { pt = "Essa melhoria já está no máximo.", en = "That upgrade is maxed out." },
	melhoria_falta = { pt = "Faltam moedas para a melhoria ({1}).", en = "Not enough coins for that upgrade ({1})." },
	aura_trocada = { pt = "Aura {1} equipada.", en = "{1} aura equipped." },
	aura_bloqueada = { pt = "Essa aura vem com um passe da loja.", en = "That aura comes with a shop pass." },

	diario_ok = { pt = "Prêmio do Dia {1}: {2}!", en = "Day {1} reward: {2}!" },
	diario_ja = { pt = "Você já pegou o prêmio de hoje. Volte amanhã!", en = "You already claimed today's reward. Come back tomorrow!" },
	missao_ok = { pt = "Missão completa! +{1}", en = "Quest complete! +{1}" },
	compra_ok = { pt = "Obrigado pela compra! +{1}", en = "Thanks for your purchase! +{1}" },
	passe_ok = { pt = "{1} ativado!", en = "{1} activated!" },
	anuncio_ok = { pt = "XP em dobro por {1}!", en = "Double XP for {1}!" },
	anuncio_indisponivel = { pt = "Nenhum anúncio disponível agora. Tente mais tarde.", en = "No ad available right now. Try again later." },
	grupo_bonus = { pt = "Obrigado por entrar no grupo! +10% de XP e {1} moedas.", en = "Thanks for joining the group! +10% XP and {1} coins." },
	teste_xp = { pt = "[Teste] +{1} XP e moedas", en = "[Test] +{1} XP and coins" },

	-- interface ---------------------------------------------------------------
	nivel = { pt = "Nível {1}", en = "Level {1}" },
	nivel_curto = { pt = "Nv {1}", en = "Lv {1}" },
	nivel_maximo = { pt = "Nível máximo", en = "Max level" },
	vida = { pt = "Vida", en = "Health" },
	moedas = { pt = "Moedas", en = "Coins" },
	zona_segura = { pt = "ZONA SEGURA", en = "SAFE ZONE" },
	zona_pvp = { pt = "PVP LIGADO", en = "PVP ON" },
	xp2_ativo = { pt = "XP x2 por {1}", en = "2x XP for {1}" },
	morreu_titulo = { pt = "VOCÊ CAIU", en = "YOU WENT DOWN" },
	morreu_voltando = { pt = "Voltando em {1}", en = "Respawning in {1}" },

	menu_elementos = { pt = "Elementos", en = "Elements" },
	menu_melhorar = { pt = "Melhorar", en = "Upgrade" },
	menu_loja = { pt = "Loja", en = "Shop" },
	menu_missoes = { pt = "Missões", en = "Quests" },
	menu_premio = { pt = "Prêmio", en = "Reward" },
	menu_gratis = { pt = "XP grátis", en = "Free XP" },

	titulo_elementos = { pt = "ELEMENTOS", en = "ELEMENTS" },
	titulo_melhorar = { pt = "MELHORAR", en = "UPGRADES" },
	titulo_loja = { pt = "LOJA", en = "SHOP" },
	titulo_missoes = { pt = "MISSÕES DE HOJE", en = "TODAY'S QUESTS" },
	titulo_diario = { pt = "PRÊMIO DIÁRIO", en = "DAILY REWARD" },
	titulo_auras = { pt = "AURAS", en = "AURAS" },

	elementos_info = { pt = "Cada elemento tem 3 golpes. Troque quando quiser, sem perder nada.", en = "Each element has 3 moves. Switch any time, nothing is lost." },
	equipar = { pt = "Equipar", en = "Equip" },
	equipado = { pt = "Equipado", en = "Equipped" },
	comprar = { pt = "Comprar", en = "Buy" },
	precisa_nivel = { pt = "Nível {1}", en = "Level {1}" },
	golpe_basico = { pt = "Clique", en = "Click" },
	golpe_especial = { pt = "Q", en = "Q" },
	golpe_supremo = { pt = "E", en = "E" },
	recarga = { pt = "{1}s de recarga", en = "{1}s cooldown" },

	melhorar_info = { pt = "Pago com as moedas do jogo. Nada aqui custa Robux.", en = "Paid with in-game coins. Nothing here costs Robux." },
	melhoria_vida = { pt = "Vida", en = "Health" },
	melhoria_dano = { pt = "Dano", en = "Damage" },
	melhoria_velocidade = { pt = "Velocidade", en = "Speed" },
	efeito_vida = { pt = "+12% de vida por nível", en = "+12% health per level" },
	efeito_dano = { pt = "+10% de dano por nível", en = "+10% damage per level" },
	efeito_velocidade = { pt = "+6% de velocidade por nível", en = "+6% speed per level" },
	maximo = { pt = "Máximo", en = "Max" },

	loja_info = { pt = "Nada aqui deixa você mais forte na luta: só XP e moedas mais rápido, e visual.", en = "Nothing here makes you stronger in a fight: only faster XP and coins, plus looks." },
	passe_xp2 = { pt = "XP em dobro", en = "2x XP" },
	passe_moedas2 = { pt = "Moedas em dobro", en = "2x Coins" },
	passe_vip = { pt = "VIP", en = "VIP" },
	passe_aura = { pt = "Pacote de auras", en = "Aura Pack" },
	desc_xp2 = { pt = "Você ganha o dobro de XP, para sempre.", en = "Earn double XP, forever." },
	desc_moedas2 = { pt = "Você ganha o dobro de moedas, para sempre.", en = "Earn double coins, forever." },
	desc_vip = { pt = "Etiqueta VIP, aura dourada e +25% de XP e moedas.", en = "VIP tag, golden aura and +25% XP and coins." },
	desc_aura = { pt = "Libera todas as auras coloridas.", en = "Unlocks every colored aura." },
	pacote_bolsa = { pt = "Bolsa de moedas", en = "Coin Pouch" },
	pacote_bau = { pt = "Baú de moedas", en = "Coin Chest" },
	pacote_tesouro = { pt = "Tesouro", en = "Treasure" },
	comprado = { pt = "Comprado", en = "Owned" },
	anuncio_titulo = { pt = "XP em dobro grátis", en = "Free 2x XP" },
	anuncio_desc = { pt = "Assista um anúncio e ganhe XP em dobro por {1} minutos.", en = "Watch an ad and get double XP for {1} minutes." },
	assistir = { pt = "Assistir", en = "Watch" },

	missao_matar = { pt = "Derrote {1} monstros", en = "Defeat {1} monsters" },
	missao_chefe = { pt = "Derrote um chefe", en = "Defeat a boss" },
	missao_subirNivel = { pt = "Suba {1} níveis", en = "Gain {1} levels" },
	missao_matarJogador = { pt = "Derrote {1} jogador", en = "Defeat {1} player" },
	missao_minutos = { pt = "Jogue {1} minutos", en = "Play for {1} minutes" },
	missao_usarSupremo = { pt = "Use o golpe E {1} vezes", en = "Use your E move {1} times" },
	missao_visitarZona = { pt = "Visite {1} zonas diferentes", en = "Visit {1} different zones" },
	novas_em = { pt = "novas em {1}", en = "new in {1}" },
	pegar = { pt = "Pegar", en = "Claim" },
	feito = { pt = "Feito", en = "Done" },
	dia = { pt = "Dia {1}", en = "Day {1}" },
	amanha = { pt = "Amanhã", en = "Tomorrow" },
	diario_info = { pt = "Entre todo dia. Se faltar um dia, volta para o Dia 1.", en = "Play every day. Miss a day and you go back to Day 1." },
	premio_moedas = { pt = "{1} moedas", en = "{1} coins" },
	premio_xp = { pt = "{1} XP", en = "{1} XP" },
	premio_xp2 = { pt = "XP x2 por {1} min", en = "2x XP for {1} min" },
	bonus_amigos = { pt = "+{1}% com {2} amigo(s) aqui", en = "+{1}% with {2} friend(s) here" },
	fechar = { pt = "Fechar", en = "Close" },

	-- mundo -------------------------------------------------------------------
	placa_vila = { pt = "VILA CENTRAL", en = "CENTRAL VILLAGE" },
	placa_treino = { pt = "BONECO DE TREINO", en = "TRAINING DUMMY" },
	portal_para = { pt = "IR PARA {1}", en = "GO TO {1}" },
	portal_nivel = { pt = "PRECISA DO NÍVEL {1}", en = "REQUIRES LEVEL {1}" },
	portal_vila = { pt = "VOLTAR PARA A VILA", en = "BACK TO VILLAGE" },
	ranking_titulo = { pt = "MAIORES LENDAS", en = "TOP LEGENDS" },
	ranking_carregando = { pt = "Carregando...", en = "Loading..." },
	como_jogar = { pt = "COMO JOGAR", en = "HOW TO PLAY" },
	passo1 = { pt = "1. Clique para atacar os monstros", en = "1. Click to attack monsters" },
	passo2 = { pt = "2. Suba de nível e aprenda elementos", en = "2. Level up and learn elements" },
	passo3 = { pt = "3. Use os portais para zonas mais fortes", en = "3. Use the portals to stronger zones" },
	passo4 = { pt = "4. Nas zonas vermelhas, cuidado com os outros!", en = "4. In red zones, watch out for other players!" },
	teste_mais = { pt = "Teste: +XP", en = "Test: +XP" },
	teste_dia = { pt = "Teste: +1 dia", en = "Test: +1 day" },
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
	local quantos = select("#", ...)
	texto = string.gsub(texto, "{(%d+)}", function(n)
		local v = valores[tonumber(n)]
		if v == nil then
			return ""
		end
		return tostring(v)
	end)
	_ = quantos
	return texto
end

return Textos
