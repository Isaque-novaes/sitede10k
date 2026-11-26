--[[
	Um "Roblox de mentirinha" para testar os scripts fora do Studio.

	Ele imita só o que o jogo usa, mas confere cada classe, propriedade,
	método, evento e enum contra a lista oficial da API do Roblox
	(API-Dump). Usar um nome que não existe, um tipo errado ou uma
	propriedade somente-leitura dá erro, como no Roblox de verdade.

	Também simula o tempo (task.wait, Heartbeat), RemoteEvents (um único
	jogador "local" vê os eventos do cliente), DataStore e compras.

	Variáveis globais que o Python define antes de carregar este arquivo:
	  API          tabela com classes e enums (gerada do API-Dump)
	  ler_arquivo  função(caminho) -> texto
]]

local API = API
local ler_arquivo = ler_arquivo

local Sim = {}
Sim.erros = {}
Sim.avisos = {}
Sim.saida = {}
Sim.T = 0
Sim.estudio = true
Sim.jogadorLocal = nil
Sim.expulsos = {}
Sim.compras = {}
Sim.passes = {}
Sim.falharDataStore = false
Sim.cofres = {}
Sim.aoFechar = {}
Sim.amizades = {} -- ["1:2"] = true
Sim.grupos = {} -- ["userId:grupoId"] = true
Sim.caixaRestrita = {} -- [userId] = true
Sim.anuncios = {} -- pedidos de anúncio
Sim.resultadoAnuncio = nil -- EnumItem ShowAdResult (nil = ShowCompleted)
Sim.precos = {}

local avisados = {}
local function avisar(msg)
	if not avisados[msg] then
		avisados[msg] = true
		table.insert(Sim.avisos, msg)
	end
end
Sim.avisar = avisar

---------------------------------------------------------------------------
-- Agendador
---------------------------------------------------------------------------
local fila = {}

local function retomar(co, ...)
	local ok, erro = coroutine.resume(co, ...)
	if not ok then
		table.insert(Sim.erros, debug.traceback(co, tostring(erro)))
	end
end

local task = {}

function task.spawn(f, ...)
	local co = type(f) == "thread" and f or coroutine.create(f)
	retomar(co, ...)
	return co
end

local function agendar(quando, co, ...)
	table.insert(fila, { quando = quando, co = co, args = { ... }, n = select("#", ...) })
end

function task.defer(f, ...)
	local co = type(f) == "thread" and f or coroutine.create(f)
	agendar(Sim.T, co, ...)
	return co
end

function task.delay(t, f, ...)
	local co = type(f) == "thread" and f or coroutine.create(f)
	agendar(Sim.T + (t or 0), co, ...)
	return co
end

function task.wait(t)
	local co = coroutine.running()
	if not co then
		error("task.wait chamado fora de uma thread", 2)
	end
	local inicio = Sim.T
	agendar(Sim.T + math.max(t or 0, 1 / 60), co)
	coroutine.yield()
	return Sim.T - inicio
end

function task.cancel(co)
	for i = #fila, 1, -1 do
		if fila[i].co == co then
			table.remove(fila, i)
		end
	end
end

Sim.task = task

---------------------------------------------------------------------------
-- Sinais (eventos)
---------------------------------------------------------------------------
local ConexaoMT = { __type = "RBXScriptConnection" }
ConexaoMT.__index = {
	Disconnect = function(c)
		rawset(c, "Connected", false)
	end,
}

local SinalMT = { __type = "RBXScriptSignal" }
local metodosSinal = {}
SinalMT.__index = function(_, chave)
	local m = metodosSinal[chave]
	if not m then
		error(tostring(chave) .. " is not a valid member of RBXScriptSignal", 2)
	end
	return m
end

local function novoSinal(nome)
	return setmetatable({ _nome = nome, _conexoes = {}, _esperando = {} }, SinalMT)
end
Sim.novoSinal = novoSinal

function metodosSinal.Connect(sinal, fn)
	if type(fn) ~= "function" then
		error("Connect espera uma função, recebeu " .. type(fn), 2)
	end
	local c = setmetatable({ Connected = true, _fn = fn }, ConexaoMT)
	table.insert(rawget(sinal, "_conexoes"), c)
	return c
end

function metodosSinal.Once(sinal, fn)
	local c
	c = metodosSinal.Connect(sinal, function(...)
		c:Disconnect()
		fn(...)
	end)
	return c
end

function metodosSinal.Wait(sinal)
	local co = coroutine.running()
	if not co then
		error("Wait chamado fora de uma thread", 2)
	end
	table.insert(rawget(sinal, "_esperando"), co)
	return coroutine.yield()
end

function Sim.disparar(sinal, ...)
	local ativas = {}
	for _, c in ipairs(rawget(sinal, "_conexoes")) do
		if rawget(c, "Connected") then
			table.insert(ativas, c)
		end
	end
	for _, c in ipairs(ativas) do
		if rawget(c, "Connected") then
			task.spawn(rawget(c, "_fn"), ...)
		end
	end
	local esperando = rawget(sinal, "_esperando")
	rawset(sinal, "_esperando", {})
	for _, co in ipairs(esperando) do
		retomar(co, ...)
	end
end

---------------------------------------------------------------------------
-- typeof
---------------------------------------------------------------------------
local function typeof(v)
	if type(v) == "table" then
		local mt = getmetatable(v)
		if mt and mt.__type then
			return mt.__type
		end
	end
	return type(v)
end
Sim.typeof = typeof

---------------------------------------------------------------------------
-- Tipos de dados: Vector3, Vector2, CFrame, Color3, UDim, UDim2...
---------------------------------------------------------------------------
local sqrt, cos, sin = math.sqrt, math.cos, math.sin

local V3 = { __type = "Vector3" }
local metodosV3 = {}
local function v3(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
end
V3.__index = function(v, k)
	if k == "Magnitude" then
		return sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
	elseif k == "Unit" then
		local m = sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
		return v3(v.X / m, v.Y / m, v.Z / m)
	elseif k == "x" or k == "y" or k == "z" then
		return rawget(v, string.upper(k))
	end
	local m = metodosV3[k]
	if m then
		return m
	end
	error(tostring(k) .. " is not a valid member of Vector3", 2)
end
V3.__newindex = function(_, k)
	error(tostring(k) .. " cannot be assigned to (Vector3 é imutável)", 2)
end
V3.__add = function(a, b)
	if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then
		error("soma inválida com Vector3: " .. typeof(a) .. " + " .. typeof(b), 2)
	end
	return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
V3.__sub = function(a, b)
	if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then
		error("subtração inválida com Vector3", 2)
	end
	return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
V3.__mul = function(a, b)
	if type(a) == "number" then
		return v3(a * b.X, a * b.Y, a * b.Z)
	elseif type(b) == "number" then
		return v3(a.X * b, a.Y * b, a.Z * b)
	elseif typeof(a) == "Vector3" and typeof(b) == "Vector3" then
		return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
	end
	error("multiplicação inválida com Vector3", 2)
end
V3.__div = function(a, b)
	if type(b) == "number" then
		return v3(a.X / b, a.Y / b, a.Z / b)
	end
	return v3(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3.__unm = function(a)
	return v3(-a.X, -a.Y, -a.Z)
end
V3.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end
V3.__tostring = function(v)
	return string.format("%g, %g, %g", v.X, v.Y, v.Z)
end
function metodosV3.Dot(a, b)
	return a.X * b.X + a.Y * b.Y + a.Z * b.Z
end
function metodosV3.Cross(a, b)
	return v3(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
end
function metodosV3.Lerp(a, b, t)
	return a + (b - a) * t
end

local Vector3 = {
	new = function(x, y, z)
		return v3(x, y, z)
	end,
}
Vector3.zero = v3(0, 0, 0)
Vector3.one = v3(1, 1, 1)
Vector3.xAxis = v3(1, 0, 0)
Vector3.yAxis = v3(0, 1, 0)
Vector3.zAxis = v3(0, 0, 1)

local V2 = { __type = "Vector2" }
local function v2(x, y)
	return setmetatable({ X = x or 0, Y = y or 0 }, V2)
end
V2.__index = function(v, k)
	if k == "Magnitude" then
		return sqrt(v.X * v.X + v.Y * v.Y)
	end
	error(tostring(k) .. " is not a valid member of Vector2", 2)
end
local Vector2 = {
	new = function(x, y)
		return v2(x, y)
	end,
}
Vector2.zero = v2(0, 0)

-- CFrame: posição + matriz de rotação 3x3 (linhas)
local CF = { __type = "CFrame" }
local metodosCF = {}
local function cf(px, py, pz, r)
	return setmetatable({ _p = v3(px, py, pz), _r = r or { 1, 0, 0, 0, 1, 0, 0, 0, 1 } }, CF)
end
local function mulR(a, b)
	local r = {}
	for i = 0, 2 do
		for j = 0, 2 do
			local s = 0
			for k = 0, 2 do
				s = s + a[i * 3 + k + 1] * b[k * 3 + j + 1]
			end
			r[i * 3 + j + 1] = s
		end
	end
	return r
end
local function aplicarR(r, v)
	return v3(
		r[1] * v.X + r[2] * v.Y + r[3] * v.Z,
		r[4] * v.X + r[5] * v.Y + r[6] * v.Z,
		r[7] * v.X + r[8] * v.Y + r[9] * v.Z
	)
end
local function transposta(r)
	return { r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] }
end
CF.__index = function(c, k)
	local r = rawget(c, "_r")
	local p = rawget(c, "_p")
	if k == "Position" or k == "p" then
		return p
	elseif k == "X" then
		return p.X
	elseif k == "Y" then
		return p.Y
	elseif k == "Z" then
		return p.Z
	elseif k == "LookVector" then
		return v3(-r[3], -r[6], -r[9])
	elseif k == "RightVector" then
		return v3(r[1], r[4], r[7])
	elseif k == "UpVector" then
		return v3(r[2], r[5], r[8])
	elseif k == "Rotation" then
		return cf(0, 0, 0, r)
	end
	local m = metodosCF[k]
	if m then
		return m
	end
	error(tostring(k) .. " is not a valid member of CFrame", 2)
end
CF.__newindex = function(_, k)
	error(tostring(k) .. " cannot be assigned to (CFrame é imutável)", 2)
end
CF.__mul = function(a, b)
	if typeof(a) ~= "CFrame" then
		error("multiplicação inválida: " .. typeof(a) .. " * " .. typeof(b), 2)
	end
	if typeof(b) == "CFrame" then
		local p = rawget(a, "_p") + aplicarR(rawget(a, "_r"), rawget(b, "_p"))
		return cf(p.X, p.Y, p.Z, mulR(rawget(a, "_r"), rawget(b, "_r")))
	elseif typeof(b) == "Vector3" then
		return rawget(a, "_p") + aplicarR(rawget(a, "_r"), b)
	end
	error("multiplicação inválida: CFrame * " .. typeof(b), 2)
end
CF.__add = function(a, b)
	if typeof(a) ~= "CFrame" or typeof(b) ~= "Vector3" then
		error("soma inválida: " .. typeof(a) .. " + " .. typeof(b), 2)
	end
	local p = rawget(a, "_p") + b
	return cf(p.X, p.Y, p.Z, rawget(a, "_r"))
end
CF.__sub = function(a, b)
	if typeof(a) ~= "CFrame" or typeof(b) ~= "Vector3" then
		error("subtração inválida: " .. typeof(a) .. " - " .. typeof(b), 2)
	end
	local p = rawget(a, "_p") - b
	return cf(p.X, p.Y, p.Z, rawget(a, "_r"))
end
CF.__tostring = function(c)
	return "CFrame(" .. tostring(rawget(c, "_p")) .. ")"
end
function metodosCF.Inverse(c)
	local rt = transposta(rawget(c, "_r"))
	local p = -aplicarR(rt, rawget(c, "_p"))
	return cf(p.X, p.Y, p.Z, rt)
end
function metodosCF.PointToObjectSpace(c, v)
	return aplicarR(transposta(rawget(c, "_r")), v - rawget(c, "_p"))
end
function metodosCF.PointToWorldSpace(c, v)
	return c * v
end
function metodosCF.ToObjectSpace(c, outro)
	return metodosCF.Inverse(c) * outro
end
function metodosCF.ToWorldSpace(c, outro)
	return c * outro
end
function metodosCF.Lerp(a, b, t)
	local pa, pb = rawget(a, "_p"), rawget(b, "_p")
	local p = pa + (pb - pa) * t
	local ra, rb = rawget(a, "_r"), rawget(b, "_r")
	local r = {}
	for i = 1, 9 do
		r[i] = ra[i] + (rb[i] - ra[i]) * t
	end
	return cf(p.X, p.Y, p.Z, r)
end
function metodosCF.GetComponents(c)
	local p, r = rawget(c, "_p"), rawget(c, "_r")
	return p.X, p.Y, p.Z, r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9]
end

local function rotX(a)
	return { 1, 0, 0, 0, cos(a), -sin(a), 0, sin(a), cos(a) }
end
local function rotY(a)
	return { cos(a), 0, sin(a), 0, 1, 0, -sin(a), 0, cos(a) }
end
local function rotZ(a)
	return { cos(a), -sin(a), 0, sin(a), cos(a), 0, 0, 0, 1 }
end

local CFrame = {}
function CFrame.new(a, b, c)
	if a == nil then
		return cf(0, 0, 0)
	elseif typeof(a) == "Vector3" then
		if typeof(b) == "Vector3" then
			return CFrame.lookAt(a, b)
		end
		return cf(a.X, a.Y, a.Z)
	elseif type(a) == "number" and type(b) == "number" and type(c) == "number" then
		return cf(a, b, c)
	end
	error("CFrame.new: argumentos inválidos (" .. typeof(a) .. ", " .. typeof(b) .. ", " .. typeof(c) .. ")", 2)
end
function CFrame.Angles(rx, ry, rz)
	return cf(0, 0, 0, mulR(mulR(rotX(rx), rotY(ry)), rotZ(rz)))
end
CFrame.fromEulerAnglesXYZ = CFrame.Angles
function CFrame.lookAt(pos, alvo)
	local frente = (alvo - pos).Unit
	local cima = v3(0, 1, 0)
	local direita = metodosV3.Cross(frente, cima).Unit
	cima = metodosV3.Cross(direita, frente)
	local tras = -frente
	return cf(pos.X, pos.Y, pos.Z, {
		direita.X, cima.X, tras.X,
		direita.Y, cima.Y, tras.Y,
		direita.Z, cima.Z, tras.Z,
	})
end
CFrame.identity = cf(0, 0, 0)

local C3 = { __type = "Color3" }
local metodosC3 = {}
local function c3(r, g, b)
	return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3)
end
C3.__index = function(_, k)
	local m = metodosC3[k]
	if m then
		return m
	end
	error(tostring(k) .. " is not a valid member of Color3", 2)
end
C3.__eq = function(a, b)
	return a.R == b.R and a.G == b.G and a.B == b.B
end
function metodosC3.Lerp(a, b, t)
	if typeof(b) ~= "Color3" then
		error("Color3:Lerp espera Color3", 2)
	end
	return c3(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end
function metodosC3.ToHSV(c)
	return 0, 0, math.max(c.R, c.G, c.B)
end
local Color3 = {}
function Color3.new(r, g, b)
	return c3(r, g, b)
end
function Color3.fromRGB(r, g, b)
	for _, v in ipairs({ r, g, b }) do
		if type(v) ~= "number" then
			error("Color3.fromRGB espera números", 2)
		end
	end
	return c3(r / 255, g / 255, b / 255)
end
function Color3.fromHSV(h, s, v)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	i = i % 6
	if i == 0 then
		return c3(v, t, p)
	elseif i == 1 then
		return c3(q, v, p)
	elseif i == 2 then
		return c3(p, v, t)
	elseif i == 3 then
		return c3(p, q, v)
	elseif i == 4 then
		return c3(t, p, v)
	end
	return c3(v, p, q)
end

local UD = { __type = "UDim" }
UD.__index = function(_, k)
	error(tostring(k) .. " is not a valid member of UDim", 2)
end
local function udim(s, o)
	return setmetatable({ Scale = s or 0, Offset = o or 0 }, UD)
end
local UDim = {
	new = function(s, o)
		return udim(s, o)
	end,
}

local UD2 = { __type = "UDim2" }
UD2.__index = function(u, k)
	if k == "Width" then
		return rawget(u, "X")
	elseif k == "Height" then
		return rawget(u, "Y")
	end
	error(tostring(k) .. " is not a valid member of UDim2", 2)
end
local function udim2(xs, xo, ys, yo)
	for _, v in ipairs({ xs or 0, xo or 0, ys or 0, yo or 0 }) do
		if type(v) ~= "number" then
			error("UDim2.new espera números", 3)
		end
	end
	return setmetatable({ X = udim(xs, xo), Y = udim(ys, yo) }, UD2)
end
local UDim2 = {
	new = function(xs, xo, ys, yo)
		return udim2(xs, xo, ys, yo)
	end,
	fromOffset = function(x, y)
		return udim2(0, x, 0, y)
	end,
	fromScale = function(x, y)
		return udim2(x, 0, y, 0)
	end,
}

local TI = { __type = "TweenInfo" }
TI.__index = function(_, k)
	error(tostring(k) .. " is not a valid member of TweenInfo", 2)
end
local TweenInfo = {
	new = function(tempo, estilo, direcao, repeticoes, inverte, atraso)
		if estilo ~= nil and (typeof(estilo) ~= "EnumItem" or estilo.EnumType ~= "EasingStyle") then
			error("TweenInfo.new: estilo inválido", 2)
		end
		return setmetatable({ Time = tempo or 1, EasingStyle = estilo, EasingDirection = direcao,
			RepeatCount = repeticoes or 0, Reverses = inverte or false, DelayTime = atraso or 0 }, TI)
	end,
}

local RND = { __type = "Random" }
local metodosRND = {}
RND.__index = function(_, k)
	local m = metodosRND[k]
	if m then
		return m
	end
	error(tostring(k) .. " is not a valid member of Random", 2)
end
local sementeGlobal = 12345
local function proximo(r)
	-- gerador congruente linear simples, determinístico
	local s = (rawget(r, "_s") * 1103515245 + 12345) % 2147483648
	rawset(r, "_s", s)
	return s / 2147483648
end
function metodosRND.NextNumber(r, a, b)
	local x = proximo(r)
	if a then
		return a + (b - a) * x
	end
	return x
end
function metodosRND.NextInteger(r, a, b)
	if type(a) ~= "number" or type(b) ~= "number" or a > b then
		error("NextInteger: intervalo inválido", 2)
	end
	return a + math.floor(proximo(r) * (b - a + 1))
end
local Random = {
	new = function(semente)
		sementeGlobal = sementeGlobal + 7919
		return setmetatable({ _s = semente or sementeGlobal }, RND)
	end,
}

local CS = { __type = "ColorSequence" }
CS.__index = function(t, k)
	if k == "Keypoints" then
		return rawget(t, "_k")
	end
	error(tostring(k) .. " is not a valid member of ColorSequence", 2)
end
local ColorSequence = {
	new = function(a, b)
		if typeof(a) == "Color3" then
			if b ~= nil and typeof(b) ~= "Color3" then
				error("ColorSequence.new: segundo argumento precisa ser Color3", 2)
			end
			return setmetatable({ _k = { a, b or a } }, CS)
		elseif type(a) == "table" and getmetatable(a) == nil then
			return setmetatable({ _k = a }, CS)
		end
		error("ColorSequence.new: argumentos inválidos (" .. typeof(a) .. ")", 2)
	end,
}
local NS = { __type = "NumberSequence" }
NS.__index = function(t, k)
	if k == "Keypoints" then
		return rawget(t, "_k")
	end
	error(tostring(k) .. " is not a valid member of NumberSequence", 2)
end
local NumberSequence = {
	new = function(a, b)
		if type(a) == "number" then
			if b ~= nil and type(b) ~= "number" then
				error("NumberSequence.new: segundo argumento precisa ser número", 2)
			end
			return setmetatable({ _k = { a, b or a } }, NS)
		elseif type(a) == "table" and getmetatable(a) == nil then
			return setmetatable({ _k = a }, NS)
		end
		error("NumberSequence.new: argumentos inválidos (" .. typeof(a) .. ")", 2)
	end,
}
local NR = { __type = "NumberRange" }
NR.__index = function(_, k)
	error(tostring(k) .. " is not a valid member of NumberRange", 2)
end
local NumberRange = {
	new = function(a, b)
		if type(a) ~= "number" or (b ~= nil and type(b) ~= "number") then
			error("NumberRange.new espera números", 2)
		end
		if b and b < a then
			error("NumberRange: o máximo precisa ser maior que o mínimo", 2)
		end
		return setmetatable({ Min = a, Max = b or a }, NR)
	end,
}

local TIPOS_SIMULADOS = {
	Vector3 = true, Vector2 = true, CFrame = true, Color3 = true,
	UDim = true, UDim2 = true, TweenInfo = true,
	ColorSequence = true, NumberSequence = true, NumberRange = true,
}

---------------------------------------------------------------------------
-- Enums
---------------------------------------------------------------------------
local EnumItemMT = { __type = "EnumItem" }
EnumItemMT.__index = function(_, k)
	error(tostring(k) .. " is not a valid member of EnumItem", 2)
end
EnumItemMT.__tostring = function(e)
	return "Enum." .. rawget(e, "EnumType") .. "." .. rawget(e, "Name")
end
local cacheEnums = {}
local EnumTipoMT = { __type = "Enum" }
EnumTipoMT.__index = function(t, item)
	local nome = rawget(t, "_nome")
	if item == "GetEnumItems" then
		return function()
			local lista = {}
			for nomeItem in pairs(API.enums[nome]) do
				table.insert(lista, t[nomeItem])
			end
			return lista
		end
	end
	local valor = API.enums[nome][item]
	if valor == nil then
		error(tostring(item) .. " is not a valid member of \"Enum." .. nome .. "\"", 2)
	end
	local itens = rawget(t, "_itens")
	if not itens[item] then
		itens[item] = setmetatable({ Name = item, Value = valor, EnumType = nome }, EnumItemMT)
	end
	return itens[item]
end
local Enum = setmetatable({}, {
	__index = function(_, nome)
		if not API.enums[nome] then
			error(tostring(nome) .. " is not a valid member of \"Enum\"", 2)
		end
		if not cacheEnums[nome] then
			cacheEnums[nome] = setmetatable({ _nome = nome, _itens = {} }, EnumTipoMT)
		end
		return cacheEnums[nome]
	end,
})

---------------------------------------------------------------------------
-- Instâncias
---------------------------------------------------------------------------
local classes = API.classes
local internos = setmetatable({}, { __mode = "k" })
Sim.internos = internos

local InstMT = { __type = "Instance" }

local function eh(classe, alvo)
	local c = classe
	while c and classes[c] do
		if c == alvo then
			return true
		end
		c = classes[c].super
	end
	return false
end
Sim.eh = eh

local cacheMembro = {}
local function membro(classe, nome)
	local chave = classe .. "." .. nome
	local cache = cacheMembro[chave]
	if cache ~= nil then
		return cache or nil
	end
	local c = classe
	while c and classes[c] do
		local m = classes[c].m[nome]
		if m then
			cacheMembro[chave] = m
			return m
		end
		c = classes[c].super
	end
	cacheMembro[chave] = false
	return nil
end

local function nomeCompleto(obj)
	local partes = {}
	local atual = obj
	while atual do
		local d = internos[atual]
		if d.classe == "DataModel" then
			break
		end
		table.insert(partes, 1, d.props.Name)
		atual = d.pai
	end
	return table.concat(partes, ".")
end
Sim.nomeCompleto = nomeCompleto

local function novaInstancia(classe, forcar)
	local def = classes[classe]
	if not def then
		error("Unable to create an Instance of type \"" .. tostring(classe) .. "\"", 3)
	end
	if not forcar and (def.tags.NotCreatable or def.tags.Service) then
		error("Unable to create an Instance of type \"" .. classe .. "\" (não pode ser criado por script)", 3)
	end
	if def.tags.Deprecated then
		avisar("classe obsoleta criada: " .. classe)
	end
	local obj = setmetatable({}, InstMT)
	internos[obj] = {
		classe = classe,
		props = { Name = classe },
		filhos = {},
		pai = nil,
		attrs = {},
		sinais = {},
		sinaisProp = {},
		sinaisAttr = {},
		tags = {},
		destruido = false,
	}
	return obj
end
Sim.novaInstancia = novaInstancia

local function sinalDe(d, nome)
	if not d.sinais[nome] then
		d.sinais[nome] = novoSinal(nome)
	end
	return d.sinais[nome]
end
Sim.sinalDe = function(obj, nome)
	return sinalDe(internos[obj], nome)
end

local function ehDescendente(obj, ancestral)
	local atual = internos[obj].pai
	while atual do
		if atual == ancestral then
			return true
		end
		atual = internos[atual].pai
	end
	return false
end

local jogo -- DataModel

local function noJogo(obj)
	return obj == jogo or ehDescendente(obj, jogo)
end

local sinaisTag = {}
local function sinalTag(tag, tipo)
	local chave = tipo .. ":" .. tag
	if not sinaisTag[chave] then
		sinaisTag[chave] = novoSinal(chave)
	end
	return sinaisTag[chave]
end

local function dispararMudanca(obj, chave, valor)
	local d = internos[obj]
	if d.sinaisProp[chave] then
		Sim.disparar(d.sinaisProp[chave])
	end
	if d.sinais.Changed then
		if eh(d.classe, "ValueBase") then
			if chave == "Value" then
				Sim.disparar(d.sinais.Changed, valor)
			end
		else
			Sim.disparar(d.sinais.Changed, chave)
		end
	end
end

local function cadaDescendente(obj, fn)
	for _, f in ipairs(internos[obj].filhos) do
		fn(f)
		cadaDescendente(f, fn)
	end
end

local function reparentar(obj, novoPai)
	local d = internos[obj]
	if d.destruido then
		error("The Parent property of " .. d.props.Name .. " is locked, current parent: NULL", 3)
	end
	if novoPai ~= nil then
		if typeof(novoPai) ~= "Instance" then
			error("Parent precisa ser uma Instance", 3)
		end
		if novoPai == obj or ehDescendente(novoPai, obj) then
			error("Attempt to set parent of " .. d.props.Name .. " would result in circular reference", 3)
		end
	end
	local antigo = d.pai
	if antigo == novoPai then
		return
	end
	local estavaNoJogo = noJogo(obj)
	if antigo then
		local lista = internos[antigo].filhos
		for i, f in ipairs(lista) do
			if f == obj then
				table.remove(lista, i)
				break
			end
		end
		if internos[antigo].sinais.ChildRemoved then
			Sim.disparar(internos[antigo].sinais.ChildRemoved, obj)
		end
	end
	d.pai = novoPai
	if novoPai then
		table.insert(internos[novoPai].filhos, obj)
		if internos[novoPai].sinais.ChildAdded then
			Sim.disparar(internos[novoPai].sinais.ChildAdded, obj)
		end
	end
	local agoraNoJogo = noJogo(obj)
	if agoraNoJogo ~= estavaNoJogo then
		local function avisarTags(item)
			for tag in pairs(internos[item].tags) do
				Sim.disparar(sinalTag(tag, agoraNoJogo and "add" or "rem"), item)
			end
		end
		avisarTags(obj)
		cadaDescendente(obj, avisarTags)
	end
	if d.sinais.AncestryChanged then
		Sim.disparar(d.sinais.AncestryChanged, obj, novoPai)
	end
end

local function destruir(obj)
	local d = internos[obj]
	if d.destruido then
		return
	end
	for i = #d.filhos, 1, -1 do
		destruir(d.filhos[i])
	end
	if d.pai then
		reparentar(obj, nil)
	end
	d.destruido = true
	if d.sinais.Destroying then
		Sim.disparar(d.sinais.Destroying)
	end
	for _, s in pairs(d.sinais) do
		for _, c in ipairs(rawget(s, "_conexoes")) do
			rawset(c, "Connected", false)
		end
	end
end
Sim.destruir = destruir

local function parsePadrao(m, classe)
	local texto = m.def
	local cat, tn = m.cat, m.tn
	if texto == nil or texto == "__api_dump_class_not_creatable__" then
		texto = nil
	end
	if cat == "Primitive" then
		if tn == "bool" then
			if texto ~= nil then
				return texto == "true"
			end
			return false
		elseif tn == "string" then
			return texto or ""
		else
			return tonumber(texto) or 0
		end
	elseif cat == "Enum" then
		if texto and API.enums[tn] and API.enums[tn][texto] ~= nil then
			return Enum[tn][texto]
		end
		for nome in pairs(API.enums[tn] or {}) do
			return Enum[tn][nome]
		end
	elseif cat == "DataType" then
		local nums = {}
		if texto then
			for n in string.gmatch(texto, "[-%d%.e]+") do
				table.insert(nums, tonumber(n))
			end
		end
		if tn == "Vector3" then
			return v3(nums[1] or 0, nums[2] or 0, nums[3] or 0)
		elseif tn == "Vector2" then
			return v2(nums[1] or 0, nums[2] or 0)
		elseif tn == "Color3" then
			return c3(nums[1] or 0.64, nums[2] or 0.64, nums[3] or 0.64)
		elseif tn == "CFrame" then
			return cf(nums[1] or 0, nums[2] or 0, nums[3] or 0)
		elseif tn == "UDim2" then
			return udim2(nums[1] or 0, nums[2] or 0, nums[3] or 0, nums[4] or 0)
		elseif tn == "UDim" then
			return udim(nums[1] or 0, nums[2] or 0)
		elseif tn == "Content" or tn == "ContentId" then
			return texto or ""
		end
	end
	return nil
end

local PADROES_ESPECIAIS = {
	CanCollide = true,
	CanTouch = true,
	CanQuery = true,
}

local function lerPropriedade(obj, d, chave, m)
	if chave == "Position" and eh(d.classe, "BasePart") then
		local c = d.props.CFrame or cf(0, 0, 0)
		return c.Position
	end
	local v = d.props[chave]
	if v ~= nil then
		return v
	end
	if eh(d.classe, "BasePart") then
		if PADROES_ESPECIAIS[chave] ~= nil then
			return PADROES_ESPECIAIS[chave]
		end
		if chave == "Size" then
			return v3(4, 1, 2)
		end
	end
	return parsePadrao(m, d.classe)
end

local function verificarTipo(classe, chave, m, v)
	local cat, tn = m.cat, m.tn
	local function erro(esperado)
		error(string.format("tipo inválido em %s.%s: esperado %s, recebeu %s", classe, chave, esperado, typeof(v)), 4)
	end
	if cat == "Primitive" then
		if tn == "bool" then
			if type(v) ~= "boolean" then
				erro("bool")
			end
		elseif tn == "string" then
			if type(v) ~= "string" then
				erro("string")
			end
		elseif tn == "float" or tn == "double" or tn == "int" or tn == "int64" then
			if type(v) ~= "number" then
				erro(tn)
			end
			if v ~= v then
				erro(tn .. " (recebeu NaN)")
			end
		end
	elseif cat == "DataType" then
		if tn == "Content" or tn == "ContentId" then
			if type(v) ~= "string" then
				erro(tn)
			end
		elseif TIPOS_SIMULADOS[tn] then
			if typeof(v) ~= tn then
				erro(tn)
			end
		end
	elseif cat == "Enum" then
		if typeof(v) == "EnumItem" then
			if v.EnumType ~= tn then
				erro("Enum." .. tn)
			end
		else
			erro("Enum." .. tn)
		end
	elseif cat == "Class" then
		if v ~= nil and (typeof(v) ~= "Instance" or not eh(internos[v].classe, tn)) then
			erro(tn)
		end
	end
end

-- métodos simulados --------------------------------------------------------
local metodos = {} -- [nome] = { classeMinima = "Instance", fn = function(self, ...) }
local function metodo(classe, nome, fn)
	metodos[nome] = metodos[nome] or {}
	table.insert(metodos[nome], { classe = classe, fn = fn })
end

local function profundidade(classe)
	local n = 0
	local c = classe
	while c and classes[c] do
		n = n + 1
		c = classes[c].super
	end
	return n
end

-- escolhe a implementação da classe mais específica (ex.: CollectionService:AddTag
-- ganha de Instance:AddTag)
local function acharMetodo(classe, nome)
	local lista = metodos[nome]
	if not lista then
		return nil
	end
	local melhor, melhorProf = nil, -1
	for _, entrada in ipairs(lista) do
		if eh(classe, entrada.classe) then
			local p = profundidade(entrada.classe)
			if p > melhorProf then
				melhor, melhorProf = entrada.fn, p
			end
		end
	end
	return melhor
end

InstMT.__index = function(obj, chave)
	local d = internos[obj]
	if chave == "ClassName" then
		return d.classe
	elseif chave == "Parent" then
		return d.pai
	elseif chave == "Name" then
		return d.props.Name
	end
	if type(chave) ~= "string" then
		error("índice inválido em Instance: " .. tostring(chave), 2)
	end
	local m = membro(d.classe, chave)
	if m then
		if m.sec then
			error("The current thread cannot access '" .. chave .. "' (lacking capability)", 2)
		end
		if m.dep then
			avisar("membro obsoleto usado: " .. d.classe .. "." .. chave)
		end
		if m.k == "P" then
			return lerPropriedade(obj, d, chave, m)
		elseif m.k == "F" then
			local fn = acharMetodo(d.classe, chave)
			if fn then
				return fn
			end
			return function()
				avisar("função não simulada: " .. d.classe .. ":" .. chave .. "()")
				return nil
			end
		elseif m.k == "E" then
			return sinalDe(d, chave)
		elseif m.k == "C" then
			return d.props[chave]
		end
	end
	for _, filho in ipairs(d.filhos) do
		if internos[filho].props.Name == chave then
			return filho
		end
	end
	error(tostring(chave) .. " is not a valid member of " .. d.classe .. " \"" .. nomeCompleto(obj) .. "\"", 2)
end

InstMT.__newindex = function(obj, chave, valor)
	local d = internos[obj]
	local m = type(chave) == "string" and membro(d.classe, chave)
	if not m then
		error(tostring(chave) .. " is not a valid member of " .. d.classe .. " \"" .. nomeCompleto(obj) .. "\"", 2)
	end
	if m.k == "F" or m.k == "E" then
		error("não é possível atribuir a " .. d.classe .. "." .. chave, 2)
	end
	if m.sec then
		error("The current thread cannot write '" .. chave .. "' (lacking capability)", 2)
	end
	if m.ro then
		error("Unable to assign property " .. chave .. ". Property is read only", 2)
	end
	if m.dep then
		avisar("membro obsoleto usado: " .. d.classe .. "." .. chave)
	end
	if m.k == "P" then
		verificarTipo(d.classe, chave, m, valor)
	elseif m.k == "C" and valor ~= nil and type(valor) ~= "function" then
		error("callback precisa ser uma função", 2)
	end
	if chave == "Parent" then
		reparentar(obj, valor)
		return
	end
	if chave == "Position" and eh(d.classe, "BasePart") then
		local atual = d.props.CFrame or cf(0, 0, 0)
		d.props.CFrame = atual - atual.Position + valor
		dispararMudanca(obj, "CFrame")
		dispararMudanca(obj, "Position")
		return
	end
	d.props[chave] = valor
	dispararMudanca(obj, chave, valor)
end

InstMT.__tostring = function(obj)
	return internos[obj].props.Name
end

-- Define uma propriedade sem as verificações (para o teste preparar o mundo)
function Sim.definir(obj, chave, valor)
	internos[obj].props[chave] = valor
	dispararMudanca(obj, chave, valor)
end

-- Métodos de Instance -------------------------------------------------------
metodo("Instance", "FindFirstChild", function(self, nome, recursivo)
	for _, f in ipairs(internos[self].filhos) do
		if internos[f].props.Name == nome then
			return f
		end
	end
	if recursivo then
		for _, f in ipairs(internos[self].filhos) do
			local achou = f:FindFirstChild(nome, true)
			if achou then
				return achou
			end
		end
	end
	return nil
end)

metodo("Instance", "FindFirstChildOfClass", function(self, classe)
	if not classes[classe] then
		error("FindFirstChildOfClass: classe desconhecida " .. tostring(classe), 2)
	end
	for _, f in ipairs(internos[self].filhos) do
		if internos[f].classe == classe then
			return f
		end
	end
	return nil
end)

metodo("Instance", "FindFirstChildWhichIsA", function(self, classe)
	for _, f in ipairs(internos[self].filhos) do
		if eh(internos[f].classe, classe) then
			return f
		end
	end
	return nil
end)

metodo("Instance", "FindFirstAncestorOfClass", function(self, classe)
	local atual = internos[self].pai
	while atual do
		if internos[atual].classe == classe then
			return atual
		end
		atual = internos[atual].pai
	end
	return nil
end)

metodo("Instance", "WaitForChild", function(self, nome, limite)
	local achou = self:FindFirstChild(nome)
	if achou then
		return achou
	end
	if not coroutine.running() then
		error("WaitForChild fora de thread", 2)
	end
	local inicio = Sim.T
	while true do
		task.wait(0.05)
		achou = self:FindFirstChild(nome)
		if achou then
			return achou
		end
		if limite and Sim.T - inicio >= limite then
			return nil
		end
		if not limite and Sim.T - inicio > 15 then
			error("Infinite yield possible on '" .. nomeCompleto(self) .. ":WaitForChild(\"" .. nome .. "\")'", 2)
		end
	end
end)

metodo("Instance", "GetChildren", function(self)
	local lista = {}
	for i, f in ipairs(internos[self].filhos) do
		lista[i] = f
	end
	return lista
end)

metodo("Instance", "GetDescendants", function(self)
	local lista = {}
	cadaDescendente(self, function(f)
		table.insert(lista, f)
	end)
	return lista
end)

metodo("Instance", "IsA", function(self, classe)
	return eh(internos[self].classe, classe)
end)

metodo("Instance", "IsDescendantOf", function(self, outro)
	return ehDescendente(self, outro)
end)

metodo("Instance", "Destroy", function(self)
	destruir(self)
end)

metodo("Instance", "ClearAllChildren", function(self)
	local filhos = internos[self].filhos
	for i = #filhos, 1, -1 do
		destruir(filhos[i])
	end
end)

metodo("Instance", "GetFullName", function(self)
	return nomeCompleto(self)
end)

local TIPOS_ATRIBUTO = {
	["nil"] = true, boolean = true, number = true, string = true,
	Vector3 = true, Vector2 = true, Color3 = true, UDim = true, UDim2 = true,
	CFrame = true, EnumItem = true, ColorSequence = true, NumberSequence = true, NumberRange = true,
}

metodo("Instance", "SetAttribute", function(self, nome, valor)
	if type(nome) ~= "string" or not string.match(nome, "^[%w_]+$") or #nome > 100
		or string.sub(nome, 1, 3) == "RBX" then
		error("nome de atributo inválido: " .. tostring(nome), 2)
	end
	if not TIPOS_ATRIBUTO[typeof(valor)] then
		error(typeof(valor) .. " is not a supported attribute type", 2)
	end
	local d = internos[self]
	if d.attrs[nome] == valor then
		return
	end
	d.attrs[nome] = valor
	if d.sinaisAttr[nome] then
		Sim.disparar(d.sinaisAttr[nome])
	end
	if d.sinais.AttributeChanged then
		Sim.disparar(d.sinais.AttributeChanged, nome)
	end
end)

metodo("Instance", "GetAttribute", function(self, nome)
	return internos[self].attrs[nome]
end)

metodo("Instance", "GetAttributes", function(self)
	local copia = {}
	for k, v in pairs(internos[self].attrs) do
		copia[k] = v
	end
	return copia
end)

metodo("Instance", "GetAttributeChangedSignal", function(self, nome)
	local d = internos[self]
	if not d.sinaisAttr[nome] then
		d.sinaisAttr[nome] = novoSinal("Attr:" .. nome)
	end
	return d.sinaisAttr[nome]
end)

metodo("Instance", "GetPropertyChangedSignal", function(self, nome)
	local d = internos[self]
	if not membro(d.classe, nome) then
		error(tostring(nome) .. " is not a valid property name.", 2)
	end
	if not d.sinaisProp[nome] then
		d.sinaisProp[nome] = novoSinal("Prop:" .. nome)
	end
	return d.sinaisProp[nome]
end)

local function adicionarTag(obj, tag)
	local d = internos[obj]
	if d.tags[tag] then
		return
	end
	d.tags[tag] = true
	if noJogo(obj) then
		Sim.disparar(sinalTag(tag, "add"), obj)
	end
end

metodo("Instance", "AddTag", function(self, tag)
	adicionarTag(self, tag)
end)
metodo("Instance", "HasTag", function(self, tag)
	return internos[self].tags[tag] == true
end)

-- PVInstance: PivotTo / GetPivot ------------------------------------------
local function pivoDe(obj)
	local d = internos[obj]
	if eh(d.classe, "BasePart") then
		return d.props.CFrame or cf(0, 0, 0)
	end
	local primaria = d.props.PrimaryPart
	if primaria and not internos[primaria].destruido then
		return internos[primaria].props.CFrame or cf(0, 0, 0)
	end
	return d.props.WorldPivot or cf(0, 0, 0)
end

metodo("PVInstance", "GetPivot", function(self)
	return pivoDe(self)
end)

metodo("PVInstance", "PivotTo", function(self, alvo)
	if typeof(alvo) ~= "CFrame" then
		error("PivotTo espera CFrame, recebeu " .. typeof(alvo), 2)
	end
	local d = internos[self]
	if eh(d.classe, "BasePart") then
		d.props.CFrame = alvo
		return
	end
	local delta = alvo * metodosCF.Inverse(pivoDe(self))
	cadaDescendente(self, function(f)
		local df = internos[f]
		if eh(df.classe, "BasePart") then
			df.props.CFrame = delta * (df.props.CFrame or cf(0, 0, 0))
		end
	end)
	if not d.props.PrimaryPart then
		d.props.WorldPivot = alvo
	end
end)

---------------------------------------------------------------------------
-- Serviços
---------------------------------------------------------------------------
local servicos = {}

local function servico(nome)
	if servicos[nome] then
		return servicos[nome]
	end
	local def = classes[nome]
	if not def or not def.tags.Service then
		error("'" .. tostring(nome) .. "' is not a valid Service name", 3)
	end
	local s = novaInstancia(nome, true)
	internos[s].props.Name = nome
	servicos[nome] = s
	if jogo then
		reparentar(s, jogo)
	end
	return s
end

jogo = novaInstancia("DataModel", true)
internos[jogo].props.Name = "Game"
Sim.jogo = jogo

metodo("ServiceProvider", "GetService", function(_, nome)
	return servico(nome)
end)
metodo("DataModel", "BindToClose", function(_, fn)
	table.insert(Sim.aoFechar, fn)
end)

local workspaceInst = servico("Workspace")
internos[workspaceInst].props.Name = "Workspace"
metodo("WorldRoot", "GetServerTimeNow", function()
	return 1700000000 + Sim.T
end)

-- Players
metodo("Players", "GetPlayers", function(self)
	local lista = {}
	for _, f in ipairs(internos[self].filhos) do
		if internos[f].classe == "Player" then
			table.insert(lista, f)
		end
	end
	return lista
end)
metodo("Players", "GetPlayerByUserId", function(self, id)
	for _, f in ipairs(internos[self].filhos) do
		if internos[f].classe == "Player" and internos[f].props.UserId == id then
			return f
		end
	end
	return nil
end)
metodo("Players", "GetPlayerFromCharacter", function(self, personagem)
	for _, f in ipairs(internos[self].filhos) do
		if internos[f].classe == "Player" and internos[f].props.Character == personagem then
			return f
		end
	end
	return nil
end)
metodo("Player", "Kick", function(self, mensagem)
	table.insert(Sim.expulsos, { jogador = self, mensagem = mensagem })
end)

-- RunService
metodo("RunService", "IsStudio", function()
	return Sim.estudio
end)
metodo("RunService", "IsServer", function()
	return true
end)
metodo("RunService", "IsClient", function()
	return true
end)
metodo("RunService", "IsRunning", function()
	return true
end)

-- TweenService
metodo("TweenService", "Create", function(_, alvo, info, props)
	if typeof(alvo) ~= "Instance" then
		error("TweenService:Create: alvo precisa ser Instance", 2)
	end
	if typeof(info) ~= "TweenInfo" then
		error("TweenService:Create: info precisa ser TweenInfo", 2)
	end
	for chave, valor in pairs(props) do
		local m = membro(internos[alvo].classe, chave)
		if not m or m.k ~= "P" then
			error("TweenService:Create: propriedade inválida " .. tostring(chave), 2)
		end
		verificarTipo(internos[alvo].classe, chave, m, valor)
	end
	local tween = novaInstancia("Tween", true)
	internos[tween].alvo = alvo
	internos[tween].info = info
	internos[tween].finais = props
	return tween
end)
metodo("TweenBase", "Play", function(self)
	local d = internos[self]
	task.delay(rawget(d.info, "Time"), function()
		if not internos[d.alvo].destruido then
			for chave, valor in pairs(d.finais) do
				d.alvo[chave] = valor
			end
		end
		Sim.disparar(sinalDe(d, "Completed"), Enum.PlaybackState.Completed)
	end)
end)
metodo("TweenBase", "Cancel", function() end)

-- Debris
metodo("Debris", "AddItem", function(_, item, tempo)
	task.delay(tempo or 10, function()
		destruir(item)
	end)
end)

-- CollectionService
metodo("CollectionService", "AddTag", function(_, obj, tag)
	adicionarTag(obj, tag)
end)
metodo("CollectionService", "HasTag", function(_, obj, tag)
	return internos[obj].tags[tag] == true
end)
metodo("CollectionService", "GetTagged", function(_, tag)
	local lista = {}
	cadaDescendente(jogo, function(f)
		if internos[f].tags[tag] then
			table.insert(lista, f)
		end
	end)
	return lista
end)
metodo("CollectionService", "GetInstanceAddedSignal", function(_, tag)
	return sinalTag(tag, "add")
end)
metodo("CollectionService", "GetInstanceRemovedSignal", function(_, tag)
	return sinalTag(tag, "rem")
end)

-- DataStore
local function validarSalvavel(valor, caminho)
	local t = type(valor)
	if t == "number" then
		if valor ~= valor or valor == math.huge or valor == -math.huge then
			error("DataStore: número inválido em " .. caminho, 4)
		end
	elseif t == "string" or t == "boolean" or t == "nil" then
		return
	elseif t == "table" then
		if getmetatable(valor) then
			error("DataStore: " .. typeof(valor) .. " não pode ser salvo em " .. caminho, 4)
		end
		local n = #valor
		local temTexto, temNumero = false, false
		for k, v in pairs(valor) do
			if type(k) == "number" then
				temNumero = true
				if k < 1 or k > n or k ~= math.floor(k) then
					error("DataStore: lista com buracos em " .. caminho, 4)
				end
			elseif type(k) == "string" then
				temTexto = true
			else
				error("DataStore: chave inválida em " .. caminho, 4)
			end
			validarSalvavel(v, caminho .. "." .. tostring(k))
		end
		if temTexto and temNumero then
			error("DataStore: tabela mista (lista + dicionário) em " .. caminho, 4)
		end
	else
		error("DataStore: tipo " .. t .. " não pode ser salvo em " .. caminho, 4)
	end
end

local function copiaProfunda(v)
	if type(v) ~= "table" then
		return v
	end
	local c = {}
	for k, x in pairs(v) do
		c[k] = copiaProfunda(x)
	end
	return c
end
Sim.copiaProfunda = copiaProfunda

metodo("DataStoreService", "GetDataStore", function(_, nome)
	local cofre = novaInstancia("DataStore", true)
	internos[cofre].props.Name = nome
	Sim.cofres[nome] = Sim.cofres[nome] or {}
	internos[cofre].dados = Sim.cofres[nome]
	return cofre
end)
metodo("GlobalDataStore", "GetAsync", function(self, chave)
	if Sim.falharDataStore then
		error("502: API Services rejected request (simulado)", 2)
	end
	return copiaProfunda(internos[self].dados[chave])
end)
metodo("GlobalDataStore", "SetAsync", function(self, chave, valor, ids)
	if Sim.falharDataStore then
		error("502: API Services rejected request (simulado)", 2)
	end
	validarSalvavel(valor, chave)
	if ids ~= nil then
		validarSalvavel(ids, "userIds")
	end
	internos[self].dados[chave] = copiaProfunda(valor)
end)

metodo("GlobalDataStore", "UpdateAsync", function(self, chave, transformar)
	if Sim.falharDataStore then
		error("502: API Services rejected request (simulado)", 2)
	end
	local antigo = copiaProfunda(internos[self].dados[chave])
	local novo = transformar(antigo, nil)
	if novo == nil then
		return nil
	end
	validarSalvavel(novo, chave)
	internos[self].dados[chave] = copiaProfunda(novo)
	return copiaProfunda(novo)
end)
metodo("DataStoreService", "GetOrderedDataStore", function(_, nome)
	local cofre = novaInstancia("OrderedDataStore", true)
	internos[cofre].props.Name = nome
	local chave = "ordenado:" .. nome
	Sim.cofres[chave] = Sim.cofres[chave] or {}
	internos[cofre].dados = Sim.cofres[chave]
	return cofre
end)
metodo("OrderedDataStore", "SetAsync", function(self, chave, valor)
	if type(valor) ~= "number" or valor ~= math.floor(valor) then
		error("OrderedDataStore só aceita números inteiros", 2)
	end
	internos[self].dados[chave] = valor
end)
metodo("OrderedDataStore", "GetSortedAsync", function(self, crescente, tamanho)
	local lista = {}
	for k, v in pairs(internos[self].dados) do
		table.insert(lista, { key = k, value = v })
	end
	table.sort(lista, function(a, b)
		if crescente then
			return a.value < b.value
		end
		return a.value > b.value
	end)
	local pagina = {}
	for i = 1, math.min(tamanho or 50, #lista) do
		pagina[i] = lista[i]
	end
	local paginas = novaInstancia("DataStorePages", true)
	internos[paginas].pagina = pagina
	return paginas
end)
metodo("Pages", "GetCurrentPage", function(self)
	return internos[self].pagina or {}
end)

-- PolicyService, AdService, grupos e amigos
metodo("PolicyService", "GetPolicyInfoForPlayerAsync", function(_, jogador)
	return { ArePaidRandomItemsRestricted = Sim.caixaRestrita[jogador.UserId] == true }
end)
local AdRewardMT = { __type = "AdReward" }
metodo("AdService", "CreateAdRewardFromDevProductId", function(_, id)
	if type(id) ~= "number" then
		error("CreateAdRewardFromDevProductId espera um número", 2)
	end
	return setmetatable({ produto = id }, AdRewardMT)
end)
metodo("AdService", "ShowRewardedVideoAdAsync", function(_, jogador, premio)
	if typeof(jogador) ~= "Instance" or internos[jogador].classe ~= "Player" then
		error("ShowRewardedVideoAdAsync: precisa de um Player", 2)
	end
	if typeof(premio) ~= "AdReward" then
		error("ShowRewardedVideoAdAsync: precisa de um AdReward", 2)
	end
	table.insert(Sim.anuncios, { jogador = jogador, produto = premio.produto })
	return Sim.resultadoAnuncio or Enum.ShowAdResult.ShowCompleted
end)
metodo("Player", "IsFriendsWithAsync", function(self, outroId)
	local a, b = internos[self].props.UserId, outroId
	return Sim.amizades[math.min(a, b) .. ":" .. math.max(a, b)] == true
end)
metodo("Player", "IsInGroupAsync", function(self, grupo)
	return Sim.grupos[internos[self].props.UserId .. ":" .. grupo] == true
end)
metodo("Players", "GetNameFromUserIdAsync", function(_, id)
	return "Usuario" .. tostring(id)
end)
metodo("MarketplaceService", "GetProductInfoAsync", function(_, id)
	return { PriceInRobux = Sim.precos[id] or 10 }
end)
metodo("ParticleEmitter", "Emit", function() end)
metodo("Sound", "Play", function() end)
metodo("Sound", "Stop", function() end)

-- MarketplaceService
metodo("MarketplaceService", "UserOwnsGamePassAsync", function(_, userId, passe)
	return Sim.passes[userId .. ":" .. passe] == true
end)
metodo("MarketplaceService", "PromptProductPurchase", function(_, jogador, id)
	table.insert(Sim.compras, { jogador = jogador, produto = id })
end)
metodo("MarketplaceService", "PromptGamePassPurchase", function(_, jogador, id)
	table.insert(Sim.compras, { jogador = jogador, passe = id })
end)

-- RemoteEvent: um único jogador local enxerga o lado do cliente
local function validarArgsRemoto(...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if type(v) == "function" or type(v) == "thread" then
			error("RemoteEvent não envia " .. type(v), 3)
		end
	end
end
metodo("RemoteEvent", "FireClient", function(self, jogador, ...)
	if typeof(jogador) ~= "Instance" or internos[jogador].classe ~= "Player" then
		error("FireClient: o primeiro argumento precisa ser um Player", 2)
	end
	validarArgsRemoto(...)
	local d = internos[self]
	d.enviados = (d.enviados or 0) + 1
	if jogador == Sim.jogadorLocal then
		Sim.disparar(sinalDe(d, "OnClientEvent"), ...)
	end
end)
metodo("RemoteEvent", "FireAllClients", function(self, ...)
	validarArgsRemoto(...)
	if Sim.jogadorLocal then
		Sim.disparar(sinalDe(internos[self], "OnClientEvent"), ...)
	end
end)
metodo("RemoteEvent", "FireServer", function(self, ...)
	validarArgsRemoto(...)
	Sim.disparar(sinalDe(internos[self], "OnServerEvent"), Sim.jogadorLocal, ...)
end)

---------------------------------------------------------------------------
-- Ambiente dos scripts
---------------------------------------------------------------------------
local Instance = {
	new = function(classe, pai)
		local obj = novaInstancia(classe, false)
		if pai then
			obj.Parent = pai
		end
		return obj
	end,
}

local mathLuau = {}
for k, v in pairs(math) do
	mathLuau[k] = v
end
function mathLuau.clamp(x, minimo, maximo)
	if minimo > maximo then
		error("max must be greater than or equal to min", 2)
	end
	return math.max(minimo, math.min(maximo, x))
end
function mathLuau.round(x)
	return math.floor(x + 0.5)
end
function mathLuau.sign(x)
	return x > 0 and 1 or (x < 0 and -1 or 0)
end

local tableLuau = {}
for k, v in pairs(table) do
	tableLuau[k] = v
end
tableLuau.unpack = unpack
function tableLuau.find(t, valor)
	for i, v in ipairs(t) do
		if v == valor then
			return i
		end
	end
	return nil
end
function tableLuau.clear(t)
	for k in pairs(t) do
		t[k] = nil
	end
end

local stringLuau = {}
for k, v in pairs(string) do
	stringLuau[k] = v
end
function stringLuau.split(s, sep)
	local partes = {}
	for parte in string.gmatch(s, "([^" .. (sep or ",") .. "]*)") do
		table.insert(partes, parte)
	end
	return partes
end

local G = {
	game = jogo,
	workspace = workspaceInst,
	Instance = Instance,
	Vector3 = Vector3,
	Vector2 = Vector2,
	CFrame = CFrame,
	Color3 = Color3,
	UDim = UDim,
	UDim2 = UDim2,
	TweenInfo = TweenInfo,
	Random = Random,
	ColorSequence = ColorSequence,
	NumberSequence = NumberSequence,
	NumberRange = NumberRange,
	utf8 = {
		char = function(...)
			local partes = {}
			for i = 1, select("#", ...) do
				local c = select(i, ...)
				if c < 0x80 then
					partes[i] = string.char(c)
				elseif c < 0x800 then
					partes[i] = string.char(0xC0 + math.floor(c / 0x40), 0x80 + c % 0x40)
				else
					partes[i] = string.char(0xE0 + math.floor(c / 0x1000), 0x80 + math.floor(c / 0x40) % 0x40, 0x80 + c % 0x40)
				end
			end
			return table.concat(partes)
		end,
	},
	Enum = Enum,
	typeof = typeof,
	task = task,
	math = mathLuau,
	table = tableLuau,
	string = stringLuau,
	os = {
		clock = function()
			return Sim.T
		end,
		time = function()
			return 1700000000 + math.floor(Sim.T)
		end,
	},
	tick = function()
		return 1700000000 + Sim.T
	end,
	print = function(...)
		local partes = {}
		for i = 1, select("#", ...) do
			partes[i] = tostring(select(i, ...))
		end
		table.insert(Sim.saida, table.concat(partes, " "))
	end,
	warn = function(...)
		local partes = {}
		for i = 1, select("#", ...) do
			partes[i] = tostring(select(i, ...))
		end
		table.insert(Sim.saida, "AVISO: " .. table.concat(partes, " "))
	end,
	assert = assert, error = error, pcall = pcall, xpcall = xpcall,
	ipairs = ipairs, pairs = pairs, next = next, select = select,
	tostring = tostring, tonumber = tonumber, type = type, unpack = unpack,
	setmetatable = setmetatable, getmetatable = getmetatable,
	rawget = rawget, rawset = rawset, rawequal = rawequal,
	coroutine = coroutine,
}
Sim.G = G

local cacheModulos = {}

local function carregarFonte(obj)
	local d = internos[obj]
	if not d.arquivo then
		error("script sem arquivo: " .. nomeCompleto(obj))
	end
	local fonte = ler_arquivo(d.arquivo)
	local chunk, erro = loadstring(fonte, "@" .. d.arquivo)
	if not chunk then
		error("erro de sintaxe: " .. tostring(erro))
	end
	local env = setmetatable({ script = obj }, { __index = G })
	setfenv(chunk, env)
	return chunk
end

G.require = function(modulo)
	if typeof(modulo) ~= "Instance" or internos[modulo].classe ~= "ModuleScript" then
		error("require espera um ModuleScript, recebeu " .. typeof(modulo), 2)
	end
	local cache = cacheModulos[modulo]
	if cache then
		if cache.carregando then
			error("require circular: " .. nomeCompleto(modulo), 2)
		end
		return cache.valor
	end
	cache = { carregando = true }
	cacheModulos[modulo] = cache
	local chunk = carregarFonte(modulo)
	local valor = chunk()
	if valor == nil then
		error("Module code did not return exactly one value: " .. nomeCompleto(modulo), 2)
	end
	cache.valor = valor
	cache.carregando = false
	return valor
end

function Sim.requerer(modulo)
	return G.require(modulo)
end

-- Cria um script com o arquivo de origem
function Sim.criarScript(classe, nome, arquivo, pai)
	local s = novaInstancia(classe, false)
	internos[s].props.Name = nome
	internos[s].arquivo = arquivo
	s.Parent = pai
	return s
end

function Sim.executar(scriptInst)
	local chunk = carregarFonte(scriptInst)
	return task.spawn(chunk)
end

function Sim.servico(nome)
	return servico(nome)
end

---------------------------------------------------------------------------
-- Tempo
---------------------------------------------------------------------------
function Sim.passo(dt)
	Sim.T = Sim.T + dt
	local rs = servico("RunService")
	local d = internos[rs]
	if d.sinais.Heartbeat then
		Sim.disparar(d.sinais.Heartbeat, dt)
	end
	if d.sinais.RenderStepped then
		Sim.disparar(d.sinais.RenderStepped, dt)
	end
	local prontos = {}
	for i = #fila, 1, -1 do
		if fila[i].quando <= Sim.T + 1e-9 then
			table.insert(prontos, table.remove(fila, i))
		end
	end
	table.sort(prontos, function(a, b)
		return a.quando < b.quando
	end)
	for _, e in ipairs(prontos) do
		retomar(e.co, unpack(e.args, 1, e.n))
	end
end

function Sim.avancar(segundos, dt)
	dt = dt or (1 / 20)
	local fim = Sim.T + segundos
	while Sim.T < fim - 1e-9 do
		Sim.passo(dt)
	end
end

---------------------------------------------------------------------------
-- Jogadores e personagens
---------------------------------------------------------------------------
function Sim.novoJogador(userId, nome, localeId, premium)
	local p = novaInstancia("Player", true)
	local d = internos[p]
	d.props.Name = nome
	d.props.DisplayName = nome
	d.props.UserId = userId
	d.props.LocaleId = localeId or "en-us"
	d.props.MembershipType = premium and Enum.MembershipType.Premium or Enum.MembershipType.None
	local mochila = novaInstancia("Backpack", true)
	reparentar(mochila, p)
	local gui = novaInstancia("PlayerGui", true)
	reparentar(gui, p)
	local scripts = novaInstancia("PlayerScripts", true)
	reparentar(scripts, p)
	reparentar(p, servico("Players"))
	Sim.disparar(sinalDe(internos[servico("Players")], "PlayerAdded"), p)
	return p
end

function Sim.removerJogador(p)
	Sim.disparar(sinalDe(internos[servico("Players")], "PlayerRemoving"), p)
	destruir(p)
end

function Sim.criarPersonagem(p, posicao)
	local modelo = novaInstancia("Model", true)
	internos[modelo].props.Name = p.Name
	local raiz = Instance.new("Part")
	raiz.Name = "HumanoidRootPart"
	raiz.Size = v3(2, 2, 1)
	raiz.CFrame = cf(posicao.X, posicao.Y, posicao.Z)
	raiz.Parent = modelo
	local cabeca = Instance.new("Part")
	cabeca.Name = "Head"
	cabeca.CFrame = cf(posicao.X, posicao.Y + 1.5, posicao.Z)
	cabeca.Parent = modelo
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = modelo
	modelo.PrimaryPart = raiz
	-- a mochila é limpa a cada nascimento
	local mochila = p:FindFirstChildOfClass("Backpack")
	if mochila then
		mochila:ClearAllChildren()
	end
	local antigo = internos[p].props.Character
	if antigo then
		destruir(antigo)
	end
	Sim.definir(p, "Character", modelo)
	modelo.Parent = workspaceInst
	Sim.disparar(sinalDe(internos[p], "CharacterAdded"), modelo)
	return modelo
end

function Sim.matar(p)
	local modelo = internos[p].props.Character
	local humanoid = modelo and modelo:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
		Sim.disparar(sinalDe(internos[humanoid], "Died"))
	end
end

function Sim.moverPara(p, cframeOuPosicao)
	local modelo = internos[p].props.Character
	local alvo = cframeOuPosicao
	if typeof(alvo) == "Vector3" then
		alvo = cf(alvo.X, alvo.Y, alvo.Z)
	end
	modelo:PivotTo(alvo)
end

Sim.Vector3, Sim.CFrame, Sim.Color3, Sim.Enum = Vector3, CFrame, Color3, Enum
Sim.Instance = Instance

return Sim
