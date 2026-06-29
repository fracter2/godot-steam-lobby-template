

TODO overall multiplayer architecture strategy
Such as
- Spawning
- Syncronizing properties
- Syncronizing events
- MultiplayerLobby purpose and overview 
- World node, what is convenience vs needed

TODO The point of MultiplayerSpawner and MultiplayerSyncronizer nodes
TODO comparison with rpc techniques


## Spawning
#### the problem + my aproach

#### rpc vs spawner
Benefits of spawner
- Simple to add/remove nodes to be replicated (UI / func)
- Fully syncs for late-joining players
- Can selectively spawn/despawn nodes for induvidual players (visibility system, after setup) 
- Can spawn using custom function (by setting spawn-func)

#### why World & branches

#### Visibility

## Syncing properties
rpc vs syncer, transfer mode differences

#### Visibility

## Syncing events
RPC calls vs syncer, transfer mode differences, input prediction 101

## MultiplayerLobby
purpose, functionality, example uses, non-uses, architecture

## Misc tools and features included