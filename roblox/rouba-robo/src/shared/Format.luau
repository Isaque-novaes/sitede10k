--[[
	Formatação de números para a tela.
	  pt: 1500 -> "1,5K"   en: 1500 -> "1.5K"
	O idioma é opcional (o padrão é "pt").
]]

local Format = {}

local SUFIXOS = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc" }

function Format.numero(n, idioma)
	n = tonumber(n) or 0
	if n ~= n then
		n = 0
	end
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
		if idioma ~= "en" then
			texto = (string.gsub(texto, "%.", ","))
		end
		texto = texto .. SUFIXOS[i]
	end

	if negativo then
		return "-" .. texto
	end
	return texto
end

function Format.dinheiro(n, idioma)
	return "$" .. Format.numero(n, idioma)
end

-- 1.5 -> "x1,5" (pt) / "x1.5" (en), 2 -> "x2"
function Format.multiplicador(m, idioma)
	local texto = string.format("%.1f", m)
	texto = (string.gsub(texto, "%.0$", ""))
	if idioma ~= "en" then
		texto = (string.gsub(texto, "%.", ","))
	end
	return "x" .. texto
end

function Format.tempo(segundos)
	segundos = math.max(0, math.ceil(segundos))
	if segundos >= 3600 then
		local horas = math.floor(segundos / 3600)
		local resto = segundos % 3600
		return string.format("%d:%02d:%02d", horas, math.floor(resto / 60), resto % 60)
	end
	return string.format("%d:%02d", math.floor(segundos / 60), segundos % 60)
end

return Format
