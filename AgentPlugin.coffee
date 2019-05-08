# AgentPlugin.coffee
# safazi 2019

# Injects mineflayer-navigate and our own methods

Mineflayer = undefined
Navigate = require 'mineflayer-navigate'
Fluture = require 'fluture'
Vec3 = require 'vec3'

Init = (Flayer) ->
	Mineflayer = Flayer
	Navigate = Navigate Flayer
	Inject

Inject = (Agent) ->
	Navigate Agent

	Agent.toBlock = (BlockOrPoint) -> # General function to resolve blocks or points
		if 'object' == typeof BlockOrPoint
			if BlockOrPoint.hasOwnProperty 'type' # It's a block
				return BlockOrPoint
			else if BlockOrPoint.hasOwnProperty 'x' # It's a point
				return Agent.blockAt BlockOrPoint

	Agent.blockAtOffset = (BlockOrPoint, xOrVec3=0, y=0, z=0) ->
		return if 'object' != typeof BlockOrPoint
		Block = Agent.toBlock BlockOrPoint
		if Block
			if 'object' == typeof xOrVec3 # Vec3 instance
				Agent.blockAt Block.position.plus xOrVec3
			else
				Agent.blockAt Block.position.offset xOrVec3, y, z

	Agent.blockUnder = (Input) ->
		return Agent.blockAtOffset Input, 0, -1, 0

	Agent.blockAbove = (Input) ->
		return Agent.blockAtOffset Input, 0, 1, 0

	Agent.blockIsEmpty = (Input) ->
		Input = Agent.toBlock Input
		return if 'object' != typeof Input
		if Input.hasOwnProperty 'type'
			if Input.boundingBox == 'empty'
				if Input.hardness != undefined
					return true if Input.hardness <= 1 # Avoid portal and water/lava blocks
		false

	Agent.getSurroundingBlocks = (Input, IgnoreAir = true) -> # Get the blocks on all 6 sides.
		Input = Agent.toBlock Input
		if Input
			Blocks = [	new Vec3  1, 0, 0
						new Vec3  0, 0, 1
						new Vec3  0, 1, 0 ]
			Result = []
			for S in Sides
				Block = Agent.blockAtOffset Input, Side
				Result.push Block  if Block and Block.type != 0 or not IgnoreAir
				Block = Agent.blockAtOffset Input, Side.scaled -1
				Result.push Block if Block and Block.type != 0 or not IgnoreAir
			Result

	Agent.runTask = (Future) -> # Blindly fork a Future - good really only for testing
		onError = (Data) -> console.error 'runTask error:',Data
		onSucceed = (Data) -> console.error 'runTask done:',Data
		Future.fork onError, onSucceed

	Agent.closestPointOutOf = (Points = [], Position = Agent.entity.position) ->
		closest = Number.MAX_SAFE_INTEGER
		point = undefined
		for P in Points
			distance = Position.distanceTo P
			if distance < closest
				distance = closest
				point = P
		point

module.exports = Init