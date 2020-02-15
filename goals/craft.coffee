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
	class Actions.craft extends Action
		constructor: (@Item, @ExpectedQuantity = 1, @Metadata) -> super Difficulty.Varying, 'craft'
		init: ->
			@Item = @Agent.resolveItem @Item
			return if not @Item
			return if @State.crafting[@Item.id]
			@State.crafting[@Item.id] = true
			@State.test = true
			WithoutTable = @Agent.recipesAll @Item.id, @Metadata
			if WithoutTable.length # Can be done without crafting table
				@Table = undefined
				@Recipe = WithoutTable[0]
				for I in @Recipe.delta
					if I.count < 0 and @State.crafting[I.id]
						return
				for I in @Recipe.delta
					if I.count < 0
						console.log 'i need',-1*I.count,@Agent.resolveItem(I.id).name
						Needed = -1*I.count * Math.ceil @ExpectedQuantity/recipe.result.count
						@require new Needs.item I.id, Needed
			else
				WithTable = @Agent.recipesAll @Item.id, @Metadata, true
				if WithTable.length
					console.log '-- table required to craft',@Item.name,'--'
					@Table = true
					@Recipe = WithTable[0]
					for I in @Recipe.delta
						if I.count < 0 and @State.crafting[I.id]
							return
					for I in @Recipe.delta
						if I.count < 0
							console.log 'i need',-1*I.count,@Agent.resolveItem(I.id).name
							Needed = -1*I.count * Math.ceil @ExpectedQuantity/recipe.result.count
							@require new Needs.item I.id, Needed
					@require new Needs.tempBlock 'crafting_table'
					@require new Actions.getNearBlock 'crafting_table'
				else @Recipe = false
		execute: ->
			return Future.reject 'craft: cant craft this' if not @Recipe
			Fluent new Future (Reject, Resolve) =>
				T = @Agent.findBlock # TODO: USE THE STATE ?
					point: @Agent.entity.position
					matching: @Agent.resolveItem('crafting_table').id
					maxDistance: 2
				if @Table
					if not T
						Reject 'craft: failed to get a table'
						return ->
				delete @State.crafting[@Item.id]
				@Agent.craft @Recipe, @Quantity, T, (err) =>
					if err
						Reject err
					else
						setTimeout Resolve, 3000
				->


###

+ craft 'diamond_sword'
	- needs.block 'crafting_table'
		+ actions.findBlock 'crafting_table'
		+ craft 'crafting_table'
			- source 'planks'
				+ search 'planks'
				+ craft 'planks'
	- needitem 'diamond', 3

###