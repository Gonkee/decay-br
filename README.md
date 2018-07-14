# DECAY-BR
A failed (or unfinished, perhaps) Battle Royale game made in Godot 3

![Screenshot](/DECAY-screenshot.png?raw=true "Screenshot")

# Info

## Game Structure

The menu (`Menu.tscn`) tells an autoloaded singleton script (`Global.gd`) to initialise an instance of 'Game.tscn', either as a server or a client peer. The Game scene contains a world scene (`World.tscn`) and a camera (`WorldView`) which will be used when the player dies in-game.

## Game.gd

The Game scene's script (`Game.gd`) initialises its network peer (`var peer`), either as a server or a client. After the network peer is initialised, it calls `tick()` (a function responsible for network updates) every 1/20th of a second.

`Game.gd` contains two arrays: `players[]` and `updatables[]`

`players[]` contains all the player objects in the current game, including other players over the network and the actual, main player in that instance of the game.

`updatables[]` contains all game objects that don't belong to players but move around the world - such as grenades and bouncy balls, but currently it only contains dropped weapons.

### `tick()` does 2 things.

**1** - it sends the `info_set` of the Game's own player to other connected peers through `rpc_unreliable("player_transform", my_id, my_player.get_info_set())`. `info_set` is a `dictionary` of variables from the player such as `translation`, `rotation` and `velocity`. It's needed as only the game's own player is controlled, and the values of the other players must be updated over the network by the other network peers, and it must update the values of its own player in the other peers as well. In the receiving end of the player's `info_set`, `set_info_set(info)` is used.

**2** - if the game instace is the server (`if(my_id == 1)`), it sends the `info_set`'s of all the updatables (dropped weapons) over the network to the other peers through `rpc_unreliable("update_updatables", info_sets)` (`info_sets` is an array of dictionaries called `info_set`). These `info_set`'s contain the values of the updatables (dropped weapons) such as gun type and ammo, but also the `updatable_id`'s of those updatables. They're needed as with these game objects (dropped weapons and potentially grenades), you want them to be synced throughout all the game instances, so only the server gets to dictate their values and send those values over the network, to keep things consistant.

The client peers, once they receive the `info_set`'s, updates the updatables in its own `updatables[]` array one by one, with the matching `updatable_id`. If there isn't an `updatable` for that `updatable_id`, then it just creates a new one according to the `info_set`. If the `updatable` exists but there's no `info_set` matching it, then the server must have deleted that `updatable`, so the client deletes it as well through `queue_free()`.

The server has access to `add_updatable()` and `delete_updatable()`, which adds/deletes `updatable`'s, but it doesn't tell the clients immediately. Rather, it waits until the next `tick()` when it `update_updatables()` and lets the clients figure it out on their own, as mentioned above. Maybe telling the clients immediately is better rather than leetting them figure it out, but I made it this way to guarantee everything's in sync, even when a player joins mid-game when there's already a bunch of `updatable`'s floating around. This could easily be fixed by just telling the client to check for existing updatables when it enters tha game, rather than trying to figure everything out in the next `tick()`.

## PlayerBasic.gd and PlayerController.gd

There are two separate scripts:
- for the main player controlled by the user in the current game (`PlayerController.gd`)
- and for the other players not controlled by the current game, but by peers over the network (`PlayerBasic.gd`).

`PlayerController.gd` inherits `PlayerBasic.gd`, so the two share the same basic functionality, but the Controller builds more functionality on top over the Basics.

`PlayerBasic.gd` has `get_info_set()` and `set_info_set(info)` to be used with `Game.gd`'s `tick()`, as mentioned above.

Both scripts have different versions of some same functions, such as `take_damage()` and `die()`. 

`take_damage()` - In the `Basic`, this functions simply calls itself (the same function) in the network peer that actually controls the player. In that game instance there would be the `Controller` and its version of this function, which actually updates the values and does something.

`die()` - This function only has one version, in `Basic`, meaning both scripts do the same thing when it's called. However, if it detects that the player is actually the main player being controlled in the game through `is_network_master()` (`set_network_master(my_id)` would have been called in `_ready()`), it calls itself in the other peers (the `Basic`, un-controlled versions of itself) through `rpc("die")` to ensure that the same player is synced properly over all the network peers.

## Inventory.gd

Each player object has an Inventory node, no matter if it's a `Basic` or `Controller`. This Inventory node contains the player's current equipped weapon, and as you may imagine, the same Inventory over different network peers must be synced properly.

The equipped weapon is the `current_equipped` object in the script. When you switch weapons, the Inventory script calls `unequip()` in `current_equipped` and sets `current_equipped` to a new gun.

There's a problem: all guns are named `Weapon`, so when you've switched guns and try to keep updating the gun's values over the network through `rpc()`, `rpc()` has a hard time finding the right `Weapon` to call. To fix this, `Inventory.gd` has a value called `equipped_id` that starts at 0 and increases by one every time the player switches weapons. All weapons that are equipped in the Inventory (including the first one) will be named using that value, including the same weapons in the other network peers, so `rpc()` will always find the right gun to update.

## Gun.gd

The gun script has a bunch of functions such as `fire()` and `reload()`, as you may expect. When `unequip()` is called, it adds a new `updatable` in the Game scene (a dropped weapon - `GunDummy.tscn` with the right values such as gun type and ammo), and `queue_free()`'s.

## Basic and Controller in the Inventory and Gun

The Inventory and Gun script have a similar  principle to the Player scripts as in their functionalities are different according to whether it is controlled by the current game (`Controller`) or some peer over the network (`Basic`). However, they don't have two separate scripts like the Player (yet). To separate the functionality, these scripts test for whether they are a `Controller` or `Basic` within functions. For example:

```
func do_some_gun_things():

  # Basic section - used by both versions
  animation()
  look_cool()
  
  if not ParentPlayer.is_network_master():
    return
  
  # Controller section - used by only Controller
  if clicked():
    fire()
  if right_clicked():
    aim()
  if pressed(KEY_R):
    reload()
```

or:

```
remote func fire(): # remote as this function is needed by rpc()

  # Basic section - used by both versions
  fire_animation()
  look_cool()
  
  # Controller section - used by only Controller
  if ParentPlayer.is_network_master():
    rpc("fire")
```
