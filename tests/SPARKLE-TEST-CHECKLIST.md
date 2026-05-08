# Sparkle Update Manual Test Checklist

## Pre-test Setup
- [ ] Build app with Sparkle integrated
- [ ] Verify `SUFeedURL` points to correct feed
- [ ] Verify `SUPublicEDKey` matches private key in Keychain
- [ ] Verify `CFBundleVersion` is incrementing integer
- [ ] Sign update archive with EdDSA (`sign_update`)

## Test 1: Basic Update Detection
- [ ] Launch older version (decrease CFBundleVersion temporarily)
- [ ] Trigger "Check for Updates..."
- [ ] **Verify:** Update alert appears with correct version
- [ ] **Verify:** Release notes render correctly (HTML/Markdown)

## Test 2: Download & Install
- [ ] Click "Install Update"
- [ ] **Verify:** Download progress appears
- [ ] **Verify:** "Install and Relaunch" button appears when ready
- [ ] Click "Install and Relaunch"
- [ ] **Verify:** App quits and relaunches
- [ ] **Verify:** New version is running (check About)

## Test 3: Auto-Check Behavior
- [ ] Fresh install (delete `~/Library/Preferences/com.duongductrong.Instantly.plist`)
- [ ] Launch app once, quit
- [ ] Launch app second time
- [ ] **Verify:** Permission prompt for auto-check appears (unless `SUEnableAutomaticChecks` set)

## Test 4: Self-Signed Specific
- [ ] Build with self-signed cert + `disable-library-validation`
- [ ] **Verify:** App launches without crash
- [ ] **Verify:** Sparkle framework loads (no "damaged" warning)
- [ ] **Verify:** Update check works

## Test 5: Developer ID Transition (future)
- [ ] Build with Developer ID cert (no `disable-library-validation`)
- [ ] **Verify:** App passes `codesign --verify --deep`
- [ ] **Verify:** Notarization succeeds (`xcrun notarytool submit`)
- [ ] **Verify:** Update from self-signed → Developer ID works (full archive, not delta)

## Test 6: Error Cases
- [ ] Disconnect network, trigger update
- [ ] **Verify:** Graceful error message (not crash)
- [ ] Serve invalid appcast (malformed XML)
- [ ] **Verify:** Error displayed to user
- [ ] Serve update with wrong EdDSA signature
- [ ] **Verify:** Update rejected, security warning shown

## Console Log Check
Run during tests:
```bash
log stream --predicate 'subsystem == "org.sparkle-project.Sparkle"'
```
- [ ] No XPC errors (code 4005)
- [ ] No signing/entitlement errors
- [ ] No "damaged" or "translocation" warnings
