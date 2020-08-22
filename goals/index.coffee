Actions = {}
Needs = {}

require('./general.coffee') Actions, Needs
require('./craft.coffee') Actions, Needs
require('./util.coffee') Actions, Needs

module.exports = {
	Actions
	Needs
}