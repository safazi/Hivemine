# AgentPlugin.coffee
# safazi 2019

# Injects mineflayer-navigate and our own methods

Mineflayer = undefined
Data = undefined

Navigate = require 'mineflayer-navigate'
Future = require 'fluture'
Fluenture = require 'fluenture'
Fluent = Fluenture.fluent
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

	Agent.toBlock = (BlockOrPoint) ->
		if 'object' == typeof BlockOrPoint
			if BlockOrPoint.hasOwnProperty 'type'
				return BlockOrPoint
			else if BlockOrPoint.hasOwnProperty 'x'
				return Agent.blockAt BlockOrPoint

	Agent.toPosition = (BlockOrPoint) -> Agent.toBlock(BlockOrPoint).position

	Agent.blockAtOffset = (BlockOrPoint, xOrVec3=0, y=0, z=0) ->
		Block = Agent.toBlock BlockOrPoint
		if Block
			if 'object' == typeof xOrVec3
				Agent.blockAt Block.position.plus xOrVec3
			else
				Agent.blockAt Block.position.offset xOrVec3, y, z

	Agent.blockUnder = (Input) -> Agent.blockAtOffset Input, 0, -1, 0

	Agent.blockAbove = (Input) -> Agent.blockAtOffset Input, 0, 1, 0

	Agent.blockIsEmpty = (Input) ->
		Input = Agent.toBlock Input
		if Input
			if Input.boundingBox == 'empty'
				if Input.hardness != undefined
					return true if Input.hardness <= 1 # Avoid portal and water/lava blocks

	Agent.getSurroundingBlocks = (Input, IgnoreAir = true) -> # Get the blocks on all 6 sides.
		Sides = [	new Vec3  1, 0, 0
					new Vec3  0, 0, 1
					new Vec3  0, 1, 0 ]
		Result = []
		for Side in Sides
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
		CanStand = Agent.blockUnder(Input).boundingBox == 'block' # X.name != 'chest' if SolidGround
		DontStandOnChests = Agent.blockUnder(Input).name != 'chest'
		FeetSpace = Agent.blockIsEmpty Input
		HeadSpace = Agent.blockIsEmpty Agent.blockAbove Input
		SolidGround and FeetSpace and HeadSpace and CanStand and DontStandOnChests

	# See if you could theoretically stand on top of Input
	Agent.isStandableGround = (Input) -> Agent.isStandableAir Agent.blockAbove Input

	# Go down until we can stand
	Agent.findGround = (Input) ->
		return Agent.blockAbove Input if Agent.isStandableGround Input
		Iter = 0
		while not Agent.isStandableAir Input
			Iter++
			Input = Agent.blockUnder Input
			return if not Input or Input.position.y <= 0 or Iter > 10
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
			return Agent.placeBlock Result.block, Result.direction, (err) ->
				if err
					cb false
				else cb true 
		cb false

	# turn input into an item
	Agent.resolveItem = (Input) ->
		Type = typeof Input
		if Type == 'object' # Could already be an Item
			if Input.hasOwnProperty 'id'
				return Input
			if Input.hasOwnProperty 'type'
				return Input
		else if Type == 'number' # ID
			X = Data.blocks[Input]
			return X if X 
			X = Data.items[Input]
			return X
		else if Type == 'string' # Name or ID
			N = new Number Input
			if Number.isInteger(N)
				return Agent.resolveItem N
			else
				X = Data.itemsByName[Input]
				return X if X
				X = Data.blocksByName[Input]
				return X

	Agent.hasItem = (Input, Quantity = 1) ->
		Item = Agent.resolveItem Input
		if Item
			for I in Agent.inventory.items()
				if I.name == Item.name
					Quantity -= I.count
			return Quantity <= 0

	Agent.countItems = (Input) ->
		Item = Agent.resolveItem Input
		if Item
			count = 0
			for I in Agent.inventory.items()
				if I.name == Item.name
					count += I.count
			return count
		return -1
	# equip an item, uses resolveItem
	Agent.easyEquip = (ResolvesToItem, dest = 'hand', cb) ->
		# Note: may not actually equip anything, use callback!
		Item = Agent.resolveItem ResolvesToItem
		if Item
			Agent.equip Item.id, dest, cb 

	# find the block behind a sign
	Agent.blockBehindSign = (Input) ->
		Input = Agent.toBlock Input
		if Input and Input.metadata
			Dir = {
				2: (new Vec3  0, 0, 1)
				3: (new Vec3  0, 0,-1)
				4: (new Vec3  1, 0, 0)
				5: (new Vec3 -1, 0, 0)
			}[Input.metadata]
			return Agent.blockAtOffset Input, Dir if Dir
	
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
			Sign = Agent.findSign Label, Range
			if Sign
				C = Agent.blockBehindSign Sign
				if C
					return C if C.type == 54 or C.type == 130 or C.type == 146	
				else
					return Agent.closestChestToBlock Sign, Range

	Agent.canOpenChest = (Chest) ->
		if Chest
			Open = Agent.entity.position.distanceTo(Chest.position) < 4.5 
			return Open and Agent.canSeeBlock Chest

	Agent.chainable = {}
	Agent.chainable.walkPath = (Path) ->
		Fluent new Future (Reject, Resolve) ->
			Walking = false
			if Path
				Walking = true
				Agent.navigate.walk Path, (Status) ->
					Walking = false
					switch Status
						when 'arrived', 'obstructed'
							Resolve Status
						when 'interrupted'
							Reject Status
			else Reject 'walkPath: bad argument #1'
			-> Agent.navigate.stop() if Walking

	Agent.chainable.nav = (Position, Retry = 0) ->
		Fluent new Future (Reject, Resolve) ->
			if Position
				Result = Agent.navigate.findPathSync Agent.toPosition(Position), tooFarThreshold: 150
				switch Result.status
					when 'success'
						return Agent.chainable.walkPath(Result.path).fork Reject, Resolve
					when 'tooFar'
						if Retry > 0
							return Agent.chainable.walkPath(Result.path).and Agent.chainable.nav Position, Retry - 1
								.fork Reject, Resolve
						else Reject 'nav: tooFar'
					else Reject 'nav: noPath'

			else Reject 'nav: bad argument #1'
			-> 

	Agent.chainable.say = (Message) ->
		Fluent new Future (Reject, Resolve) ->
			Agent.chat Message
			setTimeout Resolve, 250
			->
	
	Agent.chainable.findItem = (Open, Target) ->
		Fluent new Future (Reject, Resolve) ->
			Target = Agent.resolveItem Target
			if Target
				for Item in Open.items()
					if Item.name == Target.name
						Resolve Item
						return ->
				Reject 'findItem: not found'
			else Reject 'findItem: invalid item'
			->
	Agent.chainable.withdrawItem = (Open, Item, Amount = 1, Metadata) ->
		Fluent new Future (Reject, Resolve) ->
			Open.withdraw Item.type, Metadata, Amount, (err) ->
				if not err
					setTimeout Resolve, 250
				else Reject 'withdrawItem: '+err
			->

	Agent.chainable.getNear = (Position, Retry = 0) ->
		Fluent new Future (Reject, Resolve) ->
			if Position
				Near = Agent.findStandableGroundPosition Position
				if Near
					Agent.chainable.nav Near, Retry
						.fork Reject, Resolve
				else Reject 'getNear: no good position'
			else Reject 'getNear: bad argument #1'
			->

	Agent.chainable.closeChest = (Chest) ->			# Assume we can open it, do not bother checking.
		Fluent new Future (Reject, Resolve) ->
			if Chest
				if Chest.window
					Chest.close()
					Resolve()
				else Reject 'closeChest: no window'
			else Reject 'closeChest: bad argument #1'
			->

	Agent.chainable.openChest = (Chest) ->			# Assume we can open it, do not bother checking.
		Fluent new Future (Reject, Resolve) ->
			if Chest
				Open = Agent.openChest Chest
				if Open
					Open.once 'open', -> Resolve Open
				else Reject 'openChest: no window'
			else Reject 'openChest: bad argument #1'
			->

	Agent.chainable.openLabeledChest = (Label, Retry = 0) -> # Label -> Chest
		Fluent new Future (Reject, Resolve) ->
			if Label
				Chest = Agent.findLabeledChest Label # Eventually have this done by hivemine
				if Agent.canOpenChest Chest
					return Agent.chainable.openChest Chest
						.fork Reject, Resolve
				else if Chest
					return Agent.chainable.getNear Chest, Retry
						.and Agent.chainable.openLabeledChest Chest, Retry - 1
						.fork Reject, Resolve
				else Reject 'openLabeledChest: no chest'
			else Reject 'openLabeledChest: bad argument #1'
			->

	Agent.walkToSign = (Text) -> # findSign call, navTo call
		Fluent new Future (Reject, Resolve) ->
			if Text
				Sign = Agent.findSign Text
				if Sign
					Ground = Agent.findGround Sign
					if Ground
						return Agent.navTo(Ground.position).fork Reject, Resolve
					else
						Reject 'walkToSign.ground'
						return ->
				Reject 'walkToSign.sign'
				return -> 
			Reject 'walkToSign.args'
			return ->

	Agent.begin = (F) ->
		if Agent.Free
			Agent.Free = false
			taskCompleted = ->
				Agent.Free = true
			taskFailed = (code) ->
				# TODO: tell Hivemine
				console.error code
				Agent.Free = true
			return F.fork taskFailed, taskCompleted
		# TODO: Queue up tasks?

	Agent.changeRole = (NewRole) -> Agent.Hivemine.requestRoleChange Agent, NewRole if Agent.Hivemine
	
	Agent.hivemineAssignedRole = (Role) -> Role.onEnter Agent
	Agent.hivemineInit = (Hivemine) ->
		Agent.Hivemine = Hivemine
		Agent.Free = true

module.exports = Init