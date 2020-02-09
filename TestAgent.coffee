# TestAgent.coffee
# Test Hivemine agents

Flayer = require 'mineflayer'
Future = require 'fluture'
AgentPlugin = (require './AgentPlugin')(Flayer)

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
		console.log 'health', Agent.health, Agent.isAlive
		Agent.emit "spawn"

err=(t)->console.error 'error:',t

Hivemine = require './Hivemine.coffee'

Agent.once 'spawn', ->

	console.log 'Agent spawned'
	
	BigSequence = Agent.chainable.say('Starting big task')
		.and Agent.chainable.say('done')

	Agent.begin BigSequence