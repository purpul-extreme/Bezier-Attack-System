local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage.Modules

local RemoteEvents = ReplicatedStorage.RemoteEvents
local Attack = RemoteEvents.Attack

local Configuration = require(Modules.Configuration)
local Effects = require(Modules.Effects)

local Bezier = require("@self/Bezier")

local Debounces = {}

local BLAST_RAIDUS = 14
local BLAST_DAMAGE = 25

local PROJECTILES = 4
local COOLDOWN = 3

local function OnAttackServerEvent(player: Player, baseEndPosition: Vector3)
	if (typeof(baseEndPosition) ~= "Vector3") or (baseEndPosition ~= baseEndPosition) then return end
	
	if Debounces[player] then return end
	Debounces[player] = task.delay(COOLDOWN, function()
		Debounces[player] = nil
	end)
	
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not (humanoid) or (humanoid.Health == 0) then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	local startCFrame = humanoidRootPart.CFrame	
	
	local paths, distances = {}, {}
	
	for index = 1, PROJECTILES do
		local endPosition, projectileCreationDelay = baseEndPosition, 0
		if index > 1 then
			endPosition = Bezier.GetOffsetEndPosition(baseEndPosition)
			projectileCreationDelay = (index - 1) * Configuration.PROJECTILE_CREATION_DELAY
		end
		
		local distance = (endPosition - startCFrame.Position).Magnitude
		local distanceToNodes = math.max(math.round(distance * 0.35), 8)
		
		local controlCFrame = Bezier.GetOffsetControlCFrame(startCFrame, endPosition, distance)
		local path = Bezier.CreateBezierPath(distanceToNodes, startCFrame.Position, controlCFrame.Position, endPosition)
		
		table.insert(paths, path)
		table.insert(distances, distance)
		
		local timeToExplode = distance / Configuration.PROJECTILE_VELOCITY
		task.delay(timeToExplode + projectileCreationDelay, function()
			local parts = workspace:GetPartBoundsInRadius(endPosition, BLAST_RAIDUS)
			local exclude = {}
			
			for _, part in parts do
				local excluded = table.find(exclude, part.Parent)
				if excluded then continue end
				
				local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					humanoid.Health -= BLAST_DAMAGE
					table.insert(exclude, part.Parent)
				end
			end
		end)
	end
	
	local sendTime = workspace:GetServerTimeNow()
	Attack:FireAllClients(paths, distances, sendTime)
end

local function OnPlayerRemoving(player: Player)
	local debounce = Debounces[player]
	if debounce then
		task.cancel(debounce)
	end
	
	Debounces[player] = nil
end

Attack.OnServerEvent:Connect(OnAttackServerEvent)
Players.PlayerRemoving:Connect(OnPlayerRemoving)
