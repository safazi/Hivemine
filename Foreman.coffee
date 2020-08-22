# Foreman.coffee
# SFZILabs 2020

Future = require 'fluture'
Fluent = require('fluenture').fluent

Priorities =
	Minor: 1
	Major: 2
	Critical: 3

Difficulty =
	Free: 0
	Easy: 1
	Varying: 2
	Hard: 3

class Prerequisite
	isPrereq: true
	constructor: (@Priority = Priorities.Minor, @Name) ->
	requestAgent: (@NeedAgent = true) ->
	suggest: -> [] # Array of prerequisites and actions

class Action
	constructor: (@Difficulty = Difficulty.Varying, @Name) ->
		@Requirements = []
		@State = {}
	require: (P) ->
		P.Parent = @
		@Requirements.push P
	init: -> # Add requirements sync
	setState: (@State = {}) ->
	setAgent: (@Agent) ->
	getDepth: ->
		if @Parent
			return 1 + @Parent.getDepth()
		return 0	
	choose: (Actions) ->
		Lowest = undefined
		Choice = undefined
		for A in Actions
			if Lowest != undefined
				if A.Difficulty < Lowest
					Lowest = A.Difficulty
					Choice = A
			else
				Choice = A
				Lowest = A.Difficulty
		Choice
	resolve: -> # Run requirements
		Fluent new Future (Reject, Resolve) =>
			Index = -1
			Current = ->
			Next = =>
				Current = ->
				Index++
				P = @Requirements[Index]
				if P # 
					if P.isPrereq
						P.Agent = @Agent if P.NeedAgent
						A = P.suggest().sort (a, b) -> a.Difficulty - b.Difficulty
						# Try all prerequisites
						PotentialActions = Fluent Future.reject()
						
						if not A.length
							Reject 'no solution for '+P.Name
						else #A.start(@State).fork Reject, Next
							console.log 'trying solutions of',P.Name,'for',@Name
							while A.length > 0
								X = A.shift()
								if X.isPrereq # utils any
									a = 1
								console.log '   '+X.Name
								PotentialActions = PotentialActions.alt X.start @State, @Agent
							PotentialActions = PotentialActions.alt Future.reject 'all solutions failed for '+P.Name
							Current = PotentialActions.fork Reject, Next
					else # action, init, 
						console.log 'running',P.Name
						Current = P.start(@State, @Agent).fork Reject, Next
				else Resolve() # Completed all
			Next()
			->
				Next = ->
				Current()
				
	execute: -> Fluent new Future.resolve()
	start: (S, A) ->
		@setState S
		@setAgent A 
		@init()
		@resolve().and @execute()

###

ACTION:
	Can have prerequisites
	Can require other actions
	All children (actions and prereqs) must be satisfied before 'execute' is called

	Flow:
		Run method 'init', all our prereqs and actions are added
		Run method 'start', this returns a monadic future
		Fork the future
			Future runs method 'resolve', this calls init and then resolve on children.
			Run our method 'execute' on future success, or reject with the last error
		We are done, and our parent action (if any) continues

PREREQUISITE:
	Can only suggest actions
	Suggested actions can fail

###

EventEmitter = require 'events'

class Manager extends EventEmitter
	constructor: (@Agent) ->
		super()
		@State = {
			Managed: true
			crafting: {}
		}
	schedule: (Action) ->
		Done = =>
			@emit 'done'
			console.log 'Success'
		Fail = (S) =>
			@emit 'fail'
			console.error 'Failure:',S.message
		Action.start(@State, @Agent).fork Fail, Done

module.exports = {
	Manager,
	Prerequisite,
	Action,
	Priorities,
	Difficulty
}