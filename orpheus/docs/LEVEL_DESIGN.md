# Level Design

Level 1 is **200 x 30 tiles** (6400 x 960 px). It is drawn as text in
`scripts/level/level_data.gd`, one character per tile.

## Legend

| Char | Meaning | Char | Meaning |
| --- | --- | --- | --- |
| `#` | Earth with grass | `S` | Ancient stone (ruins) |
| `.` | Empty air | `P` | Player start |
| `*` | Echo Shard | `C` | Checkpoint (numbered left to right) |
| `E` | Shade Crawler (patrols the platform it stands on) | `^` | Obsidian thorns |
| `v` | Orb moving up and down | `h` | Orb moving left and right |
| `t` | Hint tablet (texts are listed in `HINTS`) | `O` | The end portal |

Rows are listed top to bottom. Every row must be exactly the same length.
Anything standing on the ground (`P`, `E`, `C`, `^`, `t`, `O`) goes in the row **above** the ground tile.

## The five sections

| # | Section | Tiles | What it teaches |
| --- | --- | --- | --- |
| 1 | **Awakening Grove** | 0-45 | Safe, flat ground. Tablets explain move and jump. A tiny step, then a 3-tile gap. |
| 2 | **Mossy Ruins** | 46-95 | First Shade Crawler on open ground, then a checkpoint, then thorns to jump over, then stepping stones that climb. |
| 3 | **Whispering Bridge** | 96-142 | Floating stone slabs over a chasm with gaps of 2-3 tiles, a moving orb, and a rest island with a checkpoint. |
| 4 | **Sunken Vault** | 143-183 | A short climb, then a high ledge combining thorns, a Crawler and a checkpoint, and a descent past a second orb. |
| 5 | **Portal Sanctum** | 184-199 | Final checkpoint, a Crawler, a thorn jump and the portal dais. |

Difficulty rises gradually: each hazard is introduced alone (tablet + safe space), then combined later.
A checkpoint sits before each of the harder sections.

## Echo Shards

10 in total. The portal needs **6** (`REQUIRED_ECHOES` in `level_data.gd`).
Eight are on the natural route. Two are optional risk/reward pickups: one above the moving orb
on the bridge and one high above the vault climb.

## Movement numbers

Gaps and heights were chosen against the values in `scripts/player/player.gd`
(max speed 250 px/s, jump velocity -650, gravity 1700). The level was checked with a movement simulation using these values. It also stays completable with a
jump about 15% lower, running 14% slower, or no coyote time, so it is not tuned to frame-perfect inputs.
If you change those constants, re-test the gaps.
