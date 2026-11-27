--[[
	Loja paga com as moedas do jogo: aprender elementos, equipar elementos,
	melhorar vida/dano/velocidade e escolher a aura.

	Nada aqui custa Robux. O servidor confere nível, preço e se o jogador
	realmente tem o item antes de qualquer coisa.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Textos = require(Shared:WaitForChild("Textos"))
local Jogador = require(script.Parent:WaitForChild("Jogador"))

local Loja = {}

function Loja.comprarElemento(estado, id)
	local elemento = Config.ElementoPorId[id]
	if not elemento or Jogador.temElemento(estado, id) then
		return false
	end
	if estado.nivel < elemento.nivel then
		Jogador.avisar(estado.player, "ruim", "elemento_falta_nivel", Jogador.nomeDe(elemento), elemento.nivel)
		return false
	end
	if not Jogador.gastarMoedas(estado, elemento.custo) then
		Jogador.avisar(estado.player, "ruim", "elemento_falta_moedas",
			Jogador.nomeDe(elemento), Jogador.numero(elemento.custo))
		return false
	end
	table.insert(estado.elementos, id)
	estado.equipado = id
	table.clear(estado.recargas)
	Jogador.avisar(estado.player, "bom", "elemento_comprado", Jogador.nomeDe(elemento))
	Jogador.remotos.Efeito:FireClient(estado.player, "premio", nil, elemento.cor)
	Jogador.atualizarAtributos(estado)
	return true
end

function Loja.equipar(estado, id)
	if not Config.ElementoPorId[id] or not Jogador.temElemento(estado, id) then
		return false
	end
	if estado.equipado == id then
		return false
	end
	estado.equipado = id
	table.clear(estado.recargas)
	Jogador.avisar(estado.player, "info", "elemento_equipado", Jogador.nomeDe(Config.ElementoPorId[id]))
	Jogador.atualizarAtributos(estado)
	return true
end

function Loja.melhorar(estado, tipo)
	if not Config.MELHORIAS[tipo] then
		return false
	end
	local nivel = estado.melhorias[tipo]
	local custo = Config.custoMelhoria(tipo, nivel)
	if not custo then
		Jogador.avisar(estado.player, "info", "melhoria_max")
		return false
	end
	if not Jogador.gastarMoedas(estado, custo) then
		Jogador.avisar(estado.player, "ruim", "melhoria_falta", Jogador.numero(custo))
		return false
	end
	estado.melhorias[tipo] = nivel + 1
	Jogador.aplicarPersonagem(estado, false)
	Jogador.atualizarAtributos(estado)
	Jogador.avisar(estado.player, "bom", "melhorou", function(idioma)
		return Textos.t(idioma, "melhoria_" .. tipo)
	end, nivel + 1)
	Jogador.remotos.Efeito:FireClient(estado.player, "melhoria")
	Jogador.emitir(estado, "melhorar", 1)
	return true
end

-- Auras: a dourada vem com o VIP, as coloridas com o passe de auras.
function Loja.escolherAura(estado, id)
	local aura = Config.AuraPorId[id]
	if not aura then
		return false
	end
	if aura.vip and not estado.passes.vip then
		Jogador.avisar(estado.player, "ruim", "aura_bloqueada")
		return false
	end
	if aura.passe and not estado.passes[aura.passe] and not estado.passes.vip then
		Jogador.avisar(estado.player, "ruim", "aura_bloqueada")
		return false
	end
	estado.aura = id
	Jogador.aplicarAura(estado)
	Jogador.atualizarAtributos(estado)
	Jogador.avisar(estado.player, "info", "aura_trocada", Jogador.nomeDe(aura))
	return true
end

return Loja
