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
	class Actions.quarry extends Action
		constructor: (@CornerA, @CornerB) ->
			super @Difficulty.Hard, 'quarry'
		digOutline: ->
			# first check if we're at bedrock
			Fluent new Future (Reject, Resolve) ->

		init: ->
			@require Needs.toolFor 'iron_ore'
		execute: ->
			Fluent new Future (Reject, Resolve) ->
				next = ->
					layer = @digOutline()
						.and @reinforce()
						.and @dig()
						.and @stair()
					layer.fork Reject, next
				next() 

	class Actions.stripmine extends Action
		constructor: (@Pos, @Dir) ->
			super @Difficulty.Hard, 'stripmine'
		digStep: ->
			Fluent new Future (Reject, Resolve) ->
				setTimeout Reject, 5000
				->
		init: ->
			@require Needs.toolFor 'iron_ore'
		execute: ->
			Fluent new Future (Reject, Resolve) ->
				@Agent.easyEquip 'iron_pickaxe'
				cur = ->
				next = ->
					cur = @digStep().fork Reject, next
				next()
				cur