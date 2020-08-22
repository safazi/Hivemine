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
	class Action.fail extends Action
		constructor: (@Reason = 'fail: unspecified') -> super Difficulty.Free, 'failure'
		execute: -> Fluent Future.reject @Reason
	
	class Actions.all extends Action
		constructor: (@Block, @Actions = []) -> super Difficulty.Varying, 'all'
		init: -> @require A for A in @Actions
		execute: -> Fluent Future.resolve()

	class Actions.optional extends Action
		constructor: (@Action) -> super Difficulty.Varying, 'all'
		execute: -> Fluent new Future (Reject, Resolve) -> X.start(@Agent, @State).fork Resolve, Resolve