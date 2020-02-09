# fisherman.coffee
# NOTE: Purely example, subject to massive API change!

Role = require './class.coffee'

Future = require 'fluture'
Fluenture = require 'fluenture'
Fluent = Fluenture.fluent

class Fisherman extends Role
	constructor: -> super 'fisherman' # Give the role a name

	onEnter: (Agent) => # Called when the bot joins the role
		# Call super before we do anything, sets @Agent, @Hivemine, and Agent.Role
		super Agent

		start = Fluent new Future (_, Resolve) ->
			Resolve()
			->
		if not @canFish()
			console.log 'need to get a rod'
			start = @Agent.withdrawFromLabeledChest('fishing_rod', '[fisher]')
		start = start.chain =>
			console.log 'need to walk'
			@Agent.walkToSign('[fishin spot]').map =>
				console.log 'now we can fish'
				@startFishing()

		@Agent.begin start

	onCaughtFish: => # Could report it to Hivemine, deposit it, eat it, etc.
		@fishing = false
		@startFishing() if @shouldContinueFishing()

	shouldContinueFishing: =>
		# TODO: Check we have inventory space
		# TODO: Check if we should eat
		true
		
	stopFishing: =>
		return if not @fishing
		@Agent.activateItem()
		@fishing = false
	
	onCollect: (Player, Entity) =>
		if Entity.kind == 'Drops' and Player == @Agent.entity
			@Agent.removeListener 'playerCollect', @onCollect
			# @onCaughtFish()
			
	canFish: => @Agent.hasItem 'fishing_rod'
		
	startFishing: =>
		return if @fishing
		if @canFish()
			#TODO: easyEquip call
			Water = @Agent.findBlock
				point: @Agent.entity.position
				matching: 9
				maxDistance: 10
			if Water
				@Agent.lookAt Water.position.offset(.5,0,.5), true, =>
					@Agent.easyEquip 'fishing_rod', undefined, =>
						@Agent.fish (Err) =>
							@fishing = false # do I need to bind this?
							@startFishing()
						@Agent.on 'playerCollect', @onCollect
			else console.error 'no water'
	
	onExit: (CB) -> # Called when the bot has to leave its role
		# Stop fishing if we are
		@stopFishing()
		# Deposit items
		@Agent.depositIntoLabeledChest('*', '[fisher]').chain => # '*' wildcard to deposit all items
			super CB # Call when done

module.exports = Fisherman