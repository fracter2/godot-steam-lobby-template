

TODO overall multiplayer architecture strategy
Such as
- Spawning
- Syncronizing properties
- Syncronizing events
- MultiplayerLobby purpose and overview
- World node, what is convenience vs needed



## Built-in tools introduction
// TODO overview of basic multiplayer concepts and Godot tools and their pros/cons

### Spawning - rpc vs MultiplayerSpawner
MultiplayerSpawner is an abstraction of rpc.
- Simple to add/remove nodes to be replicated (UI / func)
- Fully syncs for late-joining players
- Can selectively spawn/despawn nodes for induvidual players (visibility system, after setup)
- Can spawn using custom function (by setting spawn-func)

// TODO visibility testing

### Syncing properties
rpc vs syncer, transfer mode differences

// TODO visibility testing

### Syncing events
RPC calls vs syncer, transfer mode differences, input prediction 101

## Added features

### Spawning - spawn managers

This template adds ClientSpawnManager, ServerSpawnManager, and LocalSpawnManager nodes.
They are singletons (but not autoloads) that can be added to any 2d/3d scene.

// TODO multiplayer lobby

### MultiplayerLobby
purpose, functionality, example uses, non-uses, architecture

### Other tools
