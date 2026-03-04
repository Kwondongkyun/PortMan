# PortMan

macOS menu bar app that monitors listening ports and lets you kill processes instantly.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## What it does

- **Menu bar icon** — click to see all listening TCP ports on your machine
- **Port details** — port number, process name, PID, working directory, executable path, and full command
- **Kill with one click** — inline confirmation UI, sends SIGTERM to the process
- **Auto-refresh** — updates every 5 seconds, plus manual refresh button
- **Search** — filter by port number, process name, or path
- **Color-coded badges** — system ports (red), dev ports (blue), high ports (purple/orange)
- **Accordion detail view** — click any row to expand and see full process info

## How it works

PortMan runs `lsof -nP -iTCP -sTCP:LISTEN` to discover listening ports, then resolves each process's working directory (`lsof -d cwd`), executable path, and full command (`ps`). All lookups run concurrently using Swift async/await.

## Requirements

- macOS 13 Ventura or later
- No external dependencies

## Install

### Option A — DMG (easiest)

1. Download `PortMan.dmg` from the [Releases](https://github.com/Kwondongkyun/PortMan/releases) page
2. Open the DMG and drag **PortMan** into **Applications**
3. Launch from Applications or Spotlight

### Option B — Build from source

```bash
git clone https://github.com/Kwondongkyun/PortMan.git
cd PortMan
bash build.sh
```

`build.sh` compiles a release binary, creates `PortMan.app`, signs it ad-hoc, produces `PortMan.dmg`, and optionally copies the app to `/Applications`.

To build without prompts:

```bash
swift build -c release
```

## Run

```bash
open /Applications/PortMan.app
```

PortMan runs as a menu bar agent — no Dock icon. To quit, click the menu bar icon and press **Quit**.

## Project structure

```
PortMan/
├── Package.swift
├── build.sh                         # Build, bundle, sign, DMG
└── Sources/
    ├── PortManApp.swift             # @main entry point (MenuBarExtra)
    ├── Models/
    │   └── PortInfo.swift           # Port data model
    ├── Services/
    │   ├── ProcessRunner.swift      # Async shell command runner
    │   ├── LsofParser.swift         # lsof output parser
    │   └── PortMonitor.swift        # ObservableObject, 5s timer
    └── Views/
        ├── PortListView.swift       # Main popover view
        └── PortRowView.swift        # Individual port row + accordion
```

## License

MIT
