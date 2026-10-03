# Open Container Protection.

English | [Español](README_es.md)

Protect the containers where loot respawns, so that players cannot move or break them.

Unlike other container protection mods, this one is designed to protect all containers that haven't been placed by players, so it will protect any container anywhere on the map. However, it also allows for the configuration of specific exceptions for any container in the game.

It emerged as a free alternative to existing container protection mods. Therefore, unlike those mods, you can do whatever you want with it without needing to credit the contributors.

Although it is inspired by iLusioN's "Container Protection" mod, it has been written completely from scratch, following a radically different approach.

To date, it has been translated into all variants of Spanish and into English.

## Features:

1. Extremely simple, lightweight, and secure.
    - Defensive programming.
    - Server-side protection.
    - No configuration required.
    - Tested on a dedicated server.
    - Cache of classes, methods, and tables.
    - Safe to add/remove with existing saves.
    - Considerations for containers with multiple sprites.

3. Container protection in:
    - Indoors, in any room.
    - Outdoors, even in remote locations.

2. Container protection against:
    - Rotate.
    - Pick up.
    - Dismantle.
    - Destroy with a sledgehammer.

4. Exceptions to container protection if:
    - A player placed them.
    - They are inside the player's safehouse.
    - The player is an administrator using cheats.
    - There is a custom exception for their type.

## Sandbox options:

1. Allow in safehouses:
    - This mod will allow you to move or break the containers where loot respawns, provided they are located inside your safehouse.
    - Default: Enabled.

2. Safehouse cooldown:
    - Once this time (in minutes) has elapsed, this mod will allow you to move or break the containers where the loot respawns inside your new safehouse.
    - This only works if the "Allow in safehouses" option is enabled.
    - Default: 20.

3. Allow in vehicle interiors:
    - This mod allow you to move or break the containers where loot respawns, provided they are located inside a vehicle (Project RV Interior mod).
    - This will leave all containers located above x:22500,y:12000 completely unprotected.
    - Default: Disabled.

4. Custom exceptions:
    - Write.
    - Default: "".

##

The recommended way to add and remove custom exceptions is via the world's context menu option, but you will not be able to see it unless you have a role with the `SandboxOptions` capability.

The cheats needed to bypass the mod's restrictions are:

- `BuildCheat`: To destroy.
- `MovablesCheat`: To rotate, pick up, and dismantle.

##

This mod is 100% human-created and AI contributions are not currently being accepted. It is released under the CC0-1.0 license and is only compatible with the latest version of Project Zomboid: 42.21.

Latest tested version of Project Zomboid: 42.21.0

Steam Workshop page: https://steamcommunity.com/sharedfiles/filedetails/?id=3774828917
