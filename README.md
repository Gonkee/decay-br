# decay-br
A failed (or unfinished, perhaps) Battle Royale game made in Godot 3

# Info

## Game Structure

The menu (`Menu.tscn`) tells an autoloaded singleton script (`Global.gd`) to initialise an instance of 'Game.tscn', either as a server or a client peer. The Game scene contains a world scene (`World.tscn`) and a camera (`WorldView`) which will be used when the player dies in-game.

## Game.gd

The Game scene's script (`Game.gd`) initialises its network peer (`var peer`), either as a server or a client. After the network peer is initialised, it calls `tick()` (a function responsible for network updates) every 1/20th of a second.

`Game.gd` contains two arrays: `players[]` and `updatables[]`

`players[]` contains all the player objects in the current game, including other players over the network and the actual, main player in that instance of the game.

`updatables[]` contains all game objects that don't belong to players but move around the world - such as grenades and bouncy balls, but currently it only contains dropped weapons.

### `tick()` does 2 things.

**1** - it sends the `info_set` of the Game's own player to other connected peers through `rpc_unreliable("player_transform", my_id, my_player.get_info_set())`. `info_set` is a `dictionary` of variables from the player such as `translation`, `rotation` and `velocity`. It's needed as only the game's own player is controlled, and the values of the other players must be updated over the network by the other network peers, and it must update the values of its own player as well in the other peers..

**2** - if the game instace is the server (`if(my_id == 1)`), it sends the `info_set`'s of all the updatables (dropped weapons) over the network to the other peers through `rpc_unreliable("update_updatables", info_sets)` (`info_sets` is an array of dictionaries called `info_set`). These `info_set`'s contain the values of the updatables (dropped weapons) such as gun type and ammo, but also the `updatable_id`'s of those updatables. They're needed as with these game objects (dropped weapons and potentially grenades), you want them to be synced throughout all the game instances, so only the server gets to dictate their values and send those values over the network, to keep things consistant.

The client peers, once they receive the `info_set`'s, updates the updatables in its own `updatables[]` array one by one, with the matching `updatable_id`. If there isn't an `updatable` for that `updatable_id`, then it just creates a new one according to the `info_set`. If the `updatable` exists but there's no `info_set` matching it, then the server must have deleted that `updatable`, so the client deletes it as well through `queue_free()`.

The server has access to `add_updatable()` and `delete_updatable()`, which adds/deletes `updatable`'s, but it doesn't tell the clients immediately. Rather, it waits until the next `tick()` when it `update_updatables()` and lets the clients figure it out on their own, as mentioned above. Maybe telling the clients immediately is better rather than leetting them figure it out, but I made it this way to guarantee everything's in sync, even when a player joins mid-game when there's already a bunch of `updatable`'s floating around. This could easily be fixed by just telling the client to check for existing updatables when it enters tha game, rather than trying to figure everything out in the next `tick()`.
