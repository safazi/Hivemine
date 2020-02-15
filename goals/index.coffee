Actions = {}
Needs = {}

require('./general.coffee') Actions, Needs
require('./craft.coffee') Actions, Needs
require('./util.coffee') Actions, Need

module.exports = {
	Actions
	Needs
}