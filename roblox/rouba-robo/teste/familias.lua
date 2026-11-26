--[[
	Chaves de texto montadas pelo código ("melhoria_" .. tipo), que a busca
	por padrões não consegue ver. Devolve a lista completa delas.
]]

return function(Config)

local chaves = {}
for _, tipo in ipairs({ "renda", "vagas", "tapa" }) do
  table.insert(chaves, "melhoria_" .. tipo); table.insert(chaves, "efeito_" .. tipo)
end
for _, m in ipairs(Config.MISSOES) do table.insert(chaves, "missao_" .. m.tipo) end
for _, p in ipairs(Config.LOJA.PACOTES) do table.insert(chaves, "pacote_" .. p.chave) end
for _, p in ipairs(Config.LOJA.PASSES) do table.insert(chaves, "passe_" .. p.chave); table.insert(chaves, "desc_" .. p.chave) end
for i = 1, 4 do table.insert(chaves, "passo" .. i) end
return chaves
end
