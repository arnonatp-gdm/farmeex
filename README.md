# farmeex
A game about driving around in a tractor doing farming stuff and having fun while learning.

## Requirements

- [Godot Engine 4.3](https://godotengine.org/download/) (stable)

## Development Setup

1. Download and install [Godot 4.3](https://godotengine.org/download/).
2. Clone this repository:
   ```bash
   git clone https://github.com/arnonatp-gdm/farmeex.git
   ```
3. Open Godot, click **Import**, and select the `project.godot` file from the cloned folder.
4. Press **F5** (or the Play button) to run the game in the editor.

## Deploying the Game

### Option 1: Automated Deployment via GitHub Actions (recommended)

This repository includes a GitHub Actions workflow (`.github/workflows/export.yml`) that automatically exports the game when you push to `main` or create a release.

**What it does:**
- Exports the game for **Windows**, **Linux**, and **Web (HTML5)**
- Uploads each build as a downloadable artifact
- Deploys the Web build to **GitHub Pages** on every push to `main`

**Steps to enable:**
1. Go to your repository **Settings → Pages** and set the source to **GitHub Actions**.
2. Push your changes to the `main` branch.
3. GitHub Actions will build and deploy automatically.
4. Download platform builds from the **Actions** tab → select a run → **Artifacts**.

### Option 2: Manual Export from the Godot Editor

1. Open the project in Godot 4.
2. Install export templates: **Editor → Manage Export Templates → Download and Install**.
3. Go to **Project → Export…**
4. Select a preset (Windows, Linux, Web, etc.) and click **Export Project**.

> **Tip:** Export presets are pre-configured in `export_presets.cfg`. You can edit them via the Godot export dialog.

### Option 3: Headless Export (CI / command line)

```bash
# Export for Windows
godot --headless --export-release "Windows Desktop" --path .

# Export for Linux
godot --headless --export-release "Linux/X11" --path .

# Export for Web
godot --headless --export-release "Web" --path .
```

Output files will be placed in the `builds/` directory as configured in `export_presets.cfg`.

## Project Structure

```
farmeex/
├── .github/
│   └── workflows/
│       └── export.yml     # CI/CD export & deploy workflow
├── scenes/
│   └── main.tscn          # Main game scene
├── scripts/               # GDScript files
├── export_presets.cfg     # Godot export presets (Windows, Linux, Web)
├── project.godot          # Godot project configuration
└── README.md
```
