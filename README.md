# minegeld_jackpot

A small Minetest mod for a handheld lottery ticket.

Features:
- Gives 10 Minegeld on a normal use
- 0.1% chance to win 1,000,000 Minegeld jackpot
- Broadcasts jackpot to the server chat
- Brown and gold ticket with purple "J.W.I" artwork
- Admin commands to set/get/clear a player's "luck" which modifies jackpot chance

## Luck mechanics

Luck is a numeric value stored per-player. Effective jackpot chance is:

  effective_chance = base_chance * (1 + luck)

Where base_chance = 0.001 (0.1%). For example:
- luck = 0 -> chance = 0.001 (0.1%)
- luck = 1 -> chance = 0.002 (0.2%)
- luck = 999 -> chance = ~1 (capped at 1)

Admins can set very large luck (e.g., 1e10) which will make jackpot effectively guaranteed.

## Install

1. Put the `minegeld_jackpot` folder into your Minetest `mods` directory.
2. Make sure the `minegeld` mod is installed.
3. Create the ticket texture:

```bash
pip install pillow
python3 generate_ticket.py
```

This generates:
- `minegeld_jackpot/textures/minegeld_jackpot_ticket.png`

## Chat commands (admin only)

- `/mj_setluck <player> <value>` — set luck for a player (requires `server` privilege)
- `/mj_getluck <player>` — query a player's luck (requires `server` privilege)
- `/mj_clearluck <player>` — clear a player's luck (requires `server` privilege)

## Usage

Craft the ticket and use it in hand. Normal uses award 10 Minegeld. Rare jackpot wins award 1,000,000 Minegeld.
