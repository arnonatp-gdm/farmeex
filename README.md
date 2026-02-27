# farmeex
A game about driving around in a tractor doing farming stuff and having fun while learning.

## Requirements

- [Godot Engine 4.3](https://godotengine.org/download/) (stable)

## Opening the Project in Godot

> **Short answer:** You do **not** need to create a new project (no "farmeex2.0"). This repository *is* the Godot project — just open it in Godot and you're done.

1. Download and install [Godot 4.3](https://godotengine.org/download/).
2. Clone (or pull the latest version of) this repository to your computer:
   ```bash
   git clone https://github.com/arnonatp-gdm/farmeex.git
   ```
3. Open Godot. In the **Project Manager**, click **Import**.
4. Browse to the folder where you cloned the repo and select the `project.godot` file inside it.
5. Click **Import & Edit** — Godot will open the project.
6. Press **F5** (or the ▶ Play button) to run the game.

### I already have a "farmeex" project from a previous attempt — what do I do?

**You don't need to start over.** Here's how to get back on track without creating a duplicate project:

**Option A — Use this repo as your project (recommended)**

The cleanest approach is to treat this repo as the one true project folder:

1. Open Godot and **remove** the old farmeex project from your Project Manager list (right-click → Remove; this only removes the shortcut, it does not delete files).
2. Clone this repo (or `git pull` if you already cloned it previously).
3. Import `project.godot` from the cloned folder as described above.
4. If your previous attempt had scenes, scripts, or assets you want to keep, copy them from your old project folder into the matching subfolders of the cloned repo (`scenes/`, `scripts/`, etc.), then open the files in Godot and update any references if needed.
5. Commit the copied files to Git so they are version-controlled:
   ```bash
   git add scenes/ scripts/
   git commit -m "Bring in scenes and scripts from previous attempt"
   git push
   ```

**Option B — Point your existing project folder at this repo**

If you prefer to keep working in your existing project folder:

1. Copy the following files from this repo into your existing project folder, replacing any old versions:
   - `project.godot`
   - `export_presets.cfg`
   - `.github/` (entire folder)
2. Open Godot and import `project.godot` from that folder.

> **Why not farmeex2.0?** A new project name would mean re-creating all your scenes from scratch and losing Git history. Updating the same project keeps everything in one place and makes collaboration easier.

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
