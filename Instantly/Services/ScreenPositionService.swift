import AppKit

/// Computes pill/expanded frame origins for bottom-center positioning.
enum ScreenPositionService {
    /// Pill origin: bottom-center of the screen with margin from dock/bottom edge.
    static func pillOrigin(screen: NSScreen, pillSize: CGSize) -> NSPoint {
        let visibleFrame = screen.visibleFrame
        return NSPoint(
            x: visibleFrame.midX - pillSize.width / 2,
            y: visibleFrame.minY + DesignTokens.bottomMargin
        )
    }

    /// Expanded origin: bottom-center, sharing the same bottom edge as the pill.
    /// Panel grows upward from the bottom baseline.
    static func expandedOrigin(screen: NSScreen, expandedSize: CGSize) -> NSPoint {
        let visibleFrame = screen.visibleFrame
        return NSPoint(
            x: visibleFrame.midX - expandedSize.width / 2,
            y: visibleFrame.minY + DesignTokens.bottomMargin
        )
    }
}
