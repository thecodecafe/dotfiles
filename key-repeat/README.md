# Key repeat

This macOS-only module configures faster keyboard repetition and disables press-and-hold behavior in supported code editors.

## Configure

```sh
make key-repeat
```

The script applies these global settings:

- `InitialKeyRepeat = 15`
- `KeyRepeat = 1`
- `ApplePressAndHoldEnabled = false` for VS Code, VS Code Insiders, VSCodium, VS Code Exploration, and Windsurf

Restart affected applications after running the command. The target changes macOS preferences directly, so there is no unlink operation. Running it again is safe.

If macOS refuses the global preference writes, the script restarts the current user's `cfprefsd` service and retries. If the service remains out of sync, it validates and backs up `.GlobalPreferences.plist`, changes only the two repeat keys, and verifies the result. A failed repair is rolled back automatically; the script never uses `sudo`.

For a detailed explanation of the fallback, safety checks, and rollback behavior, see [SAFETY.md](SAFETY.md).

To remove the overrides managed by this module and return to inherited macOS defaults:

```sh
make reset-key-repeat
```

The reset is safe to repeat and only deletes the global repeat settings and the listed editor-specific press-and-hold settings. It uses the same guarded repair and rollback behavior when macOS preferences are stuck. Restart affected applications afterward.
