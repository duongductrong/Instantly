import AppKit

/// Detects notch presence and computes pill/expanded frame origins.
enum ScreenPositionService {
    /// Whether the screen has a notch (inferred from safe area insets).
    static func hasNotch(screen: NSScreen) -> Bool {
        screen.safeAreaInsets.top > 0
    }

    /// Compute the notch region from auxiliary screen areas.
    static func notchFrame(screen: NSScreen) -> NSRect? {
        guard hasNotch(screen: screen),
              let leftArea = screen.auxiliaryTopLeftArea,
              let rightArea = screen.auxiliaryTopRightArea,
              leftArea != .zero, rightArea != .zero
        else { return nil }

        let notchX = leftArea.maxX
        let notchWidth = rightArea.minX - leftArea.maxX
        let notchY = screen.frame.maxY - screen.safeAreaInsets.top
        let notchHeight = screen.safeAreaInsets.top
        return NSRect(x: notchX, y: notchY, width: notchWidth, height: notchHeight)
    }

    /// Pill origin: centered below notch or below menu bar.
    static func pillOrigin(screen: NSScreen, pillSize: CGSize) -> NSPoint {
        let screenFrame = screen.frame
        let centerX = screenFrame.midX - pillSize.width / 2

        if hasNotch(screen: screen) {
            // Position just below the notch safe area
            let topY = screenFrame.maxY - screen.safeAreaInsets.top
            return NSPoint(x: centerX, y: topY - pillSize.height - 4)
        } else {
            // Position below menu bar (visibleFrame excludes menu bar)
            let visibleTop = screen.visibleFrame.maxY
            return NSPoint(x: centerX, y: visibleTop - pillSize.height - 4)
        }
    }

    /// Expanded origin: top-anchored from pill position, expanding downward.
    static func expandedOrigin(pillOrigin: NSPoint, expandedSize: CGSize) -> NSPoint {
        let pillTop = pillOrigin.y + DesignTokens.pillHeight
        return NSPoint(
            x: pillOrigin.x + (DesignTokens.pillWidth - expandedSize.width) / 2,
            y: pillTop - expandedSize.height
        )
    }
}
