# Gruvkartong

Copyright(C) 2020 Johan Thelin

A game inspired by the amazing rymdkapsel.

![Screenshot](screenshots/front.png "Screenshot")

# Instructions

Currently you cannot do much. The idea is to create a resource mining, refining and exploration game.

## Input

- Left mouse button selects areas to dig. These have to be adjecent to a corridor (not diagonally).
- Right mouse button attempts to build a 2x2 building.

## Buildings and minions

The warehouse building type currently spawns four minions after having been created. The idea is that this is the initial building and cannot be built by the player. (currently it is possible)

The quarter building type spawns up to three minions. It is supposed to re-spawn a minion once the a minion dies, but minions cannot die, so this is kind of pointless atm.

# Todo

- Buildings!
    - Different types of buildings
        - Warehouse (always starts with one)
        - Quarters (spawns minions)
    - Tearing down buildings
    - Walking into buildings when interacting
- Doing stuff with buildings
    - Material refinement processes
- Assigning minions to tasks
    - E.g. cooking, carrying, defending, and so on
    - Random walking when bored
- Goblins
    - Appear from random blocks when digging
- Central task list, to reassign tasks when minions die, etc

## Building logic

The issue right now is that you c´an only dig a corridor from another corridor - so by building buildings all around yourself, you can effictively get yourself in a situation where you cannot dig any more.

This needs to be handled by restricting the building placement.
