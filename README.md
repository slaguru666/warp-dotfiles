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

> The installer is **Windows / PowerShell** only. On macOS or Linux the config
> paths and symlink mechanics differ, so `install.ps1` will not work as-is.

**Prerequisites:** [Git](https://git-scm.com/) and Warp installed. The repo is
public, so cloning needs no authentication.

1. Enable **Developer Mode** so non-admin symlink creation works:
   Settings > Privacy & security > For developers > Developer Mode.
   (Alternatively, run the installer from an elevated PowerShell.)
2. Clone and run:

   ```powershell
   git clone https://github.com/slaguru666/warp-dotfiles.git $env:USERPROFILE\warp-dotfiles
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

The target roots can also be overridden (handy for testing or non-standard
installs); they default to the standard Warp locations:

```powershell
pwsh -File .\install.ps1 -DataRoot C:\tmp\data -ConfigRoot C:\tmp\config -DryRun
```

- `-DataRoot`   — defaults to `%APPDATA%\warp\Warp\data` (tab_configs, themes, keybindings.yaml)
- `-ConfigRoot` — defaults to `%LOCALAPPDATA%\warp\Warp\config` (settings.toml)

### Syncing across machines

The goal is the same on every machine: clone this repo once, then symlink its
files into wherever that machine's Warp reads its config. On most machines the
defaults are correct, so you don't pass any roots:

```powershell
git clone https://github.com/slaguru666/warp-dotfiles.git $env:USERPROFILE\warp-dotfiles
pwsh -File $env:USERPROFILE\warp-dotfiles\install.ps1
```

Use `-DataRoot` / `-ConfigRoot` only when a machine stores Warp's config
somewhere non-standard (e.g. a portable install, a custom `%APPDATA%`, or a
redirected profile). Point them at that machine's Warp `data` and `config`
folders:

```powershell
pwsh -File .\install.ps1 `
  -DataRoot   D:\PortableWarp\warp\Warp\data `
  -ConfigRoot D:\PortableWarp\warp\Warp\config
```

Tip: add `-DryRun` first to confirm the resolved roots before linking. Once
linked, every machine shares the same tracked files — edit on one, `git push`,
then `git pull` on the others. Because Warp also runs **Settings Sync** in the
cloud, prefer keeping device-specific values (startup shell, preferred editor)
out of the synced `settings.toml`, or drop that entry from `$Entries` as noted
above.

## Repository status: archived (read-only)

This repository is currently **archived** on GitHub, which means:

- **Consuming the config still works** — you can `git clone` and `git pull` on
  any number of machines and run the installer normally.
- **Pushing changes is rejected** until the repo is unarchived.

To resume contributing config updates, unarchive it first (requires the
[GitHub CLI](https://cli.github.com/)):

```powershell
gh repo unarchive slaguru666/warp-dotfiles --yes
```

## Updating

Because the targets are symlinks back into this repo, edits made in Warp land
directly in the working tree. Commit and push as usual (after unarchiving, per
the note above):

```powershell
cd $env:USERPROFILE\warp-dotfiles
git add -A
git commit -m "Update Warp config"
git push
```
