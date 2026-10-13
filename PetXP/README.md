# PetXP

A simple, movable experience bar for your Hunter pet, for **World of Warcraft: Forever** (beta, interface 16001).

Originally written for Turtle WoW (1.12) by Micon and ported to the WoW Forever client.

## What it does

PetXP shows how far your pet is toward its next level. The bar appears when you have a pet out and disappears when you don't. It only runs for Hunters; on any other class it stays completely inactive.

- **Horizontal or vertical bar.** Horizontal shows full detail (pet level, XP numbers, percentage). Vertical is a tall, narrow bar with short text.
- **Color-coded progress.** The bar changes color as your pet gets closer to leveling (see below).
- **Movable.** Drag the bar with the left mouse button. Its position is remembered separately for each layout.
- **Settings window.** No typing required. Everything can be changed from a clean pop-up window styled like the game's own Options window.
- **Preview.** A Preview bar button shows the bar with sample data, so you can try the settings without a pet out.
- **Hide at max level.** Optionally hide the bar once your pet reaches your level.

## Installation

1. Download or copy the `PetXP` folder (it should contain `PetXP.toc` and `PetXP.lua`).
2. Place it in:
   `World of Warcraft\_classic_beta_\Interface\AddOns\`
3. Start the game (or type `/reload`) and make sure PetXP is enabled in the AddOns list at character select.

When it loads, you'll see a short message in chat telling you how to open the settings.

## Using it

### Moving the bar
Click and drag the bar with the **left mouse button**. Let go and it stays there.
If you lose it or want it back in the default spot, use **Reset Position** in the settings window or type `/petxp reset`.

### Settings window
Open it any of these ways:
- Type `/petxp` in chat
- Go to **Options > AddOns > PetXP** and click **Open settings**

| Setting | What it does |
|---|---|
| **Horizontal bar / Vertical bar** | Chooses the bar's shape and the amount of text shown. |
| **Show text on the bar** | Turns the writing on the bar on or off. |
| **Hide bar at max pet level** | Hides the bar when your pet has reached your level, since there's no more XP to gain until you level up. |
| **Preview bar** | Shows the bar with sample data while the window is open. It switches off when you close the window. |
| **Reset position** | Puts the bar back in its default spot for the current layout. |

Press **Escape** or **Close** to close the window.

### Bar colors

| Color | Meaning |
|---|---|
| Red | Under 33% of the way to the next level |
| Orange | Under 66% |
| Yellow | Under 100% |
| Green | Pet is at max level |
| Gray | Pet is dead |

## Chat commands

| Command | What it does |
|---|---|
| `/petxp` | Open the settings window |
| `/petxp toggle` | Switch between vertical and horizontal layout |
| `/petxp showtext on` / `off` | Show or hide the text on the bar |
| `/petxp hideatmax on` / `off` | Hide the bar when your pet is at max level |
| `/petxp reset` | Reset the bar position for the current layout |
| `/petxp help` | List the commands in chat |

## Known issues

- **Settings may not persist between sessions.** The WoW Forever beta has been reported to reset addon saved data on each launch. If your settings or bar position reset when you log back in, that is a beta issue rather than a problem with PetXP, and it should work normally once the beta bug is fixed.
- This addon was ported without access to the game for testing. If you see a Lua error, please report it along with the full error text.

## Version history

- **1.40** - Settings window rebuilt on the game's own frame style (marble background, gold border, bottom button bar), with radio buttons, color swatches and a Preview bar button.
- **1.30** - Added settings window, Options > AddOns page, saved bar position, `/petxp reset`, and a startup message.
- **1.20** - Ported to WoW Forever (interface 16001): modern API fixes, saved settings, and event handling.
- **1.10** - Original Turtle WoW version.
