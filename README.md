# SwiftUI Effects Playground

A SwiftUI app showcasing a collection of modern, animated visual effects implemented with native iOS technologies (SwiftUI, Metal, and Canvas).

## Effects

- **Slime**
  - GPU-driven metaballs / liquid blobs using Metal.
  - Controls for color, speed, clumping, animation size, cursor size, and transparency.

- **Waves**
  - Vertical line field that bends and flows like a liquid curtain.
  - Mouse / touch interaction creates strong sweeping bulges.

- **Letter Glitch**
  - Matrix-style character grid with glitchy updates and smooth color transitions.
  - Optional center and outer vignettes.

- **Gravity Balloons**
  - Colorful balloons under gravity, friction, and wall bounces.
  - Optional cursor-following attraction.

- **Dot Grid**
  - Animated dot lattice that reacts to cursor motion with springy, elastic offsets.

All effects expose a control panel with a glassy, iOS-style UI for real-time tweaking.

## Project Structure

- `EffectsApp.swift` / `ContentView.swift` – App entry and effects list.
- `UI/` – SwiftUI effect screens and control panels (one folder per effect).
- `Core/Rendering/` – Renderers and engines (e.g. Metal-based slime renderer).
- `Core/Shaders/` – Metal shader code.

## Requirements

- Xcode 16 (or newer) with iOS 18 SDK.
- iOS 18 simulator or device.

## Running the App

1. Open `Effects.xcodeproj` in Xcode.
2. Select the `Effects` scheme.
3. Run on an iOS simulator or a connected device.
4. Tap any effect in the list to open its full-screen preview and controls.

## GitHub Publishing Guide

To publish this project as a **public GitHub repo**:

1. **Initialize Git (if not already):**

   ```bash
   cd "${PWD}"
   git init
   ```

2. **Create a `.gitignore`:**

   ```bash
   cat << 'GITEOF' > .gitignore
   # Xcode & Swift
   build/
   DerivedData/
   *.xcworkspace
   xcuserdata/
   
   # Swift Package Manager
   .build/
   
   # macOS
   .DS_Store
   
   # Cursor / IDE
   .cursor/
   .idea/
   .vscode/
   GITEOF
   ```

3. **Stage and commit:**

   ```bash
   git add .
   git commit -m "Add SwiftUI effects playground"
   ```

4. **Create a new GitHub repository:**

   - Go to GitHub, click **New repository**.
   - Name it (e.g. `swiftui-effects-playground`).
   - Choose **Public**.
   - Skip the "Initialize with README" step (you already have one).

5. **Add remote and push:**

   Replace `YOUR_USERNAME` and repo name accordingly:

   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/swiftui-effects-playground.git
   git push -u origin main
   ```

After pushing, your project will be publicly available at:

```text
https://github.com/YOUR_USERNAME/swiftui-effects-playground
```

You can then add screenshots or screen recordings of each effect to the README for a nicer GitHub presentation.
