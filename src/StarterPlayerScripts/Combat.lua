local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage.Modules

local Configuration = require(Modules.Configuration)
local Effects = require(Modules.Effects)

local RemoteEvents = ReplicatedStorage.RemoteEvents
local Attack = RemoteEvents.Attack

local Map = workspace.Map
local Camera = workspace.CurrentCamera

local AverageFrameTime = 0

local function GetAverageFrameTime()
	local accumulatedFrameTime = 0
	local frameTimes = {}
	
	for index = 1, 60 do
		local frameTime = RunService.PreRender:Wait()
		table.insert(frameTimes, frameTime)
	end
	
	for _, frameTime in frameTimes do
		accumulatedFrameTime += frameTime
	end
	
	local averageFrameTime = accumulatedFrameTime / #frameTimes
	return averageFrameTime
end

local function OnAttackClientEvent(paths: {{Vector3}}, distances: {number}, sendTime: number)
	local receiveTime = workspace:GetServerTimeNow()
	local latency = receiveTime - sendTime
	
	for index, path in paths do
		local projectileCreationDelay = 0
		if index > 1 then
			projectileCreationDelay = (index - 1) * Configuration.PROJECTILE_CREATION_DELAY
		end
		
		task.delay(projectileCreationDelay, Effects.CreateProjectile, path, distances[index], latency, AverageFrameTime)
	end
end

local function OnInputBegan(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local mouseLocation = UserInputService:GetMouseLocation()
		local unitRay = Camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
		
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = {Map}
		
		local fullDirection = unitRay.Direction * 1e6
		
		local raycastResult = workspace:Raycast(unitRay.Origin, fullDirection, raycastParams)
		if raycastResult then
			Attack:FireServer(raycastResult.Position)
		end
	end
end

task.spawn(function()
	while true do
		AverageFrameTime = GetAverageFrameTime()
	end
end)

Attack.OnClientEvent:Connect(OnAttackClientEvent)
UserInputService.InputBegan:Connect(OnInputBegan)
