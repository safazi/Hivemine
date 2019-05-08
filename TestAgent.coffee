# LSD.coffee
# SFZILABS 2019

Flayer = require 'mineflayer'
Future = require 'fluture'
AgentPlugin = (require './AgentPlugin')(Flayer)

Account = require './account.json'

Agent = Flayer.createBot {
	version: '1.12.2'
	host: Account.host
	username: Account.username
	password: Account.password
}

AgentPlugin Agent

Agent.once 'login', -> console.log 'Agent login'

Agent.once "health", -> # fix for the mineflayer bug
	if Agent.health > 0 and Agent.isAlive
		Agent.emit "spawn"

err=(t)->console.error 'error:',t

Agent.once 'spawn', -> Agent.chat 'Agent active'
Agent.on 'spawn', -> Agent.chat 'Agent respawned'