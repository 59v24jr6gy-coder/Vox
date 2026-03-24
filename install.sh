#!/bin/bash
# Vox — Build, Sign & Install
set -e
cd "$(dirname "$0")"

BUNDLE_ID="com.daviduhlig.Vox"
INSTALL_PATH="$HOME/Applications/Vox.app"
ENTITLEMENTS="Vox/Resources/Vox.entitlements"

echo "=== Vox Build & Install ==="

# 1. Build (ohne Signing — machen wir manuell)
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
echo "→ Gefunden: $APP"

# 3. Alte Version beenden
pkill -x Vox 2>/dev/null || true
sleep 0.5

# 4. Nach ~/Applications kopieren
mkdir -p ~/Applications
rm -rf "$INSTALL_PATH"
cp -R "$APP" "$INSTALL_PATH"

# 5. Korrekt signieren: Identifier + Entitlements einbetten
echo "→ Signiere mit korrektem Bundle-Identifier und Entitlements..."
codesign \
  --force \
  --deep \
  --sign - \
  --identifier "$BUNDLE_ID" \
  --entitlements "$ENTITLEMENTS" \
  --options runtime \
  "$INSTALL_PATH"

# 6. Signatur prüfen
echo "→ Signatur-Check:"
codesign -dv "$INSTALL_PATH" 2>&1 | grep -E "Identifier|Signature|flags"
echo "→ Entitlements:"
codesign -d --entitlements :- "$INSTALL_PATH" 2>/dev/null | grep -E "sandbox|audio"

# 7. TCC-Eintrag für alten Identifier löschen
echo "→ Setze Accessibility zurück..."
tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null || true
tccutil reset Accessibility com.daviduhlig.PushToTalk 2>/dev/null || true

echo ""
echo "✅ Installiert und korrekt signiert: $INSTALL_PATH"
echo ""
echo "Jetzt:"
echo "1. open ~/Applications/Vox.app"
echo "2. Einstellungen → Berechtigungen → Erlauben"
echo "3. App neu starten wenn aufgefordert"
echo ""

read -p "App jetzt öffnen? [j/N] " -n 1 -r
echo
[[ $REPLY =~ ^[JjYy]$ ]] && open "$INSTALL_PATH" || true
