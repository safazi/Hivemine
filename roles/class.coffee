# class.coffee
# Hivemine role base class

# todo: add more role features

class Role
	constructor: (@Name = 'unknown') ->

	onEnter: (@Agent) =>
		if @Agent
			@Hivemine = @Agent.Hivemine
			@Agent.Role = @
		@Active = true

	# todo: maybe provide hivemine reporting functions in the base class

	onExit: (CB) =>
		@Active = false
		CB() if CB

module.exports = Role