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

## `tick()` does 2 things.

1 - it sends the `info_set` of the Game's own player to other connected peers through `rpc_unreliable("player_transform", my_id, my_player.get_info_set())`. `info_set` is a `dictionary` of variables from the player such as `translation`, `rotation` and `velocity`. It's needed as only the game's own player is controlled, and the values of the other players must be updated over the network by the other network peers, and it must update the values of its own player as well in the other peers..
