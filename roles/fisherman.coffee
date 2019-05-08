# fisherman.coffee
# NOTE: Purely example, subject to massive API change!

module.exports = (Role) -> # 'Role' is the base class
    class Fisherman extends Role
        constructor: -> super 'fisherman' # Give the role a name

        onEnter: => # Called when the bot joins the role
            super() # Call before we do anything
            @Agent.withdrawFromLabeledChest('fishing_rod', '[fisher]').chain ->
                @Agent.walkToSign('[fishin spot]').chain ->
                    @startFishing()

        onCaughtFish: => # Could report it to Hivemine, deposit it, eat it, etc.
            @startFishing()
            
        stopFishing: =>
            return if not @fishing
            @Agent.activateItem()
            @fishing = false
        
        onCollect: (Player, Entity) =>
            if Entity.kind == 'Drops' and Player === Agent.entity
                @Agent.removeListener 'playerCollect', @onCollect
                @onCaughtFish()
                
        canFish: => Agent.hasItem 'fishing_rod'
            
        startFishing: =>
            return if @fishing
            if @canFish()
                @Agent.fish (Err) -> @fishing = false
                @Agent.on 'playerCollect', @onCollect
        
        onExit: => # Called when the bot has to leave its role
            # Stop fishing if we are
            @stopFishing()
            # Deposit items
            @Agent.depositIntoLabeledChest('*', '[fisher]').chain -> # '*' wildcard to deposit all items
                super() # Call when done