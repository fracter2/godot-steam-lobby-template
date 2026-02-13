extends Node


## This autoload is supposed to serve as a collection of ALL important constants in the project.
## Excluding constants from plugins, like Steam, or when closely linked to a class (like "const" vars)

## The primary use of this autoload is to store all FILE PATHS.
## Since these are often kept as string literals, they won't update or validate automatically (without UIDs).
## This script serves to make them strongly typed constants.

# TODO ADD EQUIVOLENT TO LAYER NAMES, GROUP NAMES and COMMON META_VARS.

# TODO ADD EXISTING FILE PATHS

const MAIN_MENU := "uid://bp3lhs80g85ky"
const DEMO_GAME := "uid://dx0gencnp27xs"
const PLAYER_ENTITY := "uid://bd7v4xsokklmx"
