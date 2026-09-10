
This document is intended to list common mistakes or edge-cases with setting up the common MultiplayerSpawner and MultiplayerSyncronizer nodes.


#### Player-owned MultiplayerSpawner spawning server_owned nodes
Does it spawn?
Do child MultiplayerSyncronizer's work?


#### On client, adding node to MultiplayerSpawner path, before server spawns it in
Does it work if the nodes are the same?
Does it work if a child is added afterwards, that will be synced by another child MultiplayerSpawner?