
# Godot Steam Lobby Wrapper

This is a template to quickly get started with networking using a lobby-style multiplayer setup.
It is primarily intended as a project for me to learn networking with Steam integration, and to provide reusable tools and systems.

TODO ADD LICENSE
TODO CREATE BASE FOLDER STRUCTURE (content/, core/, ui/, docs/)

### Feature Goals

##### Steam Lobby
- [X] Add joining by right-clicking friends in the steam overlay
- [X] Add getting player usernames and nicknames
- [X] Add getting player avatars
- [ ] Add joining by invite
- [ ] Add joining by launch command
- [ ] Add chat logic and callbacks

##### Steam lobby browser?
- [ ] Add finding open friend lobbies
- [ ] Add player count display with player max
- [ ] Add public lobby finding
- [ ] Add setting lobby to private
- [ ] Add sorting 
- [ ] Add setting lobby password

##### Enet Lobby
- [X] Add joining and hosting through launch commands
- [X] Add setting custom name
- [ ] Add chat logic and callbacks

##### Lobby singleton API
- [X] Add interface for player joining and player_info changes
- [X] Add lobby-implementation interface (doesn't distinguish steam or enet lobby)
- [ ] Add propper quit logic (instead of just timeout)
- [ ] Add ability to kick players
- [ ] Add chat interface and display
- [ ] Add "tab menu" player list and lobby info (names, ping, steam user link?, public/private...)
- [ ] Consider adding Steam-specific funcs for convenience (getting peer_id from steam_id)

##### Lauch Command Parser
- [X] Make a dedicated autoload
- [X] Add ability to differentiate commands from values
- [X] Allow parsing both spaces and '=' as value sepparators

##### Settings autoload
- [ ] Make a dedicated autoload
- [ ] Add dev-mode toggle
- [ ] Add basic input mapping
- [ ] Add volume adjustment and mute toggle
- [ ] Add resolution changing
- [ ] Add v-sync toggle
- [ ] Add window / borderless / fullscreen
- [ ] Add saving/setting settings from disk 

##### Constants autoload
- [ ] Make a dedicated autoload
- [ ] Make sure name is suitable. Maybe "CON"
- [ ] Add scene paths and groups and layer names
- [ ] Add tool scripts to automate?

##### Pause Menu
- [ ] Add a simple escape-menu implementation 