--[[
	Formatação de números para a tela: 1500 -> "1,5K", 2300000 -> "2,3M".
]]

local Format = {}

local SUFIXOS = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }

function Format.numero(n)
	n = n or 0
	local negativo = n < 0
	if negativo then
		n = -n
	end

	local texto
	if n < 1000 then
		texto = tostring(math.floor(n))
	else
		local i = 1
		while n >= 1000 and i < #SUFIXOS do
			n = n / 1000
			i = i + 1
		end
		if n >= 100 then
			texto = tostring(math.floor(n + 1e-6))
		elseif n >= 10 then
			texto = string.format("%.1f", math.floor(n * 10 + 1e-6) / 10)
		else
			texto = string.format("%.2f", math.floor(n * 100 + 1e-6) / 100)
		end
		if string.find(texto, ".", 1, true) then
			texto = (string.gsub(texto, "0+$", ""))
			texto = (string.gsub(texto, "%.$", ""))
		end
		texto = (string.gsub(texto, "%.", ",")) .. SUFIXOS[i]
	end

	if negativo then
		return "-" .. texto
	end
	return texto
end

function Format.dinheiro(n)
	return "$" .. Format.numero(n)
end

-- 1.5 -> "x1,5", 2 -> "x2"
function Format.multiplicador(m)
	local texto = string.format("%.1f", m)
	texto = (string.gsub(texto, "%.0$", ""))
	return "x" .. (string.gsub(texto, "%.", ","))
end

function Format.tempo(segundos)
	segundos = math.max(0, math.ceil(segundos))
	local minutos = math.floor(segundos / 60)
	return string.format("%d:%02d", minutos, segundos % 60)
end

return Format
