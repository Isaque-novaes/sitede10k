--[[
	Efeitos no jogador:
	  - troca o texto do "segure E" para Vender (robô seu) ou Roubar (dos outros)
	  - empurrão quando você leva um tapa
	  - cores animadas dos robôs Arco-íris
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotos = ReplicatedStorage:WaitForChild("Remotos")
local jogador = Players.LocalPlayer

-- Texto do botão de interação
ProximityPromptService.PromptShown:Connect(function(prompt)
	if not prompt:GetAttribute("Robo") then
		return
	end
	local donoId = prompt:GetAttribute("DonoId")
	if donoId == nil then
		prompt.ActionText = "Comprar"
	elseif donoId == jogador.UserId then
		prompt.ActionText = "Vender por " .. tostring(prompt:GetAttribute("Venda") or "")
	else
		prompt.ActionText = "Roubar"
	end
end)

-- Empurrão do tapa
Remotos:WaitForChild("Empurrao").OnClientEvent:Connect(function(velocidade)
	local personagem = jogador.Character
	local humanoid = personagem and personagem:FindFirstChildOfClass("Humanoid")
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not humanoid or not raiz or typeof(velocidade) ~= "Vector3" then
		return
	end
	humanoid.PlatformStand = true
	raiz.AssemblyLinearVelocity = velocidade + Vector3.new(0, 35, 0)
	task.delay(0.7, function()
		if humanoid.Parent then
			humanoid.PlatformStand = false
		end
	end)
end)

-- Robôs Arco-íris
local partesArcoiris = {}
local function adicionar(parte)
	partesArcoiris[parte] = true
end
local function remover(parte)
	partesArcoiris[parte] = nil
end
for _, parte in ipairs(CollectionService:GetTagged("Arcoiris")) do
	adicionar(parte)
end
CollectionService:GetInstanceAddedSignal("Arcoiris"):Connect(adicionar)
CollectionService:GetInstanceRemovedSignal("Arcoiris"):Connect(remover)

RunService.RenderStepped:Connect(function()
	local matiz = (os.clock() * 0.25) % 1
	local cor = Color3.fromHSV(matiz, 0.75, 1)
	for parte in pairs(partesArcoiris) do
		parte.Color = cor
	end
end)
