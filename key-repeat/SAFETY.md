# Key-repeat safety details

The key-repeat module uses macOS's `defaults` command first. Direct plist editing is only a guarded fallback for the specific case where `defaults` and `cfprefsd` are out of sync.

## Read before running

> **This module changes macOS-wide keyboard settings.** `InitialKeyRepeat` and `KeyRepeat` affect every application for your user, not only Neovim or code editors.
>
> If the normal preferences API fails, the module may directly edit `~/Library/Preferences/.GlobalPreferences.plist` after validating and backing it up. It also restarts your user-level `cfprefsd` process. A failed edit is rolled back automatically, but a failed rollback requires manual recovery from the backup path printed by the script.

The command does not ask for interactive confirmation. Read the recovery and rollback sections below before running it.

## What `make key-repeat` changes

- Sets `ApplePressAndHoldEnabled=false` in supported editor domains: VS Code, VS Code Insiders, VSCodium, VS Code Exploration, and Windsurf.
- Removes the global `ApplePressAndHoldEnabled` override.
- Sets the global repeat values `InitialKeyRepeat=15` and `KeyRepeat=1`.

Missing editor domains are skipped quietly. No editor is launched or terminated.

This means a successful command does not guarantee that every listed editor domain existed or was changed.

## Recovery sequence

For the two global repeat values, the helper:

1. Tries `defaults write NSGlobalDomain` and its `-g` equivalent.
2. If the values do not match, restarts only the current user's `cfprefsd` process and retries.
3. If the preferences service is still out of sync, validates the user's `.GlobalPreferences.plist` and makes a temporary backup.
4. Changes only `InitialKeyRepeat` and `KeyRepeat` with `plutil`.
5. Restarts `cfprefsd` again and verifies both the plist and `defaults read` results.

The reset command follows the same sequence while removing those two keys. It returns them to inherited macOS defaults; it does not remember or restore a previous custom value.

## Guardrails

The direct fallback refuses to run unless `.GlobalPreferences.plist` is:

- A regular file, not a symlink.
- Writable by the current user.
- Owned by the current user's UID.
- A valid property list.

The helper never uses `sudo`, changes ownership, changes the account UID, deletes the preferences file, or rewrites unrelated keys.

## Rollback

The temporary backup is removed after successful verification. If editing or verification fails, the original plist is restored and `cfprefsd` is restarted again. If automatic restoration fails, the backup is retained and its path is printed so it can be recovered manually.

The scripts do not install software, modify Git or SSH configuration, remove tmux/Neovim processes, or persist any backup files during a successful run.
