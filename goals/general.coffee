Future = require 'fluture'
Fluent = require('fluenture').fluent

Foreman = require '../foreman.coffee'
Action = Foreman.Action
Need = Foreman.Prerequisite
Difficulty = Foreman.Difficulty
Priority = Foreman.Priority

Priorities =
	Minor: 1
	Major: 2
	Critical: 3

Difficulty =
	Free: 0
	Easy: 1
	Varying: 2
	Hard: 3

module.exports = (Actions, Needs) ->
	class Actions.item extends Action
		constructor: (@Item, @Quantity) -> super Difficulty.Free, 'haveitem'
		init: ->
			@Item = @Agent.resolveItem @Item
		execute: ->
			return Fluent Future.reject 'item: invalid' if not @Item
			Fluent new Future (Reject, Resolve) =>
				X = @Agent.hasItem @Item, @Quantity
				if X
					Resolve()
				else Reject 'item: not found'
				->

	class Actions.findBlock extends Action
		constructor: (@Block, @SearchDistance = 16) -> super Difficulty.Easy, 'findblock'
		init: -> @Block = @Agent.resolveItem @Block			
		execute: ->
			return Future.reject 'block: invalid block' if not @Block
			@Block = @Agent.findBlock
				point: @Agent.entity.position
				matching: @Block.id
				maxDistance: @SearchDistance
			return Future.resolve @Block if @Block
			Future.reject 'block: couldnt find'

	class Actions.findTree extends Action
		constructor: -> super Difficulty.Varying, 'findTree'
		execute: ->

	class Actions.chopTree extends Action
		constructor: (@MinQuantity, @Metadata) -> super Difficulty.Varying, 'chopTree'
		init: ->
			@require new Needs.findTree()
			@require new Needs.toolFor 'log', @MinQuantity
		execute: -> Fluent Future.reject 'chop: not implemented'

	class Needs.toolFor extends Need
		constructor: (@Block, @Quantity) ->
			super Priorities.Minor, 'toolfor'
			@requestAgent()
		suggest: ->
			@Block = @Agent.resolveItem @Block
			return [] if not @Block
			return [] if not @Block.diggable
			if @Block.harvestTools
				toItem = (key) ->
				return Object.keys(@Block.harvestTools).map (itemid) ->
					new Needs.item itemid
			else return [] # todo: check mcdata materials for the material of the block

	class Actions.mine extends Action
		constructor: (@Item, @Quantity) -> super Difficulty.Varying, 'mine'
		init: ->
			@require new Needs.toolFor @Item, @Quantity
			# equip tool
			# move
		execute: ->
			Fluent new Future (Reject, Resolve) ->
				Reject 'mine: not implemented'
				->
			# mine
	class Actions.source extends Action
		constructor: (@Item, @Quantity, @Metadata) -> super Difficulty.Varying, 'sourceitem'
		init: ->
			@Item = @Agent.resolveItem @Item
			return if not @Item
			if @Item.name == 'log' # todo, modularize this too
				@require new Actions.chopTree @Quantity, @Metadata
			else if @Item.name == 'cobblestone'
				
				@require new Actions.mine @Item, @Quantity  
		execute: ->
			if @Item
				return Fluent Future.resolve()
			else return Fluent Future.reject 'could not source item'


	class Needs.item extends Need
		constructor: (@Item, @Quantity, @Metadata, P = Priorities.Minor) -> super P, 'needitem'
		suggest: ->
			[
				new Actions.item @Item, @Quantity, @Metadata
				new Actions.craft @Item, @Quantity, @Metadata
				new Actions.source @Item, @Quantity, @Metadata
			]

	class Actions.placeNearby extends Action
		constructor: (@Block) -> super Difficulty.Easy, 'placenearby'
		init: ->
			@Block = @Agent.resolveItem @Block
			console.log @Block.id, @Block.name
			@require new Needs.item @Block, 1
		execute: ->
			return Fluent Future.reject 'placenearby: invalid block' if not @Block
			Ground = @Agent.groundAdjacentTo @Agent.entity.position
			return Fluent Future.reject 'placenearby: no good position' if not Ground
			Fluent new Future (Reject, Resolve) =>
				Stop = false
				@Agent.easyEquip @Block, 'hand', =>
					return if Stop
					@Agent.easyPlace Ground, (Success) =>
						return if Stop
						if Success
							setTimeout Resolve, 1250
						else Reject()
				-> Stop = true

	class Actions.tempBlock extends Action
		constructor: (@Block, @Actions = []) -> super Difficulty.Varying, 'tempblock'
		init: ->
			@require new Actions.placeNearby @Block
			@require new Actions.all @Actions
		execute: ->
			Fluent new Future (Reject, Resolve) ->
				Resolve() # todo: destroy block?
				->

	class Needs.block extends Need
		constructor: (@Block, @SearchDistance = 16) -> super Priorities.Minor, 'block'
		suggest: ->
			[
				new Actions.findBlock @Block, @SearchDistance
			]

	class Needs.tempBlock extends Need
		constructor: (@Block, @SearchDistance = 16, @Actions = []) -> super Priorities.Minor, 'tempblock'
		suggest: ->
			[
				new Actions.findBlock @Block, @SearchDistance
				new Actions.tempBlock @Block, @Actions
			]

	class Actions.getNearBlock extends Action
		constructor: -> super Difficulty.Varying, 'getnearblock'
		execute: -> Fluent Future.resolve()


		

###

+ craft 'diamond_sword'
	- needblock 'crafting_table'
		+ findblock 'crafting_table'
		+ craft 'crafting_table'
			- source 'planks'
				+ search 'planks'
				+ craft 'planks'
	- needitem 'diamond', 3

###