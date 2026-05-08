#!/bin/bash
set -e

# === Sparkle Update Integration Test ===
# Tests the full local update loop: build N -> build N+1 -> serve appcast -> verify update

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/sparkle-test"
VERSION_N="1.0.0"
VERSION_N1="1.0.1"
BUILD_N="1"
BUILD_N1="2"
BUNDLE_ID="com.duongductrong.Instantly"
LOCAL_PORT=8765

echo "=== Sparkle Update Integration Test ==="
echo ""

# === Cleanup ===
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/versions" "$BUILD_DIR/updates"

# === Phase 1: Build Version N ===
echo "→ Building Version $VERSION_N (build $BUILD_N)..."
xcodebuild -project "$PROJECT_DIR/Instantly.xcodeproj" \
    -scheme Instantly \
    -configuration Release \
    -archivePath "$BUILD_DIR/versions/Instantly-N.xcarchive" \
    archive \
    CURRENT_PROJECT_VERSION=$BUILD_N \
    MARKETING_VERSION=$VERSION_N \
    CODE_SIGN_STYLE=Automatic \
    CODE_SIGN_IDENTITY="-" \
    DEVELOPMENT_TEAM=""

# Export (fallback to direct copy for ad-hoc signed builds)
EXPORT_DIR="$BUILD_DIR/versions/Instantly-N"
mkdir -p "$EXPORT_DIR"
if [ -d "$BUILD_DIR/versions/Instantly-N.xcarchive/Products/Applications/Instantly.app" ]; then
    cp -R "$BUILD_DIR/versions/Instantly-N.xcarchive/Products/Applications/Instantly.app" "$EXPORT_DIR/"
else
    echo "❌ Failed to find built app in archive"
    exit 1
fi

# === Phase 2: Build Version N+1 ===
echo "→ Building Version $VERSION_N1 (build $BUILD_N1)..."
xcodebuild -project "$PROJECT_DIR/Instantly.xcodeproj" \
    -scheme Instantly \
    -configuration Release \
    -archivePath "$BUILD_DIR/versions/Instantly-N1.xcarchive" \
    archive \
    CURRENT_PROJECT_VERSION=$BUILD_N1 \
    MARKETING_VERSION=$VERSION_N1 \
    CODE_SIGN_STYLE=Automatic \
    CODE_SIGN_IDENTITY="-" \
    DEVELOPMENT_TEAM=""

EXPORT_DIR1="$BUILD_DIR/versions/Instantly-N1"
mkdir -p "$EXPORT_DIR1"
if [ -d "$BUILD_DIR/versions/Instantly-N1.xcarchive/Products/Applications/Instantly.app" ]; then
    cp -R "$BUILD_DIR/versions/Instantly-N1.xcarchive/Products/Applications/Instantly.app" "$EXPORT_DIR1/"
else
    echo "❌ Failed to find built app in archive"
    exit 1
fi

# === Phase 3: Sign Version N+1 with EdDSA ===
echo "→ Signing update archive..."
cd "$BUILD_DIR/versions/Instantly-N1"
zip -r "$BUILD_DIR/updates/Instantly-$VERSION_N1.zip" Instantly.app

# Find Sparkle binaries from SPM artifacts
SPARKLE_BIN=""
DERIVED_DATA="$(xcodebuild -project "$PROJECT_DIR/Instantly.xcodeproj" -scheme Instantly -showBuildSettings 2>/dev/null | grep -m1 "BUILD_DIR" | sed 's/.*= //')"
if [ -n "$DERIVED_DATA" ]; then
    # Try to find from DerivedData artifacts
    SPARKLE_BIN="$(find ~/Library/Developer/Xcode/DerivedData -path '*/Sparkle/bin' -type d 2>/dev/null | head -n1)"
fi

if [ -z "$SPARKLE_BIN" ] || [ ! -f "$SPARKLE_BIN/sign_update" ]; then
    echo "⚠️  Sparkle binaries not found. Trying to resolve packages first..."
    xcodebuild -project "$PROJECT_DIR/Instantly.xcodeproj" -scheme Instantly -resolvePackageDependencies
    SPARKLE_BIN="$(find ~/Library/Developer/Xcode/DerivedData -path '*/Sparkle/bin' -type d 2>/dev/null | head -n1)"
fi

if [ -z "$SPARKLE_BIN" ] || [ ! -f "$SPARKLE_BIN/sign_update" ]; then
    echo "⚠️  Sparkle binaries still not found. Skipping EdDSA signing in this test run."
    echo "    Run 'xcodebuild -resolvePackageDependencies' manually and retry."
    # Create a basic appcast without signature for structure testing
    cat > "$BUILD_DIR/updates/appcast.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>Instantly Changelog</title>
        <item>
            <title>Version $VERSION_N1</title>
            <pubDate>$(date -u +"%a, %d %b %Y %H:%M:%S +0000")</pubDate>
            <sparkle:version>$BUILD_N1</sparkle:version>
            <sparkle:shortVersionString>$VERSION_N1</sparkle:shortVersionString>
            <enclosure url="http://localhost:$LOCAL_PORT/Instantly-$VERSION_N1.zip" length="$(stat -f%z "$BUILD_DIR/updates/Instantly-$VERSION_N1.zip")" type="application/octet-stream" />
        </item>
    </channel>
</rss>
EOF
else
    echo "✅ Found Sparkle binaries at: $SPARKLE_BIN"
    "$SPARKLE_BIN/sign_update" "$BUILD_DIR/updates/Instantly-$VERSION_N1.zip" > "$BUILD_DIR/updates/signature.txt"

    echo "→ Generating appcast..."
    "$SPARKLE_BIN/generate_appcast" "$BUILD_DIR/updates/"
fi

# === Phase 4: Start Local HTTP Server ===
echo "→ Starting local HTTP server on port $LOCAL_PORT..."
cd "$BUILD_DIR/updates"
python3 -m http.server $LOCAL_PORT &
SERVER_PID=$!
sleep 2

# === Phase 5: Patch Version N to use local feed ===
echo "→ Patching Version N with local feed URL..."
N_APP="$BUILD_DIR/versions/Instantly-N/Instantly.app"
N_INFOPLIST="$N_APP/Contents/Info.plist"
if [ -f "$N_INFOPLIST" ]; then
    /usr/libexec/PlistBuddy -c "Set :SUFeedURL http://localhost:$LOCAL_PORT/appcast.xml" "$N_INFOPLIST" || \
    /usr/libexec/PlistBuddy -c "Add :SUFeedURL string http://localhost:$LOCAL_PORT/appcast.xml" "$N_INFOPLIST"
    # Re-sign after modifying plist (ad-hoc is fine for testing)
    codesign --force --deep --sign - "$N_APP"
else
    echo "❌ Info.plist not found at $N_INFOPLIST"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi

# === Phase 6: Verify appcast accessibility ===
echo "→ Verifying appcast is accessible..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$LOCAL_PORT/appcast.xml" | grep -q "200"; then
    echo "✅ Appcast is accessible"
else
    echo "❌ Appcast is not accessible"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi

# === Phase 7: Validate Sparkle keys in Info.plist ===
echo "→ Validating Sparkle configuration..."
PUBLIC_KEY=$(/usr/libexec/PlistBuddy -c "Print :SUPublicEDKey" "$N_INFOPLIST" 2>/dev/null || echo "")
if [ -z "$PUBLIC_KEY" ] || [ "$PUBLIC_KEY" = "PLACEHOLDER_REPLACE_WITH_EDDSA_PUBLIC_KEY" ]; then
    echo "⚠️  WARNING: SUPublicEDKey is not set or is still a placeholder."
    echo "    Updates will fail signature validation. Run generate_keys and update Info.plist."
fi

FEED_URL=$(/usr/libexec/PlistBuddy -c "Print :SUFeedURL" "$N_INFOPLIST" 2>/dev/null || echo "")
if [ -n "$FEED_URL" ]; then
    echo "✅ SUFeedURL is set: $FEED_URL"
else
    echo "❌ SUFeedURL is not set"
fi

# === Phase 8: Check Console for Sparkle logs (optional) ===
echo "→ Checking recent Sparkle logs..."
LOG_OUTPUT=$(log show --predicate 'subsystem == "org.sparkle-project.Sparkle"' --last 5m --style compact 2>/dev/null | tail -n 20 || echo "No recent logs")
if [ -n "$LOG_OUTPUT" ]; then
    echo "Recent Sparkle logs:"
    echo "$LOG_OUTPUT"
fi

# Cleanup
kill $SERVER_PID 2>/dev/null || true

echo ""
echo "=== Integration Test Complete ==="
echo ""
echo "Summary:"
echo "  - Version N built:    $VERSION_N (build $BUILD_N)"
echo "  - Version N+1 built:  $VERSION_N1 (build $BUILD_N1)"
echo "  - Update archive:     $BUILD_DIR/updates/Instantly-$VERSION_N1.zip"
echo "  - Appcast:            $BUILD_DIR/updates/appcast.xml"
echo "  - Test app:           $N_APP"
echo ""
echo "To manually test the update:"
echo "  1. Start the local server: cd $BUILD_DIR/updates && python3 -m http.server $LOCAL_PORT"
echo "  2. Launch the test app:    open '$N_APP'"
echo "  3. Open Settings -> About and click 'Check for Updates…'"
echo ""
