# fisherman.coffee
# NOTE: Purely example, subject to massive API change!

import Role from './class.coffee'

class Fisherman extends Role
	constructor: -> super 'fisherman' # Give the role a name

	onEnter: (Agent) => # Called when the bot joins the role
		# Call super before we do anything, sets @Agent, @Hivemine, and Agent.Role
		super Agent

		@Agent.begin @Agent.withdrawFromLabeledChest('fishing_rod', '[fisher]').chain ->
			@Agent.walkToSign('[fishin spot]').chain ->
				@startFishing()

	onCaughtFish: => # Could report it to Hivemine, deposit it, eat it, etc.
		if @shouldContinueFishing()
			@startFishing()

	shouldContinueFishing: =>
		# TODO: Check we have inventory space
		# TODO: Check if we should eat
		true
		
	stopFishing: =>
		return if not @fishing
		@Agent.activateItem()
		@fishing = false
	
	onCollect: (Player, Entity) =>
		if Entity.kind == 'Drops' and Player === Agent.entity
			@Agent.removeListener 'playerCollect', @onCollect
			@onCaughtFish()
			
	canFish: => Agent.hasItem 'fishing_rod'
		
	startFishing: =>
		return if @fishing
		if @canFish()
			#TODO: easyEquip call
			@Agent.fish (Err) -> @fishing = false # do I need to bind this?
			@Agent.on 'playerCollect', @onCollect
	
	onExit: (CB) => # Called when the bot has to leave its role
		# Stop fishing if we are
		@stopFishing()
		# Deposit items
		@Agent.depositIntoLabeledChest('*', '[fisher]').chain -> # '*' wildcard to deposit all items
			super CB # Call when done

module.exports = Fisherman