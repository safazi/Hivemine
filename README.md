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
### Example API
_This example is written with [Fluture](https://github.com/fluture-js/Fluture) in mind - just an idea, subject to change._
```coffee
# Get a free agent
Agent = Hivemine.findFreeAgent()
if Agent
    # Have the bot craft a pickaxe and then deposit it into a labeled chest
    Agent.createItem('iron_pickaxe').chain (Item) -> # 'chain' an action if craftItem succeeds
        # Deposit pickaxe into closest chest with sign '[tools]'
         Agent.depositIntoLabeledChest '[tools]', Item
```
