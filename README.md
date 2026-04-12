# VS Code Customization

Personal VS Code settings, keybindings, and installation helpers.

## Files

- `settings.json` - VS Code user settings.
- `keybindings.json` - VS Code user keybindings.
- `install-vscode.ps1` - Installs VS Code and the expected extensions.
- `install-config.ps1` - Installs `settings.json` and `keybindings.json` into the active VS Code user directory.

## Install VS Code

```powershell
.\install-vscode.ps1
```

## Install Settings And Keybindings

Preview the destination without writing files:

```powershell
.\install-config.ps1 -WhatIf
```

Install the configuration:

```powershell
.\install-config.ps1
```

The config installer resolves the `code` command through PowerShell. When `code` points to the Scoop `vscode` package, it installs the files into the Scoop portable user-data directory:

```text
%USERPROFILE%\scoop\apps\vscode\current\data\user-data\User
```

When `code` is not the Scoop `vscode` package, it falls back to the standard VS Code user directory:

```text
%APPDATA%\Code\User
```
