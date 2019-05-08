# Hivemine
_a server-dominating Minecraft bot, powered by Mineflayer_
***
### Bots should be able to:
- Switch roles on the fly:
-- Lumberjack, Fisherman, Miner, etc.
- Cooperate on a task
-- Building, Mining, Sorting, etc.
- Use server mechanics
-- Buying/selling items, Factions, etc.

***
## Example API
_This example is written with [Fluture](https://github.com/fluture-js/Fluture "Fluture on GitHub") in mind - just an idea, subject to change._
### Craft and store a pickaxe
```coffee
# Get a free Agent, an even higher level wrapper of mineflayer
Agent = Hivemine.findFreeAgent()
if Agent
    # Have the bot craft a pickaxe and then deposit it into a labeled chest
    Agent.createItem('iron_pickaxe').chain (Item) -> # 'chain' an action if craftItem succeeds
        # Deposit pickaxe into closest chest with sign '[tools]'
         Agent.depositIntoLabeledChest Item, '[tools]'
```
### Have an item delivered
```coffee
# Request an iron pickaxe to a chest labeled '[miningcamp]'. Returns a job id to listen for.
RequestId = Hivemine.requestItemToLabeledChest 'iron_pickaxe', '[miningcamp]'
Hivemine.once RequestId, (Status) ->
    # Status has properties related to the delivery, like 'delivered', 'item', and 'chest'
    if Status.delivered
        # Item was delivered, have Agent take it from chest
        Agent.withdrawFromChest Status.item, Status.chest
        # Alternative function:
        Agent.claimDelivery Status
```
### Force new role
```coffee
Agent.changeRole 'fisherman'
# Bot would finish their current role's task and begin a new role
```
### Role concept
```coffee
class Fisherman extends Role
    onEnter: => # Called when the bot joins the role
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
            @onCaughtFish()
            
    canFish: => Agent.hasItem 'fishing_rod'
        
    startFishing: =>
        return if @fishing
        if @canFish()
            @Agent.fish (Err) -> @fishing = false
            @Agent.once 'playerCollect', onCollect
    
    onExit: => # Called when the bot has to leave its role
        # Stop fishing if we are
        @stopFishing()
        # Deposit items
        @Agent.depositIntoLabeledChest('*', '[fisher]').chain -> # '*' wildcard to deposit all items
            super() # Call when done
```
