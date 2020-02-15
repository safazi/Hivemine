# TestAgent.coffee
# Test Hivemine agents

Flayer = require 'mineflayer'
Future = require 'fluture'
AgentPlugin = (require './Agent')(Flayer)

Account = require './account.json'

fs = require 'fs'

###

Agent = Flayer.createBot {
	version: '1.12.2'
	host: Account.host
	username: Account.username
	password: Account.password
}

###
Agent = Flayer.createBot {
	host: 'localhost' 
	username: 'hivemine_agent'
}

AgentPlugin Agent

Agent.once 'login', ->
	console.log 'Agent logged into server running',Agent.version

Agent.once "health", -> # fix for the mineflayer bug
	if Agent.health > 0 and Agent.isAlive
		Agent.emit "spawn"

err=(t)->console.error 'error:',t

Hivemine = require './Hivemine.coffee'

Agent.once 'spawn', ->
	console.log 'Agent spawned'
	###BigSequence = Agent.chainable.say 'im going to open my box now'
		.and Agent.chainable.openLabeledChest '[chest]'
			.chain (Open) ->
				Agent.chainable.findItem Open, 'fish'
					.chain (Item) -> Agent.chainable.withdrawItem Open, Item
						.and Agent.chainable.say 'got a fish'
					.chainRej -> Agent.chainable.say 'cant find a fish sorry'
					.lastly Agent.chainable.closeChest Open
						.and Agent.chainable.say 'closing the chest now'
		.and Agent.chainable.say 'ok im done'
	###
	Agent.hivemineInit Hivemine

	#Agent.begin BigSequence

	Foreman = require './Foreman.coffee'
	Manager = new Foreman.Manager Agent

	Planner = require './goals'
	
	Manager.schedule new Planner.Actions.craft 'golden_apple' # crafting_table

	Manager.on 'fail', ->
		Agent.quit()
		setTimeout process.exit, 500