#!/bin/bash
# PushToTalk – Xcode-Projekt Setup
# Dieses Skript erstellt das Xcode-Projekt via xcodegen (falls vorhanden)
# oder gibt Anweisungen für manuelles Setup.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== PushToTalk Xcode Setup ==="

# Prüfe ob xcodegen verfügbar ist
if command -v xcodegen &>/dev/null; then
    echo "✓ xcodegen gefunden – generiere Projekt…"
    xcodegen generate
    echo "✓ Xcode-Projekt generiert: PushToTalk.xcodeproj"
    open PushToTalk.xcodeproj
else
    echo "xcodegen nicht gefunden."
    echo ""
    echo "Option A: xcodegen installieren (empfohlen):"
    echo "  brew install xcodegen"
    echo "  dann dieses Skript erneut ausführen"
    echo ""
    echo "Option B: Manuelles Xcode-Setup (siehe README)"
fi
