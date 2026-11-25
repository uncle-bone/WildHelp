# WildHelp

WildHelp is a modular service hub for World of Warcraft: Forever. The first alpha is a clean-room foundation: a local listing board with explicitly triggered sharing over the current guild or party/raid addon-message scope.

## Install

1. Extract `WildHelp-0.1.0-alpha.1.zip`.
2. Copy the `WildHelp` folder into `World of Warcraft/_classic_era_/Interface/AddOns/` (use the AddOns folder for your Forever client install).
3. Restart the client or run `/reload` after the folder has been installed.
4. Enable WildHelp in the AddOns list and type `/wh`.

## Current alpha

- Save a local service listing.
- Share that listing only when you click **Share Guild** or **Share Group**.
- Display local and addon-user listings with source, age, and observed channel scope.
- Addon-message prefix: `WHLP`, protocol v1.
- Listing information currently includes category, short description, zone, and send time.

## Scope and limits

The alpha does not provide a global server or cross-layer relay. Sharing goes only through the client's `GUILD`, `PARTY`, or `RAID` addon-message channel; recipients need WildHelp and must be eligible to receive addon messages. Guild sharing is bounded by that guild channel; group sharing by the current party/raid. This release has no public-chat scanner, whisper matching, realm discovery, ratings, history, profession scan, recipe directory, provider queue, or transaction tracking. Listings expire from the local cache after seven days. No spells, invites, trades, whispers, or public messages are sent automatically.

This is a prototype, not in-game validated. See `docs/RESEARCH_INVENTORY.md` for the online project inventory and source verification status, and `docs/ATTRIBUTION.md` for source provenance.

## Development status

See `docs/PROGRESS.md`. Third-party archives have not yet been obtained or inspected, so this alpha contains no third-party code or copied assets.
