# Hivemine.coffee
# Oversees all agents

###
	
	General ideas:
		Hivemine will store a server-by-server flatfile with important information such as locations, items, tasks, etc.
		Agents will be able to:
			- Query this flatfile
			- Request items and tasks from other Agents

###

EventEmitter = require 'events'

BaseRole = require './roles/class'

fs = require 'fs'
path = require 'path'

class ServerInformation
	constructor: (@Host, @Port = 25565, @Name) ->
		Parts = @Host.split ':'
		if Parts.length
			@Port = parseInt Parts[1]	# Server port
			@Host = Parts[0]			# Server host
			@Name = @Host if not @Name 	# Name for flatfile DB

class Hivemine extends EventEmitter # thanks wvffle!
	constructor: ->
		super()
		@Agents = []
		@Roles = {}
		@readRoles()

	inquire: (Key) =>
		# Query the flatfile for a certain key
		# Would return a forked future or something.

	addAgent: (Agent) =>
		if -1 == @Agents.indexOf Agent
			Agent.hivemineInit @
			@Agents.push Agent

	findFreeAgent: =>
		# TODO: take role into consideration
		for Agent in @Agents
			return Agent if Agent.Free

	setServer: (@ServerInformation) =>
	setAgentCount: (@AgentCount = 1) =>

	loadRole: (C) =>
		instance = new C()
		if instance.Name
			@Roles[instance.Name] = C
			return true
		false

	readRoles: =>
		# roles = path.join __dirname, 'roles'
		fs.readdir './roles/', (err, files) ->
			return err if err
			for f in files
				continue if f == 'class.coffee'
				success = @loadRole require './roles/' + f
				if not success
					console.error 'Failed to load role:',f 

	fetchRole: (Name) => # Todo: Read ./roles/ and get the role
		Role = @Roles[Name]
		new Role() if Role

	assignRole: (Agent, Role) => Agent.hivemineAssignedRole Role
	requestRoleChange: (Agent, NewRole) =>
		return if Agent.Role == NewRole
		if Agent.Role
			# Quit that role
			Agent.Role.onExit ->
				Agent.Role = undefined
				@requestRoleChange Agent, NewRole
		else
			NewRole = @fetchRole NewRole
			@assignRole Agent, NewRole if NewRole

###
	requestItem
###