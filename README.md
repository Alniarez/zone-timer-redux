# ZoneTimer Redux

A rewrite of the original **ZoneTimer** by kani__. Tracks time spent and gold earned per zone, displayed on a compact HUD with a full sortable tally window.

## Features

- **Zone timer** — compact always-on-screen frame showing the current zone, time spent, and gold earned.
- **Zone tally** — scrollable list of every visited zone with total time and gold, sortable by either column.
- **CSV export** — copy all zone data to clipboard from the tally window.
- **Milestone alerts** — toast notification when you hit a time milestone in a zone.
- **AFK detection** — timer pauses automatically when you go AFK.
- **Gold tracking** — parses money loot messages to accumulate gold earned per zone.
- **Golden / standard theme** — toggle between gold and standard border on all windows.

## Slash Commands

| Command | Description |
|---------|-------------|
| `/zt` | Toggle the main timer window |
| `/zt tally` | Open the zone tally window |
| `/zt pause` | Pause the timer |
| `/zt resume` | Resume the timer |
| `/zt help` | Show command list |
| `/ztt` | Toggle the zone tally window directly |

## Settings

Open via **Escape → Options → AddOns → Zone Timer Redux**.

- **Golden theme** — gold or standard border on the timer and tally windows.
- **Window width** — resize the main timer frame (100 – 400 px).
- **Window opacity** — transparency of the main timer frame (0.1 – 1.0).
- **Font size** — text size inside the main timer frame (8 – 24).
- **Visual milestone alerts** — enable or disable toast notifications.
- **Track gold** — show or hide the gold line on the timer.
- **Sort tally by gold** — set the default sort order for the tally window.
- **Reset current zone** — clear the timer for the zone you are in right now.
- **Reset all zones** — wipe all saved zone times and milestone data.

## Compatibility

| Client | Interface |
|--------|-----------|
| Retail (The War Within) | 110207 |
| Retail PTR / next | 120001 |
| Classic Era | 11508 |
| Classic Anniversary Edition | 20505 |
| Cataclysm Classic | 40402 |
| Mists of Pandaria Classic | 50504 |

## TODO

- [ ] Per-character tracking — store and display time/gold per character instead of account-wide.
