# Orpheus: Echoes of the Lost

A pixel-art platformer made with **Godot 4** and **GDScript**.

The world has fallen silent. Orpheus, a hooded traveller carrying a lyre, sets out across a
ruined, moonlit forest to find the scattered **Echo Shards** and carry them to an ancient portal
that can restore the world's voice.

> Built for **Hack Club Jumpstart Haven**.

## Features

- **Tight platforming**: quick acceleration, variable jump height, coyote time and jump buffering
- **One hand-designed level** in five sections, from a gentle tutorial grove to a final sanctum
- **10 Echo Shards** to collect (the portal opens once you have 6; two are risky bonuses)
- **5 checkpoints**: ancient obelisks that light up and save your progress
- **Hazards that teach**: obsidian thorns, patrolling **Shade Crawlers** (jump on their heads to defeat them), and moving spiked orbs
- **An end portal** that stays dormant until you have enough Echoes, then blazes with light
- **Victory screen** with score, echoes collected, time and rank
- **HUD** (`ECHOES: 0/10`, `SCORE: 0000`, checkpoint progress), title screen and pause menu
- **Everything is generated in code**: pixel-art tiles, characters, effects, sound effects and music are all
  created by GDScript at runtime. There are no image or audio files to download or import.

## Controls

| Action | Keys |
| --- | --- |
| Move | `A` / `D` or `Left` / `Right` |
| Jump (hold for higher) | `Space`, `W` or `Up` |
| Respawn at last checkpoint | `R` |
| Pause | `Esc` or `P` |
| Mute / unmute music | `M` |

A gamepad also works (left stick or D-pad to move, `A` to jump).

## How to Run

1. Install **Godot 4.3 or newer** (the standard build, not .NET) from <https://godotengine.org/download>.
2. Open the Godot **Project Manager** and click **Import**.
3. Select the `project.godot` file at the root of this repository.
4. Press **F5** (Play) to run the game.

The project uses the **Compatibility** renderer, which is what Godot's Web export requires.

## Export to the Web (itch.io)

1. In Godot: **Editor > Manage Export Templates** and download the templates for your version.
2. **Project > Export**. A `Web` preset is included. If it is missing, click **Add... > Web**.
3. Click **Export Project**, choose an `exports/` folder and name the file `index.html`.
4. Zip the **contents** of that folder (so `index.html` is at the top level of the zip).
5. On itch.io, create a project with the kind **HTML**, upload the zip and tick
   **This file will be played in the browser**.
6. Set the embed size to **1280 x 720** and enable **Fullscreen button**.

See [`docs/SUBMISSION.md`](docs/SUBMISSION.md) for a full checklist.

## Project Structure

```
project.godot        Godot project file (main scene: main.tscn)
main.tscn            Entry scene: level + HUD + title, pause and end screens
export_presets.cfg   Web export preset
icon.svg             Project icon

scenes/
  player/            Orpheus
  enemies/           Shade Crawler, obsidian thorns, moving orb
  collectibles/      Echo Shard
  level/             Level 1, checkpoint, portal, hint tablet
  ui/                HUD, title screen, pause menu, victory screen
  effects/           Particle burst, ring, floating text

scripts/
  main.gd            Starts the game after the title screen
  player/            Movement, respawn, animated pixel-art visual
  enemies/           Patrolling enemy, thorns, moving orb
  collectibles/      Echo Shard behaviour
  level/             Level builder, the level map, scenery, checkpoint, portal
  ui/                HUD, menus, shared UI style
  effects/           Effect scenes and a spawn helper
  systems/           GameState (autoload), AudioManager (autoload), pixel-art generator

docs/                Level design notes and the submission checklist
```

## Editing the Level

The whole level is a text map in [`scripts/level/level_data.gd`](scripts/level/level_data.gd):
one character per 32x32 tile. Change the characters, press Play, and the terrain, collision,
enemies and collectibles all update. See [`docs/LEVEL_DESIGN.md`](docs/LEVEL_DESIGN.md).

## Credits

- Game design, code, art and audio: created for **Hack Club Jumpstart Haven**.
- Made with [Godot Engine](https://godotengine.org/) (MIT licence).
- [Hack Club](https://hackclub.com/) Jumpstart Haven: <https://haven.jumpstart.hackclub.com/>
