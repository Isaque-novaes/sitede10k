--[[
	Testes rápidos das Lendas Elementais: contas de nível, dano, preços e
	tabelas, sem montar o mundo.
]]

return function(Sim)
	local pasta = Sim.novaInstancia("Folder", true)
	local Config = Sim.requerer(Sim.criarScript("ModuleScript", "Config", "shared/Config.luau", pasta))
	local Format = Sim.requerer(Sim.criarScript("ModuleScript", "Format", "shared/Format.luau", pasta))
	local Vector3 = Sim.G.Vector3

	local falhas = {}
	local function erro(texto)
		table.insert(falhas, texto)
	end
	local function igual(a, b, desc)
		if a ~= b then
			erro(desc .. ": esperado " .. tostring(b) .. ", veio " .. tostring(a))
		end
	end

	-- números na tela
	igual(Format.numero(1500, "pt"), "1,5K", "numero pt")
	igual(Format.numero(1500, "en"), "1.5K", "numero en")
	igual(Format.tempo(65), "1:05", "tempo")

	-- a curva de nível tem que sempre subir
	for nivel = 1, Config.NIVEL_MAXIMO - 1 do
		if Config.xpDoNivel(nivel + 1) <= Config.xpDoNivel(nivel) then
			erro("XP do nível " .. nivel .. " não cresce")
			break
		end
	end

	-- um monstro do seu nível morre em 3 a 8 golpes básicos
	for _, nivel in ipairs({ 1, 5, 15, 30, 50, 75, 100 }) do
		local dano = Config.danoBase(nivel)
		local golpes = Config.vidaMonstro(nivel, false) / dano
		if golpes < 3 or golpes > 8 then
			erro("nível " .. nivel .. ": monstro morre em " .. string.format("%.1f", golpes) .. " golpes")
		end
		-- e o jogador aguenta pelo menos 5 ataques
		local aguenta = Config.vidaBase(nivel) / Config.danoMonstro(nivel, false)
		if aguenta < 5 then
			erro("nível " .. nivel .. ": jogador aguenta só " .. string.format("%.1f", aguenta) .. " ataques")
		end
	end

	-- cerca de 12 monstros por nível
	for _, nivel in ipairs({ 1, 10, 40, 90 }) do
		local quantos = Config.xpDoNivel(nivel) / Config.xpMonstro(nivel, false)
		if quantos < 8 or quantos > 18 then
			erro("nível " .. nivel .. ": precisa de " .. math.floor(quantos) .. " monstros para subir")
		end
	end

	-- elementos: preço e nível sempre subindo, e os 3 golpes existem
	local anterior
	for _, elemento in ipairs(Config.Elementos) do
		for _, nome in ipairs(Config.GOLPES) do
			local golpe = elemento[nome]
			if not golpe then
				erro(elemento.id .. " não tem o golpe " .. nome)
			elseif not golpe.recarga or golpe.recarga <= 0 then
				erro(elemento.id .. "." .. nome .. " sem recarga")
			elseif (golpe.dano or 0) > 0 and (golpe.alcance or 0) <= 0 and (golpe.raio or 0) <= 0 then
				erro(elemento.id .. "." .. nome .. " faz dano mas não tem alcance nem área")
			end
		end
		if anterior and (elemento.nivel <= anterior.nivel or elemento.custo <= anterior.custo) then
			erro("elemento fora de ordem: " .. elemento.id)
		end
		anterior = elemento
	end
	igual(Config.Elementos[1].custo, 0, "o primeiro elemento é grátis")

	-- zonas: níveis mínimos crescentes e sem sobreposição
	local nivelAnterior = -1
	for _, zona in ipairs(Config.Zonas) do
		if zona.nivelMinimo < nivelAnterior then
			erro("zona fora de ordem: " .. zona.id)
		end
		nivelAnterior = zona.nivelMinimo
		for _, outra in ipairs(Config.Zonas) do
			if outra ~= zona then
				local distancia = (zona.centro - outra.centro).Magnitude
				if distancia < zona.raio + outra.raio + 20 then
					erro("zonas coladas: " .. zona.id .. " e " .. outra.id)
				end
			end
		end
	end
	igual(Config.ZonaPorId.vila.pvp, false, "a vila é zona segura")

	-- todo monstro citado nas zonas existe
	for _, zona in ipairs(Config.Zonas) do
		for _, id in ipairs(zona.monstros or {}) do
			if not Config.Monstros[id] then
				erro("monstro inexistente na zona " .. zona.id .. ": " .. id)
			end
		end
		if zona.chefe and not Config.Monstros[zona.chefe] then
			erro("chefe inexistente: " .. tostring(zona.chefe))
		end
	end

	-- melhorias e missões
	for tipo, m in pairs(Config.MELHORIAS) do
		igual(Config.custoMelhoria(tipo, m.max), nil, "melhoria " .. tipo .. " para no máximo")
		if Config.custoMelhoria(tipo, 1) <= Config.custoMelhoria(tipo, 0) then
			erro("melhoria " .. tipo .. ": preço não sobe")
		end
	end
	local missoes = Config.missoesDoDia(100, 7)
	igual(#missoes, Config.MISSOES_POR_DIA, "3 missões por dia")
	local deNovo = Config.missoesDoDia(100, 7)
	igual(deNovo[1].id, missoes[1].id, "missões do dia são sempre as mesmas")
	local vistas = {}
	for _, m in ipairs(missoes) do
		if vistas[m.id] then
			erro("missão repetida no dia")
		end
		vistas[m.id] = true
	end

	-- a zona certa para cada ponto
	igual(Config.zonaDe(Vector3.new(0, 5, 0)).id, "vila", "centro é a vila")
	for _, zona in ipairs(Config.Zonas) do
		local p = Vector3.new(zona.centro.X, 5, zona.centro.Y)
		igual(Config.zonaDe(p).id, zona.id, "centro da zona " .. zona.id)
	end
	local _, fora = Config.zonaDe(Vector3.new(950, 5, 950))
	igual(fora, true, "fora de tudo é marcado como fora")

	return {
		falhas = falhas,
		info = "Nível 50: vida " .. Config.vidaBase(50) .. ", dano " .. Config.danoBase(50)
			.. ", monstro " .. Config.vidaMonstro(50, false) .. " de vida, "
			.. math.floor(Config.xpDoNivel(50) / Config.xpMonstro(50, false)) .. " monstros por nível",
	}
end
