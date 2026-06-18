# warp-dotfiles

Version-controlled [Warp](https://www.warp.dev/) configuration, symlinked into
place on each machine so file-based settings follow me everywhere.

This complements — it does not replace — Warp's cloud features:

- **Settings Sync** (cloud) handles themes, AI settings, feature toggles, and
  privacy settings automatically on login.
- **Warp Drive Workflows** (cloud) store reusable, parameterized commands
  (e.g. SSH connections).
- **This repo** captures the file-based bits Settings Sync skips: custom
  keybindings, custom themes, YAML/tab configs, and local `settings.toml`.

## Layout

```
warp-dotfiles/
├── install.ps1                         # symlink installer (Windows / PowerShell)
├── README.md
└── warp/
    ├── data/                           # -> %APPDATA%\warp\Warp\data
    │   ├── keybindings.yaml            # custom keybindings (if present)
    │   ├── tab_configs/                # launch / tab configs (TOML)
    │   └── themes/                     # custom themes
    └── config/                         # -> %LOCALAPPDATA%\warp\Warp\config
        └── settings.toml               # device settings
```

## Symlink mapping

| Repo path                       | Target on Windows                               |
| ------------------------------- | ----------------------------------------------- |
| `warp\data\tab_configs`         | `%APPDATA%\warp\Warp\data\tab_configs`          |
| `warp\data\themes`              | `%APPDATA%\warp\Warp\data\themes`               |
| `warp\data\keybindings.yaml`    | `%APPDATA%\warp\Warp\data\keybindings.yaml`     |
| `warp\config\settings.toml`     | `%LOCALAPPDATA%\warp\Warp\config\settings.toml` |

Entries whose source does not exist in the repo are skipped, so the script is
safe to run even before you've added keybindings or themes.

> Note: `settings.toml` includes some device-specific values (e.g. startup
> shell). If you don't want it shared across machines, remove that entry from
> `$Entries` in `install.ps1`.

## Set up on a new machine

1. Enable **Developer Mode** so non-admin symlink creation works:
   Settings > Privacy & security > For developers > Developer Mode.
   (Alternatively, run the installer from an elevated PowerShell.)
2. Clone and run:

   ```powershell
   git clone https://github.com/<you>/warp-dotfiles.git $env:USERPROFILE\warp-dotfiles
   cd $env:USERPROFILE\warp-dotfiles
   pwsh -ExecutionPolicy Bypass -File .\install.ps1
   ```

3. Restart Warp.

### Useful flags

```powershell
pwsh -File .\install.ps1 -DryRun   # preview changes, write nothing
pwsh -File .\install.ps1 -Force    # delete existing real targets instead of backing them up
```

Existing real files at a target are backed up to `<target>.bak-<timestamp>`
unless `-Force` is used.

## Updating

Because the targets are symlinks back into this repo, edits made in Warp land
directly in the working tree. Commit and push as usual:

```powershell
cd $env:USERPROFILE\warp-dotfiles
git add -A
git commit -m "Update Warp config"
git push
```
