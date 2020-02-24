# Gruvkartong

Copyright(C) 2020 Johan Thelin

A game inspired by the amazing rymdkapsel.

![Screenshot](screenshots/front.png "Screenshot")

# Instructions

Currently you cannot do much. The idea is to create a resource mining, refining and exploration game.

## Input

- Left mouse button selects areas to dig. These have to be adjecent to a corridor (not diagonally).
- Right mouse button attempts to build a 2x2 building.

# Todo

- Buildings!
    - Different types of buildings
    - Tearing down buildings
    - Walking into buildings when interacting
- Doing stuff with buildings
    - Material refinement processes
- Assigning minions to tasks
    - E.g. cooking, carrying, defending, and so on
- Goblins
    - Appear from random blocks when digging
- Non-hardcoded minions
    - Belong to certain buildings
- Work-queue per minion
    - carry something (two paths with an item)

## Building logic

The issue right now is that you can only dig a corridor from another corridor - so by building buildings all around yourself, you can effictively get yourself in a situation where you cannot dig any more.

This needs to be handled by restricting the building placement.
