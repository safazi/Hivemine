# AgentPlugin.coffee
# safazi 2019

# Injects mineflayer-navigate and our own methods

Mineflayer = undefined
Data = undefined

Navigate = require 'mineflayer-navigate'
Fluture = require 'fluture'
Vec3 = require 'vec3'

Init = (Flayer) ->
	Mineflayer = Flayer
	Navigate = Navigate Flayer
	Inject

# All methods starting with 'hivemine' are intended to be called by the Hivemine handler

Inject = (Agent) ->
	Navigate Agent # Inject Navigate

	if Agent.version
		Data = (require 'minecraft-data') Agent.version
	else
		Agent.once 'inject_allowed', ->
			Data = (require 'minecraft-data') Agent.version


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

	Agent.closestPointOutOf = (Points = [], Position = Agent.entity.position) ->
		closest = Number.MAX_SAFE_INTEGER
		point = undefined
		for P in Points
			distance = Position.distanceTo P
			if distance < closest
				distance = closest
				point = P
		point

	# See if your feet could theoretically be at Input
	Agent.isStandableAir = (Input) ->
		SolidGround = not Agent.blockIsEmpty Agent.blockUnder Input
		SolidGround = Agent.blockUnder(Input).name != 'chest' if SolidGround
		FeetSpace = Agent.blockIsEmpty Input
		HeadSpace = Agent.blockIsEmpty Agent.blockAbove Input
		SolidGround and FeetSpace and HeadSpace

	# See if you could theoretically stand on top of Input
	Agent.isStandableGround = (Input) -> Agent.isStandableAir Agent.blockAbove

	# Go down until we can stand
	Agent.findGround = (Input) ->
		return Agent.blockAbove Input if Agent.isStandableGround Input
		Iter = 0
		while not Agent.isStandableAir Input
			Iter++
			Input = Agent.blockUnder Input
			return if not Block or Block.position.y <= 0 or Iter > 10
		Input

	Agent.findStandableGroundPosition = (Input) ->
		# Todo: Maybe continue outwards?
		Ground = Agent.findGround Input
		return Ground.position if Ground
		Agent.groundAdjacentTo Input

	# Returns a standable point, 1 block above the ground (feet pos)
	Agent.groundAdjacentTo = (Input) ->
		Block = Agent.toBlock Input
		Sides = [	(new Vec3  1, 0, 0)
					(new Vec3 -1, 0, 0)
					(new Vec3  0, 0, 1)
					(new Vec3  0, 0,-1)   ]
		standable = []
		for S in Sides
			B = Agent.blockAt (Block.position.plus S)
			continue if not B
			if Agent.blockIsEmpty B
				if Agent.isStandableAir B
					standable.push B.position
				else
					Ground = Agent.findGround B
					if Ground
						continue if Ground.position.distanceTo B.position > 4
						standable.push Ground.position
			else if Agent.isStandableGround B
				standable.push B.position.offset 0,1,0
					
		return Agent.closestPointOutOf standable if standable.length

	# helper function for easyPlace
	Agent.findAdjacentBlockAndDirection = (Input) ->
		Input = Agent.toBlock Input
		Adjacent = Agent.getSurroundingBlocks Input
		if Adjacent.length
			return
				block: Adjacent[0]
				direction: Input.position.minus Adjacent[0].position

	# place a block without a reference block or direction
	Agent.easyPlace = (Input, cb) ->
		Result = Agent.findAdjacentBlockAndDirection Input
		if Result
			Agent.placeBlock Result.block, Result.direction, cb
			return true
		else if cb
			cb 'none'

	# turn input into an item
	Agent.resolveItem = (Input, Source) ->
		Type = typeof Input
		if Type == 'object' # Could already be an Item
			return Input if Input.hasOwnProperty 'type'
		else if Type == 'number' # ID
			return Data.items[Input]
		else if Type == 'string' # Name or ID
			N = parseInt Input
			if N != 0 and not N # Name
				return Data.itemsByName[Input]
			else # ID
				return Data.items[N]

	# equip an item, uses resolveItem
	Agent.easyEquip = (ResolvesToItem, dest = "hand", cb) ->
		# Note: may not actually equip anything, use callback!
		Item = Agent.resolveItem ResolvesToItem
		Agent.equip Item.type, dest, cb if Item

	# find the block behind a sign
	Agent.blockBehindSign = (Input) ->
		Input = Agent.toBlock Input
		if Input and Input.metadata
			Dir = {
				2: (new Vec3  0, 0, 1)
				3: (new Vec3  0, 0,-1)
				4: (new Vec3  1, 0, 0)
				5: (new Vec3 -1, 0, 0)
			}
			A = Dir[Input.metadata]
			if A
				return Agent.blockAtOffset Input, Dir

	# find a sign with specific first line of text
	Agent.findSign = (Text, Dist = 64) ->
		# TODO: consider caching signs
		if Text
			isMatch = (Block) ->
				if Block.type == 63 or Block.type == 68
					if Block.blockEntity
						T1 = Block.blockEntity.Text1
						if T1 and T1.extra
							return Text == T1.extra[0].text
				false

			Agent.findBlock
				point: Agent.entity.position,
				matching: isMatch,
				maxDistance: Dist,

	# find the closest chest to a position
	Agent.closestChestTo = (Position, Range = 16, Trapped = false, Ender = false) ->
			isMatch = (Block) -> Block.type == 54 or (Block.type == 130 and Ender) or (Block.type == 146 and Trapped)

			Agent.findBlock
				point: Position or Agent.entity.position,
				matching: isMatch,
				maxDistance: Range,

	# find the closest chest to a block
	Agent.closestChestToBlock = (Block, R, T, E) -> Agent.closestChestTo Block.position, R, T, E
	
	# find a chest behind a sign
	Agent.findLabeledChest = (Label, Range = 64) ->
		if Label
			Sign = f.findSign Label, Range
			if Sign
				C = Agent.blockBehindSign Sign
				if C
					return C if C.type == 54 or C.type == 130 or C.type == 146	
				else
					return Agent.closestChestToBlock Sign, Range

	Agent.navTo = (Position, Retry) ->
		new Future (Reject, Resolve) ->
			return Reject 'navTo.args' if not Position
			Result = Agent.navigate.findPathSync Position,
				tooFarThreshold: 150
			Path = Result.path
			Walking = false
			switch Result.status
				when 'success'
					Walking = true
					Agent.navigate.walk Path, (status) ->
						Walking = false
						if status == 'arrived'
							Resolve status
						else # TODO: deal with interrupted
							Reject status
				when 'tooFar'
					if Retry
						Walking = true
						Agent.navigate.walk Path, (status) ->
							Walking = false
							if status == 'arrived'
								nextNav = Agent.navTo Position, Retry
								# Start the next navTo
								nextNav.fork Reject, Resolve
							else
								Reject status
					else
						Reject 'navTo.far'
				else
					Reject 'navTo.noPath'

			->
				Agent.navigate.stop() if Walking

	Agent.canOpenChest = (Chest) ->
		if Chest
			See = Agent.canSeeBlock Chest
			Open = Agent.entity.position.distanceTo(Chest.position) < 4.5 
			return See and Open

	# cant use the name openChest
	Agent.chainableOpenChest = (Chest) ->
		new Future (Reject, Resolve) ->
			Reject 'chainableOpenChest.args' if not Chest
			Window = Agent.openChest Chest
			if Window != undefined
				Window.once 'open', ->
					Resolve Window
			else
				Reject 'chainableOpenChest.window'

	# cant use the name withdraw
	Agent.chainableChestWithdrawalItem = (Window, ResolvesToItem) -> 
		new Future (Reject, Resolve) ->
			I = Window.items()
			Target = Agent.resolveItem ResolvesToItem
			if Target
				for Item in I
					if Item.name == Target.name
						Window.withdraw Item.type, undefined, undefined, (err) ->
							return Reject 'chainableChestWithdrawalItem.err{' + err + '}' if err
							return Resolve Item
				Reject 'chainableChestWithdrawalItem.none'

	# withdraw a single item from a chest
	# walk to it if needed
	Agent.withdrawFromLabeledChest = (ResolvesToItem, ChestLabel) -> # sync findLabeledChest call, navTo call, withdraw call
		# TODO: support multiple items
		new Future (Reject, Resolve) ->
			return Reject 'withdrawFromLabeledChest.args' if not ChestLabel and ResolvesToItem != undefined
			Chest = Agent.findLabeledChest ChestLabel
			if Agent.canOpenChest Chest
				# No need to navigate
				openAndWithdraw = Agent.chainableOpenChest(Chest).chain (Window) ->
					Agent.chainableChestWithdrawalItem(Window, ResolvesToItem)
				openAndWithdraw.fork Reject, Resolve
			else
				Pos = Agent.findStandableGroundPosition Chest
				if Pos
					# navigate
					walk = Agent.navTo(Pos).chain(->
						Agent.chainableOpenChest(Chest)
					).chain (Window) ->
						Agent.chainableChestWithdrawalItem(Window, ResolvesToItem)
					walk.fork Reject, Resolve

	Agent.walkToSign = (Text) -> # findSign call, navTo call
		new Future (Reject, Resolve) ->
			if Text
				Sign = Agent.findSign Text
				if Sign
					Ground = Agent.findGround Sign
					return Agent.navTo(Ground.position).fork Reject, Resolve if Ground
				return Reject 'walkToSign.sign'
			Reject 'walkToSign.args'

	Agent.begin = (Future) ->
		if Agent.Free
			taskCompleted = ->
				Agent.Free = true
			taskFailed = (code) ->
				# TODO: tell Hivemine
				Agent.Free = true
			Future.fork taskFailed, taskCompleted
		# TODO: Queue up tasks?

	Agent.changeRole = (NewRole) -> Agent.Hivemine.requestRoleChange Agent, NewRole if Agent.Hivemine
	
	Agent.hivemineAssignedRole = (Role) -> Role.onEnter Agent
	Agent.hivemineInit = (Hivemine) ->
		Agent.Hivemine = Hivemine
		Agent.Free = true

module.exports = Init