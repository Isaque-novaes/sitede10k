--[[
	Testes rápidos do Rouba Robô: números e sorteios, sem montar o mundo.
	Devolve { falhas = { "texto", ... }, info = "linha para mostrar" }
]]

return function(Sim)
	local pasta = Sim.novaInstancia("Folder", true)
	local Config = Sim.requerer(Sim.criarScript("ModuleScript", "Config", "shared/Config.luau", pasta))
	local Format = Sim.requerer(Sim.criarScript("ModuleScript", "Format", "shared/Format.luau", pasta))
	local Random = Sim.G.Random

local falhas = {}
local function igual(a, b, desc)
  if a ~= b then table.insert(falhas, desc .. ": esperado " .. tostring(b) .. ", veio " .. tostring(a)) end
end
igual(Format.numero(0), "0", "numero 0")
igual(Format.numero(999), "999", "numero 999")
igual(Format.numero(1000), "1K", "numero 1000")
igual(Format.numero(1500), "1,5K", "numero 1500")
igual(Format.numero(12345), "12,3K", "numero 12345")
igual(Format.numero(999999), "999K", "numero 999999")
igual(Format.numero(2300000), "2,3M", "numero 2,3M")
igual(Format.numero(1e9), "1B", "numero 1B")
igual(Format.numero(-1500), "-1,5K", "numero negativo")
igual(Format.dinheiro(25), "$25", "dinheiro")
igual(Format.tempo(65), "1:05", "tempo")
igual(Format.tempo(0.2), "0:01", "tempo arredonda pra cima")
igual(Format.multiplicador(1), "x1", "mult 1")
igual(Format.multiplicador(1.5), "x1,5", "mult 1,5")

-- catálogo consistente
local ids = {}
for i, r in ipairs(Config.Robos) do
  if ids[r.id] then table.insert(falhas, "id repetido: " .. r.id) end
  ids[r.id] = true
  if not Config.Raridades[r.raridade] then table.insert(falhas, "raridade inválida: " .. r.id) end
  if r.forma ~= "caixa" and r.forma ~= "barril" and r.forma ~= "bola" then table.insert(falhas, "forma inválida: " .. r.id) end
  if r.preco <= 0 or r.renda <= 0 then table.insert(falhas, "preço/renda inválidos: " .. r.id) end
  local anterior = Config.Robos[i - 1]
  if anterior and anterior.preco >= r.preco then table.insert(falhas, "preço fora de ordem: " .. r.id) end
end
for raridade = 1, #Config.Raridades do
  local tem = false
  for _, r in ipairs(Config.Robos) do if r.raridade == raridade then tem = true end end
  if not tem then table.insert(falhas, "raridade sem robôs: " .. raridade) end
end

-- sorteio: Comum aparece mais que Secreto, e a sorte aumenta os raros
local function contar(sorte)
  local aleatorio = Random.new(42)
  local c = {}
  for _ = 1, 20000 do
    local r, mut = Config.sortear(sorte, aleatorio)
    c[r.raridade] = (c[r.raridade] or 0) + 1
    if mut then c.mut = (c.mut or 0) + 1 end
  end
  return c
end
local normal, sorte = contar(1), contar(3)
if not ((normal[1] or 0) > (normal[7] or 0) * 20) then table.insert(falhas, "Comum deveria ser muito mais frequente que Secreto") end
if not ((sorte[5] or 0) > (normal[5] or 0) * 1.8) then table.insert(falhas, "Hora da Sorte deveria aumentar os Lendários") end
local taxaMut = (normal.mut or 0) / 20000
if taxaMut < 0.05 or taxaMut > 0.11 then table.insert(falhas, "taxa de mutação estranha: " .. taxaMut) end
igual(Config.custoRenascer(0), 1000000, "custo renascer 0")
igual(Config.custoRenascer(1), 5000000, "custo renascer 1")
igual(Config.precoDe(Config.RoboPorId.parafusinho, "dourado"), 50, "preço com mutação")

	local porRaridade = {}
	for i = 1, #Config.Raridades do
		porRaridade[i] = normal[i] or 0
	end
	return {
		falhas = falhas,
		info = "Sorteio em 20000 robôs (raridade 1..7): " .. table.concat(porRaridade, ", "),
	}
end
