# Vox

A native macOS menu bar dictation app. Hold the Globe key (🌐), speak, release — Vox transcribes locally using Whisper and inserts the text at your cursor. No cloud, no subscription, fully local on Apple Silicon.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- **Local transcription** via [WhisperKit](https://github.com/argmaxinc/WhisperKit) (CoreML/Neural Engine optimised for Apple Silicon)
- **Globe key (🌐) or custom hotkey** — hold to record, release to transcribe & insert
- **Text insertion** via Accessibility API with Clipboard fallback for Electron apps (VS Code, Slack, etc.)
- **Animated recording orb** — floating indicator above the Dock while dictating
- **Customisable orb colour** — 7 neon presets, live preview in settings
- **Multiple Whisper models** — Tiny to Large-v3, downloadable and switchable in-app
- **Multi-language** — German, English, French, Spanish, Auto-detect
- **Runs at login**, no Dock icon (menu bar only)

## Requirements

- macOS 14.0+
- Apple Silicon (M1 or later) recommended
- Microphone access
- Accessibility permission (for global hotkey and text insertion)

## Installation

1. Clone the repo:
   ```bash
   git clone https://github.com/59v24jr6gy-coder/Vox.git
   cd Vox
   ```

2. Install [xcodegen](https://github.com/yonaskolb/XcodeGen) if not already installed:
   ```bash
   brew install xcodegen
   ```

3. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

4. Build and install:
   ```bash
   bash install.sh
   ```
   The script builds, signs and installs the app to `~/Applications/Vox.app`.

5. On first launch, Vox will request **Microphone** and **Accessibility** permissions.

## Usage

| Action | Description |
|--------|-------------|
| Hold 🌐 | Start recording |
| Release 🌐 | Transcribe and insert text |
| Click menu bar icon | Open status & settings |

## Tech Stack

| Component | Library |
|-----------|---------|
| Transcription | [WhisperKit](https://github.com/argmaxinc/WhisperKit) |
| Launch at login | [LaunchAtLogin-Modern](https://github.com/sindresorhus/LaunchAtLogin-Modern) |
| Global hotkey | CGEventTap |
| Text insertion | AXUIElement |
| Audio | AVAudioEngine |

## License

MIT
