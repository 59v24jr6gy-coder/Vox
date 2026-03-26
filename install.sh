#!/bin/bash
# Vox — Build, Sign & Install
set -e
cd "$(dirname "$0")"

BUNDLE_ID="com.daviduhlig.Vox"
INSTALL_PATH="$HOME/Applications/Vox.app"
ENTITLEMENTS="Vox/Resources/Vox.entitlements"
SIGN_IDENTITY="Apple Development: david.uhlix16@gmail.com (UR8LP2L8S5)"
HASH_FILE="$HOME/.vox_build_hash"

echo "=== Vox Build & Install ==="

# 1. Build (inkrementell — nur neu kompiliert wenn sich etwas geändert hat)
echo "→ Baue App..."
xcodebuild \
  -project Vox.xcodeproj \
  -scheme Vox \
  -configuration Debug \
  -destination "platform=macOS" \
  -skipPackagePluginValidation \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | tail -3

# 2. App-Pfad finden
APP=$(find ~/Library/Developer/Xcode/DerivedData/Vox-*/Build/Products/Debug -name "Vox.app" 2>/dev/null | head -1)
[ -z "$APP" ] && { echo "❌ Build nicht gefunden"; exit 1; }

# 3. Hash des neuen (unsignierten) Binaries berechnen
NEW_HASH=$(shasum -a 256 "$APP/Contents/MacOS/Vox" | awk '{print $1}')
OLD_HASH=$(cat "$HASH_FILE" 2>/dev/null || echo "")

# 4. Nur neu installieren wenn sich der Binary geändert hat
if [ "$NEW_HASH" = "$OLD_HASH" ] && [ -d "$INSTALL_PATH" ] && codesign -v "$INSTALL_PATH" 2>/dev/null; then
    echo "→ Binary unverändert — überspringe Signierung (Accessibility-Berechtigung bleibt erhalten)"
    pkill -x Vox 2>/dev/null || true
    sleep 0.3
    open "$INSTALL_PATH"
    echo "✅ Vox neugestartet (kein Neuinstallieren nötig)"
    exit 0
fi

echo "→ Neuer Build erkannt — installiere und signiere..."

# 5. Alte Version beenden
pkill -x Vox 2>/dev/null || true
sleep 0.5

# 6. Nach ~/Applications kopieren
mkdir -p ~/Applications
rm -rf "$INSTALL_PATH"
cp -R "$APP" "$INSTALL_PATH"

# 7. Mit echtem Developer-Zertifikat signieren
echo "→ Signiere mit: $SIGN_IDENTITY"
codesign \
  --force \
  --deep \
  --sign "$SIGN_IDENTITY" \
  --entitlements "$ENTITLEMENTS" \
  --options runtime \
  "$INSTALL_PATH"

# 8. Hash nach erfolgreicher Installation speichern
echo "$NEW_HASH" > "$HASH_FILE"

# 9. Signatur prüfen
echo "→ Signatur-Check:"
codesign -dv "$INSTALL_PATH" 2>&1 | grep -E "Identifier|Signature|TeamIdentifier"

# 10. DerivedData-Build löschen (verhindert doppelte Vox.app / TCC-Konflikte)
find ~/Library/Developer/Xcode/DerivedData/Vox-*/Build/Products/Debug -name "Vox.app" -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true

# 11. Alte PushToTalk-Berechtigung löschen (einmalig)
tccutil reset Accessibility com.daviduhlig.PushToTalk 2>/dev/null || true

echo ""
echo "✅ Installiert: $INSTALL_PATH"
echo ""
echo "⚠️  Binary hat sich geändert — Accessibility einmalig neu vergeben:"
echo "   Einstellungen → Berechtigungen → Erlauben → App neu starten"
echo ""

read -p "App jetzt öffnen? [j/N] " -n 1 -r
echo
[[ $REPLY =~ ^[JjYy]$ ]] && open "$INSTALL_PATH" || true
