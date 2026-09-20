# Submission Checklist (Hack Club Jumpstart Haven)

## 1. Test locally
- [ ] Open `project.godot` in Godot 4.3+ and press **F5**
- [ ] Play from the title screen to the portal at least once
- [ ] Check the Output panel for red errors

## 2. GitHub
```bash
git init
git add .
git commit -m "Orpheus: Echoes of the Lost"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```
The `.gitignore` already excludes `.godot/` and export output.
Make sure the repository is **public** and contains the `.gd` and `.tscn` files.

## 3. Web export
- [ ] **Project > Export > Web** (preset included), export to `exports/index.html`
- [ ] Zip the **contents** of the export folder (`index.html` must be at the top level)

## 4. itch.io
- [ ] New project, kind of project: **HTML**
- [ ] Upload the zip, tick **This file will be played in the browser**
- [ ] Viewport size **1280 x 720**, enable **Fullscreen button**
- [ ] If the game does not start, tick **SharedArrayBuffer support** and re-test
- [ ] Add a cover image and a few screenshots
- [ ] Set visibility to **Public**

## 5. Hack Club
- [ ] Submit the itch.io link and the GitHub link with the Jumpstart Haven form

## Suggested itch.io description
> The world has fallen silent. Guide Orpheus across a moonlit, ruined forest, collect the glowing
> Echo Shards and step through the ancient portal to restore the world's voice.
> Move with A/D or the arrow keys, jump with Space/W/Up, press R to respawn.
> Made with Godot 4 for Hack Club Jumpstart Haven.
