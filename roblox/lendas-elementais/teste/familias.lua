--[[
	Chaves de texto montadas pelo código ("melhoria_" .. tipo), que a busca
	por padrões não consegue ver. Devolve a lista completa delas.
]]

return function(Config)
	local chaves = {}
	for tipo in pairs(Config.MELHORIAS) do
		table.insert(chaves, "melhoria_" .. tipo)
		table.insert(chaves, "efeito_" .. tipo)
	end
	for _, m in ipairs(Config.MISSOES) do
		table.insert(chaves, "missao_" .. m.tipo)
	end
	for _, p in ipairs(Config.LOJA.PACOTES) do
		table.insert(chaves, "pacote_" .. p.chave)
	end
	for _, p in ipairs(Config.LOJA.PASSES) do
		table.insert(chaves, "passe_" .. p.chave)
		table.insert(chaves, "desc_" .. p.chave)
	end
	for _, g in ipairs(Config.GOLPES) do
		table.insert(chaves, "golpe_" .. g)
	end
	for i = 1, 4 do
		table.insert(chaves, "passo" .. i)
	end
	table.insert(chaves, "premio_moedas")
	table.insert(chaves, "premio_xp")
	table.insert(chaves, "premio_xp2")
	table.insert(chaves, "zona_entrou_segura")
	table.insert(chaves, "zona_entrou_pvp")
	return chaves
end
