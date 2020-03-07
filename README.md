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

The warehouse building type (the only type) currently spawns minions after having been created.

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
- Work-queue per minion - with central knowledge spread
    - e.g. avoid digging the same place twice

## Building logic

The issue right now is that you c´an only dig a corridor from another corridor - so by building buildings all around yourself, you can effictively get yourself in a situation where you cannot dig any more.

This needs to be handled by restricting the building placement.
