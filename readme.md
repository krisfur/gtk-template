# GTK4 Template for Zig
For `Linux` and `MacOS`.

# Deployment Guide
If building from source get prerequisites, then run `zig build run`.

### Linux
For different distros:
- Arch: `sudo pacman -S gtk4` (often preinstalled on arch based distros)
- Debian:  `sudo apt install libgtk-4-dev`
- Fedora: `sudo dnf install gtk4-devel`
- Alpine: `apk add gtk4.0-dev build-base`

### MacOS
`brew install gtk4` -> `zig build run`


## Linux App Deployment

To integrate the app into the system (search bar/dock) without a visible terminal.

Step 1: Build Release
```bash
zig build -Doptimize=ReleaseSafe
```

Step 2: Create a `.desktop` file 

Create a file named `my-app.desktop` in `~/.local/share/applications/`:

```TOML
[Desktop Entry]
Type=Application
Name=My GTK App
Exec=/path/to/your/project/zig-out/bin/my-gtk-app
Icon=utilities-terminal
Terminal=false
Categories=Utility;GTK;
```

- Terminal=false: This ensures no terminal window appears.
- Exec: Must be the absolute path to your binary.

### macOS App Deployment
To remove the terminal window and make the app portable to other Macs.

Prerequisite: Install `dylibbundler` (automates fixing library paths).

```bash
brew install dylibbundler
```

Then use the bundling script `bundle_mac.sh` which:
- Directory Structure: Creates the standard Apple folder hierarchy.
- `Info.plist`: The critical file that stops `Terminal.app` from launching.
- dylibbundler: Recursively finds every GTK/Glib dependency in `/opt/homebrew`, copies them into the App Bundle, and rewrites the binary to look for them inside the bundle instead of on your hard drive.