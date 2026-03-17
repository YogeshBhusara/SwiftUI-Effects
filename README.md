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

