local RandomNumberGenerator = Random.new()

local Bezier = {}

local X_OFFSET_SCALE = 0.3
local Y_OFFSET_SCALE = 7

local END_RADIUS = 22

function Bezier.Lerp(positionA: Vector3, positionB: Vector3, interpolation: number)
	return positionA + (positionB - positionA) * interpolation
end

function Bezier.QuadraticBezier(interpolation: number, positionA: Vector3, positionB: Vector3, positionC: Vector3)
	local firstResult = Bezier.Lerp(positionA, positionB, interpolation)
	local secondResult = Bezier.Lerp(positionB, positionC, interpolation)
	
	local finalResult = Bezier.Lerp(firstResult, secondResult, interpolation)
	return finalResult
end

function Bezier.GetOffsetEndPosition(baseEndPosition: Vector3)
	local halfEndRadius = END_RADIUS / 2
	
	local randomEndOffsetX = RandomNumberGenerator:NextNumber(-halfEndRadius, halfEndRadius)	
	local randomEndOffsetZ = RandomNumberGenerator:NextNumber(-halfEndRadius, halfEndRadius)
	
	local endPosition = baseEndPosition + Vector3.new(randomEndOffsetX, 0, randomEndOffsetZ)
	return endPosition
end

function Bezier.GetOffsetControlCFrame(startCFrame: CFrame, endPosition: Vector3, distance: number)
	local distanceToOffsetX = distance * X_OFFSET_SCALE
	local distanceToOffsetY = math.log(distance + 1) * Y_OFFSET_SCALE

	local randomControlOffsetX = RandomNumberGenerator:NextInteger(-distanceToOffsetX, distanceToOffsetX)
	local randomControlOffsetY = endPosition.Y + RandomNumberGenerator:NextInteger(distanceToOffsetY / 1.5, distanceToOffsetY)

	local randomControlPoint = RandomNumberGenerator:NextNumber(0, 1)

	local newControlCFrame = startCFrame * CFrame.new(randomControlOffsetX, randomControlOffsetY, -distance * randomControlPoint)
	return newControlCFrame
end

function Bezier.CreateBezierPath(nodes: number, startPosition: Vector3, controlPosition: Vector3, endPosition: Vector3)
	local path = {}
	
	for index = 1, nodes do
		local interpolation = index / nodes
		local position = Bezier.QuadraticBezier(interpolation, startPosition, controlPosition, endPosition)
		
		table.insert(path, position)
	end
	
	return path
end

return Bezier
