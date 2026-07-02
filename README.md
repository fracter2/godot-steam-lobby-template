
# Godot Steam Lobby Wrapper

This is a template to quickly get started with networking using a lobby-style multiplayer setup.
It is primarily intended as a project for me to learn networking with Steam integration, and to provide reusable tools and systems.

TODO ADD LICENSE

### Multiplayer Lobby Goals

##### Steam Lobby
- [X] Add joining by right-clicking friends in the steam overlay
- [X] Add getting player usernames and nicknames
- [X] Add getting player avatars
- [ ] Add joining by invite (including UI helper)
- [ ] Add joining by launch command

##### Enet Lobby
- [X] Add joining and hosting through launch commands
- [X] Add setting custom name

##### Lobby singleton API
- [X] Add interface for player joining and player_info changes
- [X] Add lobby-implementation interface (doesn't distinguish steam or enet lobby)
- [ ] Add propper quit logic (instead of just timeout)
- [ ] Add ability to kick players
- [ ] Add "tab menu" player list and lobby info (names, ping, steam user link?, public/private...)
- [ ] Auto-disable connections when lobby is full
- [ ] Password select with peer authentication
- [ ] Banlist (steam_id?)

##### Steam lobby browser?
- [ ] Add finding open friend lobbies
- [ ] Add player count display with player max
- [ ] Add public lobby finding
- [ ] Add setting lobby to invite-only
- [ ] Add setting lobby password
- [ ] Add meta info like level, gamemode, description, mods...

##### LAN Lobby browser?
- [ ] Query broadcasts in LAN

### Convenience Goals

##### Pause Menu
- [ ] Add a simple escape-menu implementation

##### Lauch Command Parser
- [X] Make a dedicated autoload
- [X] Add ability to differentiate commands from values
- [X] Allow parsing both spaces and '=' as value sepparators
- [ ] Allow providing a launch_preset.txt file via launch_preset={filepath OR ID} command.

##### Settings autoload
- [ ] Make a dedicated autoload
- [ ] Add dev-mode toggle
- [ ] Add basic input mapping
- [ ] Add volume adjustment and mute toggle
- [ ] Add resolution changing
- [ ] Add v-sync toggle
- [ ] Add window / borderless / fullscreen
- [ ] Add saving/setting settings from disk
- [ ] Add Launch commands to set window size / location

##### Constants Autoloads
- [X] Add PATHS class to contain used file paths
- [X] Add GROUPS class to contain group names... if it isn't already a thing?
- [X] Add LAYERS class to contain layer names and bitmasks
- [X] Add META class to contain used meta names
- [X] Add editor script to auto-fill LAYERS and GROUPS scripts from settings
- [X] Add editor script to validate PATHS constants
- [ ] Add SINGLETONS class + editor script to fill fron Engine.list_singletons()
- [ ] Add RPC_CHANNEL class + editor script to validate that no channels overlap

##### Log autoload
- [X] Add Log autoload to provide an easy print() using with color coding for running multiple window tests
- [X] Add prefix support, and toggling auto_prefix_as_color
- [ ] Add support funcs to changing prefix / color anytime
- [ ] Add signals when logging
	- [ ] Add support for simultanious push to in-game Console (Console-singleton)

##### Smarter multi-window setup
- [X] Add "WindowSpawnAligner" autoload to align windows via launch conmmands (to skip having to sepparate them every time you run)
- [ ] Add loading starting from config
- [ ] Investigate starting sepparate windows AFTER START? (multi-windows without debug tab?)
	- [ ] Maybe using Shell execution
	- [ ] Potential for Tests

##### Console Autoload
- [ ] In-game console / terminal UI, in / out funcs and signals ()
- [ ] Chat functionality with Lobby (/public command?)
- [ ] Allow whispers (/whisper command?)
- [ ] Allow system messages with different color
	- [ ] Colors should be inserted as BB.
	- [ ] Rember to strip user input BB.

##### Smarter MultiplayerSpawner
To make it file-path renaming resistant, it should validate existing scene-paths on build, or add dynamically in runtime.
- [ ] Add way of adding from list (like from a level config, or on-load node, or from level node, or world method)

##### Standardized Spawning API
- [ ] ServerBranchManager
	- [X] Support server-owned spawns (only callable by server, ofc) (TEST)
- [ ] PlayerBranchManager
	- [X] Support client-owned spawns via their own branch
	- [ ] Auto-set authority on spawned nodes via group (TEST)
- [ ] LocalBranchManager
	- [X] Support local (client-side only) spawns
- [ ] SpawnableScenesConfig Resource
	- [ ] Simply lists spawnable scenes
	- [ ] Tool btn to validify they still exist
	- [ ] Can be set to any spawn managers via their inspector properties
- [X] Make managers 2D/3D agnostic
- [ ] Make managers accesable as static singleton
	- [ ] Check for duplicate managers too
- [ ] World or Spawn or SPAWN autoload, for convenience funcs to use spawn managers

##### Standardized Level Loading
- [ ] Add networked func, to load levels
- [ ] Add sending save files of levels? world state? (Only level / non-replicated spawns and vars)

### Docs
Ideally, lot's of demonstration scenes and test-tools should exists to provide examples of common use cases and pitfalls.
Not only for the Lobby code but also for general networking scenarios using MultiplayerSpawner, MultiplayerSyncronizer, rpc's, and so on.

Cases that should be tested and covered:
##### MultiplayerSpawner
- [ ] Setting authority of MultiplayerSpawner spawned nodes (Setting the authority of the root of a spawned scene DOES NOT work, but setting children is OK)
- [ ] Behaviour of MultiplayerSpawner nested in MultiplayerSpawner spawned scenes
- [ ] Sepparate authority of MultiplayerSpawner node and the target root node
- [ ] Mooving nodes to/from MultiplayerSpawner root (vs just adding / removing)
- [ ] Standard visibility behaviour
- [ ] Visibility behaviour using multiple MultiplayerSyncronizers
- [ ] Adding new spawnable scenes
- [ ] Removing spawnable scenes that are already spawned

##### MultiplayerSyncronizer
- [ ] Lag and bitrate differences between sync modes (Always/OnChange/Never)
- [ ] Comparison with using rpc calls
- [ ] Comparison when using packets
- [ ] Possible comparison to using sockets directly

##### SceneMultiplayer
- [ ] Sending / recieveing raw bytes
- [ ] Authenticating peers before accepting

##### GDSteam
- [ ] Steam.setLobbyData() and it's signal
- [ ] Steam.setMemberLobbyData() purpose
- [ ] Sending messages
- [ ] Party and Beacon functionality
- [ ] Hosting without lobby?

##### Steam Integration
- [ ] Find fun stuff, like:
	- Interacting with steam music player
	- steam player-to-player messaging
